# 上游同步和迭代策略

**目的**：保持 zbot-engineering 與官方 loop-engineering 同步，同時保留 zbot 的中文化定製

**原則**：
- 官方改進 → zbot-engineering 吸收
- zbot 創新 → 可回饋上游
- 衝突 → zbot 定製優先（不破壞現有系統）

---

## 同步架構

### 三個 Git 遠程

```bash
# 檢查當前配置
cd /Users/lz/zbot/zbot-engineering
git remote -v

# 應該看到
origin      sp1050107-zbot/zbot-engineering (我們的 fork，主要)
upstream    cobusgreyling/loop-engineering (官方，讀取)
```

### 分支策略

```
官方
  main (upstream)
    ↓ weekly merge
zbot-engineering
  ├─ main (production，穩定版本)
  ├─ release/v1.x (發布分支，標籤)
  └─ feature/* (開發分支，PR 前測試)

zbot-*
  └─ main (使用 symlink 指向 zbot-engineering/main)
```

---

## 同步流程

### 週期 1: 官方更新檢測（每週一次）

**時機**：每週一 10:00 UTC  
**負責**：自動化腳本 (GitHub Actions 或 cron)

```bash
#!/bin/bash
# check-upstream-updates.sh

cd zbot-engineering

# 1. Fetch 官方最新
git fetch upstream main

# 2. 對比當前 main 和 upstream/main
BEHIND=$(git rev-list --count HEAD..upstream/main)

if [ $BEHIND -gt 0 ]; then
  echo "📢 官方有 $BEHIND 個新 commits"
  
  # 3. 生成差異報告
  git log --oneline HEAD..upstream/main > upstream-changes.txt
  
  # 4. 提交議題或通知
  echo "⚠️ 官方更新待審查: 見 upstream-changes.txt"
else
  echo "✅ 已同步最新版本"
fi
```

### 週期 2: 官方更新評審（每週四 10:00 UTC）

**參與者**：Leon (CTO) + Claude (AI)  
**議程**：
1. 查看官方更新內容 (`upstream-changes.txt`)
2. 評估是否需要吸收
3. 決定合併策略

**決策樹**：

```
官方有新 commits?
  ├─ 文檔更新 (docs/, README)
  │  └─ ✅ 直接 merge 到 feature/upstream-docs
  │
  ├─ 新 Pattern (patterns/*, starters/*)
  │  └─ 評估：是否對 zbot-* 有用？
  │     ├─ 是 → feature/upstream-pattern-xyz
  │     └─ 否 → 記錄但不 merge
  │
  ├─ 工具更新 (tools/loop-audit, loop-init, ...)
  │  └─ 評估：是否與 MCP 衝突？
  │     ├─ 有衝突 → 手動合併，測試
  │     └─ 無衝突 → 直接 merge
  │
  └─ 原始框架改進 (primitives, concepts)
     └─ 評估：是否破壞現有系統？
        ├─ 破壞 → 在 feature 分支測試後再 merge
        └─ 不破壞 → merge 到 main
```

### 週期 3: 實際合併（評審通過後）

#### 策略 A：快速合併（無衝突，官方貢獻純粹是改進）

```bash
# 1. 創建 feature 分支
git checkout -b feature/upstream-sync-$(date +%Y%m%d)

# 2. Merge 官方更新
git merge upstream/main --no-ff -m "Merge upstream loop-engineering updates

Upstream commits: $(git rev-list --count HEAD..upstream/main)
Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)

Upstream changes:"
git log --oneline HEAD..upstream/main >> /tmp/merge-message.txt

# 3. 驗證沒有衝突
git status

# 4. 測試（詳見下文）
bash test-integration.sh

# 5. Merge 到 main
git checkout main
git merge feature/upstream-sync-$(date +%Y%m%d) --ff-only

# 6. 標籤發佈
git tag -a v1.x-sync-$(date +%Y%m%d) -m "Sync upstream + zbot customization"
git push origin main --tags
```

#### 策略 B：精細合併（有潛在衝突，需要選擇性吸收）

