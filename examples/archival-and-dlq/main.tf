provider "aws" {
  region = "us-west-2"
}

data "aws_route53_zone" "selected" {
  name = "example.com"
}

# S3 bucket for archiving emails
resource "aws_s3_bucket" "email_archive" {
  bucket = "ses-email-archive-${var.environment}"
}

resource "aws_s3_bucket_lifecycle_configuration" "archive" {
  bucket = aws_s3_bucket.email_archive.id

  rule {
    id     = "archive"
    status = "Enabled"

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }
  }
}

# DLQ for failed email processing
resource "aws_sqs_queue" "dlq" {
  name = "ses-processing-dlq"
  
  # 14 days retention
  message_retention_seconds = 1209600
  
  # Enable long polling
  receive_wait_time_seconds = 20
}

# Main queue for email processing with DLQ
resource "aws_sqs_queue" "email_processing" {
  name = "ses-email-processing"
  
  # Enable long polling
  receive_wait_time_seconds = 20
  
  # Send unprocessed messages to DLQ after 3 failures
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 3
  })
}

# SNS topic subscriptions for SQS
resource "aws_sns_topic_subscription" "bounce_queue" {
  topic_arn = module.ses.bounce_topic_arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.email_processing.arn
}

resource "aws_sns_topic_subscription" "complaint_queue" {
  topic_arn = module.ses.complaint_topic_arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.email_processing.arn
}

# SQS queue policy to allow SNS
resource "aws_sqs_queue_policy" "email_processing" {
  queue_url = aws_sqs_queue.email_processing.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.email_processing.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn": [
              module.ses.bounce_topic_arn,
              module.ses.complaint_topic_arn
            ]
          }
        }
      }
    ]
  })
}

# CloudWatch alarm for DLQ
resource "aws_cloudwatch_metric_alarm" "dlq_messages" {
  alarm_name          = "ses-dlq-messages"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name        = "ApproximateNumberOfMessagesVisible"
  namespace          = "AWS/SQS"
  period             = "300"
  statistic          = "Average"
  threshold          = "0"
  alarm_description  = "Messages in DLQ detected"
  alarm_actions      = [aws_sns_topic.alerts.arn]

  dimensions = {
    QueueName = aws_sqs_queue.dlq.name
  }
}

# Alert topic for operations team
resource "aws_sns_topic" "alerts" {
  name = "ses-operation-alerts"
}

# Main SES module
module "ses" {
  source = "../../"

  domain_name     = "mail.example.com"
  route53_zone_id = data.aws_route53_zone.selected.zone_id
  
  enable_notifications = true
  enable_metrics      = true
  
  tags = {
    Environment = var.environment
    Service     = "email"
  }
}

# S3 event configuration for email archiving
resource "aws_ses_configuration_set_event_destination" "s3_archive" {
  configuration_set_name = module.ses.configuration_set_name
  event_destination_name = "s3-archive"
  enabled               = true
  matching_types        = ["send"]

  s3_destination {
    bucket_name = aws_s3_bucket.email_archive.id
    topic_arn   = module.ses.configuration_set_arn
  }
}

variable "environment" {
  type        = string
  description = "Environment name"
  default     = "production"
}

# Outputs
output "sqs_queue_url" {
  value = aws_sqs_queue.email_processing.url
}

output "dlq_queue_url" {
  value = aws_sqs_queue.dlq.url
}

output "archive_bucket" {
  value = aws_s3_bucket.email_archive.id
}

output "alerts_topic_arn" {
  value = aws_sns_topic.alerts.arn
}