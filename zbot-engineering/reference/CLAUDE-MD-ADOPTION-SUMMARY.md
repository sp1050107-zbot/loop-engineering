# CLAUDE.md 規範採納摘要

**目標**：為所有 zbot-* 項目統一 CLAUDE.md 結構，明確 MCP Server 和 Prompt 優化規範  
**項目範圍**：zbot-aladdin, zbot-aws, zbot-trading, zbot-wallet, zbot-analytics, zbot-website  
**狀態**：📋 準備階段 (2026-07-04)

---

## 📚 三份核心文檔已生成

### 1️⃣ CLAUDE-MD-STANDARDS.md
- **用途**：標準化 CLAUDE.md 結構的完整參考
- **包含**：MCP Server / Prompt 優化 / Pre-Agent / Autonomous Loop 規範
- **長度**：~5000 字
- **使用**：複製粘貼規範內容到各項目

### 2️⃣ CLAUDE-MD-IMPLEMENTATION-GUIDE.md
- **用途**：逐步實施指南
- **包含**：每個項目的工具清單、目錄結構、批量腳本
- **長度**：~2000 字
- **使用**：按步驟為每個項目添加規範

### 3️⃣ 本文 (CLAUDE-MD-ADOPTION-SUMMARY.md)
- **用途**：高層摘要和進度追蹤
- **包含**：核心要點、檢查清單、時間表
- **長度**：~1500 字
- **使用**：決策制定和進度監控

---

## 🎯 核心規範總結

### MCP Server 實現規範

**定義**：每個 zbot-* 項目必須通過 MCP (Model Context Protocol) Server 提供工具給 AI Agent。

**工具清單示例**：
```
zbot-aladdin:
  - analyze_market(symbol, timeframe) -> MarketAnalysis
  - generate_signal(analysis) -> TradingSignal
  - risk_assessment(signal, portfolio) -> RiskReport

zbot-aws:
  - infrastructure_generate(requirement, environment) -> TerraformConfig
  - cost_estimate(terraform_code) -> CostEstimate
  - validate_terraform(config) -> ValidationResult
  - query_aws_resources(query, filters) -> list
```

**開發週期**：
- Week 1: Tool 定義 (參數和輸出格式)
- Week 2: Tool 實現 (核心邏輯 + 錯誤處理)
- Week 3: Tool 測試 (單元 + 集成 + MCP 驗證)
- Week 4: Tool 上線 (~/.claude.json + 生產部署)

**註冊方式**：在 ~/.claude.json 中配置
```json
{
  "mcpServers": {
    "zbot-{PROJECT}": {
      "type": "stdio",
      "command": "python",
      "args": ["./mcp-server.py"],
      "env": {
        "AWS_PROFILE": "zbot_leonlin",
        "PROJECT": "{PROJECT}"
      }
    }
  }
}
```

---

### Prompt 優化迴圈規範

**定義**：通過持續優化 System Prompt，使 AI Agent 成功率達到 > 95%。

**版本管理**：
```
prompts/system-prompt-{AGENT_TYPE}-v{VERSION}.md
  例: system-prompt-infrastructure-v1.0.md
      system-prompt-infrastructure-v1.1.md (改進版)
```

**Prompt 結構**（必須包含這些章節）：
1. 【角色定義】- Agent 的專業能力
2. 【背景知識】- 依賴的系統和業務邏輯
3. 【能力範圍】- 能做什麼，不能做什麼
4. 【輸入格式】- 用戶如何請求
5. 【輸出格式】- Agent 應如何回應
6. 【約束條件】- 必須遵守的規則
7. 【錯誤處理】- 異常情況的應對
8. 【與其他 Agent 的協作】- 多代理協調方式
9. 【版本歷史】- 每個版本的變更

**優化週期**（每個月一次）：

| 週次 | 任務 | 交付物 |
|------|------|--------|
| W1 | 數據收集 | 10 個測試用例 + 失敗案例收集 |
| W2 | 失敗分析 | 根因分類 + 改進優先級 |
| W3 | Prompt 改進 | System Prompt v1.1 初稿 |
| W4 | 驗證上線 | 成功率 > 85% 後發佈生產 |

**失敗案例庫** (./failures/failure-log.jsonl)：
```json
{
  "id": "failure-001",
  "timestamp": "2026-07-04T10:00:00Z",
  "prompt_version": "v1.0",
  "input": "用戶的原始輸入",
  "expected_output": "應該的輸出格式",
  "actual_output": "Agent 實際輸出",
  "failure_reason": "根因（Knowledge Gap / Ambiguity / Logic Error）",
  "fix_applied_in_version": "v1.1",
  "status": "fixed" | "open"
}
```

