# 운영 매뉴얼 (Runbooks)

## 배포 프로세스

### 1. 사전 준비
```bash
# AWS CLI 구성 확인
aws sts get-caller-identity

# Terraform 버전 확인
terraform version
```

### 2. 환경 변수 설정
```bash
cd environments/prod/config
cp terraform.tfvars.example terraform.tfvars
# terraform.tfvars 파일 수정
```

### 3. Terraform 초기화
```bash
cd environments/prod/terraform
terraform init
```

### 4. 계획 확인
```bash
terraform plan -var-file=../config/terraform.tfvars
```

### 5. 적용
```bash
terraform apply -var-file=../config/terraform.tfvars
```

## 모니터링

### GuardDuty Findings 확인
```bash
aws guardduty list-findings --detector-id <DETECTOR_ID>
```

### Lambda 함수 로그 확인
```bash
aws logs tail /aws/lambda/<PROJECT_NAME>-ip-blocker --follow
```

### WAF IP Set 확인
```bash
aws wafv2 get-ip-set \
  --scope REGIONAL \
  --id <IP_SET_ID> \
  --name <IP_SET_NAME>
```

## 문제 해결

### Lambda 함수가 실행되지 않는 경우
1. CloudWatch Logs 확인
2. Lambda IAM Role 권한 확인
3. EventBridge Rule 상태 확인

### IP가 차단되지 않는 경우
1. WAF IP Set 업데이트 로그 확인
2. Lambda 함수 실행 로그 확인
3. WAF Web ACL 규칙 우선순위 확인

## 롤백 절차

```bash
# 이전 State로 복구
terraform state pull > backup.tfstate
terraform state push backup.tfstate
terraform apply -var-file=../config/terraform.tfvars
```

