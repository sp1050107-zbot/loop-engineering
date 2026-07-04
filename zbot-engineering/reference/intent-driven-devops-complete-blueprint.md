# Intent-Driven DevOps 完整實施藍圖
# AI Agent 自主運維架構（包含工具鏈生態 + 代碼實現 + 漸進式放權策略）

**願景**：從「命令式運維」→「聲明式 IaC」→ **「意圖導向自主運維」**  
**目標**：AWS + Cloudflare 全棧基礎設施由 AI Agent 自動搭建、監控、管理、回報  
**時間**：3 個月內完成漸進式放權三階段  
**團隊**：4-5 人 DevOps/SRE + AI 工程師

---

## 📊 四層架構全景 + AI Agent 對應

```
┌─────────────────────────────────────────────────────────────────┐
│                     CTO 決策層 (Observability & Intent Hub)       │
│   (接收 AI Agent 報告 → 批准關鍵決策 → 監督漸進式放權進度)        │
└───────────────────────┬──────────────────────────────────────────┘
                        │
        ┌───────────────┼───────────────┬─────────────────┐
        │               │               │                 │
        ▼               ▼               ▼                 ▼
┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│ 基礎設施層   │ │ 安全治理層   │ │ SRE可靠層    │ │ 應用發版層   │
│ Infrastructure│ │ Security    │ │ Reliability  │ │ Deployment   │
└────────┬─────┘ └──────┬───────┘ └──────┬───────┘ └──────┬───────┘
         │              │               │              │
    ┌────▼──────┐  ┌────▼──────┐  ┌────▼──────┐  ┌────▼──────┐
    │ Infra     │  │ Security  │  │ SRE       │  │ Release   │
    │ Agent     │  │ Agent     │  │ Agent     │  │ Agent     │
    │ (Claude)  │  │ (Claude)  │  │ (Claude)  │  │ (Claude)  │
    └────┬──────┘  └────┬──────┘  └────┬──────┘  └────┬──────┘
         │              │               │              │
    Terraform      WAF Rules       Runbook           Argo CD
    Infracost      IAM Policy      Alerts            Canary
    CloudFormation Secrets Mgr     Datadog           Auto-rollback
```

---

## 1️⃣ 基礎設施層 (Infrastructure Agent)

### 職責矩陣

| 階段 | 搭建 | 監控 | 管理 | 回報 |
|-----|------|------|------|------|
| **Phase 1** | PR 提議 + 人工批准 | 成本估算 + Slack 通知 | - | 每周報告 |
| **Phase 2** | 自動部署 Dev/Staging | 實時成本追蹤 + 告警 | 標籤化 + 清理 | 每日報告 |
| **Phase 3** | 自動部署 Production | 成本優化建議 | 自動縮放策略 | 即時儀表板 |

### 核心工作流

