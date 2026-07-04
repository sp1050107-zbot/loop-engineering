# zbot-engineering vs Loop Engineering 官方框架對齐分析

**目標**：識別 zbot-engineering 當前的盲點、吸收官方最佳實踐、融合中文化創新

---

## 框架對齐表

| 維度 | Loop Engineering 官方 | zbot-engineering 現有 | 差異 | 優先級 |
|------|----------------------|-----------------|------|--------|
| **Worker + Verifier 獨立性** | ✅ 完全獨立的 API 調用、無共享歷史 | ❌ Verifier 可能繼承 Triage 上下文 | 需修復 | P0 |
| **5 Agent Killers** | ✅ 設計層診斷框架 | ❌ 無 | 需補充 | P1 |
| **5 Stages (D-P-E-V-I)** | ✅ 完整流程 | ⚠️ 隱含但不明確 | 需明確化 | P1 |
| **6 Components** | ✅ 完整 | ✅ 大部分有 (Automations, Skills, Plugins) | 缺 Worktrees 集成 | P1 |
| **成本管理: Tiered Model Routing** | ✅ Best/Mid/Cheap 按複雜度 | ❌ 無 | 需補充 | P2 |
| **Memory as Rules** | ✅ 通用規則，跨運行複用 | ⚠️ Failure Log (具體案例) | 需補充「規則提取層」 | P1 |
| **Self-Correction Flow** | ✅ Capture → Diagnose → Decide → Rule | ⚠️ 隱含但無明確步驟 | 需明確化 + 中文化 | P0 |
| **中文化系統提示** | ❌ 無 | ✅ system-prompt-triage-v1-zh.md | **zbot 優勢** | ✅ |
| **MCP 統一連接層** | ✅ Plugins (概念) | ✅ mcp-server (具體實現) | **zbot 優勢** | ✅ |
| **Prompt 版本化 + 失敗記錄** | ❌ 無具體格式 | ✅ v1.0/v1.1 + failures.jsonl | **zbot 優勢** | ✅ |

---

## 關鍵差異詳解

### 1. Worker + Verifier 獨立性 (P0 - 立即修復)

#### 官方要求
```python
# ✅ 正確：完全獨立的 API 調用，無共享歷史
worker_response = client.messages.create(
    model="claude-opus",
    messages=[{"role": "user", "content": "Run triage..."}]
)

verifier_response = client.messages.create(
    model="claude-opus",
    messages=[{  # ← 全新的上下文，不包含 worker 的消息
        "role": "user", 
        "content": f"Grade this triage output:\n\n{worker_response.text}\n\nRubric: ..."
    }]
)
```

#### zbot-engineering 當前問題
```python
# ❌ 錯誤可能性：Verifier 繼承 Triage 的上下文
loop_state = read_file("LOOP-STATE.md")  # ← shared context
verifier_response = client.messages.create(
    model="claude-opus",
    messages=[
        {"role": "user", "content": f"Prior state: {loop_state}..."},  # ← 繼承偏見
        {"role": "user", "content": "Verify the triage output..."}
    ]
)
```

#### 修復方案 (Week 2)
在 `system-prompt-verifier-v1-zh.md` 中明確：

```markdown
# 系統提示：zbot Verifier (v1.0)

## ⚠️ 關鍵約束

**Verifier 必須忽略 Triage 的上下文歷史**。

不讀：
- Triage 的推理步驟
- LOOP-STATE.md 中的優先級評分
- 上次運行的結論

只讀：
- Triage 的原始輸出（findings）
- 驗證清單（rubric）
- 背景知識（項目配置）

## 執行流程

1. 清空記憶：忽略任何先前判斷
2. 獨立評分：基於 findings + rubric，不基於 state
3. 標記異議：如果發現 Triage 的可疑之處
```

**實施檢查清單**：
- [ ] system-prompt-verifier-v1-zh.md 明確「獨立性」要求
- [ ] 測試：Verifier 能否對 Triage 的結論提出異議（不跟風）
- [ ] 失敗記錄：如果 Verifier 太依賴 Triage 的判斷，記錄為「context-bias」

---

### 2. 5 Agent Killers → Pre-Agent Tiers 映射 (P1)

#### 官方的 5 Agent Killers（為什麼 Loop 失敗）

