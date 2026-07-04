# zbot 版本管理 + GitOps MR 工作流標準

**目標**：每個 `zbot-*` 項目都遵循 **語義化版本 (Semantic Versioning)** 和 **嚴格的 Git 工作流**  
**規範**：Conventional Commits + SemVer + GitHub Release Tags  
**流程**：Feature Branch → PR Review → Semantic Tag → MR to Main → Auto Deploy

---

## 📋 核心原則

### 1. 語義化版本 (Semantic Versioning)

**版本格式**：`release-MAJOR.MINOR.PATCH-prerelease+build`

```
release-1.2.3              ✅ 正式版本
release-2.0.0-rc.1        ✅ Release Candidate
release-1.5.0-beta.2      ✅ Beta 版本
release-0.1.0-alpha       ✅ Alpha 版本
release-1.2.3+20260703    ✅ 帶 build 元數據
```

**版本遞進規則**：

| 場景 | MAJOR | MINOR | PATCH | 例子 |
|-----|-------|-------|-------|------|
| 破壞性 API 變更 | ⬆️ | 0 | 0 | 1.0.0 → 2.0.0 |
| 新功能（後向兼容） | - | ⬆️ | 0 | 1.0.0 → 1.1.0 |
| Bug 修復 | - | - | ⬆️ | 1.0.0 → 1.0.1 |
| 緊急安全修復 | - | - | ⬆️ | 1.0.5 → 1.0.6 |

---

### 2. Conventional Commits 格式

**提交消息格式**：

```
<type>(<scope>): <subject>

<body>

<footer>

---

type 種類：
  feat:     新功能
  fix:      bug 修復
  docs:     文檔
  style:    程式碼風格（無功能變化）
  refactor: 程式碼重構
  perf:     性能優化
  test:     測試
  chore:    構建、依賴更新等

scope:   影響的模塊/組件
subject: 簡短描述（命令式、小寫、不帶句號）
body:    詳細說明（可選）
footer:  BREAKING CHANGE、Closes #123（可選）
```

**提交示例**：

```bash
# 新功能
git commit -m "feat(trading): implement OrderBook.executeOrder() method"

# Bug 修復
git commit -m "fix(wallet): resolve AWS KMS key rotation failure

BREAKING CHANGE: OrderBook.executeOrder() now requires explicit authorization token."

# 緊急安全修復
git commit -m "fix(security): patch Log4j vulnerability CVE-2024-12345"

# 績效優化
git commit -m "perf(analytics): optimize RDS query latency by 40%"

# 文檔
git commit -m "docs(trading): update OrderBook API documentation"
```

---

## 🔄 Git 工作流（Gitflow 變種）

### 分支策略

```
main (正式環境)
  ↑
  ├── release-* (發佈分支)
  │   └─ 用於發佈準備、熱修復
  │
staging (準發佈環境)
  ↑
  ├── develop (開發主線)
  │   ↑
  │   ├── feature/* (功能分支)
  │   │   └─ 例：feature/trading-order-matching
  │   │
  │   ├── hotfix/* (緊急修復)
  │   │   └─ 例：hotfix/security-log4j
  │   │
  │   └── bugfix/* (Bug 修復)
  │       └─ 例：bugfix/wallet-kms-retry
```

### 完整的開發流程

#### Step 1: 從 `develop` 建立功能分支

```bash
# 更新本機 develop 分支
git checkout develop
git pull origin develop

# 建立功能分支（命名規範）
git checkout -b feature/trading-order-matching

# 或 bug 修復
git checkout -b bugfix/wallet-kms-retry

# 或 緊急安全修復
git checkout -b hotfix/security-cve-2024-12345
```

#### Step 2: 在分支上開發

```bash
# 編輯代碼
vim src/trading/orderbook.go

# 提交（遵循 Conventional Commits）
git add src/trading/orderbook.go
git commit -m "feat(trading): implement OrderBook.executeOrder() with validation"

# 多個提交
git commit -m "feat(trading): add order price validation"
git commit -m "feat(trading): add order quantity validation"
git commit -m "test(trading): add unit tests for order validation"
```

