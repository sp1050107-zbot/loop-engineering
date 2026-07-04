# zbot-engineering MCP 統一集成指南

**目的**：用一個 MCP Server 統一所有 zbot-* 項目的外部工具連接  
**範圍**：GitHub、AWS、Linear、Slack（以及未來的工具）  
**語言**：中文

---

## 架構概覽

```
┌─────────────────────────────────────────┐
│     zbot-* Projects (6 個)               │
│  ┌─────────┬─────────┬─────────┐        │
│  │   AWS   │ Aladdin │ Trading │        │
│  └────┬────┴────┬────┴────┬────┘        │
│       │         │         │              │
│       └────┬────┴────┬────┘              │
│            │  MCP    │                   │
│      ┌─────▼─────────▼─────┐            │
│      │  zbot-mcp-server    │            │
│      │  (統一連接器)        │            │
│      └─────┬─────────┬─────┘            │
│            │         │                  │
│  ┌─────────┴─┬───┬───┴─────────┐       │
│  │           │   │             │        │
│ GitHub   AWS  Linear   Slack   (未來)   │
└─────────────────────────────────────────┘
```

---

## Phase 1: 基礎架構（Week 1）

### 1.1 MCP Server 目錄結構

```
zbot-engineering/mcp/
├─ package.json
├─ tsconfig.json
├─ src/
│  ├─ index.ts                    # MCP Server 主入口
│  ├─ types.ts                    # 類型定義
│  │
│  ├─ connectors/
│  │  ├─ github.connector.ts       # GitHub API wrapper
│  │  ├─ aws.connector.ts          # AWS SDK wrapper
│  │  ├─ linear.connector.ts       # Linear API wrapper
│  │  └─ slack.connector.ts        # Slack API wrapper
│  │
│  ├─ resources/
│  │  ├─ zbot-skills.resource.ts   # Skill 元數據
│  │  ├─ zbot-state.resource.ts    # 各項目的 STATE.md
│  │  └─ zbot-metrics.resource.ts  # 關鍵指標定義
│  │
│  └─ prompts/
│     ├─ loop-triage-context.ts    # Triage 上下文
│     └─ verify-checklist.ts       # Verifier 檢查清單
│
├─ dist/
│  └─ (compiled JavaScript)
│
└─ tests/
   ├─ github.test.ts
   └─ aws.test.ts
```

### 1.2 MCP Server 最小化實現

```typescript
// src/index.ts
import Anthropic from "@anthropic-ai/sdk";

interface Tool {
  name: string;
  description: string;
  input_schema: Record<string, unknown>;
}

interface ToolResult {
  type: "text" | "image";
  text?: string;
  source?: { type: "url"; url: string };
}

// MCP Server 啟動
async function startMCPServer() {
  const tools: Tool[] = [
    // GitHub Tools
    {
      name: "github_get_issues",
      description: "列出 GitHub Issues（支持過濾）",
      input_schema: {
        type: "object",
        properties: {
          repo: { type: "string", description: "e.g., zbot-aws" },
          state: { type: "string", enum: ["open", "closed"] },
          labels: { type: "array", items: { type: "string" } }
        }
      }
    },
    
    // AWS Tools
    {
      name: "aws_get_lambda_logs",
      description: "查詢 Lambda 執行日誌",
      input_schema: {
        type: "object",
        properties: {
          function_name: { type: "string" },
          filter_pattern: { type: "string" },
          time_range_minutes: { type: "integer", default: 60 }
        }
      }
    },
    
    // zbot-specific Tools
    {
      name: "zbot_get_loop_state",
      description: "讀取項目的 LOOP-STATE.md",
      input_schema: {
        type: "object",
        properties: {
          project: { 
            type: "string",
            enum: ["zbot-aws", "zbot-aladdin", "zbot-trading", 
                   "zbot-wallet", "zbot-analytics", "zbot-website"]
          }
        }
      }
    },
    
    {
      name: "zbot_update_loop_state",
      description: "更新項目的 LOOP-STATE.md",
      input_schema: {
        type: "object",
        properties: {
          project: { type: "string" },
          updates: { type: "object" }  // 部分更新
        }
      }
    }
  ];

  console.log("✅ zbot-MCP Server initialized");
  console.log(`📦 Available tools: ${tools.map(t => t.name).join(", ")}`);

  return tools;
}

// 工具執行器
async function executeTool(
  toolName: string,
  toolInput: Record<string, unknown>
): Promise<ToolResult> {
  
  switch (toolName) {
    case "github_get_issues":
      return githubGetIssues(toolInput);
    
    case "aws_get_lambda_logs":
      return awsGetLambdaLogs(toolInput);
    
    case "zbot_get_loop_state":
      return zbotGetLoopState(toolInput);
    
    case "zbot_update_loop_state":
      return zbotUpdateLoopState(toolInput);
    
    default:
      return { type: "text", text: `Unknown tool: ${toolName}` };
  }
}

// 啟動
startMCPServer()
  .then(tools => console.log("MCP Server ready"))
  .catch(err => console.error("MCP Server error:", err));
```

