# AWS Security Automation Blueprint

## Problem Statement

**기업 환경에서 발생하는 위협을 실시간으로 탐지하고, Terraform과 AWS Native 서비스를 활용해 자동 대응하는 통합 보안 면(Surface) 구축**

## 프로젝트 개요

이 프로젝트는 AWS 환경에서 발생하는 보안 위협을 자동으로 탐지하고 대응하는 통합 보안 자동화 시스템을 Terraform으로 구현합니다. 단순한 인프라 구축을 넘어, 실시간 위협 탐지부터 자동 차단까지의 완전한 보안 자동화 파이프라인을 제공합니다.

## 핵심 기능

### Phase 1: Prevention (예방)
- **WAF v2**: SQL Injection, XSS, Known Bad Inputs 차단
- **CloudFront & ALB**: HTTPS 강제 및 SSL/TLS 인증서 적용
- **Security Groups**: 엄격한 Ingress 제어 (ALB -> EC2만 허용)

### Phase 2: Detection (탐지)
- **GuardDuty**: 실시간 위협 탐지 (무단 침입, Brute Force 등)
- **AWS Config**: 규정 준수 체크 (S3 퍼블릭 액세스, IAM 키 로테이션 등)
- **Security Hub**: 통합 보안 대시보드

### Phase 3: Automation (자동화)
- **실시간 악성 IP 자동 차단 시스템**
  - GuardDuty 탐지 → EventBridge → Lambda → WAFv2 IP Set 업데이트
  - Slack 알림 통합

## 프로젝트 구조

```
aws-security-automation-blueprint/
│
├── README.md                          # 프로젝트 개요 및 사용법
├── Makefile                          # 빌드 및 배포 자동화 스크립트
├── .gitignore                        # Git 제외 파일 목록
├── .terraform-version                # Terraform 버전 고정
│
├── modules/                          # 재사용 가능한 Terraform 모듈
│   ├── vpc/                          # 네트워크 인프라 모듈
│   │   ├── main.tf                   # VPC, Subnets, IGW, NAT Gateway
│   │   ├── variables.tf              # VPC 모듈 변수
│   │   └── outputs.tf                # VPC 모듈 출력
│   │
│   ├── security/                     # 보안 서비스 모듈
│   │   ├── main.tf                   # WAF, Security Groups, GuardDuty, Config, Security Hub
│   │   ├── variables.tf              # Security 모듈 변수
│   │   └── outputs.tf                # Security 모듈 출력
│   │
│   ├── compute/                      # 컴퓨팅 리소스 모듈
│   │   ├── main.tf                   # ALB, CloudFront, Target Groups
│   │   ├── variables.tf              # Compute 모듈 변수
│   │   └── outputs.tf                # Compute 모듈 출력
│   │
│   └── automation/                   # 자동화 파이프라인 모듈
│       ├── main.tf                   # EventBridge, Lambda, IP 차단 로직
│       ├── variables.tf              # Automation 모듈 변수
│       ├── outputs.tf                # Automation 모듈 출력
│       └── lambda_zip/               # Lambda 배포 패키지 (생성됨)
│           └── .gitkeep
│
├── environments/                     # 환경별 배포 설정
│   └── prod/                         # 프로덕션 환경
│       ├── bootstrap/                # State 관리 리소스 (S3/DynamoDB)
│       │   └── terraform/            # Bootstrap Terraform 코드
│       ├── config/                   # 환경별 설정 파일
│       │   └── terraform.tfvars.example # 변수 예시 파일 (terraform.tfvars로 복사하여 사용)
│       └── terraform/                # 실제 Terraform 실행 디렉토리
│           ├── main.tf               # Provider, Variables, 모든 모듈 정의
│           ├── outputs.tf            # 환경별 출력 정의
│           └── variables.tf          # (선택사항) 변수를 별도 파일로 분리 가능
│
└── scripts/                          # 스크립트 및 소스 코드
    ├── lambda/                       # Lambda 함수 소스 코드
    │   ├── ip_blocker.py             # GuardDuty → WAF IP 차단 함수
    │   └── requirements.txt          # Python 의존성
    └── notifications/                # 알림 관련 스크립트 (예정)
```