#### Step 3: 提交 Pull Request 到 `develop`

```bash
# 推送到遠程分支
git push origin feature/trading-order-matching

# 通過 GitHub CLI 建立 PR
gh pr create \
  --title "feat(trading): implement OrderBook.executeOrder()" \
  --body "$(cat <<'EOF'
## 功能說明
實現訂單執行邏輯，包括價格和數量驗證。

## 測試清單
- [x] 單元測試覆蓋率 > 85%
- [x] 集成測試已通過
- [x] 沒有破壞性 API 變更
- [x] 文檔已更新

## 關聯 Issue
Closes #123
EOF
)" \
  --base develop
```

#### Step 4: Code Review + Auto Checks

```
PR 檢查清單：
  ✅ 代碼質量 (SonarQube, golangci-lint)
  ✅ 單元測試 (coverage > 80%)
  ✅ 集成測試
  ✅ 安全掃描 (SAST)
  ✅ 文檔更新
  ✅ 2 個審核者批准
  ⏸️ 無衝突

Action：
  GitHub Actions 自動運行
  → Lint check
  → Test suite
  → Build artifact
  → Security scan
  → Coverage report (作為 PR comment)
```

#### Step 5: Merge 到 `develop`

```bash
# 確認沒有衝突
git pull origin develop

# Squash merge (保持 commit 歷史清晰)
# 通過 GitHub UI 或 CLI
gh pr merge <PR_NUMBER> --squash --auto

# 或手工 merge
git merge --squash feature/trading-order-matching
git commit -m "feat(trading): implement OrderBook.executeOrder()"
```

---

## 🏷️ 版本發佈流程 (Release Pipeline)

### 準備 Release

#### Step 1: 建立 Release 分支

```bash
# 從 develop 建立發佈分支
git checkout -b release-x.x.x develop

# 更新版本號（所有配置文件）
vim version.txt        # 1.2.3
vim go.mod            # module version
vim package.json      # version
vim Chart.yaml        # appVersion

# 更新 CHANGELOG
vim CHANGELOG.md
# 或自動生成
git log --oneline release-1.1.0..HEAD --format="%h %s" > /tmp/changes.txt
```

#### Step 2: Release 分支的測試和修復

```bash
# 只能在 release-x.x.x 分支上進行：
# 1. Bug 修復
# 2. 版本號更新
# 3. CHANGELOG 編寫

# 禁止新功能！如果需要新功能，應該先合併回 develop，
# 然後重新建立新的 release 分支

git commit -m "chore(release): bump version to 1.2.3"
git commit -m "fix(critical): patch security issue in release-1.2.3"
```

#### Step 3: 建立 GitHub Release Tag

```bash
# 建立帶附註的 tag
git tag -a release-1.2.3 -m "Release version 1.2.3

## 新功能
- 實現 OrderBook.executeOrder()
- 加入訂單價格驗證

## Bug 修復
- 修復 AWS KMS 密鑰輪轉失敗

## 性能改善
- RDS 查詢延遲降低 40%

## 破壞性變更
BREAKING CHANGE: OrderBook API 現需提供 authorization token"

# 推送 tag 到遠程
git push origin release-1.2.3

# 或通過 GitHub CLI 建立 Release
gh release create release-1.2.3 \
  --title "Release v1.2.3" \
  --notes "$(cat CHANGELOG.md | head -30)" \
  --draft=false
```

#### Step 4: Merge 回 `main` 和 `develop`

```bash
# 先 merge 到 main（正式環境）
git checkout main
git pull origin main
git merge --no-ff release-1.2.3 -m "Merge release-1.2.3 to main"
git push origin main

# 再 merge 回 develop（確保同步）
git checkout develop
git pull origin develop
git merge --no-ff release-1.2.3 -m "Merge release-1.2.3 back to develop"
git push origin develop

# 刪除發佈分支
git branch -d release-1.2.3
git push origin --delete release-1.2.3
```

---

## 🚀 自動化發佈流程 (CI/CD)

### GitHub Actions Workflow

