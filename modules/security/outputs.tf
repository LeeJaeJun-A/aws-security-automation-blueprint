output "alb_security_group_id" {
  description = "ALB Security Group ID"
  value       = aws_security_group.alb.id
}

output "ec2_security_group_id" {
  description = "EC2 Security Group ID"
  value       = aws_security_group.ec2.id
}

output "waf_web_acl_arn" {
  description = "WAF Web ACL ARN"
  value       = aws_wafv2_web_acl.main.arn
}

output "waf_web_acl_id" {
  description = "WAF Web ACL ID"
  value       = aws_wafv2_web_acl.main.id
}

output "waf_ip_set_arn" {
  description = "WAF IP Set ARN (Block List)"
  value       = aws_wafv2_ip_set.block_list.arn
}

output "waf_ip_set_id" {
  description = "WAF IP Set ID (Block List)"
  value       = aws_wafv2_ip_set.block_list.id
}

output "guardduty_detector_id" {
  description = "GuardDuty Detector ID"
  value       = try(aws_guardduty_detector.main[0].id, null)
}

output "security_hub_arn" {
  description = "Security Hub ARN"
  value       = try(aws_securityhub_account.main[0].arn, null)
}

output "config_recorder_name" {
  description = "AWS Config Recorder Name"
  value       = try(aws_config_configuration_recorder.main[0].name, null)
}

