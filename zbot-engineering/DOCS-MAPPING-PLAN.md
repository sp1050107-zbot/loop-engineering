# zbot-engineering 文檔對標計劃

**目標**：按照 loop-engineering 官方的文檔架構，為 zbot-engineering 建立完整、中文化的文檔體系

**原則**：
- ✅ 吸收官方的教學框架（Concepts → Quickstart → Patterns）
- ✅ 中文化所有內容（面向中文團隊）
- ✅ 加入 zbot 特化（6 個項目的具體用例）
- ✅ 融合官方與 zbot 的對標分析

---

## 官方文檔 vs zbot-engineering 映射表

| # | 官方文檔 | 大小 | 用途 | zbot 對標 | 優先級 |
|---|---------|------|------|----------|--------|
| 1 | **Concepts** | 3.3K | 理論基礎 | `zh-CN/zbot-核心概念.md` | P0 |
| 2 | **QUICKSTART** | 5.4K | 5 分鐘入門 | ✅ `QUICK-START-CN.md` (已完成) | ✅ |
| 3 | **Primitives** | 3.4K | 6 個基礎要素 | `zh-CN/zbot-6大基礎要素.md` | P0 |
| 4 | **Primitives-Matrix** | 15K | 工具對比 | `zh-CN/zbot-工具矩陣.md` | P1 |
| 5 | **Patterns** (7 個) | 系列 | 生產級模式 | ✅ `patterns/zbot-*.md` (部分完成) | P1 |
| 6 | **Pattern-Picker** | 3.2K | 選擇指南 | `zh-CN/模式選擇器.md` | P1 |
| 7 | **Safety** | 3.0K | 防護措施 | `zh-CN/安全邊界與防護.md` | P1 |
| 8 | **Failure-Modes** | 4.7K | 失敗分類 | `zh-CN/失敗模式分析.md` | P2 |
| 9 | **Anti-Patterns** | 2.7K | 反面案例 | `zh-CN/反面模式.md` | P2 |
| 10 | **Operating-Loops** | 3.6K | 運維 | `zh-CN/Loop運維指南.md` | P2 |
| 11 | **Multi-Loop** | 2.4K | 並行協調 | `zh-CN/多Loop協調.md` | P2 |
| 12 | **Loop-Design-Checklist** | 3.8K | 發佈前檢查 | `zh-CN/Loop設計清單.md` | P1 |
| 13 | **Adopters** | 2.5K | 用戶案例 | `zh-CN/zbot項目案例.md` | P3 |
| 14 | **RELEASE** | 3.4K | 發佈流程 | ✅ `UPSTREAM-SYNC-STRATEGY.md` (已完成) | ✅ |

---

## Phase 1: 核心文檔（Week 1-2）

### P0 優先級：理論 + 快速開始 + 基礎

#### 1.1 zbot-核心概念.md (新建)

**對應**：官方 `docs/concepts.md`  
**內容**：
- Loop Engineering 基礎概念（英文 → 中文）
- zbot-* 的具體應用場景
- 6 大基礎要素在 zbot 中的映射

**結構**：
```
# zbot-engineering 核心概念

## Loop 工程是什麼？
- 定義：從「每次手動 prompt」到「設計自動化系統」的轉變
- 例子：zbot-aws 每日巡檢 loop
- vs Agent Harness：Loop = Harness + Schedule + State + Verify

## 相關概念
- Intent Debt (意圖債)
- Comprehension Debt (理解債)
- Orchestration Tax (協調稅)

## 6 大基礎要素 (zbot 特化)
1. Automations/Scheduling → zbot 項目的 LOOP.md
2. Worktrees → 並行執行隔離
3. Skills → zbot-triage, zbot-verify, ...
4. Plugins/MCP → zbot-mcp-server
5. Sub-agents → Verifier 層
6. Memory/State → LOOP-STATE.md + .dev-loop-state.md
```

**工作量**：3h（翻譯 + zbot 例子）

#### 1.2 zbot-6大基礎要素.md (新建)