```yaml
# .github/workflows/release.yml

name: Automated Release

on:
  push:
    branches:
      - main
    paths:
      - 'version.txt'
      - 'CHANGELOG.md'

jobs:
  create-release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Read version
        id: version
        run: echo "VERSION=$(cat version.txt)" >> $GITHUB_OUTPUT
      
      - name: Create Release
        uses: softprops/action-gh-release@v1
        with:
          tag_name: release-${{ steps.version.outputs.VERSION }}
          files: |
            build/artifacts/*
          draft: false
          prerelease: false
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      
      - name: Trigger Deployment
        run: |
          curl -X POST https://api.github.com/repos/sp1050107-zbot/zbot-${{ matrix.project }}/dispatches \
            -H "Authorization: token ${{ secrets.DEPLOYMENT_TOKEN }}" \
            -H "Accept: application/vnd.github.everest-preview+json" \
            -d '{"event_type": "deploy", "client_payload": {"version": "${{ steps.version.outputs.VERSION }}"}}'
```

---

## 📊 每個 zbot-* 項目的版本管理配置

### zbot-aladdin

```
當前版本：release-2.1.0
分支狀態：
  main:    release-2.1.0 (正式)
  staging: feature/ai-reasoning-v3 (準備 release-2.2.0)
  develop: 4 個 feature 分支待審核

最近 Release 標籤：
  release-2.1.0  (2026-06-28)
  release-2.0.5  (2026-06-21)  [安全修復]
  release-2.0.0  (2026-05-15)  [主版本升級]
```

### zbot-aws

```
當前版本：release-1.4.0
分支狀態：
  main:    release-1.4.0 (正式)
  staging: release-1.5.0-rc.1 (候選發佈)
  develop: terraform upgrade 進行中

最近 Release 標籤：
  release-1.4.0  (2026-06-25)
  release-1.3.2  (2026-06-18)  [Bug 修復]
```

### zbot-trading

```
當前版本：release-0.3.2
分支狀態：
  main:    release-0.3.2 (正式)
  staging: feature/order-matching-v2 (開發中)
  develop: 2 個 feature 分支

最近 Release 標籤：
  release-0.3.2  (2026-07-02)
  release-0.3.1  (2026-06-29)
```

### zbot-wallet

```
當前版本：release-1.0.0
分支狀態：
  main:    release-1.0.0 (正式發佈)
  staging: feature/multi-sig-support
  develop: KMS integration 完成

最近 Release 標籤：
  release-1.0.0  (2026-07-01)  [首次發佈]
```

### zbot-analytics

```
當前版本：release-0.5.0
分支狀態：
  main:    release-0.5.0 (正式)
  staging: feature/real-time-dashboard
  develop: RDS optimization

最近 Release 標籤：
  release-0.5.0  (2026-06-30)
```

### zbot-website

```
當前版本：release-2.0.1
分支狀態：
  main:    release-2.0.1 (正式)
  staging: feature/dark-mode-games
  develop: performance optimization

最近 Release 標籤：
  release-2.0.1  (2026-07-01)  [Game 優化]
  release-2.0.0  (2026-06-15)
```

---

## 🔒 MR to Main 的嚴格條件

### 必須滿足的條件

```yaml
PR/MR Merge Checklist (in GitHub):

1️⃣ Code Quality
   ✅ Code review: 至少 2 個 approve
   ✅ Lint/Format: 通過 (golangci-lint / eslint / black)
   ✅ Type check: 通過 (Go type check / TypeScript)
   ✅ Secrets scan: 無洩露 (gitleaks)

2️⃣ Testing
   ✅ Unit tests: 通過 (coverage > 80%)
   ✅ Integration tests: 通過
   ✅ E2E tests: 通過 (if applicable)
   ✅ No flaky tests

3️⃣ Security
   ✅ SAST scan: 通過 (SonarQube / Snyk)
   ✅ DAST scan: 通過 (if applicable)
   ✅ Dependencies: 無高危漏洞
   ✅ No hardcoded secrets

4️⃣ Documentation
   ✅ CHANGELOG.md: 已更新
   ✅ API docs: 已更新 (if API 變更)
   ✅ README: 已更新 (if needed)
   ✅ Comments: 複雜邏輯已注釋

5️⃣ Version Management
   ✅ Semantic version: 正確遞進
   ✅ Tag: release-x.x.x 已建立
   ✅ Release notes: 已撰寫

6️⃣ Branch Protection
   ✅ No conflicts with main/develop
   ✅ All checks passed
   ✅ Can be fast-forwarded (prefer)
```

