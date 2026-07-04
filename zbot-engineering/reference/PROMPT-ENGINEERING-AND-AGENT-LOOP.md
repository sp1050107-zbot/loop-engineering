# 提示詞工程 + Skills/MCP + Pre-Agent 深度循環開發計劃

**目標**：從「架構設計」→ **「提示詞工程」→ 「Skills/MCP 系統」→ 「Pre-Agent 框架」** → 真正的循環開發  
**核心概念**：AI Agent 的能力取決於 **提示詞品質** + **工具生態** + **前置代理準備**  
**時間**：漸進式迭代（Week 1-4 深化，Week 5+ 循環運行）

---

## 📊 循環開發的四層金字塔

```
                    ┌──────────────────┐
                    │  業務循環開發     │
                    │  (Autonomous Loop) │
                    └────────┬─────────┘
                             │
                    ┌────────▼──────────┐
                    │  Pre-Agent 框架    │
                    │  (Agent Preparation)│
                    │  - 狀態初始化      │
                    │  - 依賴檢查        │
                    │  - Context 注入    │
                    └────────┬──────────┘
                             │
                    ┌────────▼──────────┐
                    │  Skills/MCP 生態   │
                    │  (Tool Ecosystem)  │
                    │  - Custom Skills   │
                    │  - MCP Servers     │
                    │  - Tool Registry   │
                    └────────┬──────────┘
                             │
                    ┌────────▼──────────┐
                    │  提示詞工程        │
                    │  (Prompt Design)   │
                    │  - System Prompts  │
                    │  - Task Templates  │
                    │  - Refinement Loop │
                    └───────────────────┘
```

---

## 1️⃣ 提示詞工程深度規劃

### A. System Prompts for Each Layer

#### Infrastructure Agent System Prompt

```
你是一個 AWS Terraform 架構設計專家，擁有以下能力：

【背景】
- 精通 AWS 最佳實踐、Terraform IaC、成本優化
- 理解 zbot 的業務邏輯和技術棧 (EKS、RDS、Lambda、Cloudflare)
- 關注安全性、可靠性、成本效益

【能力範圍】
1. 從自然語言需求理解基礎設施意圖
   - 識別資源類型 (compute, storage, network, security)
   - 確定環保相關性約束 (region, availability zones, compliance)
   - 評估成本影響

2. 生成生產級 Terraform 代碼
   - 遵循 DRY 原則（使用 modules, variables）
   - 應用最少權限原則 (IAM policies)
   - 實施加密、監控、告警
   - 包含 outputs 和 local 變數

3. 驗證和成本估算
   - 使用 tflint, checkov, terraform validate
   - 調用 Infracost API 估算月度成本
   - 對比成本與預算

4. 與其他 Agent 協作
   - 告知 Security Agent 新的 IAM 資源
   - 通知 SRE Agent 新的監控需求
   - 提供給 Release Agent 部署配置

【輸出格式】
- Terraform 文件（main.tf, variables.tf, outputs.tf）
- 成本估算報告
- 驗證結果
- 改進建議

【約束】
- 僅生成可通過 terraform validate 的代碼
- 嚴禁硬編碼密鑰或敏感信息
- 遵循 semantic versioning（v1.0.0 format）
- 每個資源必須添加標籤：Environment, Project, Owner, CostCenter
```

#### Security Agent System Prompt

```
你是 Cloudflare + AWS 安全治理專家。

【能力】
1. CVE/漏洞應對
   - 解析 CVE 報告，評估對 zbot 的影響
   - 生成 Cloudflare WAF 表達式規則
   - 在 Staging 環境測試，無誤殺率 < 0.01%
   - 自動部署到 Production

2. IAM 動態管理
   - 監控 CloudTrail 異常操作
   - 識別過度授權（30天未使用的權限）
   - 自動生成 IAM 縮減 PR
   - 管理密鑰輪轉（90天一次）

3. 合規審計
   - 生成 SOC2/ISO27001 報告
   - 追蹤密鑰版本
   - 維護審計日誌

【與其他 Agent 協作】
- Infrastructure Agent: 驗證 IAM 策略
- SRE Agent: 提供安全告警規則
- Release Agent: 簽署檢查
```

### B. Task Templates (Prompt 模板库)

