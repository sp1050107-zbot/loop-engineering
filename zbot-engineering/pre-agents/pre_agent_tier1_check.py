#!/usr/bin/env python3

"""
Pre-Agent Tier 1: Configuration Validation

檢查 Agent 執行前的基本環境配置
"""

import os
import sys
import json
import subprocess
from pathlib import Path
from datetime import datetime

def check_env_vars(required_vars=None):
    """檢查必需的環境變數"""
    if required_vars is None:
        required_vars = ["AWS_REGION", "PROJECT_NAME"]

    missing = [k for k in required_vars if not os.getenv(k)]

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
            timeout=5,
            text=True
        )

        if result.returncode != 0:
            return False, f"AWS Secrets access failed"

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
        ("ENV_VARS", lambda: check_env_vars()),
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
    import argparse

    parser = argparse.ArgumentParser(description="Tier 1 Pre-Agent Validation")
    parser.add_argument("--project", required=True, help="Project name (e.g., zbot-aws)")
    parser.add_argument("--verbose", action="store_true")

    args = parser.parse_args()

    # 設置環境變數
    if not os.getenv("AWS_REGION"):
        os.environ["AWS_REGION"] = "ap-northeast-1"
    if not os.getenv("PROJECT_NAME"):
        os.environ["PROJECT_NAME"] = args.project

    print(f"🔍 Tier 1 Pre-Agent Validation — {args.project}")
    print()

    passed, results = run_tier1(args.project, verbose=args.verbose)

    print()
    if passed:
        print("✅ Tier 1: PASS - Agent can proceed")

        # 記錄到 LOOP-STATE.md
        try:
            with open("LOOP-STATE.md", "a") as f:
                f.write(f"\n### Pre-Agent Check: {datetime.now().isoformat()}\n")
                f.write(f"- Tier 1: ✅ PASS\n")
        except:
            pass

        sys.exit(0)
    else:
        print("❌ Tier 1: FAIL - Fix errors before proceeding")
        print("\n詳細結果:")
        print(json.dumps(results, indent=2))
        sys.exit(1)