```python
# src/agents/infrastructure_agent.py

class InfrastructureAgent:
    """
    基礎設施層 AI Agent
    
    工作流：
    1. 接收自然語言需求 (GitHub Issue / Slack)
    2. 生成 Terraform 代碼 (Claude Opus)
    3. 多層驗證 (tflint, checkov, terraform validate)
    4. 成本估算 (Infracost API)
    5. 生成 PR + 自動分配審核人
    6. 監控部署進度
    7. 生成報告
    """
    
    def __init__(self):
        self.claude_client = Anthropic(api_key=CLAUDE_API_KEY)
        self.github_client = Github(GITHUB_TOKEN)
        self.aws_client = boto3.client('ec2', region_name='us-west-2')
        self.infracost_api = InfracostAPIClient(INFRACOST_API_KEY)
    
    async def process_infrastructure_request(self, requirement: str, channel: str = "github"):
        """
        處理基礎設施搭建需求
        
        需求範例：
        "在 us-west-2 region 建立一個用於測試的 RDS MySQL 8.0 資料庫，
        使用 db.t3.medium 實例，20GB 存儲，啟用自動備份，
        預估月成本不超過 $50"
        """
        
        # Step 1: 理解需求
        understanding = await self._understand_requirement(requirement)
        # {
        #   "resource_type": "rds",
        #   "engine": "mysql",
        #   "instance_class": "db.t3.medium",
        #   "storage_gb": 20,
        #   "region": "us-west-2",
        #   "purpose": "testing",
        #   "cost_limit": 50
        # }
        
        # Step 2: 生成 Terraform 代碼
        terraform_files = await self._generate_terraform(understanding)
        # {
        #   "main.tf": "...",
        #   "variables.tf": "...",
        #   "outputs.tf": "..."
        # }
        
        # Step 3: 多層驗證
        validation_result = await self._validate_terraform(terraform_files)
        # {
        #   "syntax": "passed",
        #   "security": "passed", 
        #   "compliance": "passed"
        # }
        
        if not validation_result["all_passed"]:
            # 自動修復
            terraform_files = await self._auto_fix_terraform(
                terraform_files, 
                validation_result["errors"]
            )
        
        # Step 4: 成本估算
        cost_estimate = await self._estimate_cost(terraform_files)
        # {
        #   "monthly": 45.50,
        #   "yearly": 546,
        #   "breakdown": {"compute": 30, "storage": 15.50}
        # }
        
        # Step 5: 生成 PR
        pr = await self._create_pull_request(
            terraform_files,
            understanding,
            cost_estimate,
            channel
        )
        
        # Step 6: 根據 Phase，決定是否自動批准
        if self.phase == "phase_3":
            # Phase 3: 完全自主 (Dev/Staging)
            if pr.labels.get("environment") != "production":
                await self._auto_approve_and_deploy(pr)
        
        return {
            "status": "success",
            "pr_url": pr.html_url,
            "cost_estimate": cost_estimate,
            "deployment_status": "awaiting_approval" if self.phase in ["phase_1", "phase_2"] else "deploying"
        }
    
    async def _generate_terraform(self, understanding: dict) -> dict:
        """
        使用 Claude Opus 生成 Terraform 代碼
        """
        
        system_prompt = """
        你是 AWS Terraform 專家。根據需求生成生產級的 Terraform 代碼。
        
        要求：
        1. 遵循 AWS/Terraform 最佳實踐 (tagging, encryption, backups)
        2. 包含完整的變數定義與輸出
        3. 實施最少權限原則 (IAM, Security Groups)
        4. 考慮成本優化 (如適當的實例類型)
        5. 生成格式必須能直接驗證 (terraform validate)
        """
        
        prompt = f"""
        基礎設施需求：
        {json.dumps(understanding, indent=2, ensure_ascii=False)}
        
        請生成完整的 Terraform 配置，包括 main.tf、variables.tf 和 outputs.tf。
        """
        
        response = self.claude_client.messages.create(
            model="claude-opus-4-8",
            max_tokens=4000,
            system=system_prompt,
            messages=[{"role": "user", "content": prompt}]
        )
        
        return self._parse_terraform_blocks(response.content[0].text)
    
    async def _validate_terraform(self, files: dict) -> dict:
        """
        多層驗證：tflint + checkov + terraform validate
        """
        
        import tempfile
        import subprocess
        
        with tempfile.TemporaryDirectory() as tmpdir:
            # 寫入文件
            for filename, content in files.items():
                with open(f"{tmpdir}/{filename}", "w") as f:
                    f.write(content)
            
            errors = []
            warnings = []
            
            # 1. terraform validate (語法檢查)
            result = subprocess.run(
                ["terraform", "validate"],
                cwd=tmpdir,
                capture_output=True,
                text=True
            )
            if result.returncode != 0:
                errors.append(f"Terraform validation failed:\n{result.stderr}")
            
            # 2. tflint (風格 + 最佳實踐)
            result = subprocess.run(
                ["tflint", "--init", "--backend=false"],
                cwd=tmpdir,
                capture_output=True
            )
            result = subprocess.run(
                ["tflint", "."],
                cwd=tmpdir,
                capture_output=True,
                text=True
            )
            if result.stdout:
                warnings.append(f"tflint suggestions:\n{result.stdout}")
            
            # 3. checkov (安全掃描)
            result = subprocess.run(
                ["checkov", "-d", tmpdir, "--framework", "terraform"],
                capture_output=True,
                text=True
            )
            if "failed checks" in result.stdout.lower():
                errors.append(f"Checkov security scan failed:\n{result.stdout}")
        
        return {
            "all_passed": len(errors) == 0,
            "errors": errors,
            "warnings": warnings,
            "syntax": "passed" if len([e for e in errors if "Terraform validation" in e]) == 0 else "failed",
            "security": "passed" if len([e for e in errors if "Checkov" in e]) == 0 else "failed"
        }
    
    async def _estimate_cost(self, terraform_files: dict) -> dict:
        """
        使用 Infracost API 估算成本
        """
        
        # 生成 Infracost 配置
        infracost_config = {
            "terraform_dir": ".",
            "format": "json"
        }
        
        # 調用 Infracost API
        response = self.infracost_api.breakdown(
            terraform_dir=".",
            format="json"
        )
        
        # 解析結果
        monthly_cost = response["breakdown"]["total_monthly_cost"]
        breakdown = {
            k: v["monthly_cost"] 
            for k, v in response["breakdown"]["resources"].items()
        }
        
        return {
            "monthly": monthly_cost,
            "yearly": monthly_cost * 12,
            "breakdown": breakdown,
            "currency": "USD"
        }
    
    async def _create_pull_request(self, terraform_files: dict, understanding: dict, 
                                   cost_estimate: dict, channel: str) -> object:
        """
        在 GitHub 建立 PR，附帶完整的變更說明
        """
        
        # 構建 PR 描述
        pr_body = f"""
# Infrastructure Change Request

## Request Details
{self._format_understanding(understanding)}

## Cost Estimation
- **Monthly Cost**: ${cost_estimate['monthly']:.2f}
- **Yearly Cost**: ${cost_estimate['yearly']:.2f}
- **Breakdown**: {json.dumps(cost_estimate['breakdown'], indent=2)}

## Terraform Files
{self._format_terraform_preview(terraform_files)}

## Approval Status
- Phase: {self.phase}
- Auto-approval: {'Yes' if self.phase == 'phase_3' and understanding.get('environment') != 'production' else 'No'}
- Requires Manual Approval: {understanding.get('environment') == 'production' or self.phase in ['phase_1', 'phase_2']}

## Deployment Timeline
```
IF APPROVED:
  → terraform plan (cost verification)
  → terraform apply (infrastructure provisioning)
  → CloudFormation stack creation
  → Terraform state storage to S3
  → Output values exported to Slack
