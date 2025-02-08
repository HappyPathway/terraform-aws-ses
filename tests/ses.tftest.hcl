# Test basic SES setup
run "basic_ses_setup" {
  command = plan

  variables {
    domain_name      = "example.com"
    route53_zone_id  = "Z1234567890ABC"
    create_smtp_user = false
    enable_metrics   = true
  }

  assert {
    condition     = aws_ses_domain_identity.main.domain == "example.com"
    error_message = "SES domain identity not set correctly"
  }

  assert {
    condition     = aws_route53_record.domain_verification.zone_id == "Z1234567890ABC"
    error_message = "Route53 zone ID not set correctly"
  }

  assert {
    condition     = length(aws_route53_record.dkim) == 3
    error_message = "DKIM records not created correctly"
  }
}

# Test SMTP user creation
run "smtp_user_creation" {
  command = plan

  variables {
    domain_name      = "example.com"
    route53_zone_id  = "Z1234567890ABC"
    create_smtp_user = true
  }

  assert {
    condition     = length(aws_iam_user.smtp_user) > 0
    error_message = "SMTP user not created when create_smtp_user is true"
  }
}

# Test custom mail from domain
run "custom_mail_from" {
  command = plan

  variables {
    domain_name       = "example.com"
    route53_zone_id   = "Z1234567890ABC"
    mail_from_domain  = "mail"
  }

  assert {
    condition     = length(aws_ses_domain_mail_from.main) > 0
    error_message = "MAIL FROM domain not created when specified"
  }

  assert {
    condition     = length(aws_route53_record.mail_from_mx) > 0
    error_message = "MX record for MAIL FROM domain not created"
  }
}

# Test notifications setup
run "notifications_enabled" {
  command = plan

  variables {
    domain_name          = "example.com"
    route53_zone_id      = "Z1234567890ABC"
    enable_notifications = true
  }

  assert {
    condition     = length(aws_sns_topic.bounce) > 0 && length(aws_sns_topic.complaint) > 0
    error_message = "SNS topics not created when notifications are enabled"
  }

  assert {
    condition     = length(aws_sesv2_configuration_set_event_destination.sns_bounce) > 0
    error_message = "Bounce notification configuration not created"
  }

  assert {
    condition     = length(aws_sesv2_configuration_set_event_destination.sns_complaint) > 0
    error_message = "Complaint notification configuration not created"
  }
}

# Test CloudWatch metrics
run "cloudwatch_metrics_enabled" {
  command = plan

  variables {
    domain_name     = "example.com"
    route53_zone_id = "Z1234567890ABC"
    enable_metrics  = true
  }

  assert {
    condition     = length(aws_cloudwatch_metric_alarm.ses_metrics) > 0
    error_message = "CloudWatch metric alarm not created when metrics are enabled"
  }

  assert {
    condition     = length(aws_ses_event_destination.cloudwatch) > 0
    error_message = "CloudWatch event destination not created when metrics are enabled"
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.ses_metrics[0].metric_name == "Reputation.BounceRate"
    error_message = "CloudWatch metric alarm not configured correctly"
  }
}

# Test SNS topic name formatting
run "sns_topic_naming" {
  command = plan

  variables {
    domain_name          = "my.example.com"
    route53_zone_id      = "Z1234567890ABC"
    enable_notifications = true
  }

  assert {
    condition     = aws_sns_topic.bounce[0].name == "my-example-com-ses-bounce"
    error_message = "SNS bounce topic name not properly formatted"
  }

  assert {
    condition     = aws_sns_topic.complaint[0].name == "my-example-com-ses-complaint"
    error_message = "SNS complaint topic name not properly formatted"
  }
}

# Test TTL validation
run "invalid_ttl" {
  command = plan

  variables {
    domain_name     = "example.com"
    route53_zone_id = "Z1234567890ABC"
    ttl            = 30  # Less than minimum 60 seconds
  }

  expect_failures = [
    var.ttl
  ]
}

# Test domain name validation
run "invalid_domain_name" {
  command = plan

  variables {
    domain_name     = "invalid..domain"  # Invalid domain format
    route53_zone_id = "Z1234567890ABC"
  }

  expect_failures = [
    var.domain_name
  ]
}