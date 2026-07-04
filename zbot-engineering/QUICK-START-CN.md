# zbot-engineering 快速開始（中文）

**時間**：15 分鐘  
**成果**：讓第一個 zbot-* 項目有完整的 Loop 框架

---

## Step 1: 複製範本到 zbot-aws（5 分鐘）

```bash
cd /Users/lz/zbot

# 複製 LOOP.md 和 LOOP-STATE.md
cat > zbot-aws/LOOP.md << 'EOF'
# LOOP.md — zbot-aws

## Active Loops

| Pattern | Cadence | Level |
|---------|---------|-------|
| Daily Infra Check | 1d 08:00 | L1 report-only |
| Dependency Sweep | 1w Mon | L1 patch-only |

## Safety Gates
- ❌ 禁止自動修改 IAM、VPC、數據庫配置
- ✅ 允許：檢查日誌、報警、建議

## MCP
- Connectors: github (read), aws (read)

See LOOP-STATE.md for run history.
EOF

cat > zbot-aws/LOOP-STATE.md << 'EOF'
# LOOP-STATE.md — zbot-aws

Last run: —

## High Priority (Loop 作用中)
- (待填充)

## Watch List
- (待填充)

## Recent Noise (ignored)
- —
EOF

git -C zbot-aws add LOOP.md LOOP-STATE.md
git -C zbot-aws commit -m "Phase 1: Add Loop Engineering foundation" --no-verify 2>/dev/null || true
```

## Step 2: 複製系統提示到各項目（5 分鐘）

```bash
# 為 zbot-aws 建立 prompts/ 目錄
mkdir -p zbot-aws/prompts

# 複製中文系統提示
cp zbot-engineering/prompts/system-prompt-triage-v1-zh.md \
   zbot-aws/prompts/

git -C zbot-aws add prompts/
git -C zbot-aws commit -m "Add system prompts (v1.0 Chinese)" --no-verify 2>/dev/null || true

echo "✅ zbot-aws prompts/ ready"
```

## Step 3: 執行第一次手動 Triage（5 分鐘）

```bash
cd zbot-aws

# 閱讀 LOOP.md
cat LOOP.md

# 按照 prompts/system-prompt-triage-v1-zh.md 的步驟檢查
# Step 1: 載入上次狀態 (已讀 LOOP-STATE.md)
# Step 2: 健康檢查 (手動檢查幾個關鍵指標)
#   - EC2 狀態
#   - Lambda 性能
#   - RDS 連接
# Step 3: 評分
# Step 4: 更新 LOOP-STATE.md

# 填充 LOOP-STATE.md
cat > LOOP-STATE.md << 'EOF'
# LOOP-STATE.md — zbot-aws

Last run: 2026-07-04T10:00:00Z (manual)

## High Priority
- EC2 instances: ✅ All running
- Lambda cold start: ⚠️ 2.8s (normal)
- RDS: ✅ Connected

## Watch List
- (無)

## Recent Noise
- (無)

---

Post-Run: 首次巡檢成功完成，所有系統正常
EOF

git add LOOP-STATE.md
git commit -m "Log: First manual triage (2026-07-04)" --no-verify 2>/dev/null || true

echo "✅ First triage complete!"
```

---

## 現在 zbot-aws 已可用於自動化

```bash
# 下一步：配置定時運行
# 編輯 LOOP.md 中的 cadence
# 例：每天 08:00 UTC 自動運行

# 在項目根目錄設置 cron（或使用 GitHub Actions）
# 0 8 * * * cd zbot-aws && /loop "Run daily triage"
```

---

## 重複相同步驟到其他 5 個項目

```bash
for proj in zbot-aladdin zbot-analytics zbot-trading zbot-wallet zbot-website; do
  echo "Initializing $proj..."
  
  mkdir -p $proj/prompts
  cp zbot-engineering/prompts/system-prompt-triage-v1-zh.md $proj/prompts/
  
  # 根據項目特點定製 LOOP.md
  # (見下方項目特化部分)
  
  git -C $proj add LOOP.md LOOP-STATE.md prompts/
  git -C $proj commit -m "Phase 1: Add Loop Engineering foundation" --no-verify 2>/dev/null || true
  
  echo "✅ $proj ready"
done
```

