#!/bin/bash

# sync-upstream.sh
# 同步官方 loop-engineering 的更新到 zbot-engineering
#
# 用法:
#   bash scripts/sync-upstream.sh check       # 檢查官方更新
#   bash scripts/sync-upstream.sh merge       # 快速 merge
#   bash scripts/sync-upstream.sh review      # 詳細審查

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

ACTION=${1:-check}

echo "🔄 zbot-engineering Upstream Sync Tool"
echo "Action: $ACTION"
echo ""

# ============================================
# Step 1: Setup & Verify
# ============================================

cd "$PROJECT_ROOT"

# Verify remotes
echo "📍 Verifying git remotes..."
if git remote | grep -q "^upstream$"; then
  echo "  ✅ upstream remote exists"
else
  echo "  ⚠️  Adding upstream remote..."
  git remote add upstream https://github.com/cobusgreyling/loop-engineering.git
  echo "  ✅ upstream remote added"
fi

# ============================================
# Action: CHECK
# ============================================

if [ "$ACTION" = "check" ]; then
  echo ""
  echo "🔍 Checking for upstream updates..."

  # Fetch latest
  echo "  Fetching from upstream..."
  git fetch upstream main 2>&1 | grep -v "^From" | grep -v "^   " || true

  # Count commits behind
  BEHIND=$(git rev-list --count HEAD..upstream/main 2>/dev/null || echo 0)
  AHEAD=$(git rev-list --count upstream/main..HEAD 2>/dev/null || echo 0)

  echo ""
  echo "  Status:"
  echo "    Your main: $(git rev-parse --short main)"
  echo "    Upstream main: $(git rev-parse --short upstream/main)"
  echo "    Behind: $BEHIND commits"
  echo "    Ahead: $AHEAD commits"

  if [ $BEHIND -gt 0 ]; then
    echo ""
    echo "  📥 Latest upstream commits:"
    git log --oneline -n 10 upstream/main | head -5

    echo ""
    echo "  📋 Diff summary:"
    git diff --stat main..upstream/main | tail -5

    echo ""
    echo "  💾 Saving upstream changes report..."
    git log --oneline HEAD..upstream/main > upstream-changes-$(date +%Y%m%d).txt
    echo "  ✅ Report saved to: upstream-changes-$(date +%Y%m%d).txt"

    echo ""
    echo "  📌 Next step: bash scripts/sync-upstream.sh review"
  else
    echo ""
    echo "  ✅ Already up to date with upstream"
  fi

  exit 0
fi

# ============================================
# Action: REVIEW
# ============================================

if [ "$ACTION" = "review" ]; then
  echo ""
  echo "📋 Reviewing upstream changes..."

  git fetch upstream main

  BEHIND=$(git rev-list --count HEAD..upstream/main 2>/dev/null || echo 0)

  if [ $BEHIND -eq 0 ]; then
    echo "  ✅ Already up to date"
    exit 0
  fi

  echo ""
  echo "  Detailed diff:"
  echo "  ─────────────────────────────────────────"
  git diff main..upstream/main --stat
  echo "  ─────────────────────────────────────────"

  echo ""
  echo "  Changed files:"
  git diff --name-only main..upstream/main | sed 's/^/    /'

  echo ""
  echo "  Key commits:"
  git log --format='%h %s' -n 15 main..upstream/main

  echo ""
  echo "  Analysis:"
  echo "    - Docs changed: $(git diff --name-only main..upstream/main | grep -c 'docs/' || echo 0)"
  echo "    - Code changed: $(git diff --name-only main..upstream/main | grep -c -E '(src/|tools/|\.ts$)' || echo 0)"
  echo "    - Starters changed: $(git diff --name-only main..upstream/main | grep -c 'starters/' || echo 0)"

  echo ""
  echo "  ⚠️  Potential conflicts with zbot customizations:"
  echo "    - prompts/ → system-prompt-triage-v1-zh.md (KEEP zbot version)"
  echo "    - mcp/ → ZBOT-MCP-INTEGRATION-GUIDE.md (KEEP zbot version)"
  echo "    - pre-agents/ → tier-1-5-*.md (CHECK if needs update)"

  echo ""
  echo "  Decision needed:"
  echo "    1. bash scripts/sync-upstream.sh merge          # Fast merge (no conflicts)"
  echo "    2. bash scripts/sync-upstream.sh merge-selective # Cherry-pick (choose commits)"
  echo "    3. bash scripts/sync-upstream.sh abort           # Cancel sync"

  exit 0
fi

# ============================================
# Action: MERGE (Fast)
# ============================================

