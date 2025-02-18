provider "aws" {
  region = "us-west-2"
}

data "aws_route53_zone" "selected" {
  name = "example.com"
}

# Lambda function to process bounces and complaints
resource "aws_lambda_function" "email_processor" {
  filename      = "lambda/email_processor.zip"
  function_name = "ses-notification-processor"
  role         = aws_iam_role.lambda_role.arn
  handler      = "index.handler"
  runtime      = "nodejs16.x"

  environment {
    variables = {
      DOMAIN_NAME = "mail.example.com"
      SLACK_WEBHOOK_URL = "https://hooks.slack.com/services/xxx/yyy/zzz"
    }
  }
}

# IAM role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "ses-notification-processor-role"

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
}

# IAM policy for Lambda CloudWatch logs
resource "aws_iam_role_policy" "lambda_logs" {
  name = "ses-notification-processor-logs"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# SNS topic subscriptions for Lambda
resource "aws_sns_topic_subscription" "bounce_lambda" {
  topic_arn = module.ses.bounce_topic_arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.email_processor.arn
}

resource "aws_sns_topic_subscription" "complaint_lambda" {
  topic_arn = module.ses.complaint_topic_arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.email_processor.arn
}

# Lambda permission to allow SNS to invoke the function
resource "aws_lambda_permission" "bounce_sns" {
  statement_id  = "AllowSNSBounceInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.email_processor.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = module.ses.bounce_topic_arn
}

resource "aws_lambda_permission" "complaint_sns" {
  statement_id  = "AllowSNSComplaintInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.email_processor.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = module.ses.complaint_topic_arn
}

# Main SES module
module "ses" {
  source = "../../"

  domain_name     = "mail.example.com"
  route53_zone_id = data.aws_route53_zone.selected.zone_id
  
  enable_notifications = true
  enable_metrics      = true
  
  tags = {
    Environment = "production"
    Service     = "email-notifications"
  }
}

# Create an SES template for standardized emails
resource "aws_ses_template" "notification" {
  name    = "standard-notification"
  subject = "{{subject}}"
  html    = <<EOF
<!DOCTYPE html>
<html>
<body>
    <h1>{{subject}}</h1>
    <p>Hello {{name}},</p>
    <p>{{message}}</p>
    <p>Best regards,<br>{{sender}}</p>
</body>
</html>
EOF
  text    = "Hello {{name}},\n\n{{message}}\n\nBest regards,\n{{sender}}"
}

# Outputs
output "domain_identity_arn" {
  value = module.ses.domain_identity_arn
}

output "lambda_function_arn" {
  value = aws_lambda_function.email_processor.arn
}

output "template_name" {
  value = aws_ses_template.notification.name
}