```
        """
        
        # 建立分支
        branch_name = f"infra/auto-{understanding['resource_type']}-{int(time.time())}"
        
        # 提交代碼到分支
        repo = self.github_client.get_repo("sp1050107-zbot/zbot-aws")
        # ... git push logic ...
        
        # 建立 PR
        pr = repo.create_pull(
            title=f"🏗️ Auto-Infrastructure: {understanding['resource_type']} in {understanding.get('region', 'default')}",
            body=pr_body,
            head=branch_name,
            base="main",
            labels=[
                "infrastructure",
                understanding.get('environment', 'unknown'),
                f"cost-${int(cost_estimate['monthly'])}"
            ]
        )
        
        # 自動分配審核人
        if self.phase == "phase_1":
            pr.add_to_assignees(SENIOR_DEVOPS_ENGINEER)
        
        # 發送 Slack 通知
        await self._send_slack_notification({
            "channel": channel if channel == "slack" else "#devops-automation",
            "text": f"🏗️ 新的基礎設施變更需要審批",
            "blocks": [
                {
                    "type": "section",
                    "text": {
                        "type": "mrkdwn",
                        "text": f"*Infrastructure Request*\n{understanding['purpose']}\n\n*Estimated Cost*: ${cost_estimate['monthly']:.2f}/month"
                    }
                },
                {
                    "type": "actions",
                    "elements": [
                        {
                            "type": "button",
                            "text": {"type": "plain_text", "text": "Review PR"},
                            "url": pr.html_url
                        },
                        {
                            "type": "button",
                            "text": {"type": "plain_text", "text": "Approve"},
                            "value": pr.number,
                            "action_id": "approve_infra_pr"
                        }
                    ]
                }
            ]
        })
        
        return pr
    
    async def _auto_approve_and_deploy(self, pr: object):
        """
        Phase 3: 自動批准並部署 (Dev/Staging only)
        """
        
        # 批准 PR
        pr.create_review(event="APPROVE", body="✅ Auto-approved by Infrastructure Agent (Phase 3)")
        
        # 觸發 CI/CD 管線
        # ... GitHub Actions / GitLab CI logic ...
        
        # 監控部署進度
        deployment_status = await self._monitor_deployment(pr)
        
        return deployment_status
```

### 工具鏈生態整合

```yaml
# infrastructure-agent-toolkit.yaml

tools:
  code_generation:
    - Claude Opus 4-8 (Terraform 代碼生成)
    - GPT-4o (備用)

  validation:
    - terraform validate (語法檢查)
    - tflint v0.48+ (風格 + 最佳實踐)
    - checkov v3.0+ (安全掃描)
    - terrascan (合規檢查)

  cost_estimation:
    - Infracost API (實時成本計算)
    - AWS Pricing API (基準數據)
    - Custom Cost Model (公司內部折扣)

  deployment:
    - Terraform CLI v1.6+
    - AWS CLI v2
    - GitHub Actions (CI/CD)
    - CloudFormation (IaC 備用)

  monitoring:
    - AWS Cost Explorer API
    - CloudWatch (資源監控)
    - CloudTrail (審計)

  notification:
    - Slack API (PR 提議 + 批准)
    - GitHub API (自動評論)
    - Email (成本超預算告警)
```

---

## 2️⃣ 安全治理層 (Security Agent)

### 漏洞與威脅自動化應對

