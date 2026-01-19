variable "project_name" {
  description = "프로젝트 이름"
  type        = string
}

variable "waf_ip_set_id" {
  description = "WAF IP Set ID (Block List)"
  type        = string
}

variable "waf_ip_set_arn" {
  description = "WAF IP Set ARN (Block List)"
  type        = string
}

variable "slack_webhook_url" {
  description = "Slack Webhook URL (선택사항)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "enable_sns_notifications" {
  description = "SNS 알림 활성화 여부"
  type        = bool
  default     = true
}

variable "notification_email" {
  description = "SNS 알림을 받을 이메일 주소"
  type        = string
  default     = ""
}

variable "lambda_zip_path" {
  description = "Lambda ZIP 파일 경로 (선택사항, 비어있으면 자동 생성)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "공통 태그"
  type        = map(string)
  default     = {}
}

