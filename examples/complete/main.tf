provider "aws" {
  region = "us-west-2"
}

data "aws_route53_zone" "selected" {
  name = "example.com"
}

# Create SNS topic subscriptions for email notifications
resource "aws_sns_topic_subscription" "bounce_email" {
  topic_arn = module.ses.bounce_topic_arn
  protocol  = "email"
  endpoint  = "alerts@example.com"
}

resource "aws_sns_topic_subscription" "complaint_email" {
  topic_arn = module.ses.complaint_topic_arn
  protocol  = "email"
  endpoint  = "alerts@example.com"
}

# Create a CloudWatch dashboard for SES metrics
resource "aws_cloudwatch_dashboard" "ses_dashboard" {
  dashboard_name = "ses-monitoring"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/SES", "Reputation.BounceRate", "Domain", "example.com"],
            ["AWS/SES", "Reputation.ComplaintRate", "Domain", "example.com"]
          ]
          period = 300
          stat   = "Average"
          region = "us-west-2"
          title  = "SES Reputation Metrics"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/SES", "Send", "Domain", "example.com"],
            ["AWS/SES", "Bounce", "Domain", "example.com"],
            ["AWS/SES", "Complaint", "Domain", "example.com"],
            ["AWS/SES", "Reject", "Domain", "example.com"]
          ]
          period = 300
          stat   = "Sum"
          region = "us-west-2"
          title  = "SES Email Metrics"
        }
      }
    ]
  })
}

module "ses" {
  source = "../../"

  domain_name     = "mail.example.com"
  route53_zone_id = data.aws_route53_zone.selected.zone_id
  
  # Enable all optional features
  create_smtp_user     = true
  enable_metrics       = true
  enable_notifications = true
  mail_from_domain    = "mail"
  
  ttl = 3600 # 1 hour TTL for DNS records
  
  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
    Service     = "email"
  }
}

# Output all relevant information
output "domain_identity_arn" {
  value = module.ses.domain_identity_arn
}

output "configuration_set_name" {
  value = module.ses.configuration_set_name
}

output "smtp_user_access_key" {
  value     = module.ses.smtp_user_access_key
  sensitive = true
}

output "smtp_user_secret_key" {
  value     = module.ses.smtp_user_secret_key
  sensitive = true
}

output "mail_from_domain" {
  value = module.ses.mail_from_domain
}