```yaml
# templates/infrastructure-requests.yaml

templates:
  - name: "create_database"
    description: "建立新數據庫"
    prompt_template: |
      建立一個 {engine} 資料庫，配置如下：
      - Engine: {engine} ({version})
      - Instance: {instance_class}
      - Storage: {storage_gb} GB
      - Region: {region}
      - Multi-AZ: {multi_az}
      - Backup: {backup_retention_days} 天
      - 預估月成本上限: ${cost_limit}
      
      要求：
      1. 生成完整的 Terraform 代碼
      2. 估算實際月成本
      3. 如超預算 ${cost_limit}，建議優化方案
      4. 提供 Runbook（如何連接、備份、恢復）
    
    parameters:
      - name: engine
        type: enum
        values: [mysql, postgresql, mariadb]
        default: postgresql
      
      - name: instance_class
        type: enum
        values: [db.t3.small, db.t3.medium, db.r6i.large]
        default: db.t3.medium
      
      - name: region
        type: enum
        values: [us-west-2, ap-northeast-1, eu-west-1]
        default: ap-northeast-1
      
      - name: cost_limit
        type: number
        default: 100
    
    expected_output:
      - terraform_files: [main.tf, variables.tf, outputs.tf]
      - cost_estimate: {monthly: float, yearly: float}
      - runbook: string
      - validation_status: PASS/FAIL

  - name: "update_iam_policy"
    description: "更新 IAM 策略"
    prompt_template: |
      為 {role_name} 更新 IAM 策略：
      
      當前權限: {current_permissions}
      所需操作: {required_actions}
      最小權限原則: 只授予必要的權限
      
      要求：
      1. 生成新的 IAM policy JSON
      2. 比較修改前後的權限
      3. 識別可能移除的過度授權
      4. 提供回滾計劃
    
    parameters:
      - name: role_name
        type: string
      
      - name: required_actions
        type: list
    
    expected_output:
      - iam_policy: json
      - permission_diff: {added: list, removed: list}
      - impact_analysis: string
```

### C. Prompt Refinement Loop

```
Week 1-2: 基礎提示詞
  ├─ 每個 Agent 的 System Prompt v1.0
  ├─ 執行 10 個測試任務
  └─ 收集失敗案例

Week 3: 提示詞優化迴圈
  ├─ 分析失敗的 10 個案例
  ├─ 重寫提示詞（加入約束、示例）
  ├─ Prompt Calibration（通過 Claude API 測試）
  └─ 驗證成功率 > 90%

Week 4+: 持續改進
  ├─ 每周收集新的失敗案例
  ├─ 修改 System Prompt
  ├─ A/B 測試新舊提示詞
  └─ 版本化管理提示詞 (prompt-v1.0.md, prompt-v1.1.md)
```

---

## 2️⃣ Skills/MCP 系統設計

### A. Custom Skills 架構

```yaml
# ~/.claude/skills/zbot/

zbot/
├── SKILL.md                              # Skill 定義
├── bin/
│   ├── zbot-infra-generate              # 生成 Terraform
│   ├── zbot-cost-estimate               # 成本估算
│   ├── zbot-security-scan               # 安全掃描
│   ├── zbot-sre-diagnose                # SRE 診斷
│   └── zbot-release-canary              # 發版管理
└── lib/
    ├── infrastructure.py
    ├── security.py
    ├── observability.py
    ├── deployment.py
    └── common.py

# /zbot-infra-generate SKILL.md
name: zbot-infra-generate
description: "Generate Terraform infrastructure code from natural language requirements"

usage: |
  /zbot-infra-generate
  
  Takes natural language requirement from Slack/GitHub Issue:
  
  Input:
    - Issue URL or Slack message
    - Extract requirement details
  
  Process:
    1. Parse requirement → structured JSON
    2. Validate against zbot architecture
    3. Generate Terraform code
    4. Run validation (tflint, checkov)
    5. Estimate cost (Infracost API)
    6. Create PR on GitHub
  
  Output:
    - PR URL with full Terraform configuration
    - Cost estimate
    - Validation report
```

### B. MCP Server for zbot

