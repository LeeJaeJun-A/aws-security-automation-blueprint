variable "aws_region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-northeast-2"
}

variable "environment" {
  description = "환경 (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "state_bucket_name" {
  description = "Terraform State를 저장할 S3 버킷 이름 (전역적으로 고유해야 함)"
  type        = string
}

variable "dynamodb_table_name" {
  description = "Terraform State Lock을 위한 DynamoDB 테이블 이름"
  type        = string
  default     = "terraform-state-lock"
}

variable "enable_state_lifecycle" {
  description = "State 버전 수명 주기 정책 활성화 여부"
  type        = bool
  default     = true
}

variable "state_version_expiration_days" {
  description = "State 버전 만료일 (일)"
  type        = number
  default     = 90
}

variable "enable_dynamodb_point_in_time_recovery" {
  description = "DynamoDB Point-in-Time Recovery 활성화 여부"
  type        = bool
  default     = true
}

variable "tags" {
  description = "공통 태그"
  type        = map(string)
  default = {
    Project = "aws-security-automation"
  }
}