### 모듈별 역할

#### 1. VPC Module (`modules/vpc/`)
**역할**: 네트워크 기반 인프라 구성
- VPC 및 CIDR 블록 설정
- Public/Private Subnet 생성
- Internet Gateway 및 NAT Gateway
- Route Tables 및 Associations

**주요 리소스**:
- `aws_vpc`
- `aws_subnet` (Public/Private)
- `aws_internet_gateway`
- `aws_nat_gateway`
- `aws_route_table`

#### 2. Security Module (`modules/security/`)
**역할**: 보안 계층 구현 (Prevention & Detection)
- **Prevention**: WAF v2, Security Groups
- **Detection**: GuardDuty, AWS Config, Security Hub

**주요 리소스**:
- `aws_wafv2_web_acl` - 웹 공격 차단 규칙
- `aws_wafv2_ip_set` - IP Block List
- `aws_security_group` - 네트워크 접근 제어
- `aws_guardduty_detector` - 위협 탐지
- `aws_config_configuration_recorder` - 규정 준수 모니터링
- `aws_securityhub_account` - 통합 보안 대시보드

#### 3. Compute Module (`modules/compute/`)
**역할**: 애플리케이션 레이어 구성
- Application Load Balancer (ALB)
- CloudFront Distribution
- SSL/TLS 인증서 관리
- HTTPS 강제 리다이렉트

**주요 리소스**:
- `aws_lb` - Application Load Balancer
- `aws_lb_target_group` - 타겟 그룹
- `aws_lb_listener` - HTTP/HTTPS 리스너
- `aws_cloudfront_distribution` - CDN 및 엣지 보안

#### 4. Automation Module (`modules/automation/`)
**역할**: 실시간 위협 자동 대응 (Phase 3 핵심)
- GuardDuty Finding → EventBridge → Lambda → WAF IP 차단
- Slack 알림 통합

**주요 리소스**:
- `aws_lambda_function` - IP 차단 자동화 함수
- `aws_cloudwatch_event_rule` - GuardDuty 이벤트 캡처
- `aws_cloudwatch_event_target` - Lambda 트리거
- `aws_iam_role` - Lambda 실행 권한

### 주요 파일 설명

#### `environments/prod/terraform/main.tf`
**이 파일이 실제 Terraform 배포의 시작점입니다.**
- Provider 설정 (AWS, Archive)
- 모든 변수 정의
- 모든 모듈 조합 (VPC, Security, Compute, Automation)
- 모듈 간 의존성 관리
- 환경별 특화 설정

**중요**: 모든 Terraform 작업(`terraform init`, `plan`, `apply`)은 이 디렉토리에서 실행합니다.

#### `environments/prod/config/terraform.tfvars`
- 환경별 변수 값 설정
- `.gitignore`에 포함되어 Git에 커밋되지 않음
- `terraform.tfvars.example`을 복사하여 생성

#### `scripts/lambda/ip_blocker.py`
- GuardDuty Finding에서 공격자 IP 추출
- WAF IP Set에 IP 자동 추가
- Slack 알림 전송

#### `Makefile`
- 자주 사용하는 명령어 단축키
- Lambda 패키징 자동화
- 코드 검증 및 포맷팅

### 구조 설계 철학

이 프로젝트는 **환경별로 완전히 분리된 구조**를 사용합니다:

1. **명확한 책임 분리**
   - 루트 레벨: 재사용 가능한 모듈과 공통 리소스만 관리
   - 환경 디렉토리: 실제 배포와 설정만 관리
   - 혼란 제거: 어디서 작업해야 할지 명확함

2. **환경별 독립성**
   - 각 환경(`prod`, `staging`, `dev`)은 완전히 독립적인 Terraform State
   - 환경 간 설정 충돌 방지
   - 안전한 프로덕션 배포

3. **유지보수성**
   - 모듈 수정 시 모든 환경에 자동 반영 가능
   - 환경별 특화 설정은 `terraform.tfvars`로 관리
   - 코드 중복 최소화

## 시작하기

### 사전 요구사항