| # | Killer | 根本原因 | 症狀 |
|---|--------|--------|------|
| 1 | Context Collapse | 長任務 context 用盡 | Step 12 忘記 Step 1 的目標 |
| 2 | No Self-Correction | 遇到錯誤就重試（同樣方法） | 無限循環，成本爆炸 |
| 3 | No Verifier | 無獨立檢查 | "完成" ≠ 正確 |
| 4 | No Guardrails | 無邊界約束 | Agent 可以刪文件、花錢 |
| 5 | No Memory | 每次運行從零開始 | 同樣錯誤重複出現 |

#### zbot-engineering 的 Pre-Agent Tiers（執行前檢查）

| Tier | 檢查點 | 對應 Killer | 映射 |
|------|--------|-----------|------|
| Tier 1 | 環境配置 (API Key、密鑰) | No Guardrails | ✅ 邊界約束 |
| Tier 2 | Context 邊界 (數據量、時間窗口) | Context Collapse | ✅ 防止 context 超限 |
| Tier 3 | 工具連接 (API、DB 可達) | No Guardrails | ✅ 執行邊界 |
| Tier 4 | State 一致性 (LOOP-STATE.md 新鮮度) | No Memory | ✅ 記憶延續 |
| Tier 5 | 成本控制 (Token 預算) | No Self-Correction | ⚠️ 部分覆蓋 |

#### 改進方案：Tier 5.5 - Self-Correction 設計

新增 Tier 5.5（Week 2）：

```markdown
# Tier 5.5: Self-Correction Design Check

**目的**：確認 Loop 的故障恢復機制

### 檢查項
- [ ] 定義了明確的 FAIL 條件（不是「任何錯誤」）
- [ ] 有 Capture 步驟（記錄失敗現象 + 嘗試的方法）
- [ ] 有 Diagnose 步驟（分析根本原因，分離 API 調用）
- [ ] 有 Decide 步驟（決定新方法，而非重試舊方法）
- [ ] 有 Rule 提取步驟（從失敗中學習，寫入 memory）

### 檢查腳本

if loop has error:
  ├─ Capture: {error_msg, attempted_approach, context}
  ├─ Diagnose: "why did this fail?" (separate API call)
  ├─ Decide: "new approach or escalate?"
  ├─ Rule: "general principle to remember?"
  └─ Memory: append rule to .dev-loop-state.md
```

**實施**：在 system-prompt-triage-v1-zh.md 中加入「診斷子流程」

```markdown
## Step 4.5: 遇到檢查失敗時的診斷流程

如果某個檢查失敗（如 Lambda API 超時），不要直接標記為警告。執行：

1. **Capture**
   ```json
   {
     "check": "lambda-cold-start",
     "error": "API timeout after 30s",
     "attempted_approach": "query CloudWatch Metrics"
   }
   ```

2. **Diagnose** (在心理上分離：別信任自己的第一判斷)
   - 是臨時網絡故障？還是真實的 Lambda 性能問題？
   - 需要嘗試備用數據源（Logs vs Metrics）？

3. **Decide**
   - 如果是暫時故障 → 標記為 Low priority，下次重試
   - 如果是真實問題 → 升級為 High priority
   - 如果無法判斷 → 標記為需人工審查

4. **Rule** (提取通用原則)
   - Rule: "Lambda 健康檢查超時時，嘗試查詢 CloudWatch Logs 而不是 Metrics（Metrics API 延遲 > Logs）"
```

---

### 3. Memory as Rules vs Failure Log (P1)

#### 官方框架：Memory = 可複用規則

```python
# 每次失敗都提取一個通用規則
rule = extract_rule(failed_attempt, error)
# "RULE: When parsing JSON, always validate schema first"

# 下次運行時加載
memory = load_memory(".dev-loop-state.md")
# RULE: When parsing JSON, always validate schema first
# RULE: Lambda cold start detection via Logs, not Metrics
# RULE: Never trust cached exchange rates > 1 hour old
```

#### zbot-engineering 當前：Failure Log = 具體案例

```json
{
  "timestamp": "2026-07-04T08:15:30Z",
  "failure_type": "missed_alert",
  "description": "Lambda 冷啟 > 5s 未檢出",
  "root_cause": "Prompt 中未明確要求查詢 Logs"
  // ← 具體案例，不是通用規則
}
```

#### 融合方案 (Week 2)

在 failure 記錄中加入「規則提取」欄位：

