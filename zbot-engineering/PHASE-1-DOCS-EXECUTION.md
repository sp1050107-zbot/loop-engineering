# Phase 1 文檔執行計劃（Week 1-2）

**目標**：建立 zbot-engineering 的理論基礎和快速開始，讓新用戶和架構師都能快速上手

**時間**：2026-07-04 ~ 2026-07-18（2 週）

---

## 優先級排序

### P0（必須）- Week 1

```
□ zbot-核心概念.md           (3h)  → 理論基礎
□ zbot-6大基礎要素.md        (4h)  → 實踐指南
```

### P1（重要）- Week 1-2

```
□ 驗證 QUICK-START-CN.md     (1h)  → 已有，檢查是否完整
□ 更新 README.md            (2h)  → 導航文檔
```

**合計**：10 小時（2 人 × 5 天）

---

## 詳細任務分工

### Task 1: zbot-核心概念.md (P0, 3h)

**負責**：Claude  
**參考**：
- 官方 `loop-engineering/docs/concepts.md`
- zbot-engineering 現有文檔（LOOP.md, LOOP-STATE.md 等）

**大綱**：
```
1. Loop Engineering 是什麼？(為什麼要設計 Loop)
   - 從「手動 prompt」到「自動系統」
   - zbot-aws 每日巡檢的例子

2. 核心術語 (對應官方 concepts)
   - Agent Harness (單次 session)
   - Loop (反覆系統)
   - Intent Debt (意圖債)
   - Comprehension Debt (理解債)
   - Orchestration Tax (協調稅)
   - Cognitive Surrender (認知放棄) - 反面例子

3. 6 大基礎要素概览
   - 簡單列表 + 定義
   - 在 zbot-* 中的角色

4. 關鍵圖示
   - Mermaid 圖：Loop 系統架構
   - 流程圖：Discover → Plan → Execute → Verify → Iterate

5. 下一步導航
   - 看 zbot-6大基礎要素.md 深入
   - 看 QUICK-START-CN.md 動手做
```

**驗收標準**：
- [ ] 5-10 分鐘內讀完
- [ ] 新用戶能理解「什麼是 zbot Loop」
- [ ] 有 3+ 個真實例子（zbot-* 項目）
- [ ] 引用官方概念時標明出處

**截止**：2026-07-08

---

### Task 2: zbot-6大基礎要素.md (P0, 4h)

**負責**：Claude  
**參考**：
- 官方 `loop-engineering/docs/primitives.md`
- zbot-engineering 的現有實現（prompts/, pre-agents/, mcp/ 等）

**大綱**：
```
1. Automations / Scheduling
   - 定義：系統的「心跳」
   - 官方例子：/loop 1d
   - zbot 例子：
     * zbot-aws: /loop 1d 08:00 UTC
     * zbot-aladdin: /loop 1d 22:00 UTC
     * zbot-trading: /loop 4h
   - 配置位置：各項目的 LOOP.md

2. Worktrees
   - 定義：並行執行隔離
   - 官方工具：git worktree
   - zbot 狀態：計劃中 (Phase 2)
   - 何時需要：多個 Loop 同時改代碼時

3. Skills
   - 定義：persistent intent + conventions
   - zbot 實現：zbot-engineering/skills/
     * loop-triage/ (日常巡檢)
     * loop-verify/ (驗證層)
   - 版本管理：system-prompt-triage-v1-zh.md
   - 失敗記錄：failures.jsonl (防回歸)

4. Plugins & Connectors (MCP)
   - 定義：reach into external tools
   - zbot 實現：zbot-engineering/mcp/
     * GitHub connector (read issues)
     * AWS connector (query logs)
   - 未來計劃：Linear, Slack (Phase 3-4)

5. Sub-agents (Maker / Checker)
   - 定義：implementer ≠ verifier
   - 為什麼重要：自評有盲點
   - zbot 實現：
     * Implementer: 執行 triage
     * Verifier: 獨立檢查（完全新 API 調用）
   - 何時啟用：Prompt v1.1 (Phase 2)

6. Memory / State
   - 定義：durable spine
   - zbot 實現三層：
     * LOOP-STATE.md (項目運行歷史)
     * .dev-loop-state.md (跨項目規則庫)
     * failures.jsonl (失敗案例 + 改進方向)
   - 為什麼必需：Loop 不能「健忘」
```

