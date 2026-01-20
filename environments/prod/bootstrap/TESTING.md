# Bootstrap 테스트 가이드

## 현재 테스트 가능 상태

Bootstrap Terraform 코드는 **실제 테스트 가능한 상태**입니다.

### 완료된 검증

- **Terraform 코드 문법 검증** 완료
- **Terraform 초기화** 성공
- **Terraform 버전** 확인 (v1.5.7 >= 1.5.0)
- **AWS CLI** 설치 확인
- **코드 포맷팅** 완료
- **S3 Lifecycle 설정** 경고 수정 완료

## 테스트 전 확인 사항

### 1. AWS 자격 증명 설정

```bash
# AWS 자격 증명 확인
aws sts get-caller-identity

# 예상 출력:
# {
#     "UserId": "AIDA...",
#     "Account": "123456789012",
#     "Arn": "arn:aws:iam::123456789012:user/username"
# }
```

### 2. 필요한 AWS 권한

Bootstrap을 실행하기 위해 다음 권한이 필요합니다:

- `s3:CreateBucket`
- `s3:PutBucketVersioning`
- `s3:PutBucketEncryption`
- `s3:PutBucketPublicAccessBlock`
- `s3:PutBucketPolicy`
- `s3:PutBucketLifecycleConfiguration`
- `dynamodb:CreateTable`
- `dynamodb:PutItem`
- `dynamodb:GetItem`
- `dynamodb:DescribeTable`

### 3. S3 버킷 이름

**중요**: S3 버킷 이름은 전역적으로 고유해야 합니다.

```bash
# 설정 파일 준비
cd environments/prod/bootstrap/terraform
cp terraform.tfvars.example terraform.tfvars

# terraform.tfvars 파일에서 수정할 내용:
# state_bucket_name = "your-unique-bucket-name-here"
# 예: "mycompany-aws-security-automation-terraform-state-prod"
```

## 테스트 실행

### 방법 1: Makefile 사용 (권장)

프로젝트 루트 디렉토리에서 실행:

```bash
# 1. Bootstrap 초기화
make bootstrap-init

# 2. 생성 계획 확인 (실제 리소스 생성 전 확인)
make bootstrap-plan

# 3. 실제 리소스 생성
make bootstrap-apply

# 4. 출력값 확인 (Backend 설정에 필요)
make bootstrap-output
```

### 방법 2: 직접 Terraform 명령어 사용

```bash
cd environments/prod/bootstrap/terraform

# 1. 설정 파일 준비
cp terraform.tfvars.example terraform.tfvars
# terraform.tfvars 파일 수정 (state_bucket_name 필수!)

# 2. Terraform 초기화
terraform init

# 3. 생성 계획 확인
terraform plan -var-file=terraform.tfvars

# 4. 실제 리소스 생성
terraform apply -var-file=terraform.tfvars

# 5. 출력값 확인
terraform output
```

## 예상 결과

### `terraform plan` 실행 시

다음 리소스들이 생성될 예정임을 확인할 수 있습니다:

- `aws_s3_bucket.terraform_state` (1개)
- `aws_s3_bucket_versioning.terraform_state` (1개)
- `aws_s3_bucket_server_side_encryption_configuration.terraform_state` (1개)
- `aws_s3_bucket_public_access_block.terraform_state` (1개)
- `aws_s3_bucket_policy.terraform_state` (1개)
- `aws_s3_bucket_lifecycle_configuration.terraform_state` (1개, 선택적)
- `aws_dynamodb_table.terraform_state_lock` (1개)

**총 예상 리소스**: 6-7개

### `terraform apply` 성공 시

다음 출력값들을 확인할 수 있습니다:

```bash
# Makefile 사용
make bootstrap-output

# 또는 직접 실행
cd environments/prod/bootstrap/terraform
terraform output
```

예상 출력:
- `state_bucket_name`: 생성된 S3 버킷 이름 (Backend 설정에 사용)
- `state_bucket_arn`: 생성된 S3 버킷 ARN
- `dynamodb_table_name`: 생성된 DynamoDB 테이블 이름 (Backend 설정에 사용)
- `dynamodb_table_arn`: 생성된 DynamoDB 테이블 ARN
- `backend_config`: Backend 설정에 필요한 모든 값들 (객체)
- `backend_config_example`: Backend 설정 예제 코드 (문자열)

## 주의사항

1. **비용**: DynamoDB는 Pay-per-Request 모드이므로 실제 사용 시에만 비용이 발생합니다 (거의 무료).

2. **S3 버킷 이름**: 전역적으로 고유해야 하므로 이미 사용 중인 이름은 사용할 수 없습니다.

3. **리전**: 설정한 AWS 리전에 리소스가 생성됩니다.

4. **State 파일**: Bootstrap은 로컬 State를 사용하므로 `.terraform.tfstate` 파일이 생성됩니다.

## 문제 해결

### 오류: "Bucket already exists"

S3 버킷 이름이 이미 사용 중입니다. 다른 이름을 사용하세요.

### 오류: "Access Denied"

AWS 자격 증명이 없거나 필요한 권한이 없습니다. IAM 권한을 확인하세요.

### 오류: "Invalid bucket name"

S3 버킷 이름 규칙을 확인하세요:
- 소문자, 숫자, 하이픈(-)만 사용 가능
- 3-63자 사이
- IP 주소 형식 불가
- 점(.)으로 시작하거나 끝날 수 없음

## 테스트 완료 후

Bootstrap이 성공적으로 생성되면:

1. **출력값 확인**:
   ```bash
   make bootstrap-output
   # 또는
   cd environments/prod/bootstrap/terraform
   terraform output
   ```

2. **Backend 설정 활성화**:
   - `environments/prod/terraform/main.tf` 파일 열기
   - backend 설정 주석 해제
   - 출력값 입력 (state_bucket_name, dynamodb_table_name)

3. **State 마이그레이션**:
   ```bash
   cd environments/prod/terraform
   terraform init -migrate-state
   ```

4. **실제 인프라 배포 진행**:
   - `environments/prod/config/terraform.tfvars` 설정
   - `make plan` 및 `make apply` 실행

## 추가 리소스

- Bootstrap 가이드: [README.md](./README.md)
- 프로젝트 전체 가이드: [../../../../README.md](../../../../README.md)
