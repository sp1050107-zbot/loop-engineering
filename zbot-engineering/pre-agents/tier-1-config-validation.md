# Pre-Agent 檢查：Tier 1 - 環境配置驗證

**目的**：Agent 執行前確認所有必需的環境變數、API 密鑰、文件都已就位  
**時機**：每次 Agent 啟動時自動檢查  
**失敗行為**：如果任何檢查失敗 → 中止執行，打印清晰的錯誤信息  

---

## 檢查項目

### ✅ 必需的環境變數

```bash
# 通用環境
CLAUDE_API_KEY       # Anthropic API key (from AWS Secrets Manager)
AWS_REGION           # 預設: ap-northeast-1
AWS_PROFILE          # 預設: zbot_leonlin

# 項目特定
PROJECT_NAME         # e.g., zbot-aws, zbot-aladdin
LOOP_STATE_PATH      # 預設: ./LOOP-STATE.md
```

**檢查方法**：
```python
import os
import sys

required_env = [
    "CLAUDE_API_KEY",
    "AWS_REGION", 
    "PROJECT_NAME"
]

missing = [k for k in required_env if not os.getenv(k)]

if missing:
    print(f"❌ TIER 1 FAILED: Missing env vars: {', '.join(missing)}")
    sys.exit(1)

print("✅ Tier 1 Env: PASS")
```

### ✅ AWS Secrets Manager 可訪問性

```bash
# 驗證能否讀取 API 密鑰
aws secretsmanager get-secret-value \
  --secret-id "zbot-${PROJECT_NAME}/claude-api-key" \
  --region ap-northeast-1 \
  --query SecretString --output text > /dev/null 2>&1

if [ $? -ne 0 ]; then
  echo "❌ Cannot access Secrets Manager"
  exit 1
fi

echo "✅ Tier 1 AWS Secrets: PASS"
```

### ✅ 必需的檔案存在

```python
from pathlib import Path

required_files = {
    "LOOP-STATE.md": "State 文件（運維日誌）",
    "CLAUDE.md": "項目配置",
    ".env.local": "本地環境變數（可選）"
}

missing_files = []
for file, desc in required_files.items():
    if not Path(file).exists():
        # 對於可選文件，只警告
        if file == ".env.local":
            print(f"⚠️  {file} 不存在，但為可選")
        else:
            missing_files.append(file)

if missing_files:
    print(f"❌ TIER 1 FAILED: Missing files: {', '.join(missing_files)}")
    sys.exit(1)

print("✅ Tier 1 Files: PASS")
```

### ✅ 日誌目錄可寫入

```python
from pathlib import Path
import tempfile
import os

# 驗證 LOOP-STATE.md 可寫入
state_file = Path("LOOP-STATE.md")

try:
    # 嘗試以 append 模式打開
    with open(state_file, "a") as f:
        pass  # 不寫入，只檢查權限
    print("✅ Tier 1 Write Permission: PASS")
except PermissionError:
    print(f"❌ TIER 1 FAILED: Cannot write to {state_file}")
    sys.exit(1)
```

---

## Tier 1 完整檢查腳本

