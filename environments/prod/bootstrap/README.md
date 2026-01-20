# Terraform Backend Bootstrap

이 디렉토리는 Terraform State 관리를 위한 S3 버킷과 DynamoDB 테이블을 생성합니다.

## 중요 사항

**중요**: 이 bootstrap을 먼저 생성한 후 `../terraform/main.tf`에서 backend 설정을 활성화하세요.

## 사전 요구사항

- Terraform >= 1.5.0
- AWS CLI 구성 완료 (`aws configure` 또는 `aws configure --profile <프로필명>`)
- 적절한 AWS 권한 (S3, DynamoDB 생성 권한)
- AWS 계정 및 Access Key/Secret Key

## 사용 방법

### 1. AWS 프로필 설정 (선택사항)

여러 AWS 계정을 사용하는 경우:

```bash
# 새 프로필 추가
aws configure --profile <프로필명>
# AWS Access Key ID, Secret Access Key, Region (ap-northeast-2), Output format (json) 입력

# 프로필 사용
export AWS_PROFILE=<프로필명>

# 현재 계정 확인
aws sts get-caller-identity
```

### 2. 설정 파일 준비

```bash
cd environments/prod/bootstrap/terraform
cp terraform.tfvars.example terraform.tfvars
```

`terraform.tfvars` 파일을 수정하여 다음 항목을 설정하세요:

- `state_bucket_name`: S3 버킷 이름 (전역적으로 고유해야 함)
  - 예: `your-company-aws-security-automation-terraform-state-prod-<계정ID>`
- `aws_region`: AWS 리전 (기본값: `ap-northeast-2`)
- `environment`: 환경 이름 (기본값: `prod`)

### 3. Bootstrap 리소스 생성

**방법 1: Makefile 사용 (권장)**

```bash
# 프로젝트 루트에서 실행
make bootstrap-init    # Terraform 초기화
make bootstrap-plan    # 생성 계획 확인
make bootstrap-apply   # 리소스 생성 (yes 입력)
make bootstrap-output  # 출력값 확인
```

**방법 2: 직접 Terraform 명령어 사용**

```bash
cd environments/prod/bootstrap/terraform

# Terraform 초기화
terraform init

# 생성 계획 확인
terraform plan -var-file=terraform.tfvars

# 리소스 생성
terraform apply -var-file=terraform.tfvars
```

### 4. Backend 설정 활성화

Bootstrap이 성공적으로 생성된 후:

1. **생성된 리소스 정보 확인**:
   ```bash
   # Makefile 사용
   make bootstrap-output

   # 또는 직접 실행
   cd environments/prod/bootstrap/terraform
   terraform output
   ```

2. **Backend 설정 활성화**:
   `environments/prod/terraform/main.tf` 파일을 열고 backend 설정 주석을 해제한 후 출력값을 입력하세요:

   ```hcl
   terraform {
     backend "s3" {
       bucket         = "<state_bucket_name 출력값>"      # terraform output의 state_bucket_name 사용
       key            = "prod/aws-security-automation/terraform.tfstate"
       region         = "ap-northeast-2"
       dynamodb_table = "<dynamodb_table_name 출력값>"   # terraform output의 dynamodb_table_name 사용
       encrypt        = true
     }
   }
   ```

3. **State 마이그레이션**:
   ```bash
   cd environments/prod/terraform
   terraform init -migrate-state
   # "Migrate state to S3?" 질문에 yes 입력
   ```

이제 Terraform State가 S3에 안전하게 저장됩니다.

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

| 변수명 | 타입 | 필수 | 기본값 | 설명 |
|--------|------|------|--------|------|
| `aws_region` | string | 아니오 | `ap-northeast-2` | AWS 리전 |
| `environment` | string | 아니오 | `prod` | 환경 이름 (dev, staging, prod) |
| `state_bucket_name` | string | **예** | - | S3 버킷 이름 (전역적으로 고유해야 함) |
| `dynamodb_table_name` | string | 아니오 | `terraform-state-lock` | DynamoDB 테이블 이름 |
| `enable_state_lifecycle` | bool | 아니오 | `true` | State 버전 수명 주기 정책 활성화 |
| `state_version_expiration_days` | number | 아니오 | `90` | State 버전 만료일 (일) |
| `enable_dynamodb_point_in_time_recovery` | bool | 아니오 | `true` | DynamoDB Point-in-Time Recovery 활성화 |
| `tags` | map(string) | 아니오 | `{Project = "aws-security-automation"}` | 공통 태그 |

## 출력값

| 출력값 | 설명 |
|--------|------|
| `state_bucket_name` | 생성된 S3 버킷 이름 (Backend 설정에 사용) |
| `state_bucket_arn` | 생성된 S3 버킷 ARN |
| `dynamodb_table_name` | 생성된 DynamoDB 테이블 이름 (Backend 설정에 사용) |
| `dynamodb_table_arn` | 생성된 DynamoDB 테이블 ARN |
| `backend_config` | Backend 설정에 필요한 모든 값들 (객체) |
| `backend_config_example` | Backend 설정 예제 코드 (문자열) |

## 문제 해결

### 오류: "Bucket already exists"
S3 버킷 이름이 이미 사용 중입니다. 다른 이름을 사용하세요.

### 오류: "Access Denied"
AWS 자격 증명이 없거나 필요한 권한이 없습니다. IAM 권한을 확인하세요.

필요한 권한:
- `s3:CreateBucket`, `s3:PutBucketVersioning`, `s3:PutBucketEncryption`
- `s3:PutBucketPublicAccessBlock`, `s3:PutBucketPolicy`
- `s3:PutBucketLifecycleConfiguration`
- `dynamodb:CreateTable`, `dynamodb:PutItem`, `dynamodb:GetItem`, `dynamodb:DescribeTable`

### 오류: "Invalid bucket name"
S3 버킷 이름 규칙을 확인하세요:
- 소문자, 숫자, 하이픈(-)만 사용 가능
- 3-63자 사이
- IP 주소 형식 불가
- 점(.)으로 시작하거나 끝날 수 없음

## 다음 단계

Bootstrap이 성공적으로 생성되면:

1. `terraform output`으로 생성된 리소스 확인
2. `../terraform/main.tf`에서 backend 설정 활성화
3. State 마이그레이션 (`terraform init -migrate-state`)
4. 실제 인프라 배포 진행

자세한 테스트 가이드는 [TESTING.md](./TESTING.md)를 참조하세요.

