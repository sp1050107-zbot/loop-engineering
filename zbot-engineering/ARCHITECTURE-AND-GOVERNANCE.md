# zbot-engineering 統一管理架構

**決策**：zbot-engineering/ 作為 **中央知識庫 + 工具庫**，所有 zbot-* 項目從此複用

---

## 目錄層級關係

### 當前結構（分散）
```
/Users/lz/zbot/
├─ zbot-aladdin/           ← 獨立 CLAUDE.md、prompts/
├─ zbot-aws/               ← 獨立 CLAUDE.md、prompts/
├─ zbot-trading/           ← 獨立 CLAUDE.md、prompts/
├─ zbot-wallet/            ← 獨立 CLAUDE.md、prompts/
├─ zbot-analytics/         ← 獨立 CLAUDE.md、prompts/
├─ zbot-website/           ← 獨立 CLAUDE.md、prompts/
│
├─ loop-engineering/       ← 官方框架（只讀參考）
└─ zbot-engineering/       ← 我們的定製層（新建）
```

### 改進後結構（統一）
```
/Users/lz/zbot/
│
├─ zbot-engineering/       ← 🏢 中央控制中心
│  ├─ prompts/
│  │  ├─ system-prompt-triage-v1-zh.md         ← 所有項目共用
│  │  ├─ system-prompt-verifier-v1-zh.md       ← 所有項目共用
│  │  └─ ...
│  │
│  ├─ pre-agents/          ← 統一檢查邏輯
│  │  ├─ pre_agent_checks.py                   ← 可執行腳本
│  │  └─ ...
│  │
│  ├─ skills/              ← 可複用 Skills
│  │  ├─ loop-triage/
│  │  ├─ loop-verify/
│  │  └─ loop-aws-health/  (zbot-aws 特化)
│  │
│  ├─ mcp/                 ← 統一工具連接
│  │  ├─ zbot-mcp-server.ts
│  │  └─ connectors/
│  │
│  ├─ templates/           ← 各項目用的範本
│  │  ├─ LOOP.md.template
│  │  ├─ LOOP-STATE.md.template
│  │  ├─ CLAUDE.md.append-chapter-10-13  (要加到各項目)
│  │  └─ .dev-loop-state.md.template
│  │
│  ├─ .dev-loop-state.md   ← 跨項目通用規則庫
│  │
│  └─ docs/                ← 中央文檔
│     ├─ zh-CN/
│     ├─ LOOP-ENGINEERING-ALIGNMENT.md
│     ├─ IMPLEMENTATION-ROADMAP.md
│     └─ ...
│
├─ zbot-aladdin/
│  ├─ CLAUDE.md                          ← 項目級配置
│  ├─ LOOP.md              ← symlink → ../zbot-engineering/templates/LOOP.md (項目定製)
│  ├─ LOOP-STATE.md        ← symlink → ../zbot-engineering/templates/LOOP-STATE.md (項目定製)
│  ├─ prompts/             ← symlink → ../zbot-engineering/prompts/ (共享)
│  ├─ pre-agents/          ← symlink → ../zbot-engineering/pre-agents/ (共享)
│  └─ .dev-loop-state.md   ← symlink → ../zbot-engineering/.dev-loop-state.md
│
├─ zbot-aws/
│  ├─ CLAUDE.md
│  ├─ LOOP.md
│  ├─ LOOP-STATE.md
│  ├─ prompts/             ← symlink
│  ├─ pre-agents/          ← symlink
│  └─ .dev-loop-state.md   ← symlink
│
├─ zbot-trading/           ← (同上)
├─ zbot-wallet/            ← (同上)
├─ zbot-analytics/         ← (同上)
├─ zbot-website/           ← (同上)
│
└─ loop-engineering/       ← 官方框架（讀取但不修改）
```

---

## 三層架構