**Prompt 成熟度模型**：
```
Level 1 (v1.0):   成功率 60-75%  → 需要頻繁人工修正
Level 2 (v1.1):   成功率 75-90%  → 偶爾需要人工修正
Level 3 (v2.0):   成功率 > 95%   → 自主運行，極少人工干預
Level 4 (v3.0):   成功率 > 99%   → 完全自主，可推廣到其他項目
```

---

### Pre-Agent 檢查清單規範

**定義**：在 Agent 執行任何任務前，必須通過 5 層檢查。

**5 層檢查**：

#### 1. 上下文驗證 ✅
- User Role 已定義（DevOps / SRE / Security / Release）
- Project 名稱明確
- Environment 已指定（dev / staging / production）
- Request ID 已生成（用於追蹤）
- Authorization Token 有效

#### 2. 依賴檢查 ✅
- AWS CLI 已安裝並配置 (profile: zbot_leonlin)
- Terraform >= 1.6
- GitHub CLI (gh) 已安裝
- Docker 已安裝
- Python 依賴已安裝

#### 3. 權限檢查 ✅
- AWS 權限充足
- GitHub 倉庫訪問正常
- Cloudflare API Token 有效
- RBAC 檢查通過

#### 4. 資源可用性 ✅
- AWS 配額充足
- GitHub API 速率限制未達
- Cloudflare 無衝突
- AWS Secrets Manager 可用

#### 5. Prompt 驗證 ✅
- System Prompt 文件存在
- 版本與 Agent 版本匹配
- 包含所有必須章節
- 版本號正確

**檢查失敗的處理**：
1. 記錄失敗原因到 failure-log.jsonl
2. 生成自動補救建議
3. **不執行任務** (除非明確批准)
4. 通知相關人員 (Slack alert)

---

### Autonomous Loop 規範

**定義**：Agent 在人工監督下自主工作的循環開發模式。

**5 個 Cycle 流程**：

```
Cycle 1: 需求分析 (30 min)
  Input: GitHub Issue / Slack Message
  Output: 設計文檔 + 初步方案
  Approval: 自動（成本 < $100）或 DevOps Lead

Cycle 2-4: 詳細規劃和實現 (2-6 hours)
  並行執行多個實現任務

Cycle 5: 驗證和部署 (1 hour)
  Output: 部署報告 + RCA
  Approval: VP Engineering（Prod）
```

**Loop SLA**：

| 階段 | 目標時間 | 最大重試次數 | 失敗升級 |
|-----|---------|-----------|--------|
| 需求分析 | 30 分鐘 | 3 | DevOps Lead |
| 詳細實現 | 2 小時 | 3 | CTO |
| 驗證上線 | 1 小時 | 2 | VP Eng |

**自動化檢查點**（每個 Cycle 完成後）：
- ✅ 輸出是否有效（格式、內容完整性）
- ✅ 成本是否在預算內
- ✅ 安全掃描是否通過
- ✅ 代碼質量是否達標（Lint、Format）
- ✅ 測試覆蓋率是否 > 80%

**自動決策**：
```
所有檢查通過 → 自動進入下一個 Cycle
任何檢查失敗 → 等待人工批准或重試
```

---

## 📋 實施檢查清單

### Phase 1: 文檔準備 (已完成 ✅)

- ✅ 生成 CLAUDE-MD-STANDARDS.md (標準規範)
- ✅ 生成 CLAUDE-MD-IMPLEMENTATION-GUIDE.md (實施步驟)
- ✅ 生成本文 (CLAUDE-MD-ADOPTION-SUMMARY.md)

### Phase 2: 項目更新 (即將開始 📅)

**對每個項目執行**：

- [ ] **zbot-aladdin**
  - [ ] 更新 CLAUDE.md (添加章節 9-13)
  - [ ] 建立 prompts/ 目錄
  - [ ] 建立 failures/ 目錄
  - [ ] 創建 prompts/system-prompt-infrastructure-v1.0.md
  - [ ] 提交 git commit

- [ ] **zbot-aws**
  - [ ] 更新 CLAUDE.md
  - [ ] 建立 prompts/ 和 failures/ 目錄
  - [ ] 創建 System Prompt v1.0
  - [ ] 提交 git commit

- [ ] **zbot-trading**
  - [ ] 更新 CLAUDE.md
  - [ ] 建立目錄結構
  - [ ] 創建 System Prompt v1.0
  - [ ] 提交 git commit

- [ ] **zbot-wallet**
  - [ ] 更新 CLAUDE.md
  - [ ] 建立目錄結構
  - [ ] 創建 System Prompt v1.0
  - [ ] 提交 git commit

- [ ] **zbot-analytics**
  - [ ] 更新 CLAUDE.md
  - [ ] 建立目錄結構
  - [ ] 創建 System Prompt v1.0
  - [ ] 提交 git commit