```python
# mcp_server_zbot.py

"""
MCP Server for zbot Infrastructure Automation

Provides tools for:
1. Terraform generation and validation
2. AWS/Cloudflare resource queries
3. Cost estimation
4. Security policy generation
5. Runbook creation
"""

from mcp.server import Server, Tool
import json

server = Server("zbot-automation")

# Tool 1: Generate Terraform
@server.tool()
def generate_terraform(requirement: str, environment: str = "staging") -> dict:
    """
    Generate Terraform configuration from requirement
    
    Args:
        requirement: Natural language requirement description
        environment: "dev", "staging", "production"
    
    Returns:
        {
            "status": "success" | "error",
            "terraform_files": {...},
            "estimated_cost": 45.50,
            "validation_status": "PASS" | "FAIL"
        }
    """
    
    # 調用 Infrastructure Agent
    agent = InfrastructureAgent()
    result = agent.generate_terraform(requirement, environment)
    return result

# Tool 2: Estimate Cost
@server.tool()
def estimate_cost(terraform_code: str) -> dict:
    """Estimate AWS infrastructure cost using Infracost API"""
    
    infracost = InfracostClient()
    estimate = infracost.breakdown(terraform_code)
    return {
        "monthly": estimate["total_monthly_cost"],
        "yearly": estimate["total_monthly_cost"] * 12,
        "breakdown": estimate["resources_breakdown"]
    }

# Tool 3: Validate Terraform
@server.tool()
def validate_terraform(terraform_files: dict) -> dict:
    """Validate Terraform code (tflint, checkov, terraform validate)"""
    
    validator = TerraformValidator()
    result = validator.validate_all(terraform_files)
    return {
        "syntax": result.syntax_check,
        "security": result.security_scan,
        "compliance": result.compliance_check,
        "errors": result.errors,
        "warnings": result.warnings
    }

# Tool 4: Generate Runbook
@server.tool()
def generate_runbook(resource_type: str, operation: str) -> str:
    """
    Generate Runbook for infrastructure operations
    
    Example:
      generate_runbook("rds", "backup_restore")
      → Returns step-by-step restore guide
    """
    
    agent = SREAgent()
    runbook = agent.generate_runbook(resource_type, operation)
    return runbook

# Tool 5: Check IAM Permissions
@server.tool()
def check_iam_permissions(resource: str, role: str) -> dict:
    """
    Check if role has necessary permissions for resource
    
    Returns:
        {
            "has_permission": true | false,
            "required_permissions": [...],
            "missing_permissions": [...],
            "recommendation": "Grant these permissions"
        }
    """
    
    iam_checker = IAMChecker()
    result = iam_checker.check_permission(resource, role)
    return result

# Tool 6: Query AWS Resources
@server.tool()
def query_aws_resources(query: str, filters: dict = None) -> list:
    """
    Query AWS resources using natural language
    
    Example:
      query_aws_resources("RDS databases in us-west-2 with > 50GB storage")
      → Returns list of matching RDS instances
    """
    
    aws_client = AWSResourceClient()
    results = aws_client.query(query, filters)
    return results

# Tool 7: Generate WAF Rules
@server.tool()
def generate_waf_rules(cve_info: dict) -> list:
    """
    Generate Cloudflare WAF rules for CVE
    
    Example:
      generate_waf_rules({
        "id": "CVE-2024-12345",
        "description": "Log4j RCE",
        "workaround": "Disable JNDI"
      })
      → Returns Cloudflare WAF expressions
    """
    
    security_agent = SecurityAgent()
    rules = security_agent.generate_waf_rules(cve_info)
    return rules

if __name__ == "__main__":
    server.run()
```

### C. MCP Server Registration

```json
// ~/.claude.json

{
  "mcpServers": {
    "zbot": {
      "type": "stdio",
      "command": "python",
      "args": ["/path/to/mcp_server_zbot.py"],
      "env": {
        "AWS_PROFILE": "zbot_leonlin",
        "CLAUDE_API_KEY": "sk-...",
        "INFRACOST_API_KEY": "icst_..."
      }
    }
  }
}
```

---

## 3️⃣ Pre-Agent 框架設計

### A. Pre-Agent Checklist