### 層級 1：中央 (zbot-engineering/)
**所有權**：zbot AI Infrastructure Team  
**版本控制**：Main branch (released versions)  
**內容**：
- ✅ 通用系統提示 (v1.0, v1.1, ...)
- ✅ 通用 Skills
- ✅ MCP Server + Connectors
- ✅ Pre-Agent 檢查邏輯
- ✅ 跨項目規則庫 (.dev-loop-state.md)
- ✅ 中央文檔

**更新頻率**：每週五（Week Review）
**發佈流程**：
```
Feature → dev branch → testing (1 week) → release tag (v1.x) → all projects auto-update
```

### 層級 2：項目級 (zbot-*/LOOP.md 等)
**所有權**：各項目 Owner  
**版本控制**：Project repository  
**內容**：
- ✅ 項目級 LOOP.md (調度、MCP 配置、業務規則)
- ✅ 項目級 LOOP-STATE.md (運行歷史)
- ✅ 項目級 CLAUDE.md (第 1-9 章：項目配置)
- ❌ 通用系統提示（來自中央）
- ❌ 通用 Pre-Agent 檢查（來自中央）

**更新頻率**：每次 Loop 運行時更新 LOOP-STATE.md  
**修改規則**：只修改項目特化部分

### 層級 3：執行時 (Agent Runtime)
**所有權**：Agent 自動  
**內容**：
- ✅ failures.jsonl (當前 Loop 運行的失敗記錄)
- ✅ loop-run-log.md (執行日誌)
- ❌ 系統提示（從中央載入）
- ❌ 檢查規則（從中央載入）

**更新頻率**：每次 Loop 完成

---

## Git 管理策略

### 三個倉庫

#### 倉庫 1：sp1050107-zbot/zbot-engineering (主倉)
```
main/
├─ v1.0-release/    (tagged v1.0.0)
├─ v1.1-dev/        (testing, PRs here)
└─ feature/*        (individual improvements)

Content:
  prompts/
  skills/
  pre-agents/
  mcp/
  templates/
  .dev-loop-state.md
  docs/
```

**Commit 流程**：
```
1. Feature branch: feature/tier-5-5-check
2. Local test: test on zbot-aws
3. PR: request review (Leon + Claude)
4. Merge: fast-forward to v1.1-dev
5. Tag: git tag v1.1.0, push
6. Notify: zbot-* projects to update
```

#### 倉庫 2-7：sp1050107-zbot/zbot-* (各項目)
```
main/
├─ CLAUDE.md                    (Chapters 1-9: 項目配置)
├─ LOOP.md                      (項目級調度)
├─ LOOP-STATE.md                (運行狀態)
├─ prompts/                     → symlink ../zbot-engineering/prompts/
├─ pre-agents/                  → symlink ../zbot-engineering/pre-agents/
├─ .dev-loop-state.md           → symlink ../zbot-engineering/.dev-loop-state.md
├─ failures.jsonl               (本項目特有)
├─ loop-run-log.md              (本項目特有)
└─ ...
```

**Commit 流程**：
```
1. Agent 每次運行後 auto-commit:
   - LOOP-STATE.md updates
   - failures.jsonl appends
   - loop-run-log.md updates

2. 人工 commit (weekly):
   - LOOP.md 調度調整
   - CLAUDE.md 更新項目配置

3. 同步中央改動:
   - git submodule update --remote (or)
   - symlink refresh (each week)
```

#### 倉庫 3：cobusgreyling/loop-engineering (唯讀參考)
```
Keep upstream in sync:
  git remote add upstream https://github.com/cobusgreyling/loop-engineering.git
  git fetch upstream
  git merge upstream/main (月度)
```

---

## 文件同步機制

### 方案 A：Symlink (推薦，簡單)

```bash
# 為每個 zbot-* 建立 symlink
cd zbot-aladdin
ln -s ../zbot-engineering/prompts ./prompts
ln -s ../zbot-engineering/pre-agents ./pre-agents
ln -s ../zbot-engineering/.dev-loop-state.md ./.dev-loop-state.md

cd ../zbot-aws
ln -s ../zbot-engineering/prompts ./prompts
# ... 等等

# Git 配置：允許 symlink
git config core.symlinks true
```

