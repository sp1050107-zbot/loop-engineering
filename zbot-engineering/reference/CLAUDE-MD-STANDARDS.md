# zbot 專案 CLAUDE.md 標準規範

**目的**：統一所有 zbot-* 專案的 CLAUDE.md 結構，明確 MCP Server 和 Prompt 優化規範  
**適用於**：zbot-aladdin, zbot-aws, zbot-trading, zbot-wallet, zbot-analytics, zbot-website

---

## 📋 CLAUDE.md 新增章節（統一結構）

### 9. MCP Server 實現規範

```markdown
## MCP Server 實現規範

### 目的
本專案通過 MCP (Model Context Protocol) Server 提供自動化工具給 AI Agent。
MCP Server 定義了 Agent 可以執行的操作（Generate, Validate, Estimate, Monitor 等）。

### MCP Server 配置

**文件位置**：`./mcp-server.py` 或 `./mcp-server.js`

**基本結構**：
```python
from mcp.server import Server, Tool

server = Server("zbot-{PROJECT_NAME}")

# Tool 1: 主要業務工具
@server.tool()
def primary_tool(requirement: str) -> dict:
    """Generate/validate/estimate..."""
    pass

# Tool 2-5: 輔助工具
```

**必須實現的工具集合**：

| 專案 | 必須工具 | 可選工具 |
|-----|--------|--------|
| zbot-aladdin | strategy_analyze, signal_generate | risk_backtest |
| zbot-aws | infrastructure_generate, cost_estimate | dr_plan |
| zbot-trading | order_match, risk_compute | canary_deploy |
| zbot-wallet | key_manage, tx_sign | audit_trail |
| zbot-analytics | report_generate, dashboard_create | forecast |
| zbot-website | content_generate, seo_audit | performance_test |

### MCP 工具開發流程

1. **Tool 定義** (Week 1)
   - 定義工具的輸入參數和輸出格式
   - 遵循 JSON Schema 規範
   - 在 `tools-schema.json` 中文檔化

2. **Tool 實現** (Week 2)
   - 實現核心邏輯
   - 添加錯誤處理和驗證
   - 包含 verbose logging（用於 debug）

3. **Tool 測試** (Week 3)
   - 單元測試（每個工具）
   - 集成測試（多工具協作）
   - MCP 協議驗證

4. **Tool 上線** (Week 4)
   - 更新 `.claude.json` 註冊
   - 測試 Claude Code 連接
   - 部署到生產

### MCP Server 註冊

在 `~/.claude.json` 中：

```json
{
  "mcpServers": {
    "zbot-{PROJECT}": {
      "type": "stdio",
      "command": "python",
      "args": ["./mcp-server.py"],
      "env": {
        "AWS_PROFILE": "zbot_leonlin",
        "PROJECT": "{PROJECT_NAME}",
        "API_KEYS": "from_secrets_manager"
      }
    }
  }
}
```

### MCP Tool 清單

> 每個項目需在此明確列出所有 MCP 工具
> 格式：`tool_name(param1: type, param2: type) -> return_type`

**zbot-aladdin 的工具清單**：
```
- analyze_market(symbol: str, timeframe: str) -> MarketAnalysis
- generate_signal(analysis: MarketAnalysis) -> TradingSignal
- backtest_strategy(signal: TradingSignal, historical_data: list) -> BacktestResult
```

### MCP Tool 版本管理

- 每個工具有版本號 (v1.0, v1.1, v2.0)
- 版本號應當在 tool 的 docstring 中體現
- 破壞性變更必須升級主版本號
- 在 CHANGELOG.md 中記錄所有工具版本變更

### 與 AI Agent 的協作

MCP Tools 與 Agents 的交互流程：

```
Agent Request
    ↓
MCP Server (Validation)
    ↓
Business Logic Execution
    ↓
Result Formatting
    ↓