```python
# src/pre_agents/pre_agent_executor.py

class PreAgentExecutor:
    """
    在 Agent 執行前進行準備工作
    """
    
    async def pre_execute_checks(self, task: dict) -> dict:
        """
        執行前檢查清單
        
        Checklist:
        1. ✅ Context 驗證
        2. ✅ 依賴檢查
        3. ✅ 權限檢查
        4. ✅ 資源可用性
        5. ✅ 提示詞驗證
        """
        
        checks = {
            "context_valid": await self._validate_context(task),
            "dependencies_available": await self._check_dependencies(task),
            "permissions_granted": await self._check_permissions(task),
            "resources_available": await self._check_resources(task),
            "prompt_valid": await self._validate_prompt(task)
        }
        
        if not all(checks.values()):
            return {
                "status": "blocked",
                "failures": [k for k, v in checks.items() if not v],
                "remediation": self._suggest_remediation(checks)
            }
        
        return {"status": "ready", "all_checks": "passed"}
    
    async def _validate_context(self, task: dict) -> bool:
        """
        驗證任務上下文是否完整
        
        Required context:
        - User role (DevOps, SRE, Security, Release)
        - Project (zbot-aladdin, zbot-trading, etc)
        - Environment (dev, staging, prod)
        - Authorization level
        """
        
        required_fields = [
            "user_role",
            "project",
            "environment",
            "authorization"
        ]
        
        context = task.get("context", {})
        return all(field in context for field in required_fields)
    
    async def _check_dependencies(self, task: dict) -> bool:
        """
        檢查所有必需的依賴是否可用
        
        Dependencies:
        - AWS credentials (profile zbot_leonlin)
        - Terraform CLI v1.6+
        - GitHub API token
        - Cloudflare API token
        - Docker (for testing)
        """
        
        required_tools = [
            ("aws", "--version"),
            ("terraform", "-version"),
            ("tflint", "--version"),
            ("checkov", "--version"),
            ("gh", "--version")
        ]
        
        for tool, cmd in required_tools:
            result = subprocess.run(
                [tool] + cmd.split(),
                capture_output=True,
                text=True
            )
            if result.returncode != 0:
                return False
        
        return True
    
    async def _check_permissions(self, task: dict) -> bool:
        """
        檢查用戶是否有權執行此任務
        
        RBAC checks:
        - DevOps: can deploy to staging/production
        - SRE: can execute remediation in production
        - Security: can deploy WAF rules
        - Release Manager: can approve canary
        """
        
        user_role = task["context"]["user_role"]
        action = task.get("action")
        environment = task["context"]["environment"]
        
        # 定義權限矩陣
        permissions = {
            "DevOps": {
                "deploy": ["staging", "dev"],
                "modify_infrastructure": ["staging", "dev"]
            },
            "SRE": {
                "execute_remediation": ["all"],
                "modify_alerts": ["all"]
            },
            "Security": {
                "deploy_waf": ["prod"],
                "rotate_secrets": ["all"]
            },
            "Release": {
                "approve_canary": ["all"],
                "promote_traffic": ["prod"]
            }
        }
        
        if user_role not in permissions:
            return False
        
        allowed_envs = permissions[user_role].get(action, [])
        return environment in allowed_envs or "all" in allowed_envs
    
    async def _check_resources(self, task: dict) -> bool:
        """
        檢查必需的 AWS/Cloudflare 資源是否存在
        """
        
        project = task["context"]["project"]
        
        # 檢查 AWS 資源
        aws_resources = await self._query_aws_resources(project)
        
        # 檢查 Cloudflare 資源
        cf_resources = await self._query_cloudflare_resources(project)
        
        return len(aws_resources) > 0 and len(cf_resources) > 0
    
    async def _validate_prompt(self, task: dict) -> bool:
        """
        驗證 Agent System Prompt 是否版本匹配
        
        Check:
        - Prompt version exists
        - Prompt version matches agent version
        - Prompt contains required sections
        """
        
        agent_type = task.get("agent_type")
        prompt_path = f"./prompts/{agent_type}-prompt-v{PROMPT_VERSION}.md"
        
        if not os.path.exists(prompt_path):
            return False
        
        with open(prompt_path) as f:
            content = f.read()
        
        required_sections = [
            "【背景】",
            "【能力範圍】",
            "【輸出格式】",
            "【約束】"
        ]
        
        return all(section in content for section in required_sections)
```

### B. Pre-Agent State Initialization