- Terraform >= 1.5.0
- AWS CLI 구성 완료 (`aws configure` 또는 `aws configure --profile <프로필명>`)
- 적절한 AWS 권한 (IAM, VPC, WAF, GuardDuty, Lambda, EventBridge, S3, DynamoDB 등)
- AWS 계정 및 Access Key/Secret Key

### 사용법

**중요**: 인프라 배포 전에 먼저 **Bootstrap (State 관리 리소스)**을 생성해야 합니다.

**Step 1: AWS 프로필 설정 (선택사항)**

여러 AWS 계정을 사용하는 경우:

```bash
# 새 프로필 추가
aws configure --profile <프로필명>
# AWS Access Key ID, Secret Access Key, Region (ap-northeast-2), Output format (json) 입력

# 프로필 사용
export AWS_PROFILE=<프로필명>
```

**Step 2: Bootstrap 생성 (State 관리를 위한 S3/DynamoDB)**

```bash
# Bootstrap 설정 파일 준비
cd environments/prod/bootstrap/terraform
cp terraform.tfvars.example terraform.tfvars

# terraform.tfvars 파일 수정 (중요!)
# state_bucket_name을 전역적으로 고유한 이름으로 변경
# 예: "your-company-aws-security-automation-terraform-state-prod-<계정ID>"

# Bootstrap 생성
make bootstrap-init
make bootstrap-plan    # 생성될 리소스 확인
make bootstrap-apply   # 실제 생성 (yes 입력)

# Bootstrap 출력값 확인 (Backend 설정에 필요)
make bootstrap-output
```

**참고**: Bootstrap 테스트 가이드는 [environments/prod/bootstrap/TESTING.md](./environments/prod/bootstrap/TESTING.md)를 참조하세요.

**Step 3: Backend 설정 활성화**

Bootstrap이 성공적으로 생성된 후:

```bash
# 1. Bootstrap 출력값 확인
cd environments/prod/bootstrap/terraform
terraform output

# 2. environments/prod/terraform/main.tf 파일 수정
# backend 설정 주석을 해제하고 출력값 입력:
# - bucket: state_bucket_name 출력값
# - dynamodb_table: dynamodb_table_name 출력값
# - region: ap-northeast-2
# - encrypt: true

# 3. State 마이그레이션
cd ../../terraform
terraform init -migrate-state
# "Migrate state to S3?" 질문에 yes 입력
```

**Step 4: 인프라 배포**

```bash
# 1. 설정 파일 준비
cd environments/prod/config
cp terraform.tfvars.example terraform.tfvars

# 2. terraform.tfvars 파일 수정
# 필수 항목:
# - aws_region: "ap-northeast-2"
# - project_name: "aws-security-automation"
# - environment: "prod"
# - vpc_cidr: "10.0.0.0/16"
# - availability_zones: ["ap-northeast-2a", "ap-northeast-2c"]

# 3. 인프라 배포
cd ../terraform

# 방법 1: Makefile 사용 (권장)
make init
make plan    # 생성될 리소스 확인 (비용 확인!)
make apply   # 실제 배포 (yes 입력)

# 방법 2: 직접 Terraform 명령어 사용
terraform plan -var-file=../config/terraform.tfvars
terraform apply -var-file=../config/terraform.tfvars
```

**참고 문서**:
- Bootstrap 가이드: [environments/prod/bootstrap/README.md](./environments/prod/bootstrap/README.md)
- Bootstrap 테스트 가이드: [environments/prod/bootstrap/TESTING.md](./environments/prod/bootstrap/TESTING.md)

### 배포 흐름

1. **AWS 프로필 설정** (선택사항): `aws configure --profile <프로필명>`
2. **Bootstrap 생성**: State 관리 리소스 (S3/DynamoDB) 생성
3. **Backend 설정**: `environments/prod/terraform/main.tf`에서 backend 활성화
4. **환경 설정**: `environments/prod/config/terraform.tfvars` 설정
5. **초기화**: `terraform init` (또는 `make init`)
6. **계획 확인**: `terraform plan` (또는 `make plan`)
7. **배포**: `terraform apply` (또는 `make apply`)

### Makefile 명령어

