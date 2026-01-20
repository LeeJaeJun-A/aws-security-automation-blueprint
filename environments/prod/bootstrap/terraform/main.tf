# Terraform Backend Bootstrap
# Terraform State 관리를 위한 S3 버킷과 DynamoDB 테이블을 생성합니다.

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Bootstrap은 로컬 backend를 사용 (아직 remote backend가 없음)
}

# Provider 설정
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = merge(
      var.tags,
      {
        Purpose     = "Terraform-Backend"
        ManagedBy   = "Terraform"
        Environment = var.environment
      }
    )
  }
}

# 데이터 소스
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# S3 버킷: Terraform State 저장
resource "aws_s3_bucket" "terraform_state" {
  bucket = var.state_bucket_name

  tags = merge(
    var.tags,
    {
      Name        = var.state_bucket_name
      Description = "Terraform State Storage"
    }
  )
}

# S3 버킷 버전 관리
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# S3 버킷 서버 측 암호화
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 버킷 퍼블릭 액세스 차단
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 버킷 정책: Terraform State 접근 제어 (선택사항)
# 주의: 버킷 정책의 Deny 규칙이 IAM 권한보다 우선하므로,
# admin 계정에서도 접근이 차단될 수 있습니다.
# 필요시 나중에 수동으로 추가하거나, IAM 정책으로만 관리하는 것을 권장합니다.
# resource "aws_s3_bucket_policy" "terraform_state" {
#   bucket = aws_s3_bucket.terraform_state.id
#
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Sid    = "AllowAccountAccess"
#         Effect = "Allow"
#         Principal = {
#           AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
#         }
#         Action = "s3:*"
#         Resource = [
#           aws_s3_bucket.terraform_state.arn,
#           "${aws_s3_bucket.terraform_state.arn}/*"
#         ]
#       },
#       {
#         Sid       = "DenyInsecureConnections"
#         Effect    = "Deny"
#         Principal = "*"
#         Action    = "s3:*"
#         Resource = [
#           aws_s3_bucket.terraform_state.arn,
#           "${aws_s3_bucket.terraform_state.arn}/*"
#         ]
#         Condition = {
#           Bool = {
#             "aws:SecureTransport" = "false"
#           }
#         }
#       }
#     ]
#   })
# }

# S3 버킷 수명 주기 정책 (선택적, State 버전 관리용)
resource "aws_s3_bucket_lifecycle_configuration" "terraform_state" {
  count  = var.enable_state_lifecycle ? 1 : 0
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    id     = "expire-old-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = var.state_version_expiration_days
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# DynamoDB 테이블: Terraform State Lock
resource "aws_dynamodb_table" "terraform_state_lock" {
  name         = var.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  point_in_time_recovery {
    enabled = var.enable_dynamodb_point_in_time_recovery
  }

  server_side_encryption {
    enabled = true
  }

  tags = merge(
    var.tags,
    {
      Name        = var.dynamodb_table_name
      Description = "Terraform State Locking"
    }
  )
}