if [ "$ACTION" = "merge" ]; then
  echo ""
  echo "🔗 Fast merging upstream updates..."

  git fetch upstream main

  # Create feature branch
  FEATURE_BRANCH="feature/upstream-sync-$(date +%Y%m%d-%H%M%S)"
  echo "  Creating feature branch: $FEATURE_BRANCH"
  git checkout -b "$FEATURE_BRANCH"

  # Attempt merge
  echo "  Merging upstream/main..."
  if git merge upstream/main --no-ff -m "Merge upstream loop-engineering updates

Upstream merges $(git rev-list --count main..upstream/main) new commits
Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)

Upstream commits:
$(git log --oneline main..upstream/main | sed 's/^/  /')
" 2>&1 | tee /tmp/merge.log; then

    echo "  ✅ Merge successful (no conflicts)"

    # Run tests
    echo ""
    echo "🧪 Running integration tests..."
    if [ -f "test-integration.sh" ]; then
      bash test-integration.sh || {
        echo "  ❌ Tests failed"
        echo "  Aborting merge..."
        git merge --abort
        exit 1
      }
    fi

    # Merge to main
    echo ""
    echo "  Merging to main..."
    git checkout main
    git merge "$FEATURE_BRANCH" --ff-only

    # Tag release
    TAG="v$(date +%Y%m%d)-upstream-sync"
    echo "  Creating tag: $TAG"
    git tag -a "$TAG" -m "Sync upstream loop-engineering
Date: $(date -u)
Branch: $FEATURE_BRANCH"

    # Clean up
    git branch -d "$FEATURE_BRANCH"

    echo ""
    echo "✅ Upstream sync complete!"
    echo "  Tag: $TAG"
    echo "  Push with: git push origin main --tags"

  else
    echo "  ⚠️  Merge conflicts detected"
    echo "  Please manually resolve conflicts:"
    echo "    git status"
    echo ""
    echo "  Common conflict points:"
    echo "    - prompts/*.md → keep zbot version"
    echo "    - mcp/*.md → keep zbot version"
    echo "    - docs/ → merge (accept both)"
    echo ""
    echo "  After resolving:"
    echo "    git add ."
    echo "    git merge --continue"
    exit 1
  fi

  exit 0
fi

# ============================================
# Action: MERGE-SELECTIVE
# ============================================

if [ "$ACTION" = "merge-selective" ]; then
  echo ""
  echo "🎯 Selective merge (cherry-pick specific commits)..."

  git fetch upstream main

  # Show available commits
  echo ""
  echo "  Available upstream commits:"
  git log --format='%h %s' -n 20 main..upstream/main | nl

  echo ""
  echo "  Enter commit numbers to cherry-pick (space-separated):"
  echo "  Example: 1 3 5"
  read -p "  > " SELECTIONS

  # Create feature branch
  FEATURE_BRANCH="feature/upstream-selective-$(date +%Y%m%d)"
  git checkout -b "$FEATURE_BRANCH"

  # Cherry-pick selected commits
  for NUM in $SELECTIONS; do
    COMMIT=$(git log --format='%h' -n 20 main..upstream/main | sed -n "${NUM}p")
    if [ -n "$COMMIT" ]; then
      echo "  Cherry-picking: $COMMIT"
      git cherry-pick "$COMMIT" || {
        echo "  ⚠️  Conflict in cherry-pick"
        echo "  Resolve manually, then: git cherry-pick --continue"
        exit 1
      }
    fi
  done

  # Merge to main
  git checkout main
  git merge "$FEATURE_BRANCH"

  # Clean up
  git branch -d "$FEATURE_BRANCH"

  echo ""
  echo "✅ Selective merge complete!"

  exit 0
fi

# ============================================
# Action: ABORT
# ============================================

if [ "$ACTION" = "abort" ]; then
  echo ""
  echo "⏹️ Aborting sync..."

  if [ -n "$(git status --porcelain)" ]; then
    echo "  Cleaning up working directory..."
    git reset --hard HEAD
  fi

  # Delete feature branches
  git for-each-ref --format '%(refname:short)' refs/heads/feature/upstream* | xargs -r git branch -D

  echo "  ✅ Aborted"
  exit 0
fi

# ============================================
# Unknown action
# ============================================

echo ""
echo "❌ Unknown action: $ACTION"
echo ""
echo "Usage:"
echo "  bash scripts/sync-upstream.sh check              # Check for updates"
echo "  bash scripts/sync-upstream.sh review             # Review changes"
echo "  bash scripts/sync-upstream.sh merge              # Fast merge"
echo "  bash scripts/sync-upstream.sh merge-selective    # Cherry-pick commits"
echo "  bash scripts/sync-upstream.sh abort              # Cancel sync"

exit 1
