output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "waf_web_acl_arn" {
  description = "WAF Web ACL ARN"
  value       = module.security.waf_web_acl_arn
}

output "waf_web_acl_id" {
  description = "WAF Web ACL ID"
  value       = module.security.waf_web_acl_id
}

output "automation_lambda_function_arn" {
  description = "자동화 Lambda 함수 ARN"
  value       = module.automation.lambda_function_arn
}

output "automation_lambda_function_name" {
  description = "자동화 Lambda 함수 이름"
  value       = module.automation.lambda_function_name
}

output "security_hub_arn" {
  description = "Security Hub ARN"
  value       = module.security.security_hub_arn
}

output "guardduty_detector_id" {
  description = "GuardDuty Detector ID"
  value       = module.security.guardduty_detector_id
}

output "alb_dns_name" {
  description = "ALB DNS 이름"
  value       = module.compute.alb_dns_name
}

output "cloudfront_domain_name" {
  description = "CloudFront Domain Name"
  value       = module.compute.cloudfront_domain_name
}

output "ec2_instance_id" {
  description = "EC2 Instance ID"
  value       = module.compute.ec2_instance_id
}

output "sns_topic_arn" {
  description = "SNS Topic ARN (보안 알림)"
  value       = module.automation.sns_topic_arn
}

