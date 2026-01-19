# Archive Provider (Lambda ZIP 생성을 위해 필요)
terraform {
  required_providers {
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }
}

# Lambda 함수: GuardDuty 이벤트 기반 IP 자동 차단
resource "aws_lambda_function" "ip_blocker" {
  filename      = var.lambda_zip_path != "" ? var.lambda_zip_path : data.archive_file.lambda_zip.output_path
  function_name = "${var.project_name}-ip-blocker"
  role          = aws_iam_role.lambda.arn
  handler       = "ip_blocker.lambda_handler"
  runtime       = "python3.11"
  timeout       = 60

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic,
    aws_iam_role_policy.lambda_waf,
    data.archive_file.lambda_zip
  ]

  environment {
    variables = {
      WAF_IP_SET_ID     = var.waf_ip_set_id
      WAF_IP_SET_ARN    = var.waf_ip_set_arn
      SLACK_WEBHOOK_URL = var.slack_webhook_url
      SNS_TOPIC_ARN     = var.enable_sns_notifications ? aws_sns_topic.security_alerts[0].arn : ""
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-ip-blocker-lambda"
    }
  )
}

# Lambda ZIP 파일 생성
data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/lambda_zip/${var.project_name}-lambda.zip"

  source {
    content  = file("${path.module}/../../scripts/lambda/ip_blocker.py")
    filename = "ip_blocker.py"
  }
}

# Lambda IAM Role
resource "aws_iam_role" "lambda" {
  name = "${var.project_name}-ip-blocker-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Lambda 기본 실행 권한
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Lambda WAF 권한
resource "aws_iam_role_policy" "lambda_waf" {
  name = "${var.project_name}-lambda-waf-policy"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "wafv2:GetIPSet",
          "wafv2:UpdateIPSet"
        ]
        Resource = var.waf_ip_set_arn
      }
    ]
  })
}

# EventBridge Rule: GuardDuty Finding (Medium 이상)
resource "aws_cloudwatch_event_rule" "guardduty_finding" {
  name        = "${var.project_name}-guardduty-finding-rule"
  description = "Capture GuardDuty findings with severity Medium or Higher"

  event_pattern = jsonencode({
    source      = ["aws.guardduty"]
    detail-type = ["GuardDuty Finding"]
    detail = {
      severity = [
        { numeric = [">=", 4.0] }
      ]
    }
  })

  tags = var.tags
}

# EventBridge Rule Target: Lambda
resource "aws_cloudwatch_event_target" "lambda" {
  rule      = aws_cloudwatch_event_rule.guardduty_finding.name
  target_id = "TriggerLambdaFunction"
  arn       = aws_lambda_function.ip_blocker.arn

  depends_on = [
    aws_lambda_permission.eventbridge
  ]
}

# Lambda 권한: EventBridge에서 호출 허용
resource "aws_lambda_permission" "eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ip_blocker.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.guardduty_finding.arn
}

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${aws_lambda_function.ip_blocker.function_name}"
  retention_in_days = 30

  tags = var.tags
}

# SNS Topic: 보안 알림
resource "aws_sns_topic" "security_alerts" {
  count = var.enable_sns_notifications ? 1 : 0
  name  = "${var.project_name}-security-alerts"

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-security-alerts-topic"
    }
  )
}

# SNS Topic Subscription: 이메일
resource "aws_sns_topic_subscription" "email" {
  count     = var.enable_sns_notifications && var.notification_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.security_alerts[0].arn
  protocol  = "email"
  endpoint  = var.notification_email
}

# SNS Topic Policy: Lambda에서 발행할 수 있도록 허용
resource "aws_sns_topic_policy" "security_alerts" {
  count = var.enable_sns_notifications ? 1 : 0
  arn   = aws_sns_topic.security_alerts[0].arn
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.security_alerts[0].arn
      }
    ]
  })
}

# Lambda IAM 권한: SNS 발행
resource "aws_iam_role_policy" "lambda_sns" {
  count = var.enable_sns_notifications ? 1 : 0
  name  = "${var.project_name}-lambda-sns-policy"
  role  = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.security_alerts[0].arn
      }
    ]
  })
}

