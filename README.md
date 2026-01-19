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

### Phase 3: Automation (자동화) ⭐
- **실시간 악성 IP 자동 차단 시스템**
  - GuardDuty 탐지 → EventBridge → Lambda → WAFv2 IP Set 업데이트
  - Slack 알림 통합

## 프로젝트 구조

자세한 프로젝트 구조는 [PROJECT_STRUCTURE.md](./PROJECT_STRUCTURE.md)를 참조하세요.

```
aws-security-automation-blueprint/
├── modules/
│   ├── vpc/              # 네트워크 인프라 (VPC, Subnets, Internet Gateway 등)
│   ├── security/         # 보안 서비스 (WAF, Security Groups, GuardDuty 등)
│   ├── compute/          # 컴퓨팅 리소스 (EC2, ALB, CloudFront 등)
│   └── automation/       # 자동화 파이프라인 (EventBridge, Lambda, IP 차단)
├── environments/
│   └── prod/             # 프로덕션 환경 설정
│       ├── config/       # 환경별 설정 파일
│       └── terraform/    # 환경별 Terraform 코드
├── scripts/
│   ├── lambda/           # Lambda 함수 소스 코드
│   └── notifications/    # 알림 관련 스크립트
├── docs/
│   ├── architecture/     # 아키텍처 다이어그램 및 문서
│   └── runbooks/         # 운영 매뉴얼
├── Makefile              # 빌드 및 배포 자동화
├── .gitignore           # Git 제외 파일 목록
├── .terraform-version   # Terraform 버전 고정
└── README.md            # 이 파일
```

## 시작하기

### 사전 요구사항

- Terraform >= 1.5.0
- AWS CLI 구성 완료
- 적절한 AWS 권한 (IAM, VPC, WAF, GuardDuty 등)

### 사용법

**방법 1: Makefile 사용 (권장)**

```bash
# 초기화
make init

# 배포 계획 확인
make plan

# 인프라 배포
make apply
```

**방법 2: 직접 Terraform 명령어 사용**

모든 Terraform 작업은 `environments/{env}/terraform/` 디렉토리에서 실행합니다.

```bash
# 설정 파일 준비
cd environments/prod/config
cp terraform.tfvars.example terraform.tfvars
# terraform.tfvars 파일 수정

# Terraform 작업
cd ../terraform
terraform init
terraform plan -var-file=../config/terraform.tfvars
terraform apply -var-file=../config/terraform.tfvars
```

## 프로젝트 구조 설명

이 프로젝트는 **환경별로 완전히 분리된 구조**를 사용합니다:

- **루트 레벨**: 모듈(`modules/`), 스크립트(`scripts/`), 문서(`docs/`)만 관리
- **환경별 배포**: `environments/{env}/terraform/` 디렉토리에서 실제 배포 수행
  - 각 환경은 독립적인 Terraform State 관리
  - 환경별 설정은 `environments/{env}/config/terraform.tfvars`에서 관리

## 아키텍처

자세한 아키텍처 문서는 [docs/architecture/](./docs/architecture/) 디렉토리를 참조하세요.

## 보안 고려사항

- 모든 민감한 값은 Terraform Variables 또는 AWS Secrets Manager를 사용하세요
- `.tfvars` 파일은 Git에 커밋하지 마세요 (`.gitignore`에 포함됨)
- 프로덕션 환경 배포 전 반드시 스테이징 환경에서 테스트하세요

## 라이선스

MIT License

## 기여

이슈 및 Pull Request를 환영합니다.