**對應**：官方 `docs/primitives.md`  
**內容**：
- 6 個基礎要素的詳細解說（中文）
- 每個要素在 zbot-* 中的具體應用
- 代碼示例

**結構**：
```markdown
# zbot-engineering 的 6 大基礎要素

## 1. Automations / Scheduling
- 官方概念：heartbeat，無調度 = 無 loop
- zbot 應用：
  - zbot-aws: 每天 08:00 UTC 日常巡檢
  - zbot-aladdin: 每天 22:00 UTC 回測驗證
  - zbot-trading: 每 4 小時交易所健康檢查

## 2. Worktrees
- 官方概念：並行執行 without collision
- zbot 應用：
  - 各 zbot-* 項目的 feature branch 隔離
  - Pre-merge verification 獨立環境

## 3. Skills
- 官方概念：persistent intent + conventions
- zbot 應用：
  - zbot-engineering/skills/loop-triage/
  - SKILL.md + prompt-v1.0-zh.md + failures.jsonl
  - 共享給 6 個項目（via symlink）

## 4. Plugins & Connectors (MCP)
- 官方概念：reach into real tools
- zbot 應用：
  - zbot-mcp-server (GitHub, AWS connectors)
  - 統一工具連接層

## 5. Sub-agents (Maker/Checker)
- 官方概念：實現者 ≠ 驗證者
- zbot 應用：
  - Implementer: 執行檢查、生成建議
  - Verifier: 獨立評估、防止虛假警報

## 6. Memory / State
- 官方概念：durable spine outside conversations
- zbot 應用：
  - LOOP-STATE.md (運行歷史)
  - .dev-loop-state.md (跨項目規則)
  - failures.jsonl (失敗案例)
```

**工作量**：4h（詳細說明 + 例子）

---

## Phase 2: 生產級文檔（Week 2-3）

### P1 優先級：模式 + 設計清單 + 工具矩陣

#### 2.1 zbot-工具矩陣.md (新建)

**對應**：官方 `docs/primitives-matrix.md`  
**內容**：
- 各 zbot-* 項目的工具支持矩陣
- 官方 Loop Engineering 工具 vs zbot 實現對比

**結構**：
```markdown
# zbot-engineering 工具矩陣

## 官方支持工具 vs zbot 實現

| 工具 | 官方支持 | zbot 實現 | 狀態 |
|------|--------|---------|------|
| Grok | ✅ | 無 (只用 Claude) | - |
| Claude Code | ✅ | ✅ 主要 | 生產 |
| Codex | ✅ | 無 | - |
| Opencode | ✅ | 可行 | 計劃 |

## zbot-* 項目的基礎要素矩陣

| 基礎要素 | zbot-aws | zbot-aladdin | zbot-trading | zbot-wallet | zbot-analytics | zbot-website |
|---------|---------|-------------|-------------|-----------|---------------|-------------|
| Automations | ✅ (1d 08:00) | ✅ (1d 22:00) | ✅ (4h) | ⚠️ | ⚠️ | ⚠️ |
| Worktrees | 計劃 | 計劃 | 計劃 | - | - | - |
| Skills | ✅ shared | ✅ shared | ✅ shared | ✅ shared | ✅ shared | ✅ shared |
| MCP | ✅ AWS | ⚠️ (future) | ⚠️ (future) | - | - | - |
| Sub-agents | ✅ v1.1 | ✅ v1.1 | ✅ v1.1 | - | - | - |
| Memory | ✅ STATE.md | ✅ STATE.md | ✅ STATE.md | ✅ STATE.md | ✅ STATE.md | ✅ STATE.md |
```

**工作量**：3h

#### 2.2 Loop設計清單.md (新建)

**對應**：官方 `docs/loop-design-checklist.md`  
**內容**：
- Loop 發佈前的檢查清單（中文 + zbot 定製）
- 每個 zbot-* 項目的啟動檢查清單