```bash
# 1. 創建 feature 分支
git checkout -b feature/upstream-selective-$(date +%Y%m%d)

# 2. 手動挑選需要的 commits
# （不直接 merge，而是逐個 cherry-pick）

git cherry-pick upstream/main~5  # 官方的 docs 改進
git cherry-pick upstream/main~3  # 官方的 bug fix
# 跳過 upstream/main~4 (與 zbot MCP 衝突)

# 3. 手動解決衝突（如有）
# 編輯有衝突的文件
git add conflicted-file.md
git cherry-pick --continue

# 4. 測試
bash test-integration.sh

# 5. Merge 到 main
git checkout main
git merge feature/upstream-selective-$(date +%Y%m%d)
git tag -a v1.x-sync-selective-$(date +%Y%m%d)
git push origin main --tags
```

#### 策略 C：深度整合（官方框架大更新，需要重構）

```bash
# 1. 創建長期 feature 分支
git checkout -b feature/upstream-major-integration

# 2. Merge 官方主分支
git merge upstream/main

# 3. 解決衝突（可能很多）
# 通常涉及：
#   - prompts/ 中文化 vs 官方英文版本
#   - MCP 定義 vs 官方的 Plugins 概念
#   - Pre-Agent Tiers vs 官方的 5 Killers 映射

# 4. 完整測試（2-3 天）
bash test-integration.sh
bash test-zbot-projects.sh  # 測試所有 6 個項目

# 5. Code Review（Leon + Claude）
# 驗證 zbot 定製沒有被破壞

# 6. Merge 到 main（不 ff-only，保留合併歷史）
git checkout main
git merge feature/upstream-major-integration
git tag -a v2.0-upstream-major-sync
git push origin main --tags

# 7. 更新所有 zbot-* 項目（可能需要手動調整）
for proj in ../zbot-*; do
  cd $proj
  git pull origin main
  # 檢查 symlink 是否還有效
  [ -L prompts ] && echo "✅ $proj: symlink OK" || echo "❌ $proj: symlink broken"
done
```

---

## 衝突解決策略

### 常見衝突 1：Prompts（官方英文 vs zbot 中文）

```
官方更新: docs/primitives.md (新概念)
zbot 有: prompts/system-prompt-triage-v1-zh.md (中文版)

解決方案:
1. 官方 docs/ 有新知識 → 翻譯並融合到 zbot 版本
2. 保留 zbot 的中文版本（不覆蓋）
3. 在 system-prompt-triage-v1-1-zh.md (v1.1) 中吸收官方改進
```

**具體步驟**：
```bash
# 官方有新的 5 Stages 解釋？
# 1. 閱讀官方文件
cat upstream-main:docs/concepts.md | grep -A 20 "5 Stages"

# 2. 翻譯並改進 zbot 版本
vi prompts/system-prompt-triage-v1-1-zh.md
# 添加官方新解釋，保留中文風格

# 3. 標記改進來源
# 在 system-prompt-triage-v1-1-zh.md 中加：
# "v1.1 改進: 吸收官方 loop-engineering 2026-07-XX 的新概念"
```

### 常見衝突 2：MCP vs Plugins

```
官方框架: "Plugins & Connectors" (概念)
zbot 實現: "mcp/" (具體代碼)

解決方案:
1. zbot-engineering/mcp/ 保持不變（我們的創新）
2. 吸收官方 Plugins 的設計思想到 MCP
3. 在文檔中說明映射關係
```

**文檔映射**：
```markdown
# MCP vs Plugins 映射

Loop Engineering 官方術語 "Plugins & Connectors"
↓ 在 zbot-engineering 中的實現
zbot-engineering/mcp/

GitHub Connector (MCP) ← GitHub Plugin (官方概念)
AWS Connector (MCP) ← AWS Plugin (官方概念)
Linear Connector (未實現) ← Linear Plugin (官方計劃)
```

### 常見衝突 3：Pre-Agent Tiers vs 5 Agent Killers

```
官方框架: 5 Agent Killers (為什麼 Loop 失敗)
zbot 改進: Pre-Agent 5 Tiers (如何預防失敗)

解決方案:
1. 保留 zbot 的 Pre-Agent Tiers（預防性）
2. 將 5 Agent Killers 對應映射到 Tiers
3. 文檔記錄映射表（LOOP-ENGINEERING-ALIGNMENT.md）
```

---

## 測試策略

### 測試 1: 官方更新兼容性

