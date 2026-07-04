# 失敗記錄格式和管理

**目的**：記錄 Agent 的失敗案例，用於改進 Prompt、防止回歸、建立知識庫

**存儲**：每個 Skill 下的 `failures.jsonl`（JSON Lines 格式，一行一個失敗記錄）

---

## 記錄格式（JSON Lines）

```json
{
  "timestamp": "2026-07-04T08:15:30Z",
  "run_id": "loop-triage-20260704-081530",
  "skill": "loop-triage",
  "prompt_version": "v1.0",
  "project": "zbot-aws",
  
  "failure_type": "missed_alert",
  "severity": "high",
  
  "description": "Lambda 冷啟動時間超過 5 秒，但 Agent 未檢出",
  
  "expected_behavior": "Agent 應檢查 CloudWatch Logs 中的 'Init Duration'，並對比歷史均值。如果當前 > 3 秒應 Alert",
  
  "actual_behavior": "Agent 只檢查了 CloudWatch Metrics dashboard，沒有深入查看 Logs。遺漏了冷啟動時間",
  
  "root_cause": "系統提示中的 'Step 2: 健康檢查' 沒有明確要求查看 Logs。Agent 進行了最小化檢查。",
  
  "context": {
    "metric": "Lambda Init Duration",
    "value": "5.2 秒",
    "threshold": "3.0 秒",
    "historical_avg": "2.1 秒",
    "data_source": "AWS CloudWatch Logs"
  },
  
  "token_cost": {
    "input": 1240,
    "output": 520,
    "total": 1760
  },
  
  "reproduction_steps": [
    "1. 執行 daily triage for zbot-aws",
    "2. Agent 拉取 CloudWatch Metrics (不查看 Logs)",
    "3. Lambda Init Duration > 3s 但未被檢出"
  ],
  
  "remediation": {
    "prompt_fix": "在 system-prompt-triage-v1-zh.md Step 2 中添加：'For Lambda: 必須檢查 CloudWatch Logs filter by 「Init Duration」'",
    "prompt_version_next": "v1.1",
    "priority": "P1"
  },
  
  "tags": ["lambda", "cloudwatch", "missed-alert", "prompt-ambiguity"],
  
  "assignee": "claude-code",
  "status": "open",
  "resolution_date": null,
  
  "notes": "這是一個 Prompt 指令不明確的案例。需要在 v1.1 中強化 Logs 查詢的優先級"
}
```

---

## 欄位詳解

| 欄位 | 類型 | 說明 | 必需？ |
|------|------|------|--------|
| `timestamp` | ISO 8601 | 失敗發生時間 | ✅ |
| `run_id` | string | 本次 Loop 運行的唯一 ID | ✅ |
| `skill` | string | 所屬 Skill 名稱 | ✅ |
| `prompt_version` | string | 使用的 Prompt 版本（v1.0, v1.1 等） | ✅ |
| `project` | string | zbot-* 項目名 | ✅ |
| `failure_type` | enum | 失敗類型（見下表） | ✅ |
| `severity` | enum | 嚴重度 (critical/high/medium/low) | ✅ |
| `description` | string | 人類可讀的失敗描述 | ✅ |
| `expected_behavior` | string | 應該做什麼 | ✅ |
| `actual_behavior` | string | 實際做了什麼 | ✅ |
| `root_cause` | string | 根本原因分析 | ✅ |
| `context` | object | 失敗發生時的上下文數據 | ⚠️ |
| `token_cost` | object | 本次運行的 Token 消耗 | ⚠️ |
| `reproduction_steps` | array | 如何重現此失敗 | ⚠️ |
| `remediation` | object | 修復方案 | ✅ |
| `tags` | array | 標籤（用於聚類） | ✅ |
| `assignee` | string | 負責改進的人/系統 | ⚠️ |
| `status` | enum | 狀態 (open/in-progress/resolved/wontfix) | ✅ |
| `resolution_date` | ISO 8601 | 修復完成時間 | ⚠️ |
| `notes` | string | 自由文本備註 | ⚠️ |

---

## 失敗類型分類

```
1. missed_alert
   └─ Agent 應發現問題但沒發現
   └─ 例：Lambda 冷啟 > 3s 未檢出

2. false_positive
   └─ Agent 報告了不存在的問題
   └─ 例：報告 EC2 stopped，但實際是 running

3. incorrect_action
   └─ Agent 採取了錯誤的行動
   └─ 例：建議 scale down（實際應 scale up）

4. timeout
   └─ Agent 運行超過預期時間
   └─ 例：API 查詢超過 30 秒

5. api_error
   └─ 外部 API 錯誤
   └─ 例：AWS API 返回 500

6. prompt_ambiguity
   └─ Prompt 指令不清楚
   └─ 例：「檢查健康」但沒說檢查什麼

7. hallucination
   └─ Agent 編造了不存在的數據
   └─ 例：報告一個虛假的 metric 值

8. context_limit
   └─ 數據超過 context 限制
   └─ 例：日誌太多無法全部讀取
```

---

## 記錄失敗的流程

### 場景 1：Agent 自己發現失敗（Verifier 角色）