**結構**：
```markdown
# zbot Loop 設計清單

## 發佈前檢查（緊急事項）

### Tier 0: 基礎配置
- [ ] LOOP.md 定義了調度 (cadence, level, cadence)
- [ ] LOOP-STATE.md 初始化
- [ ] 項目級 CLAUDE.md Chapters 1-9 完整
- [ ] 環境變數文檔清楚

### Tier 1: Safety
- [ ] 定義了明確的 denylist (禁止操作)
- [ ] MCP connectors 是 read-only (除非特別授權)
- [ ] Token 預算限制已設置
- [ ] 有人工 gate (決不能完全自動化的改動)

### Tier 2: Observability
- [ ] LOOP-STATE.md 會被每次 Loop 更新
- [ ] failures.jsonl 記錄失敗案例
- [ ] loop-run-log.md 記錄執行日誌
- [ ] 有明確的監控指標

### Tier 3: Verification
- [ ] Verifier sub-agent 已集成
- [ ] 有獨立的測試/驗證步驟
- [ ] 無自評（Verifier ≠ Implementer）

### Tier 4: State Management
- [ ] .dev-loop-state.md 指向中央規則庫
- [ ] 無懸而未決的待辦項 (除非標記為"等待人工")
- [ ] State 一致性檢查 (timestamps, json 格式等)

### Tier 5: Cost Control
- [ ] Token 預算清晰 (daily, weekly)
- [ ] 成本估計準確（已 backtest）
- [ ] 超出預算時自動停止機制
```

**工作量**：3h

#### 2.3 模式選擇器.md (新建)

**對應**：官方 `docs/pattern-picker.md`  
**內容**：
- zbot-* 應該選擇哪種模式
- 決策樹

**結構**：
```markdown
# zbot 模式選擇器

你是誰？ → 選擇 Loop 模式

## zbot-aws (基礎設施)
→ Daily Triage + Audit Sweeper
→ 目標：每日健康檢查 + 自動修復簡單故障

## zbot-aladdin (金融算法)
→ Daily Backtest + Rebalance Checker
→ 目標：回測驗證 + 風險評分

## zbot-trading (交易所)
→ Exchange Health Check + Account Risk Monitor
→ 目標：連接監控 + 槓桿風險告警

## zbot-wallet (錢包)
→ Sync Verification + Balance Reconciliation
→ 目標：鏈上同步 + 餘額檢查

## zbot-analytics (分析)
→ Data Quality Check
→ 目標：數據品質驗證

## zbot-website (網站)
→ Deployment Health Check
→ 目標：部署狀態監控
```

**工作量**：2h

---

## Phase 3: 風險 + 運維文檔（Week 3-4）

### P2 優先級：失敗模式、反面模式、運維

#### 3.1 失敗模式分析.md (新建)

**對應**：官方 `docs/failure-modes.md`  
**內容**：
- zbot-* 中實際發生的失敗案例
- 根本原因分析
- 防護措施

**結構**：
```markdown
# zbot 失敗模式分析

## FM-001: Prompt 曖昧導致的漏檢

**症狀**：Agent 遺漏關鍵的健康檢查項
**例子**：zbot-aws Lambda 冷啟 > 5s 未被檢出
**根本原因**：Prompt 中"檢查健康"沒有明確列出要查什麼
**防護**：
- Prompt v1.1 明確化檢查清單
- failures.jsonl 記錄每次漏檢
- Verifier 獨立檢查是否遺漏

## FM-002: Context Collapse

**症狀**：Long-running Loop 中途 token 用盡，Agent 忘記初始目標
**例子**：zbot-aladdin 日內交易回測耗盡 context
**根本原因**：未設置 Loop 時長上限
**防護**：
- Pre-Agent Tier 2 檢查：Context 邊界
- 超過 5 分鐘自動停止
- 分解為多個小 Loop

## FM-003: False Positives 導致告警疲勞

**症狀**：每次都有虛假警報，人工開始忽略所有警報
**例子**：zbot-trading 每 4 小時就有虛假的"exchange offline"
**根本原因**：Threshold 設置不當，未考慮網絡波動
**防護**：
- Verifier 二次檢查（排除短暫波動）
- 失敗記錄中標記"false_positive"
- Backtest 時追蹤虛假警報率
```

**工作量**：4h