Agent Response
```

---

## 10. Prompt 優化迴圈規範

### 目的
本專案通過持續的 Prompt 優化迴圈，使 AI Agent 的成功率達到 > 95%。
每個失敗案例都是改進 System Prompt 的機會。

### System Prompt 版本管理

**文件位置**：`./prompts/system-prompt-{AGENT_TYPE}-v{VERSION}.md`

**命名規則**：
- `system-prompt-infrastructure-v1.0.md` (初版)
- `system-prompt-infrastructure-v1.1.md` (小改進)
- `system-prompt-infrastructure-v2.0.md` (大改進)

### Prompt 結構標準

每個 System Prompt 必須包含以下章節：

```markdown
# System Prompt: {AGENT_TYPE} Agent v{VERSION}

## 【角色定義】
你是一個...的專家，擁有以下能力：

## 【背景知識】
- zbot 架構和業務邏輯
- 依賴的外部系統
- 安全和合規要求

## 【能力範圍】
1. 主要能力 1
2. 主要能力 2
3. 主要能力 3

## 【輸入格式】
用戶會以以下格式提供需求：
{format_example}

## 【輸出格式】
你必須按以下格式回應：
{output_example}

## 【約束條件】
- 僅生成可驗證的代碼
- 遵循命名規範
- 不使用硬編碼敏感信息
- 需要考慮...

## 【錯誤處理】
當遇到以下情況時，應該如何反應：
- 缺少必要的輸入參數
- 資源不可用
- 權限不足

## 【與其他 Agent 的協作】
- 與 Security Agent 的交互方式
- 與 SRE Agent 的交互方式
- 與 Release Agent 的交互方式

## 【版本歷史】
v1.0 (2026-06-15): 初版發佈
v1.1 (2026-06-25): 改進了...
```

### Prompt 優化迴圈流程

#### Phase 1: 數據收集 (Week 1)
- [ ] 運行 10 個測試用例（包括邊界情況）
- [ ] 記錄所有失敗案例
- [ ] 分析失敗的共同特徵

#### Phase 2: 失敗分析 (Week 2)
- [ ] 對每個失敗案例進行根因分析
- [ ] 分類失敗原因（缺乏背景知識、歧義、邏輯錯誤 etc）
- [ ] 優先排序最常見的失敗

#### Phase 3: Prompt 改進 (Week 3)
- [ ] 為每個失敗類別設計改進方案
- [ ] 添加更多背景知識或約束條件
- [ ] 重新組織章節順序以提高清晰度
- [ ] 新建 v1.1 版本

#### Phase 4: 驗證和上線 (Week 4)
- [ ] 在相同的 10 個測試用例上驗證 v1.1
- [ ] 成功率是否 > 85%？
- [ ] 是否沒有引入新的失敗？
- [ ] 標記為生產版本
- [ ] 更新 CLAUDE.md 中的版本引用

### Prompt 失敗案例庫

**文件位置**：`./failures/failure-log.jsonl`

每個失敗案例應記錄：
```json
{
  "id": "failure-001",
  "timestamp": "2026-07-03T14:32:00Z",
  "prompt_version": "v1.0",
  "input": "用戶的原始輸入",
  "expected_output": "應該的輸出格式",
  "actual_output": "Agent 實際輸出",
  "failure_reason": "根因分析（缺少背景知識 / 歧義 / 邏輯錯誤）",
  "fix_applied_in_version": "v1.1",
  "status": "fixed" | "open" | "acknowledged"
}
```

### Prompt 改進建議來源

1. **自動化檢測**：
   - Agent 輸出驗證失敗
   - 代碼執行錯誤
   - 成本估算異常

2. **人工反饋**：
   - Code Review 期間發現的問題
   - CTO Dashboard 的批注
   - 開發者的手工修正

3. **A/B 測試**：
   - 新 Prompt 版本 vs 舊版本
   - 同一套測試用例
   - 統計成功率提升

### Prompt 成熟度評級

```
Level 1: 初版 (v1.0)
  - 成功率: 60-75%
  - 需要頻繁人工修正

Level 2: 改進版 (v1.1-v1.9)
  - 成功率: 75-90%
  - 偶爾需要人工修正

Level 3: 穩定版 (v2.0+)
  - 成功率: > 95%
  - 自主運行，極少人工干預

Level 4: 優化版 (v3.0+)
  - 成功率: > 99%
  - 完全自主，可推廣到其他項目