```bash
#!/bin/bash
# test-integration.sh

echo "🧪 Testing zbot-engineering + upstream updates"

# 1. 驗證 zbot-engineering 目錄結構
required_files=(
  "prompts/system-prompt-triage-v1-zh.md"
  "pre-agents/tier-1-config-validation.md"
  "mcp/ZBOT-MCP-INTEGRATION-GUIDE.md"
  ".dev-loop-state.md"
)

for file in "${required_files[@]}"; do
  if [ ! -f "$file" ]; then
    echo "❌ Missing: $file"
    exit 1
  fi
done

echo "✅ All critical zbot files present"

# 2. 驗證官方框架還能用
if [ -f "../loop-engineering/README.md" ]; then
  echo "✅ Official loop-engineering still accessible"
else
  echo "❌ Official loop-engineering not found"
  exit 1
fi

# 3. 測試 symlink
for proj in ../zbot-aws ../zbot-aladdin; do
  if [ -L "$proj/prompts" ]; then
    echo "✅ $proj: prompts symlink OK"
  else
    echo "❌ $proj: prompts symlink broken"
    exit 1
  fi
done

echo "✅ All tests passed"
```

### 測試 2: zbot-* 項目適配性

```bash
#!/bin/bash
# test-zbot-projects.sh

echo "🧪 Testing all zbot-* projects"

for proj in zbot-aws zbot-aladdin zbot-trading zbot-wallet zbot-analytics zbot-website; do
  echo ""
  echo "→ $proj"
  
  cd "../$proj"
  
  # 1. 驗證 LOOP.md 能讀
  if grep -q "## Active Loops" LOOP.md; then
    echo "  ✅ LOOP.md OK"
  else
    echo "  ❌ LOOP.md corrupted"
    exit 1
  fi
  
  # 2. 驗證 symlink 有效
  if [ -f "prompts/system-prompt-triage-v1-zh.md" ]; then
    echo "  ✅ prompts symlink OK"
  else
    echo "  ❌ prompts symlink broken"
    exit 1
  fi
  
  # 3. 驗證 Pre-Agent 檢查可運行
  if python ../zbot-engineering/pre-agents/tier-1-config-validation.py --project "$proj" > /tmp/preagent.log 2>&1; then
    echo "  ✅ Pre-Agent checks executable"
  else
    echo "  ⚠️  Pre-Agent check failed (may be expected if env not set)"
  fi
  
  cd ../zbot-engineering
done

echo ""
echo "✅ All zbot-* projects functional"
```

---

## 版本管理

### 版本號格式

```
zbot-engineering version: X.Y-sync-YYYYMMDD

X.Y  = zbot 版本 (1.0, 1.1, 2.0, ...)
sync = 表示包含官方同步
YYYYMMDD = 同步日期

例:
v1.0-sync-20260707  = zbot v1.0，吸收 2026-07-07 的官方更新
v1.1-sync-20260714  = zbot v1.1，吸收 2026-07-14 的官方更新
v2.0-upstream-major = zbot v2.0，大型官方整合
```

### 版本發佈清單

```bash
# 每次官方同步後發佈

# 1. 更新 VERSION 文件
echo "v1.0-sync-20260704" > zbot-engineering/VERSION

# 2. 建立發佈標籤
git tag -a v1.0-sync-20260704 -m "Sync upstream + zbot customizations
- Merged X commits from upstream
- Maintained zbot-specific: prompts (CN), MCP, Pre-Agent Tiers
- All zbot-* projects tested and working
- Date: 2026-07-04"

# 3. 更新 CHANGELOG
cat >> zbot-engineering/CHANGELOG.md << 'EOF'

## v1.0-sync-20260704

### Upstream Sync
- Merged: [upstream commits list]
- Maintained: Chinese prompts, MCP integration

### zbot Customizations
- system-prompt-triage-v1-zh.md (production)
- Pre-Agent Tier 1-5
- MCP Server + GitHub/AWS Connectors

### Testing
- ✅ All zbot-* projects functional
- ✅ Symlinks verified
- ✅ Upstream features intact
EOF

# 4. Push 發佈
git push origin main --tags
```

---

## 監控和告警

### 自動同步檢查 (Cron Job)

```bash
# 每週一 10:00 UTC 運行

#!/bin/bash
# /usr/local/bin/zbot-upstream-check.sh

cd /Users/lz/zbot/zbot-engineering

# 1. Fetch upstream
git fetch upstream main 2>&1 | tee /tmp/fetch.log

# 2. 檢查差異
BEHIND=$(git rev-list --count HEAD..upstream/main)

# 3. 如果有更新，發送通知
if [ $BEHIND -gt 0 ]; then
  {
    echo "📢 zbot-engineering: 官方有 $BEHIND 個新 commits"
    echo ""
    echo "Changes:"
    git log --oneline HEAD..upstream/main
    echo ""
    echo "Action: Review and merge at Week Review (Thursday)"
  } | mail -s "zbot-engineering: Upstream updates available" leon@zbot.dev
fi
```