```python
# src/pre_agents/state_initializer.py

class StateInitializer:
    """
    初始化 Agent 執行狀態
    """
    
    async def initialize_agent_state(self, agent_type: str, task: dict) -> dict:
        """
        準備 Agent 的初始狀態
        
        Returns:
        {
            "agent_id": "uuid",
            "context": {...},
            "tools_available": [...],
            "memory": {...},
            "sla": {"deadline": "...", "max_retries": 3}
        }
        """
        
        agent_id = str(uuid.uuid4())
        
        context = {
            "user": task["context"]["user"],
            "project": task["context"]["project"],
            "environment": task["context"]["environment"],
            "timestamp": datetime.utcnow().isoformat(),
            "request_id": task.get("request_id")
        }
        
        # 根據 Agent 類型加載工具
        tools = await self._load_tools_for_agent(agent_type)
        
        # 加載記憶（如果有）
        memory = await self._load_agent_memory(agent_type)
        
        # 設置 SLA
        sla = self._setup_sla(agent_type, task)
        
        return {
            "agent_id": agent_id,
            "agent_type": agent_type,
            "context": context,
            "tools_available": tools,
            "memory": memory,
            "sla": sla,
            "status": "initialized"
        }
    
    async def _load_tools_for_agent(self, agent_type: str) -> list:
        """
        根據 Agent 類型加載可用工具
        """
        
        tool_manifest = {
            "infrastructure": [
                "generate_terraform",
                "estimate_cost",
                "validate_terraform",
                "query_aws_resources"
            ],
            "security": [
                "generate_waf_rules",
                "check_iam_permissions",
                "scan_cve",
                "rotate_secrets"
            ],
            "sre": [
                "diagnose_alert",
                "generate_runbook",
                "execute_remediation",
                "verify_fix"
            ],
            "release": [
                "generate_canary_manifest",
                "monitor_deployment",
                "auto_rollback",
                "generate_report"
            ]
        }
        
        tools = tool_manifest.get(agent_type, [])
        
        # 驗證每個工具都已通過 MCP 註冊
        available_tools = []
        for tool in tools:
            if await self._verify_tool_available(tool):
                available_tools.append(tool)
        
        return available_tools
    
    def _setup_sla(self, agent_type: str, task: dict) -> dict:
        """
        設置 Agent 執行的 SLA（服務等級協議）
        """
        
        sla_defaults = {
            "infrastructure": {"deadline_minutes": 30, "max_retries": 3},
            "security": {"deadline_minutes": 5, "max_retries": 2},  # CVE urgent
            "sre": {"deadline_minutes": 10, "max_retries": 5},
            "release": {"deadline_minutes": 45, "max_retries": 2}
        }
        
        sla = sla_defaults.get(agent_type, {})
        
        # 如果任務指定了優先級，調整 deadline
        if task.get("priority") == "critical":
            sla["deadline_minutes"] = sla["deadline_minutes"] // 2
        
        sla["deadline"] = (
            datetime.utcnow() + timedelta(minutes=sla["deadline_minutes"])
        ).isoformat()
        
        return sla
```

---

## 4️⃣ 真正的循環開發流程

### A. Autonomous Development Loop

```
┌─────────────────────────────────────────────────────────────┐
│                   CTO Dashboard                              │
│         (監督循環進度、批准關鍵決策、調整策略)                │
└────────────────────┬────────────────────────────────────────┘
                     │ 監控 + 報告
                     ▼
┌─────────────────────────────────────────────────────────────┐
│              循環開發協調器 (Loop Coordinator)                │
│  - 決策關鍵決策點 (Approval Gate)                           │
│  - 觸發下一個 Agent                                         │
│  - 收集 Agent 產出                                         │
└────────────┬────────────────┬────────────────┬──────────────┘
             │                │                │
             ▼                ▼                ▼
    ┌─────────────┐   ┌────────────┐   ┌────────────┐
    │ Pre-Agent   │   │ Agent Task │   │Verification│
    │ Executor    │   │Executor    │   │Executor    │
    │ ✅ Context  │   │✅ Generate │   │✅ Test     │
    │ ✅ Deps     │   │✅ Validate │   │✅ QA       │
    │ ✅ Perms    │   │✅ Estimate │   │✅ Security │
    └──────┬──────┘   └──────┬─────┘   └────┬───────┘
           │                 │              │
           └────────┬────────┴──────────────┘
                    │ (Success / Failure)
                    ▼
        ┌─────────────────────────────┐
        │  Report + Feedback Loop      │
        │  - Document results          │
        │  - Update prompts if needed  │
        │  - Log metrics               │
        │  - Trigger next iteration    │
        └─────────────────────────────┘
```