```python
# src/agents/security_agent.py

class SecurityAgent:
    """
    安全治理層 AI Agent
    
    工作流：
    1. 監聽 CVE 數據庫 + 安全公告
    2. 分析企業影響範圍
    3. 自動生成 WAF 規則 + IAM 策略
    4. 測試驗證 (Staging)
    5. 自動部署 (Production)
    6. 審計日誌追蹤
    7. 合規報告生成
    """
    
    async def handle_zero_day_threat(self, cve_info: dict):
        """
        應對 0-day 漏洞
        
        範例 CVE：
        {
            "id": "CVE-2024-12345",
            "title": "Log4j Remote Code Execution",
            "severity": "CRITICAL",
            "affected_software": ["apache-log4j:2.0-2.19"],
            "fix_available": false,
            "workaround": "Disable JNDI in logging configuration"
        }
        """
        
        # Step 1: 分析企業受影響範圍
        impact = await self._analyze_impact(cve_info)
        # {
        #   "affected_services": ["zbot-trading", "zbot-aladdin"],
        #   "affected_regions": ["us-west-2", "ap-northeast-1"],
        #   "data_at_risk": "user_credentials, trading_data"
        # }
        
        if impact["severity"] == "CRITICAL":
            # Step 2: 立即生成 WAF 規則
            waf_rules = await self._generate_waf_rules(cve_info)
            # 例：阻止所有帶有 JNDI lookup 的請求
            # rule: "contains(body, 'jndi:')  → block"
            
            # Step 3: 在 Staging 環境測試
            test_result = await self._test_waf_rules(waf_rules, environment="staging")
            
            if test_result["false_positives"] < 0.01:  # < 0.01% 誤殺率
                # Step 4: 自動部署到 Production
                await self._deploy_waf_rules(waf_rules, environment="production")
                
                # Step 5: 監控部署效果
                await self._monitor_waf_deployment(waf_rules, cve_info)
    
    async def _generate_waf_rules(self, cve_info: dict) -> list:
        """
        使用 Claude 生成 Cloudflare WAF 規則
        """
        
        system_prompt = """
        你是 Cloudflare WAF 安全專家。根據 CVE 信息生成對應的 WAF 規則表達式。
        
        Cloudflare WAF 表達式格式：
        - http.request.body.string contains "malicious_pattern"
        - cf.threat_score > 50
        - ip.geoip.country == "CN"
        - (http.request.uri.path contains "/admin" and http.request.method == "POST")
        
        要求：
        1. 生成最小化誤殺的規則
        2. 考慮合法用戶的使用情況
        3. 規則應該可立即生效
        """
        
        prompt = f"""
        CVE 信息：
        {json.dumps(cve_info, indent=2, ensure_ascii=False)}
        
        請生成對應的 Cloudflare WAF 規則，以及簡短的說明。
        """
        
        response = self.claude_client.messages.create(
            model="claude-opus-4-8",
            max_tokens=2000,
            system=system_prompt,
            messages=[{"role": "user", "content": prompt}]
        )
        
        # 解析 WAF 規則 (JSON 格式)
        waf_rules = self._parse_waf_rules(response.content[0].text)
        return waf_rules
    
    async def monitor_iam_anomalies(self):
        """
        持續監控 IAM 異常：
        1. 過度授權的帳號
        2. 異地登錄 (5 分鐘內不同國家)
        3. 未使用的 API 密鑰
        """
        
        # 1. 查詢 CloudTrail 事件
        events = await self._query_cloudtrail({
            "event_names": ["CreateAccessKey", "PutUserPolicy", "AttachUserPolicy"],
            "time_range": "last_7_days"
        })
        
        # 2. 分析過度授權
        overprovisioned = await self._identify_overprovisioned_iam(events)
        # {
        #   "user": "engineer_alice",
        #   "current_permissions": ["RDS:*", "DynamoDB:*", "EC2:*", ...],
        #   "used_permissions": ["RDS:DescribeDBInstances", "EC2:DescribeInstances"],
        #   "unused_days": 30,
        #   "recommendation": "Reduce to RDS:Read + EC2:Read"
        # }
        
        # 3. 自動發起 PR 縮減權限
        for user_finding in overprovisioned:
            pr = await self._create_iam_reduction_pr(user_finding)
            await self._notify_user_manager(user_finding, pr)
    
    async def rotate_secrets_automatically(self):
        """
        自動密鑰輪轉 (每季度)
        """
        
        secrets = self.secrets_manager_client.list_secrets()
        
        for secret in secrets['SecretList']:
            # 檢查輪轉週期
            last_rotated = secret['LastRotatedDate']
            days_since_rotation = (datetime.now() - last_rotated).days
            
            if days_since_rotation > 90:  # 每季度
                # 生成新密鑰
                new_secret = await self._generate_new_secret(secret)
                
                # 更新應用配置 (無停機)
                await self._update_app_config_secret(secret['Name'], new_secret)
                
                # 驗證新密鑰有效
                if await self._verify_secret_works(new_secret):
                    # 存檔舊密鑰
                    await self._archive_old_secret(secret['Name'])
                    
                    # 通知團隊
                    await self._notify_secret_rotation(secret['Name'])
```

