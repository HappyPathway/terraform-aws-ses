resource "aws_ses_domain_identity" "main" {
  domain = var.domain_name
}

resource "aws_ses_domain_dkim" "main" {
  domain = aws_ses_domain_identity.main.domain
}

resource "aws_route53_record" "domain_verification" {
  zone_id = var.route53_zone_id
  name    = "_amazonses.${var.domain_name}"
  type    = "TXT"
  ttl     = "600"
  records = [aws_ses_domain_identity.main.verification_token]
}

resource "aws_route53_record" "dkim" {
  count   = 3
  zone_id = var.route53_zone_id
  name    = "${element(aws_ses_domain_dkim.main.dkim_tokens, count.index)}._domainkey.${var.domain_name}"
  type    = "CNAME"
  ttl     = "600"
  records = ["${element(aws_ses_domain_dkim.main.dkim_tokens, count.index)}.dkim.amazonses.com"]
}

resource "aws_ses_configuration_set" "main" {
  name = "${var.domain_name}-config-set"
}

# Add SPF record
resource "aws_route53_record" "spf" {
  zone_id = var.route53_zone_id
  name    = var.domain_name
  type    = "TXT"
  ttl     = var.ttl
  records = ["v=spf1 include:amazonses.com ~all"]
}

# Configure MAIL FROM domain if specified
resource "aws_ses_domain_mail_from" "main" {
  count            = var.mail_from_domain != "" ? 1 : 0
  domain           = aws_ses_domain_identity.main.domain
  mail_from_domain = "mail.${var.domain_name}"
}

# Add MX record for MAIL FROM
resource "aws_route53_record" "mail_from_mx" {
  count   = var.mail_from_domain != "" ? 1 : 0
  zone_id = var.route53_zone_id
  name    = aws_ses_domain_mail_from.main[0].mail_from_domain
  type    = "MX"
  ttl     = var.ttl
  records = ["10 feedback-smtp.${data.aws_region.current.name}.amazonses.com"]
}

# Create SMTP user if requested
resource "aws_iam_user" "smtp_user" {
  count = var.create_smtp_user ? 1 : 0
  name  = "ses-smtp-${var.domain_name}"
  tags  = var.tags
}

resource "aws_iam_access_key" "smtp_user" {
  count = var.create_smtp_user ? 1 : 0
  user  = aws_iam_user.smtp_user[0].name
}

resource "aws_iam_user_policy" "smtp_policy" {
  count = var.create_smtp_user ? 1 : 0
  name  = "ses-smtp-policy"
  user  = aws_iam_user.smtp_user[0].name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ses:SendRawEmail",
          "ses:SendEmail"
        ]
        Resource = [aws_ses_domain_identity.main.arn]
      }
    ]
  })
}

# Add CloudWatch metrics for configuration set
resource "aws_cloudwatch_metric_alarm" "ses_metrics" {
  count               = var.enable_metrics ? 1 : 0
  alarm_name          = "${var.domain_name}-ses-metrics"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name        = "Reputation.BounceRate"
  namespace          = "AWS/SES"
  period             = "300"
  statistic          = "Average"
  threshold          = "0.05"
  alarm_description  = "SES reputation bounce rate exceeded 5%"
  
  dimensions = {
    Domain = var.domain_name
  }
}

resource "aws_ses_event_destination" "cloudwatch" {
  count               = var.enable_metrics ? 1 : 0
  name               = "cloudwatch-metrics"
  configuration_set_name = aws_ses_configuration_set.main.name
  
  cloudwatch_destination {
    default_value  = var.domain_name
    dimension_name = "ses-domain"
    value_source   = "messageTag"
  }

  matching_types = ["send", "reject", "bounce", "complaint"]
}

# Add SNS topics for bounce and complaint notifications
resource "aws_sns_topic" "bounce" {
  count = var.enable_notifications ? 1 : 0
  name  = replace("${var.domain_name}-ses-bounce", ".", "-")
  tags  = var.tags
}

resource "aws_sns_topic" "complaint" {
  count = var.enable_notifications ? 1 : 0
  name  = replace("${var.domain_name}-ses-complaint", ".", "-")
  tags  = var.tags
}

# Add SNS event destinations for bounce and complaint notifications
resource "aws_sesv2_configuration_set_event_destination" "sns_bounce" {
  count                   = var.enable_notifications ? 1 : 0
  configuration_set_name  = aws_ses_configuration_set.main.name
  event_destination_name  = "bounce-notifications"

  event_destination {
    sns_destination {
      topic_arn = aws_sns_topic.bounce[0].arn
    }
    matching_event_types = ["BOUNCE"]
  }
}

resource "aws_sesv2_configuration_set_event_destination" "sns_complaint" {
  count                   = var.enable_notifications ? 1 : 0
  configuration_set_name  = aws_ses_configuration_set.main.name
  event_destination_name  = "complaint-notifications"

  event_destination {
    sns_destination {
      topic_arn = aws_sns_topic.complaint[0].arn
    }
    matching_event_types = ["COMPLAINT"]
  }
}

data "aws_region" "current" {}
