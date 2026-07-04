# 如何在 zbot-* 項目中應用 Loop Engineering 邏輯

**目標**：將 loop-engineering 的設計思想轉化為 6 個 zbot-* 項目的實際運維 Loop

**適用於**：CTO、架構師、運維工程師

---

## 核心映射：官方概念 → zbot 應用

### Loop Engineering 的設計思想

```
官方框架：
  自動化系統 = Scheduling + Triage + State + Verifier + 人工 Gate
  
zbot 應用：
  每個 zbot-* = LOOP.md (調度) + LOOP-STATE.md (狀態) + System Prompts (規則) + Pre-Agent 檢查
```

### 6 個 Primitives 在 zbot-* 中的體現

| 基礎要素 | 官方定義 | zbot 實現 | 位置 |
|---------|--------|---------|------|
| **1. Automations** | Heartbeat | `/loop 1d` or `/loop 4h` | 各項目 LOOP.md |
| **2. Worktrees** | 並行隔離 | Git worktree (計劃中) | .worktrees/ |
| **3. Skills** | Intent 知識庫 | system-prompt-triage-v1-zh.md | zbot-engineering/prompts/ |
| **4. MCP** | 工具連接 | GitHub/AWS connectors | zbot-engineering/mcp/ |
| **5. Sub-agents** | Maker/Checker | Implementer + Verifier | prompts/ (v1.1) |
| **6. Memory/State** | 持久存儲 | LOOP-STATE.md + failures.jsonl | 各項目 + 中央 |

---

## 六個項目的具體應用

### 📊 zbot-aws（基礎設施運維）

**項目特性**：
- 關鍵性：⭐⭐⭐⭐⭐（生產環境）
- 目標：24/7 自動化監控和故障預警

#### Loop 設計

```markdown
# LOOP.md — zbot-aws

## Active Loops

### Loop 1: Daily Infrastructure Audit (L1 report-only)
- 調度：每天 08:00 UTC
- 技能：loop-triage (EC2/Lambda/RDS 健康檢查)
- 狀態：LOOP-STATE.md
- 級別：L1（只報告，不修復）
- 成本：~5K tokens/day
- MCP：GitHub (report as issues) + AWS (query logs)

### Loop 2: Backup Verification (L1 read-only)
- 調度：每天 10:00 UTC
- 技能：backup-verifier
- 狀態：LOOP-STATE.md
- 級別：L1（只讀，驗證備份完整性）
- 成本：~3K tokens/day

### Loop 3: Cost Optimization (1w Monday 09:00)
- 調度：每週一 09:00 UTC
- 技能：cost-optimizer
- 狀態：LOOP-STATE.md
- 級別：L1（分析成本趨勢，建議優化）
- 成本：~10K tokens/week
```

#### Pre-Agent 檢查清單

```yaml
# zbot-aws LOOP Pre-Checks

Tier 1: 環境驗證
  ✓ AWS_PROFILE=zbot_leonlin 設置
  ✓ AWS Secrets Manager 可訪問: zbot-aws/claude-api-key
  ✓ LOOP-STATE.md 存在

Tier 2: Context 邊界
  ✓ 上次運行時間 > 5 分鐘（防重複）
  ✓ 本週 token 使用 < 100K

Tier 3: 工具連接
  ✓ AWS CLI 可運行: aws ec2 describe-instances
  ✓ CloudWatch API 可達
  ✓ GitHub API 可達

Tier 4: State 一致性
  ✓ LOOP-STATE.md 最後更新 < 24h
  ✓ 沒有超過 7 天的待辦項未解決

Tier 5: 成本控制
  ✓ 日預算 < 10K tokens
  ✓ 運行時間 < 5 min
```

#### Prompts 版本化