---

## 3️⃣ 運維可靠性層 (SRE Agent)

### 自動故障診斷與自癒

```python
# src/agents/sre_agent.py

class SREAgent:
    """
    SRE 可靠性層 AI Agent
    
    工作流：
    1. 接收告警（Datadog/Prometheus）
    2. 告警聚合與降噪
    3. 根據 Runbook 自動診斷
    4. 執行自癒指令
    5. 監控修復效果
    6. 生成事後分析報告
    """
    
    async def handle_alert(self, alert: dict):
        """
        處理告警事件
        
        告警範例：
        {
            "alert_id": "alert_12345",
            "service": "zbot-trading",
            "metric": "eks_node_oom",
            "value": 95,  # 95% 記憶體使用率
            "severity": "CRITICAL",
            "timestamp": "2024-01-15T14:32:00Z"
        }
        """
        
        # Step 1: 告警去重 (5 分鐘內同類告警聚合)
        deduped_alert = await self._deduplicate_alert(alert)
        
        if not deduped_alert["is_new_incident"]:
            return  # 已存在相同事件，跳過
        
        # Step 2: 查找對應的 Runbook
        runbook = await self._find_runbook(alert)
        # {
        #   "id": "runbook_eks_oom",
        #   "title": "EKS Node Out of Memory",
        #   "diagnosis_steps": [...],
        #   "remediation_steps": [...]
        # }
        
        # Step 3: 自動診斷
        diagnosis = await self._run_diagnosis(alert, runbook)
        # {
        #   "root_cause": "Pod memory leak in zbot-trading service",
        #   "affected_pods": ["trading-replica-0", "trading-replica-1"],
        #   "recommended_action": "restart_pod"
        # }
        
        # Step 4: 執行自動修復
        remediation = await self._execute_remediation(diagnosis, runbook)
        
        # Step 5: 驗證修復效果
        if await self._verify_fix(alert, remediation):
            # Step 6: 生成事後分析
            rca = await self._generate_rca(alert, diagnosis, remediation)
        else:
            # 修復失敗，升級人工處理
            await self._escalate_to_oncall(alert, diagnosis, remediation)
    
    async def _execute_remediation(self, diagnosis: dict, runbook: dict) -> dict:
        """
        根據診斷結果執行自動修復
        """
        
        remediation_log = []
        
        # 獲取建議的行動
        action = diagnosis.get("recommended_action")
        
        if action == "restart_pod":
            # kubectl rollout restart deployment/zbot-trading
            result = subprocess.run(
                [
                    "kubectl", "rollout", "restart",
                    f"deployment/{diagnosis['affected_service']}"
                ],
                capture_output=True,
                text=True
            )
            remediation_log.append({
                "action": "pod_restart",
                "status": "success" if result.returncode == 0 else "failed",
                "output": result.stdout
            })
        
        elif action == "scale_out":
            # 水平擴容 (增加副本)
            current_replicas = await self._get_current_replicas(
                diagnosis['affected_service']
            )
            new_replicas = current_replicas + 2
            
            result = subprocess.run(
                [
                    "kubectl", "scale", "deployment",
                    diagnosis['affected_service'],
                    f"--replicas={new_replicas}"
                ],
                capture_output=True,
                text=True
            )
            remediation_log.append({
                "action": "scale_out",
                "from_replicas": current_replicas,
                "to_replicas": new_replicas,
                "status": "success" if result.returncode == 0 else "failed"
            })
        
        elif action == "scale_instance_type":
            # AWS Auto Scaling Group 調整
            asg_name = diagnosis.get("asg_name")
            current_instance_type = await self._get_asg_instance_type(asg_name)
            new_instance_type = self._upgrade_instance_type(current_instance_type)
            
            result = await self._update_asg_instance_type(asg_name, new_instance_type)
            remediation_log.append({
                "action": "upgrade_instance_type",
                "from": current_instance_type,
                "to": new_instance_type,
                "status": "success" if result else "failed"
            })
        
        return {
            "remediation_log": remediation_log,
            "total_actions": len(remediation_log),
            "success_count": sum(1 for log in remediation_log if log["status"] == "success")
        }
    
    async def _generate_rca(self, alert: dict, diagnosis: dict, remediation: dict) -> dict:
        """
        自動生成事後分析報告 (5 分鐘內)
        
        使用 Claude 串聯事件時間線、根因、修復過程，生成結構化 RCA 報告
        """
        
        # 收集事件相關信息
        timeline = await self._collect_event_timeline(alert)
        # {
        #   "alert_triggered": "2024-01-15T14:32:00Z",
        #   "diagnosis_completed": "2024-01-15T14:34:15Z",
        #   "remediation_started": "2024-01-15T14:34:20Z",
        #   "service_recovered": "2024-01-15T14:36:45Z"
        # }
        
        logs = await self._fetch_pod_logs(diagnosis['affected_pods'])
        metrics = await self._fetch_metrics(alert, time_range="5m")
        
        # 使用 Claude 分析根因
        rca_content = await self._analyze_rca_with_claude(
            timeline, 
            diagnosis, 
            remediation,
            logs,
            metrics
        )
        
        rca_report = {
            "incident_id": alert['alert_id'],
            "title": f"RCA: {alert['service']} {alert['metric']}",
            "severity": alert['severity'],
            "timeline": timeline,
            "root_cause": rca_content['root_cause'],
            "impact_analysis": {
                "affected_users": rca_content['affected_users'],
                "data_integrity": rca_content['data_integrity_status'],
                "error_rate_spike": rca_content['error_rate_increase']
            },
            "remediation_summary": remediation,
            "preventive_measures": rca_content['preventive_recommendations'],
            "generated_by": "SRE Agent",
            "generated_at": datetime.utcnow().isoformat()
        }
        
        # 保存到 Notion
        await self._save_rca_to_notion(rca_report)
        
        # 發送到 Slack
        await self._send_rca_to_slack(rca_report)
        
        return rca_report
```