**優點**：
- ✅ 簡單，改一處所有項目都更新
- ✅ 無額外同步成本

**缺點**：
- ❌ Windows 上 symlink 支持不完整
- ❌ CI/CD 中可能需要特殊處理

### 方案 B：Git Submodule

```bash
# 將 zbot-engineering 加為 submodule
cd zbot-aladdin
git submodule add ../zbot-engineering ./zbot-engineering
git config submodule.zbot-engineering.update checkout

# 使用時
prompts/ → ../zbot-engineering/prompts/
```

**優點**：
- ✅ 跨平台相容
- ✅ CI/CD 友好

**缺點**：
- ❌ 複雜度高
- ❌ 更新時需要手動 commit

### 方案 C：自動同步腳本

```bash
#!/bin/bash
# sync-loop-engineering.sh

for proj in zbot-aladdin zbot-aws zbot-trading zbot-wallet zbot-analytics zbot-website; do
  echo "Syncing $proj..."
  
  # 複製（如果不用 symlink）
  cp -r zbot-engineering/prompts $proj/
  cp -r zbot-engineering/pre-agents $proj/
  cp zbot-engineering/.dev-loop-state.md $proj/
  
  # Commit
  cd $proj
  git add prompts/ pre-agents/ .dev-loop-state.md
  git commit -m "chore: sync zbot-engineering changes ($(date +%Y-%m-%d))" --no-verify
  cd ..
done
```

**優點**：
- ✅ 簡單可靠
- ✅ 可排程（cron）

**缺點**：
- ❌ 每週需要運行
- ❌ 可能有 merge 衝突

**建議**：Symlink（方案 A）作為主方案，方案 C 作為備用

---

## 治理流程

### 週期性評審

#### 每週五 10:00 UTC (Week Review)
```
參與者: Leon (CTO), Claude (AI)
時長: 30 min

Agenda:
1. 本週 Loop 統計 (運行次數、成功率、成本)
2. 失敗案例審視 (failures.jsonl 新增項)
3. 規則庫更新 (.dev-loop-state.md 新增項)
4. Prompt 版本決策 (v1.0 → v1.1? → v1.2?)
5. 下週優先級 (P0/P1/P2)

Output:
- Week Review 會議紀錄
- 新規則通知 (GitHub Discussion)
- v1.x tag (如有改動)
```

#### 每月第一周 (Month Review)
```
參與者: Leon, Claude, 各項目 Owner
時長: 1 hour

Agenda:
1. 上月成果回顧 (失敗率、成本、改進)
2. 官方 loop-engineering 更新同步 (月度 merge)
3. 跨項目對標 (哪個項目做得最好)
4. 下月計劃 (新 Skills、新 Connectors)

Output:
- Month Review 報告
- 新 Feature 優先級排序
```

---

## 初始化清單

### Week 1 Action (立即)

```bash
# 1. 確認 zbot-engineering 目錄結構
cd /Users/lz/zbot
tree -L 2 zbot-engineering/

# 2. 為 6 個項目建立 symlink
for proj in zbot-aladdin zbot-aws zbot-trading zbot-wallet zbot-analytics zbot-website; do
  cd $proj
  ln -s ../zbot-engineering/prompts ./prompts 2>/dev/null || true
  ln -s ../zbot-engineering/pre-agents ./pre-agents 2>/dev/null || true
  ln -s ../zbot-engineering/.dev-loop-state.md ./.dev-loop-state.md 2>/dev/null || true
  git config core.symlinks true
  git add prompts pre-agents .dev-loop-state.md
  git commit -m "chore: link to zbot-engineering central library" --no-verify 2>/dev/null || true
  cd ..
done

# 3. 驗證
ls -la zbot-aws/prompts  # 應該顯示 symlink
cat zbot-aws/prompts/system-prompt-triage-v1-zh.md  # 應該可讀

# 4. 初始化各項目的 LOOP.md + LOOP-STATE.md
# (見各項目的 QUICK-START-CN.md)
```