### B. Loop Configuration

```yaml
# loop-config.yaml

loop_cycles:
  - cycle: 1
    title: "Infrastructure Planning"
    agents:
      - type: infrastructure
        task: "analyze_requirements"
        prompt: "Review GitHub issues for infrastructure needs"
        approval: "DevOps Lead"
        timeout_minutes: 30
    
    metrics:
      - "pr_created"
      - "terraform_validated"
      - "cost_estimated"
  
  - cycle: 2
    title: "Security Assessment"
    agents:
      - type: security
        task: "assess_security"
        dependencies: ["cycle-1"]
        approval: "Security Lead"
    
    metrics:
      - "waf_rules_generated"
      - "iam_audit_complete"
  
  - cycle: 3
    title: "SRE Readiness"
    agents:
      - type: sre
        task: "prepare_runbooks"
        dependencies: ["cycle-1", "cycle-2"]
        approval: "SRE Lead"
    
    metrics:
      - "runbook_generated"
      - "alerts_configured"
  
  - cycle: 4
    title: "Release Preparation"
    agents:
      - type: release
        task: "prepare_deployment"
        dependencies: ["cycle-1", "cycle-2", "cycle-3"]
        approval: "Release Manager"
    
    metrics:
      - "canary_manifest_generated"
      - "deployment_verified"
  
  - cycle: 5
    title: "Production Deployment"
    agents:
      - type: release
        task: "deploy_canary"
        dependencies: ["cycle-4"]
        approval: "CTO" if production else "DevOps Lead"
    
    metrics:
      - "deployment_successful"
      - "traffic_promoted"
      - "rca_generated"

# Loop 執行策略
loop_execution:
  mode: "sequential_with_approval"
  # 其他選項: "parallel", "dynamic_ordering"
  
  retry_policy:
    max_retries: 3
    backoff_seconds: [10, 60, 300]
  
  approval_gates:
    - cycle: 4
      if: "infrastructure_cost > $1000"
      required_approvers: ["CTO", "DevOps Lead"]
    
    - cycle: 5
      if: "environment == production"
      required_approvers: ["VP Engineering"]
  
  escalation:
    timeout_minutes: 60
    escalate_to: "on-call"
```

### C. Loop Iteration Example

```
Day 1 - Cycle 1: Infrastructure Planning
  09:00 - Infrastructure Agent receives issues
  09:15 - Pre-Agent checks: ✅ All passed
  09:20 - Agent generates Terraform code + cost estimate
  09:35 - Verification: ✅ terraform validate passed, ✅ cost < budget
  09:40 - PR created: https://github.com/.../pull/123
  09:45 - CTO reviews PR on Dashboard
  10:00 - ✅ CTO approves → Merged to develop
  10:05 - Slack notification sent

Day 1 - Cycle 2: Security Assessment
  10:10 - Security Agent reviews new infrastructure
  10:15 - Pre-Agent checks: ✅ All passed
  10:20 - Agent generates IAM policies + WAF rules
  10:35 - Verification: ✅ SAST scan passed, ✅ no permissions issues
  10:40 - PR created + reviewed
  11:00 - ✅ Approved → Merged
  11:05 - Cloudflare WAF rules deployed to staging

Day 1 - Cycle 3: SRE Readiness
  11:10 - SRE Agent analyzes infrastructure
  11:15 - Pre-Agent checks: ✅ All passed
  11:20 - Agent generates Prometheus alerts + Runbooks
  11:45 - Verification: ✅ Alerts tested in staging
  12:00 - ✅ Approved → Dashboard updated

Day 1 - Cycle 4: Release Preparation
  12:05 - Release Agent prepares canary
  12:15 - Pre-Agent checks: ✅ All passed
  12:20 - Agent generates Argo CD manifest
  12:45 - Verification: ✅ Dry-run successful
  13:00 - ✅ Approved → Ready for deployment

Day 1 - Cycle 5: Production Deployment
  13:05 - Release Agent starts canary (1% traffic)
  13:10 - Monitoring: 5xx rate 0.01% (vs baseline 0.02%) ✅
  13:20 - Promote to 10% ✅
  13:40 - Promote to 50% ✅
  14:10 - Promote to 100% ✅
  14:20 - ✅ Deployment complete
  14:25 - RCA report generated automatically

Day 2 - Report
  09:00 - Daily report generated:
    ✅ 1 infrastructure deployed
    ✅ 0 security issues
    ✅ 100% deployment success rate
    💰 Cost impact: +$45/month (within budget)
    ⏱️ Total cycle time: 5 hours (vs manual: 2 days)
```