---

## 4️⃣ 應用發版層 (Release Agent)

### 智能金絲雀發佈 + 自動回滾

```python
# src/agents/release_agent.py

class ReleaseAgent:
    """
    應用發版層 AI Agent
    
    工作流：
    1. 監聽新版本 (Docker image tag)
    2. 編寫 Argo CD Application Manifest
    3. 定義金絲雀發佈策略
    4. 執行漸進式發佈 (1% → 10% → 50% → 100%)
    5. 監控關鍵指標 (5xx error, latency, logs)
    6. 智能品質門控 + 自動回滾
    7. 生成發版報告
    """
    
    async def deploy_new_version(self, image_info: dict, release_notes: str):
        """
        部署新版本
        
        image_info:
        {
            "repository": "zbot/trading",
            "tag": "v1.2.3",
            "digest": "sha256:abc123...",
            "build_time": "2024-01-15T10:00:00Z",
            "builder": "github-actions"
        }
        """
        
        # Step 1: 生成 Argo CD Manifest
        argocd_manifest = await self._generate_argocd_manifest(image_info)
        # {
        #   "apiVersion": "argoproj.io/v1alpha1",
        #   "kind": "Application",
        #   "metadata": {"name": "zbot-trading-canary"},
        #   "spec": {
        #     "source": {"repoURL": "...", "path": "..."},
        #     "destination": {"server": "...", "namespace": "zbot"},
        #     "syncPolicy": {"automated": {"prune": true}}
        #   }
        # }
        
        # Step 2: 建立金絲雀發佈計劃
        canary_plan = {
            "stages": [
                {"percentage": 1, "duration_minutes": 5, "max_5xx_rate": 0.1},
                {"percentage": 10, "duration_minutes": 10, "max_5xx_rate": 0.15},
                {"percentage": 50, "duration_minutes": 15, "max_5xx_rate": 0.2},
                {"percentage": 100, "duration_minutes": 0, "max_5xx_rate": 0.25}
            ]
        }
        
        # Step 3: 應用 Canary Manifest
        await self._apply_argocd_manifest(argocd_manifest, stage=1)
        
        # Step 4: 監控第一階段
        stage_result = await self._monitor_canary_stage(
            image_info,
            current_stage=1,
            plan=canary_plan
        )
        
        if stage_result["quality_passed"]:
            # 進行下一階段
            for stage_num in range(2, len(canary_plan["stages"]) + 1):
                await self._apply_argocd_manifest(argocd_manifest, stage=stage_num)
                
                stage_result = await self._monitor_canary_stage(
                    image_info,
                    current_stage=stage_num,
                    plan=canary_plan
                )
                
                if not stage_result["quality_passed"]:
                    # 品質門控失敗，自動回滾
                    await self._auto_rollback(image_info, stage_num)
                    break
        else:
            # 第一階段就失敗，立即回滾
            await self._auto_rollback(image_info, 1)
    
    async def _monitor_canary_stage(self, image_info: dict, current_stage: int, plan: dict) -> dict:
        """
        監控金絲雀發佈的每個階段
        
        關鍵指標：
        - HTTP 5xx 錯誤率
        - P99 延遲
        - Pod 重啟次數
        - 異常日誌
        """
        
        stage_config = plan["stages"][current_stage - 1]
        traffic_percentage = stage_config["percentage"]
        max_5xx_rate = stage_config["max_5xx_rate"]
        
        # 從 Cloudflare Analytics 和 Prometheus 收集指標
        metrics = await self._collect_deployment_metrics(
            image_info['repository'],
            image_info['tag'],
            time_range=f"{stage_config['duration_minutes']}m"
        )
        # {
        #   "5xx_error_rate": 0.05,
        #   "p99_latency_ms": 250,
        #   "pod_restarts": 0,
        #   "error_logs": [...]
        # }
        
        # 與舊版本比較
        old_version_metrics = await self._get_old_version_metrics(
            image_info['repository']
        )
        # {
        #   "5xx_error_rate": 0.02,
        #   "p99_latency_ms": 180
        # }
        
        # 品質門控判定
        quality_check = {
            "passed": True,
            "checks": {}
        }
        
        # 檢查 1: 5xx 錯誤率是否合理
        error_rate_increase = metrics["5xx_error_rate"] - old_version_metrics["5xx_error_rate"]
        if error_rate_increase > 0.005:  # 增加 > 0.5%
            quality_check["checks"]["5xx_rate"] = "FAILED"
            quality_check["passed"] = False
        else:
            quality_check["checks"]["5xx_rate"] = "PASSED"
        
        # 檢查 2: 延遲是否可接受
        latency_increase = metrics["p99_latency_ms"] - old_version_metrics["p99_latency_ms"]
        if latency_increase > 50:  # 增加 > 50ms
            quality_check["checks"]["latency"] = "FAILED"
            quality_check["passed"] = False
        else:
            quality_check["checks"]["latency"] = "PASSED"
        
        # 檢查 3: Pod 是否頻繁重啟
        if metrics["pod_restarts"] > 2:
            quality_check["checks"]["pod_stability"] = "FAILED"
            quality_check["passed"] = False
        else:
            quality_check["checks"]["pod_stability"] = "PASSED"
        
        # 檢查 4: 是否有異常日誌 (ERROR, PANIC)
        if await self._detect_error_logs(metrics["error_logs"]):
            quality_check["checks"]["error_logs"] = "FAILED"
            quality_check["passed"] = False
        else:
            quality_check["checks"]["error_logs"] = "PASSED"
        
        return {
            "stage": current_stage,
            "traffic_percentage": traffic_percentage,
            "metrics": metrics,
            "quality_passed": quality_check["passed"],
            "quality_checks": quality_check["checks"],
            "recommendation": "proceed_to_next_stage" if quality_check["passed"] else "rollback"
        }
    
    async def _auto_rollback(self, image_info: dict, failed_stage: int):
        """
        自動回滾
        """
        
        # 回滾指令
        rollback_cmd = f"""
        kubectl set image deployment/zbot-trading \
            trading={self.previous_image_tag} \
            --namespace=zbot
        """
        
        result = subprocess.run(rollback_cmd, shell=True, capture_output=True, text=True)
        
        # 驗證回滾成功
        if await self._verify_rollback_success():
            # 生成回滾報告
            rollback_report = {
                "version_attempted": image_info["tag"],
                "failed_at_stage": failed_stage,
                "rollback_time": datetime.utcnow().isoformat(),
                "reason": "Quality gate failed: 5xx error rate spike > 0.5%",
                "status": "completed"
            }
            
            # 發送到 GitHub PR
            await self._post_rollback_report_to_github(image_info, rollback_report)
            
            # 發送到 Slack
            await self._send_rollback_alert_to_slack(image_info, rollback_report)
            
            # 鎖定發版管線 (需人工檢查)
            await self._lock_release_pipeline(image_info['repository'])
```