- [ ] **zbot-website**
  - [ ] 更新 CLAUDE.md
  - [ ] 建立目錄結構
  - [ ] 創建 System Prompt v1.0
  - [ ] 提交 git commit

### Phase 3: MCP Server 實現 (後續)

- [ ] zbot-aladdin: 實現 analyze_market, generate_signal, risk_assessment
- [ ] zbot-aws: 實現 infrastructure_generate, cost_estimate 等
- [ ] 其他項目...

### Phase 4: Prompt 優化迴圈 (後續)

- [ ] Week 1: 運行 10 個測試用例
- [ ] Week 2: 分析失敗案例
- [ ] Week 3: 改進 Prompt v1.1
- [ ] Week 4: 驗證和上線

### Phase 5: Loop 部署 (後續)

- [ ] 實現 Pre-Agent Executor (5 層檢查)
- [ ] 配置 Loop SLA 和自動檢查點
- [ ] 首次 Loop 測試運行
- [ ] 監控和優化

---

## ⏱️ 時間表

| 日期 | 里程碑 | 責任人 |
|------|--------|--------|
| 2026-07-04 | 文檔生成完成 ✅ | Claude |
| 2026-07-05 ~ 07-08 | Phase 2: 6 個項目 CLAUDE.md 更新 | Dev Team |
| 2026-07-09 ~ 07-22 | Phase 3: MCP Server 實現 (4 週) | Dev Team |
| 2026-07-23 ~ 08-27 | Phase 4: Prompt 優化迴圈 (4 週) | AI/ML Team |
| 2026-08-28 ~ 09-11 | Phase 5: Loop 部署和測試 (2 週) | DevOps Team |
| 2026-09-12 | 全系統上線 🚀 | CTO |

---

## 📊 KPI 和成功指標

### 短期 (1 個月內)

- ✅ 所有 6 個項目 CLAUDE.md 已更新
- ✅ 所有 MCP Server 規範已文檔化
- ✅ 所有 System Prompt v1.0 已創建
- ✅ 所有項目的 Pre-Agent 檢查清單已就位

### 中期 (3 個月內)

- ✅ 所有 MCP Tool 已實現並通過測試
- ✅ 所有 Prompt 優化迴圈完成至少 1 個週期
- ✅ 所有 Prompt 成功率 > 85%
- ✅ 所有 Loop SLA 成功率 > 90%

### 長期 (6 個月內)

- ✅ 所有 Prompt 成功率 > 95%
- ✅ AI Agent 自動化完成率 > 90%
- ✅ 人工干預率 < 10%
- ✅ 平均完成時間縮短 60% (從手工→自動)

---

## 🔗 相關文檔鏈接

- CLAUDE-MD-STANDARDS.md — 標準規範完整版
- CLAUDE-MD-IMPLEMENTATION-GUIDE.md — 逐步實施指南
- PROMPT-ENGINEERING-AND-AGENT-LOOP.md — 提示詞工程深度文檔
- VERSIONING-AND-GITOPS-WORKFLOW.md — 版本管理規範
- intent-driven-devops-complete-blueprint.md — 完整架構設計

---

## 💡 核心原則

### 1. **規範優先**
在實現代碼之前，先定義清晰的規範和檢查清單。

### 2. **持續改進**
每個失敗案例都是改進 Prompt 和流程的機會。

### 3. **可測試性**
每個環節都應該有明確的測試標準和驗收條件。

### 4. **可觀測性**
記錄所有失敗、改進和迭代，形成可追蹤的改進歷史。

### 5. **自動化優先**
優先自動化檢查和修復，減少人工干預。

---

## ❓ 常見問題

**Q: MCP Server 是必須的嗎？**  
A: 是的。MCP Server 定義了 Agent 能做什麼，是整個 Loop 的基礎。

**Q: 如果 Prompt v1.0 成功率很低怎麼辦？**  
A: 這是正常的。Level 1 (v1.0) 的成功率預期是 60-75%，通過迭代改進到 Level 3 (v2.0) 的 > 95%。

**Q: Pre-Agent 檢查失敗可以跳過嗎？**  
A: 不能。檢查失敗意味著 Agent 沒有正確的執行環境，跳過檢查會導致失敗。

**Q: Loop 要運行多長時間？**  
A: 每個 Cycle 有明確的 SLA（30 min ~ 2 hours）。首次 Loop 通常需要 1-2 週完成一個完整週期。

---

## 📞 支持和反饋

- **問題報告**：在各項目的 Issues 中創建 Issue，標籤 `mcp-server` 或 `prompt-optimization`
- **規範改進**：在 CLAUDE.md 中添加 `## Feedback` 章節
- **進度追蹤**：每週在 CTO Dashboard 中報告進度

---

**文檔版本**：v1.0  
**最後更新**：2026-07-04  
**下次審查**：2026-07-11