```

本項目當前的 System Prompt 版本：**v{CURRENT_VERSION}**（成熟度：**{MATURITY_LEVEL}**）

---

## 11. Pre-Agent 檢查清單規範

### 目的
在 Agent 執行任何任務前，Pre-Agent Executor 必須通過以下檢查。
這確保 Agent 有正確的上下文和權限。

### 必須通過的檢查清單

#### 1. 上下文驗證 (Context Validation)
```
✅ User Role 已定義（DevOps / SRE / Security / Release）
✅ Project 名稱明確（zbot-aladdin / zbot-trading / 等）
✅ Environment 已指定（dev / staging / production）
✅ Request ID 已生成（用於追蹤）
✅ Authorization Token 有效
```

#### 2. 依賴檢查 (Dependency Check)
```
✅ AWS CLI 已安裝並配置 (profile: zbot_leonlin)
✅ Terraform 版本 >= 1.6
✅ GitHub CLI (gh) 已安裝
✅ Docker 已安裝（用於驗證）
✅ 必要的 Python 包已安裝
```

#### 3. 權限檢查 (Permission Check)
```
✅ AWS 權限足夠（根據操作類型）
✅ GitHub 倉庫訪問權限
✅ Cloudflare API Token 有效
✅ 操作符合用戶角色的 RBAC
```

#### 4. 資源可用性 (Resource Availability)
```
✅ AWS 資源配額未滿
✅ GitHub API 速率限制未達上限
✅ Cloudflare 配置無衝突
✅ 必要的 Secret 已在 AWS Secrets Manager 中
```

#### 5. Prompt 驗證 (Prompt Validation)
```
✅ System Prompt 文件存在
✅ Prompt 版本與 Agent 版本匹配
✅ Prompt 包含必要的所有章節
✅ Prompt 版本號正確
```

### Pre-Agent 檢查失敗的處理

當任何檢查失敗時，Pre-Agent Executor 應該：

1. **記錄失敗原因**（進 failure-log.jsonl）
2. **生成補救建議**（自動化建議或人工審批）
3. **不執行任務**（除非明確批准）
4. **通知相關人員**（Slack alert）

---

## 12. Autonomous Loop 規範

### 目的
本專案支持循環開發模式，Agent 可在人工監督下自主工作。

### Loop 的五個階段

#### Cycle 1: 需求分析
```
Task: 解析用戶需求並生成初步設計
Agent: Infrastructure Agent (針對 AWS) / Security Agent (針對 WAF) 等
Input: GitHub Issue / Slack Message
Output: 設計文檔 + 初步方案
Approval Gate: 自動批准（如成本 < $100）
```

#### Cycle 2-4: 詳細規劃和實現
```
(根據專案類型調整)
```

#### Cycle 5: 驗證和上線
```
(部署、監控、RCA)
```

### Loop 執行 SLA

| 階段 | 目標時間 | 最大重試次數 | 失敗升級 |
|------|---------|-----------|--------|
| 需求分析 | 30 分鐘 | 3 | DevOps Lead |
| 詳細實現 | 2 小時 | 3 | CTO |
| 驗證上線 | 1 小時 | 2 | VP Eng |

### Loop 的自動化檢查點

```
每個 Cycle 完成後：
  ✅ 檢查輸出是否有效
  ✅ 成本是否在預算內
  ✅ 安全掃描是否通過
  ✅ 代碼質量是否達標
  ✅ 測試覆蓋率是否 > 80%
```

如果所有檢查通過 → 自動進入下一個 Cycle
如果任何檢查失敗 → 等待人工批准

---

## 13. 更新日誌

### 本文檔何時更新

- [ ] 每當 System Prompt 升級版本時
- [ ] 每當新增 MCP Tool 時
- [ ] 每當 Pre-Agent 檢查清單變更時
- [ ] 每月進行一次完整審查

### 版本歷史

| 版本 | 日期 | 主要變更 |
|------|------|--------|
| v1.0 | 2026-07-04 | 初版發佈，包含 MCP/Prompt/PreAgent/Loop 規範 |

---

**責任人**：{PROJECT_OWNER}  
**最後審查**：{DATE}  
**下次審查預定**：{NEXT_REVIEW_DATE}