### GitHub Branch Protection Rules

```yaml
# 每個 zbot-* 項目的 main 分支設置

Protection Rules:
  - Require pull request reviews before merging
    ✅ Dismiss stale pull request approvals when new commits are pushed
    ✅ Require review from Code Owners
    ✅ Require status checks to pass before merging (all)
  
  - Status checks that must pass:
    ✅ build / test / lint
    ✅ sonarqube-scan
    ✅ security-scan
    ✅ coverage-check (coverage > 80%)
  
  - Additional settings:
    ✅ Require branches to be up to date before merging
    ✅ Require signed commits
    ✅ Require conversation resolution before merging
    ✅ Include administrators in restrictions
    ✅ Restrict who can push to matching branches
```

---

## 📈 版本發佈報告模板

### 每次發佈後生成報告

```markdown
# Release Report: release-1.2.3

**Release Date**: 2026-07-03  
**Environment**: Production  
**Duration**: Stable for 24h ✅

## Summary
- **Features**: 3 個新功能
- **Bug Fixes**: 5 個 bug 修復
- **Breaking Changes**: 0 個
- **Contributors**: 5 人

## Changelog
### New Features
- feat(trading): OrderBook.executeOrder() implementation
- feat(wallet): Multi-sig support
- feat(analytics): Real-time dashboard

### Bug Fixes
- fix(security): CVE-2024-12345 patch
- fix(trading): Order matching race condition
- fix(wallet): KMS key rotation failure
- fix(analytics): RDS query timeout
- fix(website): Mobile responsiveness

### Performance
- perf: RDS query latency -40%
- perf: Lambda cold start -200ms
- perf: CloudFront cache hit ratio +15%

## Deployment Status
✅ Production: 100% traffic
⏱️ Deployment duration: 12 minutes
📊 Error rate: 0.01% (normal: 0.02%)
🔄 Rollback: Not needed

## Metrics
- Errors: 0 (vs. baseline: 5-10)
- Latency (p99): 180ms (vs. baseline: 200ms)
- Success rate: 99.98%

## Next Release
**Expected**: release-1.3.0 (2026-07-17)
**Focus**: 
- Order matching optimization
- Real-time analytics dashboards
- WAF rule improvements

## Approval Chain
- DevOps Lead: ✅ Approved
- VP Engineering: ✅ Approved
- Release Manager: ✅ Deployed
```

---

## 🔄 版本回滾流程

### 如果新版本出現嚴重問題

```bash
# 方案 1: 快速回滾到上一個 tag
git checkout release-1.1.0
git push origin release-1.1.0

# 方案 2: 建立 hotfix 分支從 main 緊急修復
git checkout -b hotfix/critical-bug main
git commit -m "fix: critical production bug"
git tag release-1.2.4
git push origin release-1.2.4

# 方案 3: 通知 CTO Dashboard
# SRE Agent 自動觸發回滾，發送 Slack alert
```

---

## 📋 每個項目的檢查清單

### Pre-Release 檢查清單