---

## 🔄 漸進式放權三階段策略

### Phase 1: AI 提議，人類確認 (0-4 週)

```
基礎設施層：
  ├─ Agent 生成 Terraform PR
  ├─ Agent 計算成本預估
  └─ ⏸️ 等待 Slack "Approve" 按鈕

安全治理層：
  ├─ Agent 掃描漏洞，生成 WAF 規則
  ├─ Agent 在 Staging 測試
  └─ ⏸️ 等待人類在 Slack 確認部署到 Prod

SRE 可靠性層：
  ├─ Agent 自動診斷告警
  ├─ Agent 生成 Runbook 建議
  └─ ⏸️ 等待 On-Call 批准執行修復

應用發版層：
  ├─ Agent 生成金絲雀發佈計劃
  ├─ Agent 發佈 1% 流量，監控指標
  └─ ⏸️ 等待 Release Manager 批准進階

決策點（CTO Dashboard）：
  - "Approve Infrastructure" button
  - "Deploy WAF Rule to Prod" button
  - "Execute Remediation" button
  - "Promote to Next Stage" button
```

**工具支持**：Slack Workflow + GitHub Approve Button

---

### Phase 2: 唯讀自動化，完全透明 (4-8 週)

```
完全自動化：
  ├─ 監控 ✅ (成本、告警、漏洞、發版指標)
  ├─ 報告生成 ✅ (日報、周報、RCA)
  └─ 建議 ✅ (縮減 IAM、更新依賴、優化成本)

仍需人工決策：
  ├─ ⏸️ 部署到 Production (基礎設施)
  ├─ ⏸️ 發佈到 100% 流量 (應用發版)
  └─ ⏸️ 執行危險操作 (密鑰輪轉、刪除資源)

CTO Dashboard 變化：
  - 實時 KPI 儀表板 (自動更新)
  - AI 建議列表 (按優先級排序)
  - 需要人工決策的項目 (清晰標記)
  - 自動化節省 (成本、時間、防止故障)

報告頻率：
  - Daily Report @ 9 AM
  - Weekly Executive Summary
  - Monthly Compliance Report
```

