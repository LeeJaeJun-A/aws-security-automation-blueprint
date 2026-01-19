variable "project_name" {
  description = "프로젝트 이름"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public Subnet ID 목록"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "ALB Security Group ID"
  type        = string
}

variable "waf_web_acl_id" {
  description = "WAF Web ACL ID"
  type        = string
}

variable "certificate_arn" {
  description = "ACM 인증서 ARN (선택사항, 비어있으면 새로 생성)"
  type        = string
  default     = ""
}

variable "domain_name" {
  description = "도메인 이름 (인증서 생성 시 사용)"
  type        = string
  default     = ""
}

variable "enable_cloudfront" {
  description = "CloudFront 활성화 여부"
  type        = bool
  default     = true
}

variable "enable_deletion_protection" {
  description = "ALB 삭제 방지 활성화"
  type        = bool
  default     = false
}

variable "enable_ec2" {
  description = "EC2 인스턴스 생성 여부"
  type        = bool
  default     = true
}

variable "ec2_instance_type" {
  description = "EC2 인스턴스 타입"
  type        = string
  default     = "t3.micro"
}

variable "ec2_ami_id" {
  description = "EC2 AMI ID (비어있으면 최신 Amazon Linux 2 사용)"
  type        = string
  default     = ""
}

variable "ec2_key_name" {
  description = "EC2 Key Pair 이름 (SSH 접근용, 선택사항)"
  type        = string
  default     = ""
}

variable "ec2_security_group_id" {
  description = "EC2 Security Group ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private Subnet ID 목록 (EC2 배치용)"
  type        = list(string)
}

variable "user_data" {
  description = "EC2 User Data 스크립트 (선택사항)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "공통 태그"
  type        = map(string)
  default     = {}
}