```bash
# 運行這個腳本在提交 MR 到 main 之前

#!/bin/bash

project=$1  # 如 zbot-trading

echo "🔍 Pre-Release Checks for $project"

# 1. 版本號檢查
VERSION=$(cat version.txt)
if git tag -l | grep -q "release-$VERSION"; then
  echo "❌ Tag already exists: release-$VERSION"
  exit 1
fi
echo "✅ Version: release-$VERSION is new"

# 2. Changelog 檢查
if ! grep -q "## $VERSION" CHANGELOG.md; then
  echo "❌ Version not in CHANGELOG.md"
  exit 1
fi
echo "✅ CHANGELOG.md updated"

# 3. 測試覆蓋率檢查
go test -cover ./... | grep coverage
if [ $? -ne 0 ]; then
  echo "❌ Test coverage failed"
  exit 1
fi
echo "✅ Test coverage passed"

# 4. Lint 檢查
golangci-lint run ./...
if [ $? -ne 0 ]; then
  echo "❌ Lint check failed"
  exit 1
fi
echo "✅ Lint check passed"

# 5. 依賴檢查
go mod tidy
git diff go.mod go.sum
if [ -n "$(git diff go.mod go.sum)" ]; then
  echo "⚠️  Dependencies changed - please review"
fi
echo "✅ Dependencies check done"

# 6. 文件整潔檢查
if [ -n "$(git status -s)" ]; then
  echo "❌ Uncommitted changes exist:"
  git status -s
  exit 1
fi
echo "✅ Working directory is clean"

echo ""
echo "✅ All checks passed! Ready for MR to main"
echo ""
echo "Next steps:"
echo "  git tag -a release-$VERSION -m 'Release $VERSION'"
echo "  git push origin release-$VERSION"
echo "  git push origin develop"
echo "  gh release create release-$VERSION --notes '$(cat CHANGELOG.md | head -20)'"
```

---

## 🎯 Intent-Driven DevOps 中的版本管理

### Release Agent 集成

```python
# src/agents/release_agent.py

class ReleaseAgent:
    """
    發版代理 - 自動化版本管理和發佈流程
    """
    
    async def auto_semantic_version_bump(self, commits: list) -> str:
        """
        根據 Conventional Commits 自動決定版本號
        
        commits: [
            {"type": "feat", "scope": "trading", ...},
            {"type": "fix", "scope": "wallet", ...},
            {"type": "feat", "body": "BREAKING CHANGE: ...", ...}
        ]
        
        Returns: "release-1.2.0" 或 "release-2.0.0"
        """
        
        has_breaking = any("BREAKING CHANGE" in c.get("body", "") for c in commits)
        has_features = any(c["type"] == "feat" for c in commits)
        has_fixes = any(c["type"] == "fix" for c in commits)
        
        current_version = self._get_current_version()  # e.g., "1.2.3"
        major, minor, patch = map(int, current_version.split("."))
        
        if has_breaking:
            major += 1
            minor = 0
            patch = 0
        elif has_features:
            minor += 1
            patch = 0
        elif has_fixes:
            patch += 1
        
        new_version = f"{major}.{minor}.{patch}"
        return f"release-{new_version}"
    
    async def create_release_with_changelog(self, new_version: str) -> dict:
        """
        使用 Claude 生成 Changelog 並建立 Release
        """
        
        # 取得最近 commits
        commits = await self._get_commits_since_last_tag()
        
        # 使用 Claude 生成 Changelog
        changelog = await self.claude_client.messages.create(
            model="claude-opus-4-8",
            messages=[{
                "role": "user",
                "content": f"根據以下 commit 生成 Changelog 格式的發佈說明：\n{commits}"
            }]
        )
        
        # 建立 GitHub Release
        release = await self._create_github_release(
            tag=new_version,
            body=changelog.content[0].text
        )
        
        # 更新 CHANGELOG.md
        await self._update_changelog_file(new_version, changelog.content[0].text)
        
        # 發送 Slack 通知
        await self._notify_release_on_slack(new_version, release)
        
        return {"version": new_version, "release_url": release["html_url"]}
```

---

## 📞 關鍵檢查清單

```
✅ 所有 zbot-* 項目都有：
   - [ ] 語義化版本標籤 (release-x.x.x)
   - [ ] Conventional Commits 提交消息
   - [ ] GitHub Branch Protection 規則
   - [ ] CHANGELOG.md 和 Release Notes
   - [ ] 自動化測試和 CI/CD
   - [ ] Code Review 流程 (2 approve 需求)
   - [ ] 狀態檢查 (lint, test, scan)
   - [ ] 簽署的 commit (GPG)
```

---

**文檔版本**：v1.0  
**最後更新**：2026-07-03  
**適用項目**：zbot-aladdin, zbot-aws, zbot-trading, zbot-wallet, zbot-analytics, zbot-website
