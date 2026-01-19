.PHONY: init plan apply destroy validate format clean

# Terraform 명령어 단축키
init:
	cd environments/prod/terraform && terraform init

plan:
	cd environments/prod/terraform && terraform plan -var-file=../config/terraform.tfvars

apply:
	cd environments/prod/terraform && terraform apply -var-file=../config/terraform.tfvars

destroy:
	cd environments/prod/terraform && terraform destroy -var-file=../config/terraform.tfvars

validate:
	cd environments/prod/terraform && terraform validate

format:
	terraform fmt -recursive

# Lambda 패키징
package-lambda:
	cd scripts/lambda && \
	pip install -r requirements.txt -t . && \
	zip -r ../../modules/automation/lambda_zip/ip-blocker-lambda.zip . -x "*.pyc" "__pycache__/*"

# 전체 프로젝트 정리
clean:
	find . -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.tfstate*" -delete
	find . -type f -name ".terraform.lock.hcl" -delete
	find . -type f -name "*.zip" -path "*/lambda_zip/*" -delete

# 문서 생성 (예시)
docs:
	@echo "📚 프로젝트 문서:"
	@echo "  - README.md: 프로젝트 개요"
	@echo "  - docs/architecture/README.md: 아키텍처 문서"
	@echo "  - docs/runbooks/OPERATIONS.md: 운영 매뉴얼"

help:
	@echo "사용 가능한 명령어:"
	@echo "  make init          - Terraform 초기화"
	@echo "  make plan          - 배포 계획 확인"
	@echo "  make apply         - 인프라 배포"
	@echo "  make destroy       - 인프라 삭제"
	@echo "  make validate      - Terraform 코드 검증"
	@echo "  make format        - Terraform 코드 포맷팅"
	@echo "  make package-lambda - Lambda 함수 패키징"
	@echo "  make clean         - 빌드 파일 정리"
	@echo "  make docs          - 문서 목록 출력"
	@echo "  make help          - 이 도움말 출력"