---

## 項目特化（可選）

### zbot-aladdin（金融算法）

```markdown
# LOOP.md — zbot-aladdin

## Active Loops
| Pattern | Cadence | Level |
|---------|---------|-------|
| Daily Backtest | 1d 22:00 UTC | L1 report-only |
| Rebalance Check | 3d Sun 20:00 | L1 suggest-only |

## Safety Gates
- ❌ 禁止自動交易
- ✅ 允許：回測、性能報告、建議

## Key Metrics
- Sharpe Ratio > 1.5
- Max Drawdown < 15%
```

### zbot-trading（交易所）

```markdown
# LOOP.md — zbot-trading

## Active Loops
| Pattern | Cadence | Level |
|---------|---------|-------|
| Exchange Health | 4h | L1 report-only |
| Order Book Check | 2h | L1 watch-only |

## Safety Gates
- ❌ 禁止自動下單
- ✅ 允許：檢查連接、監控價格

## Key Metrics
- Exchange API 連接 < 100ms
- Order Book 新鮮度 < 30s
```

### zbot-aws（基礎設施）

```markdown
# LOOP.md — zbot-aws

## Active Loops
| Pattern | Cadence | Level |
|---------|---------|-------|
| Daily Audit | 1d 08:00 | L1 report-only |
| Backup Check | 1d 10:00 | L1 read-only |

## Safety Gates
- ❌ 禁止修改生產配置
- ✅ 允許：檢查日誌、生成報告

## Key Metrics
- EC2 運行時間 > 99%
- Lambda 冷啟 < 3s
```

---

## 現在檢查

```bash
# 驗證所有 6 個項目都有基礎框架
for proj in zbot-aladdin zbot-analytics zbot-aws zbot-trading zbot-wallet zbot-website; do
  echo "=== $proj ==="
  [ -f "$proj/LOOP.md" ] && echo "✅ LOOP.md" || echo "❌ missing"
  [ -f "$proj/LOOP-STATE.md" ] && echo "✅ LOOP-STATE.md" || echo "❌ missing"
  [ -d "$proj/prompts" ] && echo "✅ prompts/" || echo "❌ missing"
done
```

---

## 下一步（Week 2）

1. **測試 Pre-Agent 檢查**
   ```bash
   python zbot-engineering/pre-agents/tier-1-config-validation.py --project zbot-aws
   ```

2. **記錄失敗案例**
   - 運行 triage 時發現 Agent 遺漏的問題
   - 記錄到 `zbot-engineering/skills/loop-triage/failures.jsonl`

3. **啟動 MCP Server 開發**
   ```bash
   cd zbot-engineering/mcp
   npm install
   npm run dev
   ```

---

## 參考文檔

- **完整指南**：`zbot-engineering/README.md`
- **系統提示詳解**：`zbot-engineering/prompts/system-prompt-triage-v1-zh.md`
- **Pre-Agent 檢查**：`zbot-engineering/pre-agents/tier-1-config-validation.md`
- **失敗記錄**：`zbot-engineering/skills/loop-triage/FAILURE-LOG-FORMAT.md`
- **實施路線圖**：`zbot-engineering/IMPLEMENTATION-ROADMAP.md`
- **MCP 集成**：`zbot-engineering/mcp/ZBOT-MCP-INTEGRATION-GUIDE.md`

---

**就這樣！** 🎉  
你現在有了一個結構化的 Loop Engineering 框架。

**下一行動**：
- 每天檢查 LOOP-STATE.md，看 Agent 有沒有發現新問題
- 每週檢查失敗記錄，改進系統提示
- 4 週後，升級到 L2（Implementer ↔ Verifier Split）
