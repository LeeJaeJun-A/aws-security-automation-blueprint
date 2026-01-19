variable "project_name" {
  description = "프로젝트 이름"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR 블록"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "Public Subnet CIDR 블록 목록"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "Private Subnet CIDR 블록 목록"
  type        = list(string)
}

variable "availability_zones" {
  description = "사용할 가용 영역"
  type        = list(string)
}

variable "enable_nat_gateway" {
  description = "NAT Gateway 활성화 여부"
  type        = bool
  default     = true
}

variable "tags" {
  description = "공통 태그"
  type        = map(string)
  default     = {}
}