```bash
# Bootstrap 명령어
make bootstrap-init    # Bootstrap Terraform 초기화
make bootstrap-plan    # Bootstrap 배포 계획 확인
make bootstrap-apply   # Bootstrap 리소스 생성 (S3/DynamoDB)
make bootstrap-output   # Bootstrap 출력값 확인

# 인프라 배포
make init              # Terraform 초기화
make plan              # 배포 계획 확인
make apply             # 인프라 배포
make destroy           # 인프라 삭제
make validate          # Terraform 코드 검증

# 유틸리티
make format            # Terraform 코드 포맷팅
make package-lambda    # Lambda 함수 패키징
make clean             # 빌드 파일 정리
make help              # 도움말 출력
```

### 자동화 플로우

```
GuardDuty Finding (Severity >= Medium)
    ↓
EventBridge Rule
    ↓
Lambda Function (IP Blocker)
    ↓
WAF IP Set 업데이트 (자동 차단)
    ↓
Slack 알림
```

### 주요 컴포넌트

1. **네트워크 레이어 (VPC Module)**
   - VPC 및 서브넷 구성
   - Internet Gateway 및 NAT Gateway
   - 라우팅 테이블

2. **보안 레이어 (Security Module)**
   - WAF v2: 웹 공격 차단
   - Security Groups: 네트워크 액세스 제어
   - GuardDuty: 위협 탐지
   - AWS Config: 규정 준수 모니터링
   - Security Hub: 통합 보안 대시보드

3. **컴퓨팅 레이어 (Compute Module)**
   - Application Load Balancer (ALB)
   - CloudFront Distribution
   - SSL/TLS 인증서 관리

4. **자동화 레이어 (Automation Module)**
   - EventBridge: 이벤트 기반 트리거
   - Lambda: IP 차단 자동화 함수
   - CloudWatch: 로깅 및 모니터링

## 보안 고려사항

- 모든 민감한 값은 Terraform Variables 또는 AWS Secrets Manager를 사용하세요
- `.tfvars` 파일은 Git에 커밋하지 마세요 (`.gitignore`에 포함됨)
- AWS Access Key와 Secret Key는 안전하게 관리하세요
- 프로덕션 환경 배포 전 반드시 스테이징 환경에서 테스트하세요
- S3 버킷 이름은 전역적으로 고유해야 합니다
- Bootstrap 생성 후 반드시 Backend 설정을 활성화하여 State를 안전하게 관리하세요

## 아키텍처

### 아키텍처 다이어그램

프로젝트의 전체 아키텍처 다이어그램은 `architecture.drawio` 파일에 포함되어 있습니다.

