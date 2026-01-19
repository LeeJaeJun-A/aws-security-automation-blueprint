# 프로젝트 구조

## 전체 구조

```
aws-security-automation-blueprint/
│
├── 📄 README.md                          # 프로젝트 개요 및 사용법
├── 📄 PROJECT_STRUCTURE.md              # 이 파일 (프로젝트 구조 설명)
├── 📄 Makefile                          # 빌드 및 배포 자동화 스크립트
├── 📄 .gitignore                        # Git 제외 파일 목록
├── 📄 .terraform-version                # Terraform 버전 고정
│
├── 📁 modules/                          # 재사용 가능한 Terraform 모듈
│   ├── 📁 vpc/                          # 네트워크 인프라 모듈
│   │   ├── main.tf                      # VPC, Subnets, IGW, NAT Gateway
│   │   ├── variables.tf                 # VPC 모듈 변수
│   │   └── outputs.tf                   # VPC 모듈 출력
│   │
│   ├── 📁 security/                     # 보안 서비스 모듈
│   │   ├── main.tf                      # WAF, Security Groups, GuardDuty, Config, Security Hub
│   │   ├── variables.tf                 # Security 모듈 변수
│   │   └── outputs.tf                   # Security 모듈 출력
│   │
│   ├── 📁 compute/                      # 컴퓨팅 리소스 모듈
│   │   ├── main.tf                      # ALB, CloudFront, Target Groups
│   │   ├── variables.tf                 # Compute 모듈 변수
│   │   └── outputs.tf                   # Compute 모듈 출력
│   │
│   └── 📁 automation/                   # 자동화 파이프라인 모듈 ⭐
│       ├── main.tf                      # EventBridge, Lambda, IP 차단 로직
│       ├── variables.tf                 # Automation 모듈 변수
│       ├── outputs.tf                   # Automation 모듈 출력
│       └── 📁 lambda_zip/               # Lambda 배포 패키지 (생성됨)
│           └── .gitkeep
│
├── 📁 environments/                     # 환경별 배포 설정
│   └── 📁 prod/                         # 프로덕션 환경
│       ├── 📁 config/                   # 환경별 설정 파일
│       │   └── terraform.tfvars.example # 변수 예시 파일 (terraform.tfvars로 복사하여 사용)
│       └── 📁 terraform/                # 실제 Terraform 실행 디렉토리 ⭐
│           ├── main.tf                  # Provider, Variables, 모든 모듈 정의
│           ├── outputs.tf               # 환경별 출력 정의
│           └── variables.tf             # (선택사항) 변수를 별도 파일로 분리 가능
│
├── 📁 scripts/                          # 스크립트 및 소스 코드
│   ├── 📁 lambda/                       # Lambda 함수 소스 코드
│   │   ├── ip_blocker.py                # GuardDuty → WAF IP 차단 함수
│   │   └── requirements.txt             # Python 의존성
│   └── 📁 notifications/                # 알림 관련 스크립트 (예정)
│
└── 📁 docs/                             # 문서
    ├── 📁 architecture/                 # 아키텍처 문서
    │   └── README.md                    # 아키텍처 개요
    └── 📁 runbooks/                     # 운영 매뉴얼
        └── OPERATIONS.md                # 배포 및 운영 가이드
```

## 모듈별 역할

### 1. VPC Module (`modules/vpc/`)
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

### 2. Security Module (`modules/security/`)
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

### 3. Compute Module (`modules/compute/`)
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

### 4. Automation Module (`modules/automation/`) ⭐
**역할**: 실시간 위협 자동 대응 (Phase 3 핵심)
- GuardDuty Finding → EventBridge → Lambda → WAF IP 차단
- Slack 알림 통합

**주요 리소스**:
- `aws_lambda_function` - IP 차단 자동화 함수
- `aws_cloudwatch_event_rule` - GuardDuty 이벤트 캡처
- `aws_cloudwatch_event_target` - Lambda 트리거
- `aws_iam_role` - Lambda 실행 권한

## 배포 흐름

1. **환경 설정**: `environments/prod/config/terraform.tfvars` 설정
2. **초기화**: `terraform init` (또는 `make init`)
3. **계획 확인**: `terraform plan` (또는 `make plan`)
4. **배포**: `terraform apply` (또는 `make apply`)

## 주요 파일 설명

### `environments/prod/terraform/main.tf` ⭐
**이 파일이 실제 Terraform 배포의 시작점입니다.**
- Provider 설정 (AWS, Archive)
- 모든 변수 정의
- 모든 모듈 조합 (VPC, Security, Compute, Automation)
- 모듈 간 의존성 관리
- 환경별 특화 설정

**중요**: 모든 Terraform 작업(`terraform init`, `plan`, `apply`)은 이 디렉토리에서 실행합니다.

### `environments/prod/config/terraform.tfvars`
- 환경별 변수 값 설정
- `.gitignore`에 포함되어 Git에 커밋되지 않음
- `terraform.tfvars.example`을 복사하여 생성

### `scripts/lambda/ip_blocker.py`
- GuardDuty Finding에서 공격자 IP 추출
- WAF IP Set에 IP 자동 추가
- Slack 알림 전송

### `Makefile`
- 자주 사용하는 명령어 단축키
- Lambda 패키징 자동화
- 코드 검증 및 포맷팅

## 구조 설계 철학

### 왜 이런 구조를 사용하나요?

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

## 유지보수 고려사항

1. **모듈화**: 각 컴포넌트를 독립적인 모듈로 분리하여 재사용성 확보
2. **환경 분리**: 프로덕션/스테이징 환경별로 독립적인 설정 및 State 관리
3. **변수 관리**: 민감한 정보는 `terraform.tfvars`로 관리하고 Git 제외
4. **상태 관리**: S3 Backend 사용 권장 (`environments/{env}/terraform/main.tf`에서 설정)
5. **문서화**: 각 모듈의 역할과 의존성을 명확히 문서화

## 다음 단계

1. ✅ 프로젝트 구조 생성
2. ⏭️ 실제 AWS 리소스 배포 및 테스트
3. ⏭️ 아키텍처 다이어그램 작성
4. ⏭️ 백서 문서화 (10~12페이지)