#### 3.2 反面模式.md (新建)

**對應**：官方 `docs/anti-patterns.md`  
**內容**：
- zbot-engineering 設計中的常見錯誤
- 為什麼這樣做會失敗

**結構**：
```markdown
# zbot 反面模式

## AP-001: 所有項目用相同 Prompt

❌ 錯誤做法：
```python
# 所有 zbot-* 項目共用同一個 prompt
prompts/system-prompt-triage-v1-zh.md (通用)
```

✅ 正確做法：
```python
# 基礎 prompt 共用
prompts/system-prompt-triage-v1-zh.md (通用 4 steps)

# 項目特化檢查清單
zbot-aws/prompts-custom/system-prompt-aws-triage-v1-zh.md
  → 增加 EC2/Lambda/RDS 特定檢查

zbot-aladdin/prompts-custom/system-prompt-aladdin-triage-v1-zh.md
  → 增加 Sharpe Ratio/Drawdown 檢查
```

原因：不同項目的"健康"定義不同。通用 prompt 要麼太寬泛，要麼對某個項目不適用。

## AP-002: Verifier 繼承 Implementer 的上下文

❌ 錯誤做法：
```python
response_impl = client.messages.create(
  messages=[{"role": "user", "content": "Run triage..."}]
)
# Verifier 看到 Implementer 的整個對話歷史
response_verifier = client.messages.create(
  messages=response_impl.messages + [
    {"role": "user", "content": "Grade this output"}
  ]
)
```

✅ 正確做法：
```python
response_impl = client.messages.create(
  messages=[{"role": "user", "content": "Run triage..."}]
)
# Verifier 完全獨立的 API 調用，無歷史
response_verifier = client.messages.create(
  messages=[
    {"role": "user", "content": f"Grade this:\n{response_impl.text}\n\nRubric: ..."}
  ]
)
```

原因：Verifier 必須有獨立的判斷，否則會被 Implementer 的盲點誤導。
```

**工作量**：3h

---

## Phase 4: 實用工具文檔（Week 4）

### P3 優先級：案例、最佳實踐、引用

#### 4.1 zbot項目案例.md (新建)

**對應**：官方 `docs/adopters.md`  
**內容**：
- 6 個 zbot-* 項目各自的 Loop 故事
- 成果指標

**結構**：
```markdown
# zbot-* 項目案例

## 案例 1: zbot-aws 日常運維 Loop

**背景**：每天需要手動檢查 EC2、Lambda、RDS 的狀態

**Loop 設計**：
- Cadence: 1d 08:00 UTC
- Level: L1 (report-only)
- Skill: loop-triage

**成果**：
- ✅ 自動發現故障時間從 4h → 5 min
- ✅ 每月節省 ~10 小時人工檢查
- ✅ 虛假警報率 < 5% (Verifier 有效)

**下一步**：
- [ ] Upgrade to L2 (assisted fix)
- [ ] Worktree 支持並行修復

---

## 案例 2: zbot-aladdin 交易算法驗證 Loop

**背景**：每天需要驗證回測結果、風險指標

**Loop 設計**：
- Cadence: 1d 22:00 UTC (EOD)
- Level: L1 (report-only)
- Skill: aladdin-backtest-verify

**成果**：
- ✅ 發現風險異常的時間從 next day → EOD same day
- ✅ 3 個月內捕獲 2 個潛在虧損算法
- ✅ Sharpe ratio 追蹤自動化

**下一步**：
- [ ] 集成 Linear 讓 Loop 自動提交 issue
```

**工作量**：3h

---

## 文檔完成度目標

### Week 1-2 (P0)：基礎教學框架
- ✅ QUICK-START-CN.md (已完成)
- [ ] zbot-核心概念.md
- [ ] zbot-6大基礎要素.md

目標：新用戶能 15 分鐘內理解 zbot-engineering 的基本原理

### Week 2-3 (P1)：生產級決策
- [ ] zbot-工具矩陣.md
- [ ] Loop設計清單.md
- [ ] 模式選擇器.md

目標：項目經理/架構師能決定「怎樣用 Loop」