**代碼示例**：
```python
# 示例 1: Verifier 獨立檢查
worker = client.messages.create(
  messages=[{"role": "user", "content": "Run triage..."}]
)

# 獨立的 API 調用，無歷史繼承
verifier = client.messages.create(
  messages=[
    {"role": "user", "content": f"Grade: {worker.text}"}
  ]
)

# 示例 2: State 持久化
with open("LOOP-STATE.md", "a") as f:
  f.write(f"Last run: {datetime.now().isoformat()}\n")
  f.write(f"Findings: ...\n")
```

**驗收標準**：
- [ ] 每個基礎要素有 1-2 頁的詳細說明
- [ ] 有 2-3 個 zbot 實例代碼
- [ ] 有"為什麼"（不只是"是什麼"）
- [ ] 有"何時"（什麼時候用這個基礎要素）

**截止**：2026-07-11

---

### Task 3: 驗證 QUICK-START-CN.md (P1, 1h)

**負責**：Leon  
**檢查項**：
- [ ] 15 分鐘確實能入門嗎？實測一遍
- [ ] 命令是否都能運行？
- [ ] 輸出是否與文檔描述一致？

**截止**：2026-07-10

---

### Task 4: 更新 README.md (P1, 2h)

**負責**：Claude  
**更新內容**：
```markdown
# zbot-engineering 中央文檔庫

## 快速導航

根據你的角色，選擇對應的文檔：

### 👨‍💼 CTO / 架構師
想理解 zbot Loop 的全景設計？
→ 開始：`zbot-核心概念.md` (15 min)
→ 深入：`zbot-6大基礎要素.md` (30 min)
→ 生產檢查清單：(Phase 2) Loop設計清單.md

### 👨‍💻 工程師
想快速上手，建立第一個 Loop？
→ 開始：`QUICK-START-CN.md` (15 min)
→ 實操：各 zbot-* 項目的 LOOP.md
→ 深入：各 Skill 的 SKILL.md

### 🛠️ 運維 / DevOps
想知道怎麼運行、監控、排障？
→ 開始：`ARCHITECTURE-AND-GOVERNANCE.md` (治理流程)
→ 同步官方更新：`UPSTREAM-SYNC-QUICK-GUIDE.md`
→ 故障排除：(Phase 3) 失敗模式分析.md

### 🎓 新人培訓
想完整理解系統？
→ 課程順序：
  1. 核心概念 (15 min)
  2. 6 大基礎要素 (30 min)
  3. 快速開始 (15 min)
  4. 實操 zbot-aws (30 min)
  5. 深入 Prompt 工程 (1h)

## 文檔層級

| 層級 | 文檔 | 深度 | 時間 |
|------|------|------|------|
| L1 (入門) | QUICK-START-CN.md | 概念 + 做法 | 15 min |
| L2 (理解) | 核心概念.md + 6大基礎要素.md | 理論 + 例子 | 45 min |
| L3 (生產) | ARCHITECTURE-AND-GOVERNANCE.md | 治理 + 決策 | 1h |
| L4 (運維) | (Phase 3) 失敗模式分析.md | 風險 + 排障 | 深入研究 |

## 文檔狀態

| 文檔 | 狀態 | 發佈時間 |
|------|------|--------|
| QUICK-START-CN.md | ✅ 完成 | 2026-07-04 |
| 核心概念.md | 🚧 進行中 | 2026-07-08 |
| 6大基礎要素.md | 🚧 進行中 | 2026-07-11 |
| 工具矩陣.md | 📋 計劃中 | 2026-07-18 |
| Loop設計清單.md | 📋 計劃中 | 2026-07-18 |
| 失敗模式分析.md | 📋 計劃中 | 2026-07-25 |

## 官方文檔對應

zbot-engineering 文檔基於 loop-engineering 官方框架的中文化 + zbot 特化。

參考映射：
→ 官方概念文檔：`loop-engineering/docs/concepts.md`
→ 官方基礎要素：`loop-engineering/docs/primitives.md`
→ 官方工具矩陣：`loop-engineering/docs/primitives-matrix.md`
```

