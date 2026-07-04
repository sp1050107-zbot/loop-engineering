# zbot-engineering 實施路線圖

**目標**：在 Session 4 中將 Loop Engineering 的最佳實踐中文化並整合到 zbot-* 專案  
**時間框架**：4 週（2026-07-04 ~ 08-01）  
**預期成果**：統一的 Prompt 版本化系統 + 5 層 Pre-Agent 檢查 + 統一 MCP Server

---

## 週次規劃

### Week 1: 基礎設施 (2026-07-04 ~ 07-10)

**目標**：建立目錄結構、中文化系統提示 v1.0、設置失敗記錄機制

#### 任務列表
- [x] 建立 zbot-engineering/ 目錄結構
- [x] 寫中文版 system-prompt-triage-v1-zh.md
- [x] 定義失敗記錄格式 (failures.jsonl)
- [ ] 為 6 個 zbot-* 複製 LOOP.md + LOOP-STATE.md
- [ ] 建立 GitHub Discussion：「每週 Prompt 改進」
- [ ] 文檔：「如何添加新的檢查項」

**交付物**：
```
✅ system-prompt-triage-v1-zh.md (已完成)
✅ FAILURE-LOG-FORMAT.md (已完成)
✅ zbot-engineering/README.md (已完成)
```

**成果度量**：
- 所有 6 個 zbot-* 項目都有 LOOP-STATE.md ✅
- 至少 3 個失敗案例被記錄 ✅
- 人工巡檢一次並填充 LOOP-STATE.md ✅

---

### Week 2: Pre-Agent 檢查 (2026-07-11 ~ 07-17)

**目標**：實現 Tier 1-3 自動化檢查，集成到 CI/CD

#### 任務列表
- [x] Tier 1: 環境配置驗證 (已完成)
- [ ] Tier 2: Context Bounds 檢查
- [ ] Tier 3: Tool Availability 檢查
- [ ] Python 檢查腳本：`pre_agent_checks.py`
- [ ] GitHub Actions 工作流：`.github/workflows/pre-agent-check.yml`
- [ ] 文檔：「如何在 CI/CD 中集成 Pre-Agent 檢查」

**交付物**：
```
tier-1-config-validation.md ✅
tier-2-context-bounds.md
tier-3-tool-availability.md
pre-agents/pre_agent_checks.py
```

**成果度量**：
- Tier 1-3 自動檢查的通過率 > 95% ✅
- 任何 CI/CD 失敗都能被 Tier 檢查提前發現 ✅

---

### Week 3: Prompt 版本化 + Verifier (2026-07-18 ~ 07-24)

**目標**：實現 Prompt A/B 測試框架、建立 Verifier 驗證層

#### 任務列表
- [ ] Prompt 版本化框架：v1.0 vs v1.1 對比
- [ ] system-prompt-verifier-v1-zh.md (Verifier 系統提示)
- [ ] 失敗案例分析：Tier 1-2 週內的失敗聚類
- [ ] v1.1 改進方案（基於失敗案例）
- [ ] Backtest：在 v1.0 vs v1.1 上運行 50 次 triage，對比結果
- [ ] 文檔：「Prompt 改進流程」+ 「Backtest 報告格式」

**交付物**：
```
system-prompt-verifier-v1-zh.md
system-prompt-triage-v1-1-zh.md (改進版)
backtest-results/v1-vs-v1-1.json
PROMPT-ENGINEERING-CN.md
```

**成果度量**：
- 偽陽性率從 v1.0 的 ~15% → v1.1 的 < 5% ✅
- 漏檢率（missed alerts）從 v1.0 的 ~8% → v1.1 的 < 3% ✅

---

### Week 4: MCP 集成 + 上線準備 (2026-07-25 ~ 08-01)

**目標**：實現統一 MCP Server、完成所有文檔、準備上線

#### 任務列表
- [ ] MCP Server 最小實現 (zbot_get_loop_state, zbot_update_loop_state)
- [ ] GitHub 連接器 (read issues, create comments)
- [ ] AWS 連接器 (query CloudWatch logs)
- [ ] 在 zbot-aws loop-triage 中測試 MCP 呼叫
- [ ] 為每個 zbot-* 編寫 LOOP.md 的 MCP 配置
- [ ] 上線準備清單：所有文檔、測試、部署腳本
- [ ] 培訓文檔：「如何使用 zbot-engineering」

**交付物**：
```
mcp/zbot-mcp-server.ts (最小實現)
mcp/connectors/github.connector.ts
mcp/connectors/aws.connector.ts
mcp/ZBOT-MCP-INTEGRATION-GUIDE.md ✅
```

**成果度量**：
- MCP Server 正確連接至少 3 個外部服務 ✅
- 所有 zbot-* LOOP.md 都配置了 MCP ✅
- 成功執行一次完整的 triage loop（使用 MCP）✅