### 1.3 工具實現示例：zbot_get_loop_state

```typescript
// src/resources/zbot-state.resource.ts
import fs from "fs/promises";
import path from "path";

export async function zbotGetLoopState(
  input: Record<string, unknown>
): Promise<{ type: "text"; text: string }> {
  
  const project = input.project as string;
  
  // 驗證項目名稱
  const validProjects = [
    "zbot-aws", "zbot-aladdin", "zbot-trading",
    "zbot-wallet", "zbot-analytics", "zbot-website"
  ];
  
  if (!validProjects.includes(project)) {
    return {
      type: "text",
      text: `❌ Invalid project: ${project}`
    };
  }
  
  // 讀取 LOOP-STATE.md
  const stateFile = path.join(process.cwd(), `../${project}/LOOP-STATE.md`);
  
  try {
    const content = await fs.readFile(stateFile, "utf-8");
    
    return {
      type: "text",
      text: `✅ LOOP-STATE.md for ${project}:\n\n${content}`
    };
  
  } catch (error) {
    return {
      type: "text",
      text: `❌ Cannot read LOOP-STATE.md for ${project}: ${(error as Error).message}`
    };
  }
}

export async function zbotUpdateLoopState(
  input: Record<string, unknown>
): Promise<{ type: "text"; text: string }> {
  
  const project = input.project as string;
  const updates = input.updates as Record<string, unknown>;
  
  // 讀取當前內容
  const stateFile = path.join(process.cwd(), `../${project}/LOOP-STATE.md`);
  
  try {
    const content = await fs.readFile(stateFile, "utf-8");
    
    // 簡單的替換邏輯（實際應使用更複雜的 Markdown parser）
    let updated = content;
    
    // 更新 "Last run" 時間戳
    if (updates.last_run) {
      updated = updated.replace(
        /Last run: .*/,
        `Last run: ${updates.last_run}`
      );
    }
    
    // 更新 "High Priority" 部分
    if (updates.high_priority) {
      const prioritySection = updates.high_priority as string;
      updated = updated.replace(
        /## High Priority \(.*?\)\n(.*?)\n\n/s,
        `## High Priority (Agent 作用中)\n${prioritySection}\n\n`
      );
    }
    
    // 寫入更新
    await fs.writeFile(stateFile, updated);
    
    return {
      type: "text",
      text: `✅ Updated LOOP-STATE.md for ${project}`
    };
  
  } catch (error) {
    return {
      type: "text",
      text: `❌ Cannot update LOOP-STATE.md: ${(error as Error).message}`
    };
  }
}
```

---

## Phase 2: 連接器實現（Week 2-3）

### 2.1 GitHub 連接器

```typescript
// src/connectors/github.connector.ts
import { Octokit } from "@octokit/rest";

const github = new Octokit({
  auth: process.env.GITHUB_TOKEN
});

export async function githubGetIssues(input: Record<string, unknown>) {
  const repo = input.repo as string;  // e.g., "zbot-aws"
  const state = (input.state as string) || "open";
  
  const owner = "sp1050107-zbot";  // Fork owner
  
  try {
    const response = await github.issues.listForRepo({
      owner,
      repo,
      state,
      per_page: 10
    });
    
    return {
      type: "text",
      text: JSON.stringify(response.data, null, 2)
    };
  } catch (error) {
    return {
      type: "text",
      text: `❌ GitHub API error: ${(error as Error).message}`
    };
  }
}

export async function githubCreateIssue(
  repo: string,
  title: string,
  body: string
) {
  const owner = "sp1050107-zbot";
  
  return github.issues.create({
    owner,
    repo,
    title,
    body
  });
}

export async function githubCreateComment(
  repo: string,
  issue_number: number,
  body: string
) {
  const owner = "sp1050107-zbot";
  
  return github.issues.createComment({
    owner,
    repo,
    issue_number,
    body
  });
}
```

### 2.2 AWS 連接器

```typescript
// src/connectors/aws.connector.ts
import AWS from "aws-sdk";