```
prompts/
├─ system-prompt-triage-v1-zh.md (通用，4 steps)
└─ (項目特化)

zbot-aws/
└─ prompts-custom/
   ├─ system-prompt-aws-triage-v1-zh.md (AWS 特化)
   │  └─ 檢查項：EC2/Lambda/RDS/S3
   │  └─ 閾值：EC2 uptime > 99%, Lambda cold start < 3s
   │
   └─ system-prompt-aws-cost-v1-zh.md (成本分析)
      └─ 分析 EC2 Right-sizing、Spot Instance 節省
```

#### 失敗記錄 + 改進

```jsonl
# failures.jsonl 例

{"timestamp":"2026-07-04T08:15:00Z","failure_type":"missed_alert","description":"Lambda cold start > 5s 未檢出","root_cause":"Prompt 未明確要求查詢 CloudWatch Logs","remediation":{"prompt_fix":"Add: 'For Lambda: must query CloudWatch Logs filter by Init Duration'","prompt_version_next":"v1.1"}}

{"timestamp":"2026-07-03T10:00:00Z","failure_type":"false_positive","description":"RDS 報告 offline，實際網絡波動","root_cause":"無重試邏輯","remediation":{"design_fix":"Verifier 二次檢查，排除短暫波動","add_to_verifier_prompt":"retry_transient_failures=true"}}
```

---

### 💰 zbot-aladdin（金融算法驗證）

**項目特性**：
- 關鍵性：⭐⭐⭐⭐⭐（交易決策）
- 目標：每日回測驗證 + 風險評分

#### Loop 設計

```markdown
# LOOP.md — zbot-aladdin

## Active Loops

### Loop 1: Daily Backtest Verification (L1 report-only)
- 調度：每天 22:00 UTC (EOD)
- 技能：backtest-verifier
- 檢查項：
  * Sharpe Ratio (target > 1.5)
  * Max Drawdown (limit < 15%)
  * P&L 趨勢
  * 交易信號延遲 (should be < 30s from EOD)
- 狀態：LOOP-STATE.md
- 成本：~15K tokens/day (backtest 耗時)

### Loop 2: Portfolio Rebalance Signal (L1 suggest-only)
- 調度：每週日 20:00 UTC (before Monday trading)
- 技能：rebalance-checker
- 檢查項：
  * 各幣對配置比例
  * 風險敞口變化
- 狀態：LOOP-STATE.md
- 成本：~5K tokens/week
```

#### Prompts 特化（金融領域特殊性）

```
zbot-aladdin/prompts-custom/
├─ system-prompt-aladdin-backtest-v1-zh.md
│  ├─ 專業詞彙：Sharpe、Sortino、VaR、Expected Shortfall
│  ├─ 檢查流程：
│  │  Step 1: 載入昨日回測結果
│  │  Step 2: 計算 Sharpe = (平均收益 - rf) / 標準差
│  │  Step 3: 計算 Max Drawdown = 最大下跌幅度
│  │  Step 4: 檢查信號延遲
│  │  Step 5: 風險評分
│  └─ 失敗模式：忽略極值事件、不檢查滑點
│
└─ system-prompt-aladdin-risk-v1-zh.md
   └─ 獨立風險驗證（Verifier 角色）
      └─ 檢查：Sharpe < 1.0 是否真實，或數據錯誤？
```

#### Verifier 角色（獨立風險評估）

```python
# Verifier 的獨立決策流程

Implementer 的結論：
  "Sharpe Ratio = 0.8 (< 1.5 threshold)"
  
Verifier 的獨立檢查：
  1. 重新計算 Sharpe (不信任 Implementer)
  2. 檢查數據源 (是否有 NaN/Inf)
  3. 檢查市場環境 (是否極端行情)
  4. 決策：
     ✓ 確實低於閾值 → 建議改進
     ✗ 數據錯誤 → 標記為 false_alert
```

---

### 🏦 zbot-trading（交易所監控）

**項目特性**：
- 關鍵性：⭐⭐⭐⭐⭐（實時交易）
- 目標：交易所連接穩定性 + 風險監控

#### Loop 設計

