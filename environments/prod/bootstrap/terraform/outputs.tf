output "state_bucket_name" {
  description = "Terraform State S3 버킷 이름"
  value       = aws_s3_bucket.terraform_state.id
}

output "state_bucket_arn" {
  description = "Terraform State S3 버킷 ARN"
  value       = aws_s3_bucket.terraform_state.arn
}

output "dynamodb_table_name" {
  description = "Terraform State Lock DynamoDB 테이블 이름"
  value       = aws_dynamodb_table.terraform_state_lock.name
}

output "dynamodb_table_arn" {
  description = "Terraform State Lock DynamoDB 테이블 ARN"
  value       = aws_dynamodb_table.terraform_state_lock.arn
}

output "backend_config" {
  description = "Terraform Backend 설정 값"
  value = {
    bucket         = aws_s3_bucket.terraform_state.id
    dynamodb_table = aws_dynamodb_table.terraform_state_lock.name
    region         = var.aws_region
    encrypt        = true
  }
}

output "backend_config_example" {
  description = "Terraform Backend 설정 예제 (코드 형식)"
  value       = <<-EOT
    backend "s3" {
      bucket         = "${aws_s3_bucket.terraform_state.id}"
      key            = "prod/aws-security-automation/terraform.tfstate"
      region         = "${var.aws_region}"
      dynamodb_table = "${aws_dynamodb_table.terraform_state_lock.name}"
      encrypt        = true
    }
  EOT
}

