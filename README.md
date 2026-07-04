# zbot — 意圖驅動的自主運維

由 4 層 AI Agent 自動搭建、監控、管理多雲環境的自主運維系統。

---

## 🚀 快速入口

| 角色 | 從這裡開始 | 下一步 |
|------|----------|------|
| **首次訪問** | [ZBOT-ENGINEERING-MASTER-SUMMARY.md](./ZBOT-ENGINEERING-MASTER-SUMMARY.md) (5 分鐘) | → README-INTENT-DRIVEN-DEVOPS.md |
| **CTO/架構師** | [README-INTENT-DRIVEN-DEVOPS.md](./README-INTENT-DRIVEN-DEVOPS.md) | → intent-driven-devops-complete-blueprint.md |
| **開發工程師** | [zbot-engineering/README.md](./zbot-engineering/README.md) | → 選擇項目 → LOOP.md |
| **AI Agent** | 項目的 CLAUDE.md + LOOP.md | → zbot-engineering/prompts/ |

---

## 📂 目錄結構

```
zbot/
├─ README.md (本文件 — 入口)
├─ 🔷 架構文檔
│  ├─ ZBOT-ENGINEERING-MASTER-SUMMARY.md
│  ├─ README-INTENT-DRIVEN-DEVOPS.md  
│  ├─ intent-driven-devops-complete-blueprint.md
│  ├─ PROMPT-ENGINEERING-AND-AGENT-LOOP.md
│  └─ VERSIONING-AND-GITOPS-WORKFLOW.md
│
├─ 🔶 中央庫 (所有項目共用)
│  └─ zbot-engineering/
│     ├─ README.md (中央導航)
│     ├─ LOOP.md (系統編排)
│     ├─ prompts/ (系統提示詞)
│     ├─ pre-agents/ (前置檢查)
│     ├─ reference/ (歸檔文檔)
│     └─ docs/zh-CN/ (中文文檔)
│
├─ 🟢 項目實例 (6 個)
│  ├─ zbot-aws/
│  ├─ zbot-k8s/
│  └─ ... 等等
│
└─ 🔵 其他: DOCS-CLEANUP-AUDIT.md 等
```

---

## 📋 常見任務

```bash
# 查看系統狀態
cat zbot-engineering/LOOP-STATE.md

# 查看項目狀態
cat zbot-aws/LOOP-STATE.md

# 執行 Pre-Agent 檢查
python3 zbot-engineering/pre-agents/pre_agent_tier1_check.py --project zbot-aws

# 新增項目
./zbot-engineering/scripts/init-new-project.sh zbot-newproject
```

---

## ❓ 常見問題

**Q: 從哪裡開始？**  
A: 第一次來看 ZBOT-ENGINEERING-MASTER-SUMMARY.md (5 分鐘)

**Q: zbot-engineering 和 zbot-aws 有什麼區別？**  
A: zbot-engineering 是中央庫（所有項目共用），zbot-aws 是項目實例

**Q: AI Agent 如何知道讀哪個文檔？**  
A: 通過 LOOP.md 中的顯式引用（Agent 不會自動掃描根目錄）

---

**狀態**：✅ 運營中 | **進度**：Phase 2 完成，Phase 3 進行中  
**負責人**：Leon Lin | **內存位置**：`~/.claude/projects/-Users-lz-zbot/memory/`