```
Verifier Agent 檢查 Implementer 的輸出 → 發現問題
    ↓
Verifier 將失敗信息寫入 failures.jsonl
    ↓
人工審視 failures.jsonl → 決定是否改進 Prompt
    ↓
更新 Prompt 版本（v1.0 → v1.1）
    ↓
在 failure 記錄中加入 resolution_date
```

### 場景 2：人工發現失敗

```
人工運行 loop-triage 後，發現 Agent 漏掉什麼
    ↓
手動編寫 failures.jsonl 新行
    ↓
提交 Issue 到 GitHub
    ↓
Prompt Engineer 評估改進優先級
```

---

## 使用失敗記錄改進 Prompt

### Step 1: 聚類失敗

```bash
# 按 failure_type 和 project 聚類
cat failures.jsonl | jq -r '[.failure_type, .project] | @csv' | sort | uniq -c

# 輸出例
      2 "missed_alert","zbot-aws"
      3 "prompt_ambiguity","zbot-aladdin"
      1 "false_positive","zbot-trading"
```

### Step 2: 確認 Prompt 版本

```bash
# 查找哪個 v1.0 導致最多失敗
cat failures.jsonl | jq -r 'select(.status == "open") | [.prompt_version, .failure_type] | @csv'

# 輸出
"v1.0","missed_alert"
"v1.0","missed_alert"
"v1.0","prompt_ambiguity"
```

### Step 3: 編寫改進方案

在 failures.jsonl 的 `remediation` 欄位記錄：
```json
{
  "remediation": {
    "prompt_fix": "在 Step 2 中添加：'For Lambda: ...'",
    "lines_changed": ["Step 2.1", "Step 2.2"],
    "estimated_impact": "減少 80% of missed Lambda alerts",
    "prompt_version_next": "v1.1"
  }
}
```

### Step 4: 發佈新版本

更新 `system-prompt-triage-v1-1-zh.md`：
```markdown
# 系統提示：zbot 每日巡檢 (v1.1)

## 改進日誌 (vs v1.0)

### 修復：Lambda 冷啟動檢查遺漏
- **問題**：v1.0 中 Lambda 檢查不完整，遺漏冷啟動時間（見 failures.jsonl #1-2）
- **改進**：在 Step 2 中強制執行 CloudWatch Logs 查詢
- **驗證**：已通過 backtest（見 backtest-results/v1.1-lambda-checks.json）
```

---

## 自動化失敗檢測（Verifier 角色）

```python
#!/usr/bin/env python3
"""
Verifier 自動檢查 Triage 輸出的品質
"""

import json
from datetime import datetime

def verify_triage_output(triage_output, state_file):
    """
    驗證 Triage 輸出是否包含所有預期的檢查項
    """
    
    failures = []
    
    # 檢查 1: 是否檢查了所有必需的 metrics
    required_checks = {
        "zbot-aws": ["ec2", "lambda", "rds", "s3"],
        "zbot-aladdin": ["sharpe_ratio", "max_drawdown", "api_cost"],
        "zbot-trading": ["exchange_connection", "order_book", "leverage"],
    }
    
    for project, metrics in required_checks.items():
        if project not in triage_output.get("projects_checked", []):
            continue
        
        for metric in metrics:
            if metric not in triage_output.get("metrics", []):
                failures.append({
                    "type": "missed_alert",
                    "metric": metric,
                    "project": project
                })
    
    # 檢查 2: 是否有異常檢測
    if not triage_output.get("alerts"):
        # 沒有任何警告可能是合法的，或者是 false negative
        pass
    
    # 檢查 3: 是否更新了 LOOP-STATE.md
    if not triage_output.get("state_updated"):
        failures.append({
            "type": "state_not_updated",
            "severity": "high"
        })
    
    return failures

def log_failure(failure_dict, skill="loop-triage"):
    """將失敗記錄到 failures.jsonl"""
    
    record = {
        "timestamp": datetime.now().isoformat() + "Z",
        "skill": skill,
        "failure_type": failure_dict["type"],
        "severity": failure_dict.get("severity", "medium"),
        "status": "open",
        # ... 其他欄位根據 failure_dict 自動填充
    }
    
    with open(f"skills/{skill}/failures.jsonl", "a") as f:
        f.write(json.dumps(record) + "\n")
```

---

## Prompt 版本發佈流程

1. **發現問題** → 寫入 failures.jsonl
2. **分析根因** → 填充 remediation 欄位
3. **測試改進** → 在 backtest 環境驗證
4. **發佈新版本** → 建立 `system-prompt-triage-v1-1-zh.md`
5. **更新舊失敗記錄** → 標記為 resolved

```bash
# 示例：發佈 v1.1
cp system-prompt-triage-v1-zh.md system-prompt-triage-v1-1-zh.md
# 編輯 v1-1-zh.md，加入改進日誌

# 標記舊失敗為已解決
cat failures.jsonl | \
  jq '. as $orig | if .prompt_version == "v1.0" and .failure_type == "missed_alert" 
       then .resolution_date = "2026-07-10T00:00:00Z" | .status = "resolved" 
       else . end' > failures.jsonl.new
mv failures.jsonl.new failures.jsonl
```

---

**下一步**：定期（每週）審視 failures.jsonl，優先修復 P1 級別的失敗