**다이어그램 보기**:
- [draw.io](https://app.diagrams.net/) 또는 [VS Code Draw.io Extension](https://marketplace.visualstudio.com/items?itemName=hediet.vscode-drawio)으로 열기
- 파일: `architecture.drawio`

**중요**: draw.io에서 파일을 열 때 AWS 아이콘 라이브러리가 자동으로 로드됩니다. 만약 아이콘이 표시되지 않으면:
1. draw.io에서 "More Shapes" 클릭
2. "AWS" 검색 및 선택
3. AWS 아이콘 라이브러리 활성화

다이어그램에는 다음이 포함됩니다:
- 네트워크 아키텍처 (VPC, Subnets, Internet Gateway, NAT Gateway)
- 보안 계층 (WAF, Security Groups, GuardDuty, Config, Security Hub)
- 컴퓨팅 리소스 (CloudFront, ALB, EC2)
- 자동화 파이프라인 (EventBridge, Lambda, WAF IP Set)
- 알림 시스템 (SNS, Slack, CloudWatch)

### 자동화 플로우

```
GuardDuty Finding (Severity >= Medium)
    ↓
EventBridge Rule
    ↓
Lambda Function (IP Blocker)
    ↓
WAF IP Set 업데이트 (자동 차단)
    ↓
Slack 알림 / SNS 알림
```

### 주요 컴포넌트

1. **네트워크 레이어 (VPC Module)**
   - VPC 및 서브넷 구성
   - Internet Gateway 및 NAT Gateway
   - 라우팅 테이블

2. **보안 레이어 (Security Module)**
   - WAF v2: 웹 공격 차단
   - Security Groups: 네트워크 액세스 제어
   - GuardDuty: 위협 탐지
   - AWS Config: 규정 준수 모니터링
   - Security Hub: 통합 보안 대시보드

3. **컴퓨팅 레이어 (Compute Module)**
   - Application Load Balancer (ALB)
   - CloudFront Distribution
   - SSL/TLS 인증서 관리

4. **자동화 레이어 (Automation Module)**
   - EventBridge: 이벤트 기반 트리거
   - Lambda: IP 차단 자동화 함수
   - CloudWatch: 로깅 및 모니터링

## 유지보수 고려사항

1. **모듈화**: 각 컴포넌트를 독립적인 모듈로 분리하여 재사용성 확보
2. **환경 분리**: 프로덕션/스테이징 환경별로 독립적인 설정 및 State 관리
3. **변수 관리**: 민감한 정보는 `terraform.tfvars`로 관리하고 Git 제외
4. **상태 관리**: S3 Backend 사용 권장 (Bootstrap으로 생성 후 `environments/{env}/terraform/main.tf`에서 설정)
5. **문서화**: 각 모듈의 역할과 의존성을 명확히 문서화
6. **비용 관리**: 테스트 후 불필요한 리소스는 `make destroy`로 삭제

## 테스트

### 빠른 테스트 (Bootstrap만)

```bash
cd environments/prod/bootstrap/terraform
cp terraform.tfvars.example terraform.tfvars
# state_bucket_name 수정
make bootstrap-init
make bootstrap-plan
make bootstrap-apply
```

### 전체 인프라 테스트

1. Bootstrap 생성 (위 단계)
2. Backend 설정 활성화
3. 인프라 배포 (`make apply`)
4. 테스트 완료 후 정리 (`make destroy`)

**주의**: 전체 인프라 배포 시 NAT Gateway, ALB, CloudFront 등으로 인해 비용이 발생합니다. 테스트 후 반드시 삭제하세요.

자세한 테스트 가이드는 [environments/prod/bootstrap/TESTING.md](./environments/prod/bootstrap/TESTING.md)를 참조하세요.

## Security & Detection Services

프로젝트에 포함된 Security 및 Detection 서비스들의 상세 정보는 [SECURITY_SERVICES.md](./SECURITY_SERVICES.md)를 참조하세요.

주요 서비스:
- **WAF v2**: CloudFront에 연결된 웹 애플리케이션 방화벽
- **Security Groups**: VPC 레벨 네트워크 보안 그룹 (ALB, EC2용)
- **GuardDuty**: 계정 레벨 위협 탐지 서비스
- **AWS Config**: 계정 레벨 규정 준수 모니터링
- **Security Hub**: 통합 보안 대시보드

## CI/CD

### GitHub Actions

프로젝트에는 자동화된 보안 스캔을 위한 GitHub Actions 워크플로우가 포함되어 있습니다.

#### Prowler Security Scan

Terraform 파일 변경 시 자동으로 AWS 보안 스캔을 실행합니다.

**워크플로우 파일**: `.github/workflows/prowler.yml`

**트리거 조건**:
- Pull Request: `modules/**/*.tf`, `environments/**/*.tf` 변경 시
- Push to main: 동일 경로 변경 시
- 수동 실행: `workflow_dispatch` 지원

**필요한 GitHub Secrets**:
- `AWS_ACCESS_KEY_ID`: AWS Access Key
- `AWS_SECRET_ACCESS_KEY`: AWS Secret Key

**스캔 결과**:
- JSON, CSV, HTML 형식의 리포트 생성
- Artifacts로 자동 업로드 (30일 보관)
- Critical, High, Medium 심각도 이슈 검사

**설정 방법**:
1. GitHub 저장소 Settings → Secrets and variables → Actions
2. `AWS_ACCESS_KEY_ID` 및 `AWS_SECRET_ACCESS_KEY` 추가
3. 적절한 AWS 권한이 있는 IAM 사용자 사용

## 라이선스

MIT License

## 기여

이슈 및 Pull Request를 환영합니다.

