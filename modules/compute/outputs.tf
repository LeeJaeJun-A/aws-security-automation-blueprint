output "alb_arn" {
  description = "ALB ARN"
  value       = aws_lb.main.arn
}

output "alb_dns_name" {
  description = "ALB DNS 이름"
  value       = aws_lb.main.dns_name
}

output "target_group_arn" {
  description = "Target Group ARN"
  value       = aws_lb_target_group.main.arn
}

output "cloudfront_distribution_id" {
  description = "CloudFront Distribution ID"
  value       = try(aws_cloudfront_distribution.main[0].id, null)
}

output "cloudfront_domain_name" {
  description = "CloudFront Domain Name"
  value       = try(aws_cloudfront_distribution.main[0].domain_name, null)
}

output "ec2_instance_ids" {
  description = "EC2 Instance ID 목록"
  value       = aws_instance.main[*].id
}

output "ec2_instance_private_ips" {
  description = "EC2 Instance Private IP 목록"
  value       = aws_instance.main[*].private_ip
}

output "ec2_instance_public_ips" {
  description = "EC2 Instance Public IP 목록 (null if in private subnet)"
  value       = aws_instance.main[*].public_ip
}

# 하위 호환성을 위한 단일 인스턴스 출력값 (첫 번째 인스턴스)
output "ec2_instance_id" {
  description = "EC2 Instance ID (첫 번째 인스턴스, 하위 호환성)"
  value       = try(aws_instance.main[0].id, null)
}

output "ec2_instance_private_ip" {
  description = "EC2 Instance Private IP (첫 번째 인스턴스, 하위 호환성)"
  value       = try(aws_instance.main[0].private_ip, null)
}

output "ec2_instance_public_ip" {
  description = "EC2 Instance Public IP (첫 번째 인스턴스, 하위 호환성)"
  value       = try(aws_instance.main[0].public_ip, null)
}