---

## 🔄 關鍵的循環改進

### Feedback Loop

```python
# src/loop_coordinator/feedback_loop.py

class FeedbackLoop:
    """
    收集循環的執行結果，持續改進提示詞和流程
    """
    
    async def collect_cycle_feedback(self, cycle_result: dict):
        """
        收集每個循環的反饋
        """
        
        feedback = {
            "cycle_id": cycle_result["cycle_id"],
            "agent_type": cycle_result["agent_type"],
            "success": cycle_result["success"],
            "execution_time": cycle_result["execution_time_seconds"],
            "approval_time": cycle_result["approval_time_seconds"],
            "issues": cycle_result.get("issues", []),
            "metrics": cycle_result.get("metrics", {})
        }
        
        # 存儲反饋
        self.feedback_store.append(feedback)
        
        # 如果失敗，分析原因
        if not cycle_result["success"]:
            root_cause = await self._analyze_failure(cycle_result)
            feedback["root_cause"] = root_cause
            
            # 觸發提示詞優化
            await self._trigger_prompt_optimization(
                agent_type=cycle_result["agent_type"],
                failure_case=cycle_result
            )
        
        # 定期生成改進建議
        if len(self.feedback_store) % 10 == 0:
            improvements = await self._generate_improvements()
            await self._notify_devops_team(improvements)
    
    async def _trigger_prompt_optimization(self, agent_type: str, failure_case: dict):
        """
        當 Agent 失敗時，自動優化其 System Prompt
        """
        
        # 獲取當前提示詞版本
        current_prompt = self._load_system_prompt(agent_type)
        
        # 使用 Claude 分析失敗原因
        analysis = await self.claude_client.messages.create(
            model="claude-opus-4-8",
            messages=[{
                "role": "user",
                "content": f"""
                Agent {agent_type} 在以下情況下失敗：
                
                失敗案例：{failure_case}
                
                當前 System Prompt：
                {current_prompt}
                
                請提議如何改進 System Prompt 以避免此失敗。
                """
            }]
        )
        
        # 生成改進版本
        improved_prompt = await self._generate_improved_prompt(
            current_prompt,
            analysis.content[0].text
        )
        
        # 版本化存儲
        new_version = self._bump_prompt_version(agent_type)
        self._save_prompt_version(agent_type, new_version, improved_prompt)
        
        # 在 Staging 環境驗證
        await self._test_prompt_on_staging(agent_type, new_version)
        
        # 如果通過測試，自動推廣到生產
        if await self._validate_prompt_improvements(agent_type, new_version):
            await self._promote_prompt_to_production(agent_type, new_version)
            await self._notify_team("Prompt optimized for " + agent_type)
```

---

## 📊 Loop 成熟度模型

```
Level 1: Manual Review
  - Agent 生成建議
  - 人工審核
  - 手工執行
  ⏱️ 時間: 2-3 天

Level 2: Approval Gate
  - Agent 生成
  - Pre-Agent 檢查 ✅
  - Slack "Approve" 按鈕
  - 自動執行
  ⏱️ 時間: 4-6 小時

Level 3: Smart Approval
  - Agent 生成
  - Pre-Agent 檢查
  - 如果成本 < $100，自動批准
  - 其他需人工批准
  ⏱️ 時間: 2-3 小時

Level 4: Full Autonomy (Dev/Staging)
  - Agent 完全自主
  - 只生成報告
  - 人工監督
  ⏱️ 時間: 30-60 分鐘

Level 5: Bounded Autonomy (Production)
  - Agent 自主決策
  - 但受 SLA 和成本限制
  - 超出限制需人工批准
  ⏱️ 時間: 5-15 分鐘
```

---

**文檔版本**：v1.0  
**最後更新**：2026-07-04  
**下一步**：選定第一個 Skill (推薦：zbot-infra-generate)，開始 Week 1 實施