**關鍵監控**：Agent 的建議準確率，如果 > 95% 就可進入 Phase 3

---

### Phase 3: 完全自主運維 (8-12 週+)

```
完全自主運維 (Dev/Staging)：
  ├─ ✅ 自動部署基礎設施
  ├─ ✅ 自動生成 WAF 規則並上線
  ├─ ✅ 自動修復故障
  ├─ ✅ 自動發佈應用 (1% → 100%)
  └─ ✅ 自動回滾失敗發佈

受限自主運維 (Production)：
  ├─ ✅ 自動監控 + 告警聚合
  ├─ ✅ 自動診斷 + 建議
  ├─ ⏸️ 部署基礎設施 → 需批准
  ├─ ⏸️ 應用發佈 1% 流量 → 需批准
  ├─ ⏸️ 進階到 10%+ 流量 → 自動（若品質通過）
  └─ ✅ 緊急安全修復 → 自動 (事後通知)

Approval 邏輯：
  if environment == "production":
    if operation in ["deploy_infrastructure", "canary_1_percent"]:
      require_approval(CTO_OR_VP_ENGINEERING)
    elif operation in ["canary_10_percent", "canary_50_percent"]:
      if quality_metrics_passed and cost_within_budget:
        proceed_automatically()
      else:
        require_approval(DevOps_Lead)
    elif operation in ["emergency_waf", "emergency_rollback"]:
      proceed_immediately()
      notify_slack_async()
```

---

## 📊 Phase 轉換條件

| Criteria | Phase 1→2 | Phase 2→3 |
|----------|-----------|-----------|
| **建議準確率** | 已達 80% | > 95% |
| **自動化通過率** | - | > 99% |
| **安全事件** | 0 次誤操作 | 0 次誤操作 (連續 2 週) |
| **成本節省** | > $10k/月 | > $30k/月 |
| **時間投入** | 4 週 | 4 週 |
| **CTO 信心度** | 中 (每個決策審核) | 高 (週報抽檢) |

---

## 🎯 實施時間表

```
Week 1-2:   基礎設施部署 (Agents, Observability, Approval Flow)
Week 3-4:   Phase 1 試運行 (所有 4 層手動批准)
Week 5-6:   監控 Agent 準確率，調整策略
Week 7-8:   轉入 Phase 2 (監控 + 報告完全自動)
Week 9-10:  積累 Phase 2 數據，評估轉移條件
Week 11-12: Phase 3 灰度 (Dev/Staging 完全自主)
Week 13+:   Production 受限自主 + 持續優化
```

---

## 📞 關鍵成功因素 (KSF)

1. **明確的 Approval Flow**
   - Slack 按鈕 + GitHub PR Review + 管理員面板
   - 每個決策都有 audit trail

2. **高品質的 Runbook**
   - AI 生成的初版 Runbook 需要人類驗證與改進
   - 建立 Runbook 評分機制 (準確性、執行時間)

3. **實時可觀測性**
   - 每個 Agent 的決策都有日誌
   - Slack Dashboard 展示當前自動化進度

4. **漸進式信任建立**
   - 不要急著完全放權
   - 監控每個 Phase 的穩定性指標

5. **人工在迴圈中**
   - Phase 1/2 保留充足的人類審批點
   - 建立 Agent 失敗升級機制
   - 定期 CTO 審查自動化決策

---

**文檔完成日期**：2026-07-03  
**下一步**：選定第一層（推薦 SRE 層）進行試點，驗證 Agent 可靠性