const cloudwatch = new AWS.CloudWatchLogs({
  region: process.env.AWS_REGION || "ap-northeast-1"
});

export async function awsGetLambdaLogs(input: Record<string, unknown>) {
  const functionName = input.function_name as string;
  const filterPattern = (input.filter_pattern as string) || "";
  const timeRangeMinutes = (input.time_range_minutes as number) || 60;
  
  const startTime = Date.now() - timeRangeMinutes * 60 * 1000;
  
  try {
    const response = await cloudwatch.filterLogEvents({
      logGroupName: `/aws/lambda/${functionName}`,
      startTime,
      interleaved: true,
      filterPattern
    }).promise();
    
    return {
      type: "text",
      text: JSON.stringify(response.events, null, 2)
    };
  } catch (error) {
    return {
      type: "text",
      text: `❌ AWS CloudWatch error: ${(error as Error).message}`
    };
  }
}
```

---

## Phase 3: Skill 集成（Week 3-4）

### 3.1 在 LOOP.md 中配置 MCP

```markdown
# LOOP.md — zbot-aws

## MCP Configuration

### Server
- Name: zbot-mcp-server
- Address: localhost:3000 (development) or serverless endpoint (production)
- Auth: AWS IAM + GITHUB_TOKEN

### Available Connectors
- **github**: Read/write issues, create comments
- **aws**: Query CloudWatch logs, Lambda metrics
- **linear**: (future) Manage Linear issues
- **slack**: (future) Post alerts

### Usage in Skills

In `loop-triage` skill:
```python
# Call MCP to get Loop State
mcp.call("zbot_get_loop_state", {"project": "zbot-aws"})

# Call MCP to get Lambda logs
mcp.call("aws_get_lambda_logs", {
  "function_name": "zbot-processor",
  "filter_pattern": "ERROR"
})

# Call MCP to create GitHub issue
mcp.call("github_create_issue", {
  "repo": "zbot-aws",
  "title": "Lambda cold start time exceeded",
  "body": "..."
})
```

### Security & Scopes

- Read-only access for triage (Phase 1)
- Read + comment for assisted fixes (Phase 2)
- Full access only after human review (Phase 3)
```

### 3.2 Skill 中使用 MCP

```markdown
# zbot-engineering/skills/loop-triage/SKILL.md

## Requirements

- Python 3.9+
- MCP Server: zbot-mcp-server (running on localhost:3000)
- AWS Credentials: via AWS_PROFILE env
- GitHub Token: via GITHUB_TOKEN env

## Integration

### Read Loop State
```python
from mcp_client import MCPClient

client = MCPClient("http://localhost:3000")

# 讀取所有項目的 LOOP-STATE.md
for project in ["zbot-aws", "zbot-aladdin", "zbot-trading"]:
    state = client.call("zbot_get_loop_state", {"project": project})
    print(f"[{project}] Last run: {state['last_run']}")
```

### Create Issues
```python
# 檢測到問題，自動建立 GitHub Issue
if lambda_cold_start > 5:
    issue = client.call("github_create_issue", {
        "repo": "zbot-aws",
        "title": f"Lambda cold start: {lambda_cold_start}s",
        "body": f"Detected on {datetime.now()}"
    })
    print(f"Issue created: {issue.get('html_url')}")
```
```

---

## 部署指南

### 開發環境

```bash
# 1. 安裝依賴
cd zbot-engineering/mcp
npm install

# 2. 編譯
npm run build

# 3. 啟動 MCP Server
npm start
# → Server listening on http://localhost:3000

# 4. 測試
curl http://localhost:3000/health
# → {"status": "ok", "tools": [...]}
```

### 生產環境

部署到 AWS Lambda（無伺服器）：

```bash
# 1. 打包
npm run build:lambda

# 2. 上傳到 AWS
aws lambda update-function-code \
  --function-name zbot-mcp-server \
  --zip-file fileb://dist/lambda.zip \
  --region ap-northeast-1

# 3. 驗證
aws lambda invoke \
  --function-name zbot-mcp-server \
  --region ap-northeast-1 \
  --payload '{"action": "health"}' \
  /tmp/response.json

cat /tmp/response.json
```

---

## 下一步

- [ ] Week 1: 建立基礎 MCP 框架
- [ ] Week 2: GitHub 連接器完成
- [ ] Week 3: AWS 連接器完成 + Skill 集成
- [ ] Week 4: Linear/Slack 連接器 + 生產部署

---

**引用**：
- MCP 官方：https://modelcontextprotocol.io
- Anthropic SDK：https://github.com/anthropics/anthropic-sdk-python