```json
{
  "timestamp": "2026-07-04T08:15:30Z",
  "failure_type": "missed_alert",
  "description": "Lambda 冷啟 > 5s 未檢出",
  "root_cause": "Prompt 中未明確要求查詢 Logs",
  
  "extracted_rule": {
    "principle": "Lambda 冷啟動檢查應優先使用 CloudWatch Logs (filter 'Init Duration')，而不是 Metrics dashboard",
    "applies_to": ["zbot-aws", "any-lambda-monitoring"],
    "priority": "P1"
  },
  
  "remediation": {
    "prompt_fix": "Add explicit instruction: 'For Lambda: Must query CloudWatch Logs with filter pattern \"Init Duration\"'",
    "next_version": "v1.1",
    "rule_added_to": ".dev-loop-state.md"
  }
}
```

**新文件**：`.dev-loop-state.md` (跨運行的通用規則)

```markdown
# .dev-loop-state.md — zbot Loop Memory

Last updated: 2026-07-04
Frequency: Updated after each loop failure

## General Rules

### Lambda Monitoring
- RULE: Cold start detection via CloudWatch Logs (filter "Init Duration"), not Metrics
  - Reason: Metrics API has 1-2 min lag; Logs are real-time
  - Applied to: zbot-aws triage v1.1+
  - Source: Failure 2026-07-03 #1

### API Cost Management  
- RULE: Never trust cached exchange rates > 1 hour old
  - Reason: Crypto prices move every minute; stale data causes bad trades
  - Applied to: zbot-trading, zbot-aladdin
  - Source: Failure 2026-06-28 #3

### Market Data
- RULE: When market data API times out, check 3 sources in order: (1) local cache, (2) backup API, (3) alert human
  - Reason: Single source outages are common; fallback prevents false alerts
  - Applied to: zbot-aladdin backtest loop
  - Source: Failure 2026-06-15 #7
```

**在 Triage Prompt 中加載**：

```markdown
## 前置：載入通用規則

在執行檢查前，閱讀 `.dev-loop-state.md` 中的所有通用規則。
它們代表過去失敗中學到的教訓。

例如：
- Lambda 冷啟 → 查詢 CloudWatch Logs
- 交易對 → 不信任 > 1 小時的緩存
- 數據源故障 → 用 Fallback 而非直接告警
```

---

### 4. Tiered Model Routing (P2 - 成本優化)

#### 官方建議
```
Best Model (Fable 5 / Opus):     高複雜度、需要判斷的任務
Mid Model (Sonnet / DeepSeek):   中等推理
Cheap Model (Haiku / MiniMax):   提取、重組、重試
```

#### zbot-engineering 應用 (Week 3)

在 LOOP.md 中加入模型路由規則：

```markdown
# LOOP.md — zbot-aws

## Model Routing

### Task: Daily Triage (Step 1-2: Discover & Plan)
- Complexity: Medium (data gathering, prioritization)
- Route: **Sonnet** (cost-optimized)
- Cost: ~5K tokens/run

### Task: Triage Diagnosis (if failure detected)
- Complexity: High (root cause analysis, judgment calls)
- Route: **Opus** (best reasoning)
- Cost: ~3K tokens (only on failure, not every run)

### Task: Triage Output Formatting
- Complexity: Low (restructure data)
- Route: **Haiku** (cheap)
- Cost: ~500 tokens

### Total Budget
- Normal run: 5K tokens (Sonnet)
- Failure + diagnosis: +3K (Opus)
- Daily cap: 10K tokens
- Weekly cap: 100K tokens
```

**實施檢查清單**：
- [ ] 在 LOOP.md 中定義每個 Step 的模型選擇
- [ ] 在系統提示中記錄模型路由邏輯
- [ ] Backtest 時對比：All-Opus vs Routed 的成本和品質

---

### 5. 明確化 5 Stages (D-P-E-V-I) 在 Triage 中的體現 (P1)

#### 官方框架的 5 Stages

```
DISCOVER (探索) → PLAN (規劃) → EXECUTE (執行) → VERIFY (驗證) → ITERATE (迭代)
```

#### 在 zbot-aladdin Daily Triage 中的映射

```
DISCOVER:
  - 讀取 LOOP-STATE.md (上次狀態)
  - 查詢市場數據 API (今天的數據)
  - 列出候選檢查項

PLAN:
  - 優先級排序 (哪些檢查最重要)
  - 預估 token 成本
  - 決定檢查順序 (快速失敗優先)

EXECUTE:
  - 逐項執行檢查
  - 收集 findings
  - 評分每個 finding

VERIFY:
  - Verifier 檢查 findings 的有效性
  - 確認沒有遺漏的項目
  - 確認沒有虛假警報

ITERATE:
  - 發現遺漏？ → 補充檢查
  - 發現虛假警報？ → 調整閾值
  - 用失敗案例改進 Prompt v1.1
```