**驗收標準**：
- [ ] 新用戶看到清楚的導航
- [ ] 文檔狀態一目了然
- [ ] 有深度指引（新手 → 高級）

**截止**：2026-07-11

---

## 協作流程

### 步驟 1: Claude 寫初稿 (2-3 天)

```bash
cd /Users/lz/zbot/zbot-engineering

# 創建文檔
touch docs/zh-CN/zbot-核心概念.md
touch docs/zh-CN/zbot-6大基礎要素.md

# 寫初稿（直接編輯或通過 Claude）
```

### 步驟 2: Leon 審視 (1 天)

審視清單：
- [ ] 邏輯是否清楚？
- [ ] zbot 例子是否準確？
- [ ] 有沒有與官方框架的邏輯偏離？
- [ ] 深度是否合適（新手能懂嗎？）

反饋方式：
```bash
# 在文檔中加 TODO 註釋
# [TODO] 這個例子需要改進，因為...

# 或直接編輯 + commit
git commit -m "docs: improve zbot-核心概念.md

- Rewrote Intent Debt section for clarity
- Added 3 more zbot examples
- Fixed terminology translation"
```

### 步驟 3: Claude 改進 (1-2 天)

根據反饋：
```bash
# 改進文檔
vi docs/zh-CN/zbot-核心概念.md

# 再次驗證
git diff

# 提交
git add docs/zh-CN/zbot-核心概念.md
git commit -m "docs: final review - zbot-核心概念.md ready for release"
```

### 步驟 4: 發佈 & 通知 (1 day)

```bash
# 標籤發佈
git tag -a v1.0-docs-phase1 -m "Phase 1 core documentation

- zbot-核心概念.md (released)
- zbot-6大基礎要素.md (released)

Phase 2 coming: 2026-07-18"

# Push
git push origin main --tags

# 通知（可選）
# 在 GitHub Discussion 發帖：「Phase 1 文檔發佈」
```

---

## 時間表

| 日期 | 里程碑 | 負責 |
|------|--------|------|
| 2026-07-04 (周五) | Phase 1 計劃確認 | Leon |
| 2026-07-08 (周二) | 核心概念.md 初稿 → 審視 | Claude → Leon |
| 2026-07-10 (周四) | QUICK-START 驗證完成 | Leon |
| 2026-07-11 (周五) | 6大基礎要素.md 完成 + README 更新 | Claude → Leon |
| 2026-07-11 (周五) | Phase 1 發佈 & Tag | Claude |

---

## Phase 1 發佈清單

✅ 準備發佈前檢查：

```
□ zbot-核心概念.md
  - [ ] 語言流暢（中文）
  - [ ] 有 3+ zbot 例子
  - [ ] 與官方思路一致
  - [ ] 沒有技術錯誤

□ zbot-6大基礎要素.md
  - [ ] 每個要素都有"官方定義 + zbot 實現"
  - [ ] 有代碼示例
  - [ ] 能解答"為什麼需要這個"

□ README.md 更新
  - [ ] 導航清楚
  - [ ] 文檔狀態準確

□ 整體
  - [ ] 無死鏈接
  - [ ] 無拼寫錯誤
  - [ ] 代碼示例都是真實的（可運行）
  - [ ] 新用戶能跟著操作
```

---

## 可交付物

完成 Phase 1 後，zbot-engineering 將具備：

✅ **理論基礎** (核心概念.md)
- 新人能理解「為什麼要做 Loop」
- 架構師能從「系統設計」層面思考

✅ **實踐指南** (6大基礎要素.md)
- 工程師知道「怎麼用 6 個基礎要素」
- 每個要素都有 zbot 實例和代碼

✅ **快速入門** (QUICK-START-CN.md 驗證)
- 15 分鐘能跑起一個 Loop

✅ **清晰導航** (README.md)
- 不同角色知道讀什麼

---

**開始日期**：2026-07-04  
**Phase 1 完成日期**：2026-07-11  
**Phase 2 開始日期**：2026-07-18

Go! 🚀
