output "lambda_function_arn" {
  description = "Lambda 함수 ARN"
  value       = aws_lambda_function.ip_blocker.arn
}

output "lambda_function_name" {
  description = "Lambda 함수 이름"
  value       = aws_lambda_function.ip_blocker.function_name
}

output "eventbridge_rule_arn" {
  description = "EventBridge Rule ARN"
  value       = aws_cloudwatch_event_rule.guardduty_finding.arn
}

output "sns_topic_arn" {
  description = "SNS Topic ARN (보안 알림)"
  value       = try(aws_sns_topic.security_alerts[0].arn, null)
}