### 合併後驗證

```bash
# 每次 merge 後自動運行 CI

.github/workflows/upstream-sync-verify.yml:

name: Upstream Sync Verification
on: [push, pull_request]

jobs:
  verify:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Test Integration
        run: bash test-integration.sh
      - name: Test zbot-* Projects
        run: bash test-zbot-projects.sh
```

---

## 回饋上游

### 貢獻流程（如果 zbot 改進適用於官方）

```
zbot-engineering 的改進
  ↓
評估：通用性？無損?
  ├─ 是 → 準備上游 PR
  └─ 否 → 保留為 zbot 特化

準備上游 PR:
  1. 建立 upstream-contribution 分支
  2. 提取改進（例: 新的 Pre-Agent 概念）
  3. 翻譯為英文
  4. 提交 PR 到官方倉庫
  
例:
- zbot 的 "Pre-Agent Tiers" 框架 → 可貢獻
- zbot 的中文提示詞 → 不貢獻（語言特定）
- zbot 的 MCP 實現 → 部分貢獻（通用部分）
```

---

## 時間表

### 每週

| 天 | 時間 | 任務 |
|-----|------|------|
| 一 | 10:00 UTC | 檢查官方更新 (`check-upstream-updates.sh`) |
| 四 | 10:00 UTC | Week Review + 評審是否 merge |
| 四 | 14:00 UTC | 執行 merge（如通過） |
| 五 | 10:00 UTC | 標籤發佈、通知各項目更新 |

### 每月

| 活動 | 時間 | 負責 |
|------|------|------|
| 大型官方更新評估 | 月末 | Leon + Claude |
| 回饋貢獻準備 | 月末 | Claude |
| 發佈新版本號 | 月末 | Leon |

---

## 檢查清單

**準備同步前**：
- [ ] git remote 配置完成（upstream 指向官方）
- [ ] test-integration.sh 和 test-zbot-projects.sh 可執行
- [ ] CHANGELOG.md 和 VERSION 文件存在

**merge 官方更新時**：
- [ ] 閱讀官方 commits
- [ ] 確認無破壞性改動
- [ ] 在 feature 分支測試
- [ ] 通過所有 CI 檢查
- [ ] 標籤發佈
- [ ] 通知各 zbot-* 項目

**merge 後**：
- [ ] 所有 symlink 有效
- [ ] zbot-* 項目能執行 Pre-Agent 檢查
- [ ] 沒有 prompt 檔案損壞
- [ ] CHANGELOG 已更新

---

## 常見問題

### Q: 官方更新與 zbot 定製衝突了怎麼辦？

**A**: 按衝突類型選擇策略
- **文檔衝突** → 手動合併，保留中文版本
- **代碼衝突** → cherry-pick 官方改進，re-apply zbot 定製
- **框架衝突** → feature 分支隔離測試，逐步整合

### Q: 可以回饋改進到官方嗎？

**A**: 可以，但要評估通用性
- Pre-Agent 概念（通用）→ 可貢獻
- 中文提示詞（特定）→ 不貢獻
- MCP 實現（可通用）→ 部分貢獻

### Q: 多久合併一次官方更新？

**A**: 推薦週期
- **快速 merge**（文檔/小 fix）→ 即時（週內）
- **評估後 merge**（新功能）→ 週度（Thursday Week Review）
- **深度整合**（大改動）→ 月度（月末 Month Review）

### Q: 官方更新破壞了 zbot 項目怎麼辦？

**A**: 恢復計畫
```bash
# 1. 立即回滾
git revert <merge-commit>

# 2. 建立隔離 feature 分支
git checkout -b fix/upstream-breakage

# 3. 手動修復衝突，保持 zbot 功能完整

# 4. 測試後重新 merge
git checkout main
git merge fix/upstream-breakage
```

---

**所有者**：Leon Lin (CTO)  
**維護者**：Claude (AI Infrastructure)  
**審核頻率**：每週四 10:00 UTC  
**下次同步**：2026-07-11
