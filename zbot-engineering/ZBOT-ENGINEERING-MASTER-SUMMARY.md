# zbot-engineering 中央庫概覽

統一管理中心，連接所有 zbot-* 項目。

**日期**：2026-07-04  
**狀態**：✅ 初始化完成  
**6 個項目已連接**

---

## 中央庫架構

```
zbot-engineering/                  ⭐ 核心管理庫
├─ prompts/                        系統提示詞（版本化、中文）
├─ pre-agents/                     前置檢查（5 層驗證）
├─ mcp/                            工具連接層
├─ reference/                      歸檔文檔
├─ docs/zh-CN/                     中文文檔
├─ LOOP.md                         系統編排定義
└─ LOOP-STATE.md                   全局執行狀態

每個 zbot-* 項目：
├─ CLAUDE.md                       項目規範
├─ LOOP.md                         項目編排
├─ LOOP-STATE.md                   項目狀態
├─ prompts → symlink               指向中央庫
├─ pre-agents → symlink            指向中央庫
└─ failures.jsonl                  項目特有失敗記錄
```

---

## 核心內容

| 組件 | 用途 | 狀態 |
|------|------|------|
| system-prompt-triage-v1-zh.md | Agent 巡檢提示（4 步） | ✅ |
| tier-1-config-validation.md | 環境驗證 + Python 腳本 | ✅ |
| FAILURE-LOG-FORMAT.md | 失敗記錄格式 + 規則提取 | ✅ |
| MCP-INTEGRATION-GUIDE.md | 工具連接（GitHub、AWS） | ✅ |
| LOOP-ENGINEERING-ALIGNMENT.md | 官方框架對齐 | ✅ |

---

## 快速開始

```bash
# 查看系統狀態
cat zbot-engineering/LOOP-STATE.md

# 查看 Prompt
cat zbot-engineering/prompts/system-prompt-triage-v1-zh.md

# 驗證項目連接
cd zbot-aws && ls -l prompts/pre-agents/

# 運行前置檢查
python3 zbot-engineering/pre-agents/pre_agent_tier1_check.py --project zbot-aws

# 查看完整導航
cat zbot-engineering/README.md
```

---

## 治理流程

| 時間 | 會議 | 內容 |
|------|------|------|
| 每週五 10:00 UTC | Week Review | Leon + Claude 評審進度 |
| 每月第一周 | Month Review | 全團隊同步 |
| 每月最後一週 | Upstream Merge | 同步至 loop-engineering |

---

## 下一步

- **Week 2 (2026-07-11)**：P0 - 獨立 Verifier + Self-Correction
- **Week 3 (2026-07-18)**：P1 - Prompt v1.1 改進 + 5 Stages 標記
- **Week 4 (2026-07-25)**：P2 - MCP Server 最小版本 + Worktrees 支持

---

## 三層改進迴圈

```
Loop 執行 → failures.jsonl 記錄 → Week Review 分析
    ↑                                    ↓
    ←──── v1.1 Prompt 改進 ←── 規則提取
```

---

**負責人**：Leon Lin (CTO) + Claude (AI Infrastructure)  
**完整導航**：[zbot-engineering/README.md](./README.md)  
**下次評審**：2026-07-11
