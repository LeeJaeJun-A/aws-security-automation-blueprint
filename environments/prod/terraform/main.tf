# 프로덕션 환경별 Terraform 설정
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }

  # 프로덕션 환경별 State 관리
  # backend "s3" {
  #   bucket = "your-terraform-state-bucket"
  #   key    = "prod/aws-security-automation/terraform.tfstate"
  #   region = "ap-northeast-2"
  #   encrypt = true
  # }
}

# Variables 정의
variable "aws_region" {
  description = "AWS 리전"
  type        = string
}

variable "project_name" {
  description = "프로젝트 이름"
  type        = string
}

variable "environment" {
  description = "환경 (dev, staging, prod)"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR 블록"
  type        = string
}

variable "availability_zones" {
  description = "사용할 가용 영역 목록"
  type        = list(string)
}

variable "slack_webhook_url" {
  description = "Slack Webhook URL (선택사항)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "notification_email" {
  description = "알림을 받을 이메일 주소"
  type        = string
  default     = ""
}

variable "allowed_cidr_blocks" {
  description = "관리자 접근 허용 CIDR 블록 목록"
  type        = list(string)
  default     = []
}

variable "enable_guardduty" {
  description = "GuardDuty 활성화 여부"
  type        = bool
  default     = true
}

variable "enable_security_hub" {
  description = "Security Hub 활성화 여부"
  type        = bool
  default     = true
}

variable "enable_config" {
  description = "AWS Config 활성화 여부"
  type        = bool
  default     = true
}

variable "tags" {
  description = "공통 태그"
  type        = map(string)
  default     = {}
}

# Provider 설정
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = merge(
      var.tags,
      {
        Environment = var.environment
        Project     = var.project_name
      }
    )
  }
}

# 데이터 소스
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# VPC 모듈
module "vpc" {
  source = "../../../modules/vpc"

  project_name       = var.project_name
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  public_subnet_cidrs = [
    cidrsubnet(var.vpc_cidr, 4, 0),
    cidrsubnet(var.vpc_cidr, 4, 1)
  ]
  private_subnet_cidrs = [
    cidrsubnet(var.vpc_cidr, 4, 8),
    cidrsubnet(var.vpc_cidr, 4, 9)
  ]
  enable_nat_gateway = true
  tags               = var.tags
}

# Security 모듈
module "security" {
  source = "../../../modules/security"

  project_name            = var.project_name
  vpc_id                  = module.vpc.vpc_id
  allowed_ssh_cidr_blocks = var.allowed_cidr_blocks
  enable_guardduty        = var.enable_guardduty
  enable_config           = var.enable_config
  enable_security_hub     = var.enable_security_hub
  tags                    = var.tags
}

# Compute 모듈
module "compute" {
  source = "../../../modules/compute"

  project_name          = var.project_name
  vpc_id                = module.vpc.vpc_id
  public_subnet_ids     = module.vpc.public_subnet_ids
  private_subnet_ids    = module.vpc.private_subnet_ids
  alb_security_group_id = module.security.alb_security_group_id
  ec2_security_group_id = module.security.ec2_security_group_id
  waf_web_acl_id        = module.security.waf_web_acl_id
  enable_cloudfront     = true
  enable_ec2            = true
  ec2_instance_type     = "t3.micro"
  tags                  = var.tags
}

# Automation 모듈
module "automation" {
  source = "../../../modules/automation"

  project_name             = var.project_name
  waf_ip_set_id            = module.security.waf_ip_set_id
  waf_ip_set_arn           = module.security.waf_ip_set_arn
  slack_webhook_url        = var.slack_webhook_url
  enable_sns_notifications = true
  notification_email       = var.notification_email
  tags                     = var.tags
}