### Week 3-4 (P2)：風險管理
- [ ] 失敗模式分析.md
- [ ] 反面模式.md
- ✅ UPSTREAM-SYNC-STRATEGY.md (已完成)

目標：運維人員能「預測和防止」失敗

### Month 2+ (P3)：社區建設
- [ ] zbot項目案例.md
- [ ] 最佳實踐合集.md
- [ ] 常見問題解答.md

目標：知識沉澱，方便未來團隊查閱

---

## 文檔組織結構

```
zbot-engineering/
├─ docs/
│  ├─ zh-CN/
│  │  ├─ zbot-核心概念.md              (Phase 1)
│  │  ├─ zbot-6大基礎要素.md           (Phase 1)
│  │  ├─ zbot-工具矩陣.md              (Phase 2)
│  │  ├─ Loop設計清單.md               (Phase 2)
│  │  ├─ 模式選擇器.md                 (Phase 2)
│  │  ├─ 安全邊界與防護.md             (Phase 2)
│  │  ├─ 失敗模式分析.md               (Phase 3)
│  │  ├─ 反面模式.md                   (Phase 3)
│  │  ├─ Loop運維指南.md               (Phase 3)
│  │  ├─ 多Loop協調.md                 (Phase 3)
│  │  ├─ zbot項目案例.md               (Phase 4)
│  │  └─ FAQ.md                       (Phase 4)
│  │
│  └─ reference/
│     ├─ 官方文檔鏈接.md
│     └─ zbot-engineering設計思路.md
│
├─ README.md                           (總覽)
├─ QUICK-START-CN.md                   ✅ (已完成)
├─ ARCHITECTURE-AND-GOVERNANCE.md      ✅ (已完成)
├─ LOOP-ENGINEERING-ALIGNMENT.md       ✅ (已完成)
└─ UPSTREAM-SYNC-STRATEGY.md           ✅ (已完成)
```

---

## 開發流程

### 每個文檔的標準流程

```
1. Draft (我寫初稿)
2. Review (Leon 審視結構 + 例子是否 accurate)
3. Enhancement (Claude 補充例子和細節)
4. Test (在 zbot-* 項目中驗證內容可行性)
5. Publish (Merge to main, tag version)
```

### 評審清單（每份文檔）

- [ ] 是否有明確的目標受眾（新手/架構師/運維）
- [ ] 是否有 3+ 個真實例子（不是假的）
- [ ] 是否與官方對應文檔的邏輯一致
- [ ] 是否有actionable 的下一步

---

## 預期成果

### 完成後的文檔體系應該達到：

1. **新用戶** → 15 分鐘入門（QUICK-START）
2. **架構師** → 30 分鐘理解設計（概念 + Primitives + 清單）
3. **運維** → 知道如何運行、監控、排障（運維 + 失敗模式）
4. **社區** → 可複用的知識庫（案例 + 最佳實踐）

### 與官方框架的對標結果：

| 維度 | 官方 | zbot | 評估 |
|------|------|------|------|
| 文檔數量 | 14 | 12+ | 95% 覆蓋 |
| 語言 | 英文 | 中文 | ✅ 完全本地化 |
| 項目特化 | 通用 | zbot-* 特化 | ✅ 增加實用性 |
| 深度 | 概念 + 案例 | 概念 + 案例 + 程式 | ✅ 更實用 |

---

## 下一步

**立即開始（Week 1）**：
```bash
# 1. 建立目錄結構
mkdir -p /Users/lz/zbot/zbot-engineering/docs/zh-CN

# 2. 優先完成 P0 文檔
- zbot-核心概念.md
- zbot-6大基礎要素.md

# 3. 讓 Leon 和 Claude 合作完成初稿
```

**每週進度檢查**：
- 周末：Week Review 時檢查文檔進度
- 月底：Month Review 時評估是否達成里程碑

---

**所有者**：Leon Lin (架構)  
**作者**：Claude (AI Infrastructure)  
**審核**：Leon (準確性)  
**下次更新**：2026-07-18 (Phase 2 開始)