```python
#!/usr/bin/env python3
"""
pre_agent_tier1.py — Tier 1 Configuration Validation

用法:
  python pre_agent_tier1.py --project zbot-aws
  python pre_agent_tier1.py --project zbot-aladdin --strict
"""

import os
import sys
import json
import subprocess
import argparse
from pathlib import Path
from datetime import datetime

def check_env_vars():
    """檢查必需的環境變數"""
    required = ["CLAUDE_API_KEY", "AWS_REGION", "PROJECT_NAME"]
    missing = [k for k in required if not os.getenv(k)]
    
    if missing:
        return False, f"Missing env vars: {', '.join(missing)}"
    
    return True, "All required env vars present"

def check_aws_secrets(project_name):
    """檢查 AWS Secrets Manager 連接"""
    try:
        result = subprocess.run(
            [
                "aws", "secretsmanager", "get-secret-value",
                "--secret-id", f"zbot-{project_name}/claude-api-key",
                "--region", os.getenv("AWS_REGION", "ap-northeast-1"),
                "--query", "SecretString",
                "--output", "text"
            ],
            capture_output=True,
            timeout=5
        )
        
        if result.returncode != 0:
            return False, f"AWS Secrets access failed: {result.stderr.decode()}"
        
        return True, "AWS Secrets Manager accessible"
    
    except Exception as e:
        return False, f"AWS Secrets check failed: {str(e)}"

def check_required_files():
    """檢查必需的檔案"""
    required = ["LOOP-STATE.md", "CLAUDE.md"]
    missing = [f for f in required if not Path(f).exists()]
    
    if missing:
        return False, f"Missing files: {', '.join(missing)}"
    
    return True, "All required files present"

def check_write_permissions():
    """檢查檔案寫入權限"""
    try:
        state_file = Path("LOOP-STATE.md")
        with open(state_file, "a") as f:
            pass  # 不寫入，只檢查
        
        return True, "Write permissions OK"
    
    except PermissionError:
        return False, "Cannot write to LOOP-STATE.md"

def run_tier1(project_name, verbose=False):
    """執行 Tier 1 檢查"""
    
    checks = [
        ("ENV_VARS", check_env_vars),
        ("AWS_SECRETS", lambda: check_aws_secrets(project_name)),
        ("REQUIRED_FILES", check_required_files),
        ("WRITE_PERMISSIONS", check_write_permissions),
    ]
    
    results = {}
    all_pass = True
    
    for check_name, check_func in checks:
        passed, message = check_func()
        results[check_name] = {"passed": passed, "message": message}
        
        if passed:
            print(f"  ✅ {check_name}: {message}")
        else:
            print(f"  ❌ {check_name}: {message}")
            all_pass = False
    
    return all_pass, results

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Tier 1 Pre-Agent Validation")
    parser.add_argument("--project", required=True, help="Project name (e.g., zbot-aws)")
    parser.add_argument("--verbose", action="store_true")
    
    args = parser.parse_args()
    
    print(f"🔍 Tier 1 Pre-Agent Validation — {args.project}")
    print()
    
    passed, results = run_tier1(args.project, verbose=args.verbose)
    
    print()
    if passed:
        print("✅ Tier 1: PASS - Agent can proceed")
        
        # 記錄到 LOOP-STATE.md
        with open("LOOP-STATE.md", "a") as f:
            f.write(f"\n### Pre-Agent Check: {datetime.now().isoformat()}\n")
            f.write(f"- Tier 1: ✅ PASS\n")
        
        sys.exit(0)
    else:
        print("❌ Tier 1: FAIL - Fix errors before proceeding")
        print("\n詳細結果:")
        print(json.dumps(results, indent=2))
        sys.exit(1)
```

**使用**：
```bash
# 在項目根目錄執行
python ../zbot-engineering/pre-agents/tier-1-config-validation.py --project zbot-aws

# 在 LOOP.md 中集成（Agent 啟動時）
pre_flight_check: "python ../zbot-engineering/pre-agents/tier-1-config-validation.py --project $PROJECT"
```

---

## 失敗排查指南

| 錯誤信息 | 原因 | 解決方案 |
|---------|------|--------|
| `Missing env vars: CLAUDE_API_KEY` | API 密鑰未設置 | `export CLAUDE_API_KEY=$(aws secretsmanager ...)`  |
| `AWS Secrets access failed` | 無 AWS 認證 | `aws configure --profile zbot_leonlin` |
| `Missing files: LOOP-STATE.md` | 未初始化項目 | `cp ../zbot-engineering/starters/LOOP-STATE.md ./` |
| `Cannot write to LOOP-STATE.md` | 文件權限問題 | `chmod 644 LOOP-STATE.md` |

---

## 整合到 CI/CD

在 GitHub Actions 中加入 Tier 1 檢查：

```yaml
# .github/workflows/pre-agent-check.yml
name: Pre-Agent Validation

on:
  workflow_dispatch:  # 手動觸發

jobs:
  tier1:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Tier 1 Validation
        run: |
          python zbot-engineering/pre-agents/tier-1-config-validation.py \
            --project ${{ github.event.inputs.project || 'zbot-aws' }}
```

---

**下一步**：Tier 2 - Context Bounds 檢查（`tier-2-context-bounds.md`）