### Week 2-4 Action

```
□ 建立 GitHub Discussion: "Weekly Loop Review"
□ 設置 Week Review 會議 (每週五)
□ 配置 sync-loop-engineering.sh cron (每週四 22:00 UTC)
□ 文檔：各項目的「如何修改 LOOP.md」指南
```

---

## 常見問題

### Q1：如果某個 zbot-* 項目要特化提示詞呢？

**A**：項目級覆蓋

```bash
# 在 zbot-aladdin/prompts/ 中建立特化版本
mkdir -p zbot-aladdin/prompts-custom/
cp ../zbot-engineering/prompts/system-prompt-triage-v1-zh.md \
   prompts-custom/system-prompt-triage-aladdin-v1-zh.md

# 在 zbot-aladdin/CLAUDE.md 中指定使用
chapter 11:
  prompt_triage: "./prompts-custom/system-prompt-triage-aladdin-v1-zh.md"
```

### Q2：如何回報在某個項目發現的 Bug（改進）？

**A**：向中央提 PR

```bash
# 1. 在 zbot-aws Loop 運行時發現 Prompt 問題
# 2. 記錄到 failures.jsonl
# 3. 提交 GitHub Issue 到 zbot-engineering/issues
# 4. PR 修改 system-prompt-triage-v1-zh.md
# 5. Merge 後所有項目自動獲得改進
```

### Q3：symlink 無法在 Windows CI/CD 上工作怎麼辦？

**A**：方案 C（自動同步腳本）

```bash
# 在 CI/CD 中運行
bash zbot-engineering/scripts/sync-loop-engineering.sh

# 或使用 GitHub Actions
- name: Sync zbot-engineering
  run: bash zbot-engineering/scripts/sync-loop-engineering.sh
```

### Q4：中央 zbot-engineering 的 v1.1 發佈後，各項目怎麼更新？

**A**：自動 (symlink) 或手動 (PR)

```bash
# Symlink 情況
# 無需任何操作，下次 Loop 執行時自動載入 v1.1

# 複製情況
git pull origin main  # 自動同步（如果配置了 sync cron）
```

---

## 成熟度等級

### 當前 (Week 1)：Level 1 (初期)
```
中央: zbot-engineering/ 有基礎框架
各項目: 複製和 symlink 中央的文件
協作: 臨時性，基於 GitHub Discussion
```

### Month 1 (Week 2-4)：Level 2 (運營)
```
中央: 已發佈 v1.0 + 開發 v1.1
各項目: 全部使用 symlink
協作: 正式 Week Review 會議 + cron 同步
```

### Month 2-3 (Q3)：Level 3 (成熟)
```
中央: CI/CD 全自動化、Backtest 工具成熟
各項目: 支持項目級覆蓋和特化配置
協作: 跨項目學習、規則庫充盈
```

### Month 4+ (Q4)：Level 4 (卓越)
```
中央: 可作為開源發佈或商用產品
各項目: 完全自主且與中央同步
協作: AI 自動分析 failures.jsonl、自動生成改進方案
```

---

## 總結

✅ **zbot-engineering/ = 中央控制中心**
- Prompts、Skills、Pre-Agents、MCP、Docs 集中管理
- 版本化發佈（v1.0, v1.1, ...）

✅ **各 zbot-* = 項目級應用**
- Symlink 指向中央（實時同步）
- 項目級 LOOP.md/LOOP-STATE.md（獨立管理）
- 可以項目級特化（如需要）

✅ **跨項目規則庫**
- `.dev-loop-state.md` 存在於中央
- 所有項目共用
- 每週更新

✅ **治理流程**
- 每週五 Week Review
- 月度 Month Review
- 月度官方 upstream merge

**下一步**：執行 Week 1 Action，建立 symlink