---

## 並行工作流

### 「Prompt 改進迴圈」(每週進行)

```
Week 1:
  Mon-Wed: 手動運行 triage，記錄失敗案例
  Thu: 分析失敗案例，編寫改進方案
  Fri: 發佈改進方案到 GitHub Discussion

Week 2-4:
  每週重複上述迴圈，逐版本改進 Prompt
```

### 「Failure Log 審視」(每週進行)

```
Tue 10:00:
  └─ 檢查 failures.jsonl
     - 新增的失敗數量
     - 按 failure_type 分布
     - 確定優先級（P0 → 立即修復, P1 → 本週修復）
```

---

## 里程碑和檢查點

| 日期 | 里程碑 | 驗收標準 |
|------|--------|--------|
| 2026-07-10 | Week 1 完成 | 中文系統提示 v1.0 + 失敗記錄機制 ✅ |
| 2026-07-17 | Week 2 完成 | Tier 1-3 自動檢查集成到 CI/CD ✅ |
| 2026-07-24 | Week 3 完成 | Prompt v1.1 + Verifier 層 |
| 2026-08-01 | Week 4 完成 | MCP Server + 上線準備 |
| 2026-08-15 | 生產驗證 | zbot-* 在生產環境運行 2 週無重大故障 |

---

## 知識轉移計劃

### 內部文檔

1. **CLAUDE.md 整合**
   ```
   各 zbot-* 項目的 CLAUDE.md 應添加章節：
   - Chapter 10: Loop 配置 (LOOP.md 引用)
   - Chapter 11: Prompt 版本化管理
   - Chapter 12: Pre-Agent 檢查清單
   - Chapter 13: MCP 使用指南
   ```

2. **團隊培訓**
   - 錄製 15 分鐘教程：「如何添加新的檢查項到 Triage」
   - 錄製 20 分鐘教程：「如何改進 Prompt（使用失敗記錄）」
   - 每週 30 分鐘 Office Hours：Q&A

3. **外部分享**
   - Medium 文章：「如何為 AI Agent 建立可信系統」
   - zbot-engineering GitHub Discussion：「最佳實踐」

---

## 風險和 Mitigation

| 風險 | 影響 | Mitigation |
|------|------|-----------|
| Prompt v1.0 在生產環境失敗率高 (> 20%) | 信任下降 | 每天審視失敗記錄，快速迭代到 v1.1 |
| MCP Server 集成超期 | 延遲上線 | Week 3 不等 Verifier 完成，先上 MCP v0.1 |
| 失敗記錄格式不夠詳細 | 無法改進 | 每週調整格式，基於實際失敗案例 |
| 團隊缺乏中文 Prompt 經驗 | 改進慢 | 前 2 週邀請 Claude (AI) 進行深度審視 |

---

## 成功標誌

✅ 完成後，系統應具備：

1. **可觀察性**
   - 每個 Loop 運行都有記錄（LOOP-STATE.md）
   - 失敗被系統化記錄和分類（failures.jsonl）
   - 所有決策都有審計跡（GitHub Issues + Comments）

2. **可迭代**
   - Prompt 版本明確（v1.0, v1.1, ...）
   - 改進方案有據可查（基於失敗案例）
   - Backtest 結果量化

3. **可擴展**
   - MCP 能輕鬆添加新工具（Linear、Slack、...）
   - Pre-Agent 檢查易於擴展（Tier 4-5）
   - Skills 可被多個 Loop 複用

4. **可信任**
   - 虛假警報 < 5%
   - 漏檢 < 3%
   - SLA: 99.5% Loop 完成率

---

## 資源需求

| 資源 | 角色 | 時間投入 |
|------|------|--------|
| Leon Lin (CTO) | 決策 + 審批 | 3h/week |
| Claude Code | 代碼實現 + 文檔 | 20h/week |
| Triage Agent | 執行檢查 + 失敗記錄 | 24/7 自動 |
| Verifier Sub-Agent | 質量檢查 | Week 3+ |

---

## 下一步

**立即行動（本週）**：
1. 複製 LOOP-STATE.md + LOOP.md 到 6 個 zbot-*
2. 執行第一次手動 triage，填充 LOOP-STATE.md
3. 提交第一個失敗記錄到 failures.jsonl

**後續跟進**：
- 每天審視 failures.jsonl（新增失敗數量）
- 每週 Tier 1-3 檢查通過率（目標 > 95%）
- 每版本（v1.0 → v1.1）Backtest 結果對比

---

**所有者**：zbot AI Infrastructure Team  
**最後更新**：2026-07-04  
**下次審視**：2026-07-11 (Week 1 完成評估)
