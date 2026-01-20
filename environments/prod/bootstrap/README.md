# Terraform Backend Bootstrap

이 디렉토리는 Terraform State 관리를 위한 S3 버킷과 DynamoDB 테이블을 생성합니다.

## 중요 사항

**중요**: 이 bootstrap을 먼저 생성한 후 `../terraform/main.tf`에서 backend 설정을 활성화하세요.

## 사용 방법

### 1. 설정 파일 준비

```bash
cd environments/prod/bootstrap/terraform
cp terraform.tfvars.example terraform.tfvars
# terraform.tfvars 파일을 수정하여 state_bucket_name을 설정
```

### 2. Bootstrap 리소스 생성

```bash
# Terraform 초기화
terraform init

# 생성 계획 확인
terraform plan -var-file=terraform.tfvars

# 리소스 생성
terraform apply -var-file=terraform.tfvars
```

### 3. Backend 설정 활성화

Bootstrap이 성공적으로 생성된 후:

1. `terraform output` 명령어로 생성된 리소스 정보 확인:
   ```bash
   terraform output
   ```

2. `../terraform/main.tf`에서 backend 설정 주석 해제 및 수정:
   ```hcl
   terraform {
     backend "s3" {
       bucket         = "your-state-bucket-name"  # output의 state_bucket_name 사용
       key            = "prod/aws-security-automation/terraform.tfstate"
       region         = "ap-northeast-2"
       dynamodb_table = "terraform-state-lock"     # output의 dynamodb_table_name 사용
       encrypt        = true
     }
   }
   ```

3. `../terraform/`에서 `terraform init -migrate-state` 실행하여 state를 S3로 마이그레이션

## 생성되는 리소스

- **S3 버킷**: Terraform State 파일 저장
  - 버전 관리 활성화
  - 서버 측 암호화 (AES256)
  - 퍼블릭 액세스 차단
  - HTTPS 강제 및 TLS 1.2 이상 요구

- **DynamoDB 테이블**: Terraform State Lock 관리
  - Pay-per-Request 모드
  - Point-in-Time Recovery (선택적)
  - 서버 측 암호화

## 변수 설명

- `state_bucket_name` (필수): S3 버킷 이름 (전역적으로 고유해야 함)
- `dynamodb_table_name` (선택): DynamoDB 테이블 이름 (기본값: `terraform-state-lock`)
- `enable_state_lifecycle` (선택): State 버전 수명 주기 정책 활성화 (기본값: `true`)
- `state_version_expiration_days` (선택): State 버전 만료일 (기본값: `90`)

## 출력값

- `state_bucket_name`: 생성된 S3 버킷 이름
- `dynamodb_table_name`: 생성된 DynamoDB 테이블 이름
- `backend_config`: Backend 설정에 필요한 값들
- `backend_config_example`: Backend 설정 예제 코드

