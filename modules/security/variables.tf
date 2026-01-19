variable "project_name" {
  description = "프로젝트 이름"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "allowed_ssh_cidr_blocks" {
  description = "SSH 접근을 허용할 CIDR 블록 목록"
  type        = list(string)
  default     = []
}

variable "enable_guardduty" {
  description = "GuardDuty 활성화 여부"
  type        = bool
  default     = true
}

variable "enable_config" {
  description = "AWS Config 활성화 여부"
  type        = bool
  default     = true
}

variable "enable_security_hub" {
  description = "Security Hub 활성화 여부"
  type        = bool
  default     = true
}

variable "tags" {
  description = "공통 태그"
  type        = map(string)
  default     = {}
}