```markdown
# LOOP.md — zbot-trading

## Active Loops

### Loop 1: Exchange Health Check (4h)
- 調度：每 4 小時
- 檢查項：
  * API 連接延遲 (target < 100ms)
  * Order Book 新鮮度 (target < 30s)
  * 訂單成交率 (應 > 95%)
- 級別：L1 (read-only)
- 成本：~2K tokens/4h

### Loop 2: Account Risk Monitor (1h)
- 調度：每 1 小時
- 檢查項：
  * 當前槓桿比例 (limit < 5.0x)
  * Net Worth 變化 (alert if > 5% change)
  * 掛起訂單 (alert if > 12h old)
  * 交易對風險 (concentration risk)
- 級別：L1 (alert-only)
- 成本：~1K tokens/h

### Loop 3: Liquidation Risk (immediate)
- 觸發條件：槓桿 > 4.5x 或虧損 > 3%
- 檢查項：平倉風險、市場流動性
- 級別：L1 (alert to human)
- 成本：計量外（關鍵路徑）
```

#### Prompts 特化（交易專業性）

```
zbot-trading/prompts-custom/
├─ system-prompt-trading-health-v1-zh.md
│  └─ 檢查項清單（具體到每個交易對和槓桿級別）
│
└─ system-prompt-trading-risk-v1-zh.md (Verifier)
   └─ 獨立風險決策：是否應立即平倉？
```

#### 人工 Gate（關鍵決策點）

```
Loop 報警 → 人工決策 → 執行

例：
Loop 檢測：槓桿 4.8x，市場下跌 2%
Loop 建議：考慮部分平倉以降低風險
人工決策：
  ✓ 是否同意平倉？
  ✓ 是否改變交易策略？
  ✗ 如果不同意，記錄原因 → 優化 Loop
```

---

### 💼 zbot-wallet（錢包管理）

**項目特性**：
- 關鍵性：⭐⭐⭐⭐（資金安全）
- 目標：鏈上同步驗證 + 餘額檢查

#### Loop 設計

```markdown
# LOOP.md — zbot-wallet

## Active Loops

### Loop 1: Sync Status Verification (6h)
- 調度：每 6 小時
- 檢查項：
  * 最後區塊同步時間 (should be < 1h old)
  * 同步進度 (should be 100%)
- 級別：L1 (read-only)

### Loop 2: Balance Reconciliation (1d)
- 調度：每天 08:00 UTC
- 檢查項：
  * 本地餘額 vs 鏈上餘額 (delta < 0.1%)
  * 待確認交易 (should have 6+ confirmations)
- 級別：L1 (alert-only)
```

---

### 📈 zbot-analytics（數據品質檢查）

**項目特性**：
- 關鍵性：⭐⭐⭐（輔助決策）
- 目標：數據集質量驗證

#### Loop 設計

```markdown
# LOOP.md — zbot-analytics

## Active Loops

### Loop 1: Data Quality Check (1d)
- 調度：每天 09:00 UTC
- 檢查項：
  * 數據集更新時間
  * NULL 值比例
  * 異常值檢測 (3-sigma)
  * 數據一致性 (primary key 唯一性)
- 級別：L1 (report-only)
```

---

### 🌐 zbot-website（網站部署監控）

**項目特性**：
- 關鍵性：⭐⭐⭐（用戶體驗）
- 目標：部署健康檢查

#### Loop 設計

```markdown
# LOOP.md — zbot-website

## Active Loops

### Loop 1: Deployment Health (30m)
- 調度：每 30 分鐘
- 檢查項：
  * HTTP 200 status
  * 響應時間 (target < 1s)
  * SSL 證書有效期
  * DNS 解析正常
- 級別：L1 (alert-only)
```

---

## 統一的 Loop 運維框架

### 每個項目的標準文件

```
zbot-*/
├─ LOOP.md                              ← 調度定義（所有 Loops）
├─ LOOP-STATE.md                        ← 運行狀態
├─ CLAUDE.md                            ← 項目配置（1-9 章）
│
├─ prompts-custom/                      ← 項目特化提示詞
│  ├─ system-prompt-{project}-triage-v1-zh.md
│  └─ system-prompt-{project}-{specialty}-v1-zh.md
│
└─ failures.jsonl                       ← 失敗記錄
```