**在 system-prompt-triage-v1-zh.md 中明確化** (Week 2)：

```markdown
# 系統提示：zbot Daily Triage (v1.0)

## 5 Stages 映射

### Stage 1: DISCOVER (2 分鐘)
讀取 LOOP-STATE.md → 了解上次狀態
列出今天需要檢查的所有項目

### Stage 2: PLAN (1 分鐘)
排序檢查項目（優先級 + 成本）
決定執行順序

### Stage 3: EXECUTE (5-7 分鐘)
逐項執行檢查
記錄每項的結果

### Stage 4: VERIFY (2 分鐘)
Verifier Sub-Agent 檢查 findings

### Stage 5: ITERATE (1 分鐘)
更新 LOOP-STATE.md
記錄失敗案例
```

---

## Alignment 優先級排序

### 🔴 P0 (立即，本週)
1. **獨立 Verifier Context** — 修改 system-prompt-verifier-v1-zh.md
2. **顯式 Self-Correction 流程** — 在 Triage Prompt 中加入 Capture → Diagnose → Decide

### 🟠 P1 (本月，Week 2-3)
3. **Memory as Rules** — 新增 `.dev-loop-state.md` + 失敗記錄中加「提取規則」欄位
4. **Tier 5.5 檢查** — Pre-Agent 加入「自我修正設計驗證」
5. **5 Stages 明確化** — 在 Triage Prompt 中逐步標記

### 🟡 P2 (下月，Week 4+)
6. **Tiered Model Routing** — LOOP.md 中定義模型選擇規則
7. **Worktrees 集成** — 各項目支持並行 worktree 執行

---

## zbot-engineering 獨有的優勢（保留）

| 優勢 | 來源 | 保留策略 |
|------|------|--------|
| 完全中文化系統提示 | zbot 自研 | ✅ 保留並擴展（不翻譯官方的，改造成中文思維） |
| Prompt 版本化 + Failure Log | zbot 自研 | ✅ 保留並融合「規則提取」 |
| MCP 統一連接層 | zbot 自研 | ✅ 保留並與官方的 Plugins 概念對齐 |
| Pre-Agent 5 Tier 檢查 | zbot 自研 | ✅ 保留並映射到 5 Agent Killers |

---

## 改進路線（2026-07 到 08）

### Week 1 ✅ 完成
- [x] zbot-engineering 基礎架構（README、快速開始）
- [x] 中文系統提示 v1.0
- [x] Pre-Agent Tier 1 檢查

### Week 2 🔴 P0 優先
- [ ] **獨立 Verifier Context** 明確化
- [ ] **Self-Correction 流程** 融入 Triage Prompt
- [ ] Pre-Agent Tier 2-3 檢查
- [ ] Memory as Rules 框架（.dev-loop-state.md）

### Week 3 🟠 P1
- [ ] Prompt v1.1（基於失敗記錄改進）
- [ ] 5 Stages 在 Triage 中的體現
- [ ] Tier 5.5 檢查
- [ ] Backtest: v1.0 vs v1.1 對比

### Week 4 🟡 P2
- [ ] Tiered Model Routing 定義
- [ ] MCP + 官方 Plugins 概念對齐
- [ ] Worktrees 支持

---

## 對齐完成標誌

✅ 系統設計層面
- [ ] 5 Agent Killers 都被映射到檢查機制
- [ ] Self-Correction 流程明確且可驗證
- [ ] Worker & Verifier 完全獨立

✅ 實施層面
- [ ] system-prompt-triage-v1-zh.md 包含所有 5 Stages
- [ ] system-prompt-verifier-v1-zh.md 明確要求獨立性
- [ ] .dev-loop-state.md 記錄可複用規則

✅ 成本層面
- [ ] LOOP.md 定義模型路由規則
- [ ] 失敗記錄中有「規則提取」欄位

✅ 可觀測性
- [ ] 每個 Loop 運行都有 5 Stages 的記錄
- [ ] 每個失敗都有診斷記錄
- [ ] 每週有規則更新日誌

---

**所有者**：zbot AI Infrastructure Team  
**最後更新**：2026-07-04  
**下次同步**：2026-07-11 (Week 2 完成評估)
