# 아키텍처 문서

이 디렉토리에는 프로젝트의 아키텍처 다이어그램과 설계 문서가 포함됩니다.

## 주요 컴포넌트

### 1. 네트워크 레이어 (VPC Module)
- VPC 및 서브넷 구성
- Internet Gateway 및 NAT Gateway
- 라우팅 테이블

### 2. 보안 레이어 (Security Module)
- WAF v2: 웹 공격 차단
- Security Groups: 네트워크 액세스 제어
- GuardDuty: 위협 탐지
- AWS Config: 규정 준수 모니터링
- Security Hub: 통합 보안 대시보드

### 3. 컴퓨팅 레이어 (Compute Module)
- Application Load Balancer (ALB)
- CloudFront Distribution
- SSL/TLS 인증서 관리

### 4. 자동화 레이어 (Automation Module)
- EventBridge: 이벤트 기반 트리거
- Lambda: IP 차단 자동화 함수
- CloudWatch: 로깅 및 모니터링

## 자동화 플로우

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

## 다이어그램

아키텍처 다이어그램은 별도 파일로 추가 예정입니다.