### 中央共享的文件（symlink）

```
zbot-*/
├─ prompts → ../zbot-engineering/prompts/          (通用提示詞)
├─ pre-agents → ../zbot-engineering/pre-agents/    (檢查邏輯)
├─ mcp/ → ../zbot-engineering/mcp/                 (工具連接)
└─ .dev-loop-state.md → ../zbot-engineering/.dev-loop-state.md
```

---

## 實施路線（從現在開始）

### Week 1: 基礎設施 ✅ 已完成

```
✅ zbot-engineering/ 中央庫建立
✅ LOOP.md + LOOP-STATE.md 範本複製到 6 個項目
✅ 所有項目連接 symlink (prompts/, pre-agents/, .dev-loop-state.md)
✅ Pre-Agent Tier 1 檢查實現
```

### Week 2: 理論文檔（進行中）

```
🚧 zbot-核心概念.md (寫作中)
🚧 zbot-6大基礎要素.md (寫作中)
```

### Week 3: 項目特化 Prompts

```
□ zbot-aws: 完成 AWS 特化提示詞 v1.0
  └─ 檢查清單：EC2/Lambda/RDS/S3/Cost

□ zbot-aladdin: 完成金融特化提示詞 v1.0
  └─ 檢查清單：Sharpe/Drawdown/交易信號/風險

□ zbot-trading: 完成交易特化提示詞 v1.0
  └─ 檢查清單：連接/訂單簿/槓桿/風險

□ 其他項目: 簡化版提示詞
```

### Week 4: Verifier + MCP

```
□ system-prompt-verifier-v1-zh.md (獨立驗證層)
□ MCP Server 最小實現 (GitHub + AWS connectors)
□ 各項目集成 Verifier
```

---

## 決策樹：何時用 L1 vs L2 vs L3

```
你的 Loop 是：
├─ 只讀信息 (查詢、報告)？ → L1 report-only
│  └─ 例：zbot-aws 日常巡檢、zbot-aladdin 回測驗證
│
├─ 可以自動修復？ → L2 assisted
│  ├─ 必須有 Verifier 檢查
│  ├─ 必須有人工 gate
│  └─ 例：自動重啟服務、自動調整告警閾值
│
└─ 關鍵操作 (交易、轉帳、修改配置)？ → L3 unattended
   └─ 需要 3+ 週成熟度驗證
   └─ 例：自動交易、自動轉帳（暫不考慮）
```

---

## 檢查清單：項目 Loop 上線前

### 每個 zbot-* 項目的發佈清單

```
□ LOOP.md 定義清楚
  ✓ 調度明確（cadence, 級別）
  ✓ 檢查項列表完整
  ✓ MCP 配置清楚

□ LOOP-STATE.md 初始化
  ✓ 格式正確
  ✓ 路徑正確

□ Prompts 完整
  ✓ 通用 prompt 可用（symlink 有效）
  ✓ 項目特化 prompt 完整
  ✓ 版本號明確

□ Pre-Agent 檢查
  ✓ Tier 1-3 可運行
  ✓ 環境變數完整

□ 測試
  ✓ 手動運行一次 triage
  ✓ 驗證 LOOP-STATE.md 更新正常
  ✓ failures.jsonl 能記錄失敗
```

---

**目標**：每個 zbot-* 項目都成為一個自動化 Loop，按照 loop-engineering 的設計思想運行

**下一步**：選擇一個項目（推薦 zbot-aws），完整落地這套框架，然後複製到其他 5 個項目

**時間表**：
- Week 1: 基礎完成 ✅
- Week 2: 文檔完成 🚧
- Week 3: 項目特化 Prompts 完成
- Week 4: Verifier + MCP 完成
- Month 2: 6 個項目全部上線運行
EOF
cat /Users/lz/zbot/zbot-engineering/APPLY-LOOP-TO-ZBOT-PROJECTS.md | head -200
