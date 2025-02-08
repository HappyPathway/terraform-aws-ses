output "domain_identity_arn" {
  value       = aws_ses_domain_identity.main.arn
  description = "The ARN of the SES domain identity"
}

output "configuration_set_name" {
  value       = aws_ses_configuration_set.main.name
  description = "The name of the configuration set"
}

output "smtp_user_access_key" {
  value       = var.create_smtp_user ? aws_iam_access_key.smtp_user[0].id : null
  description = "The access key for the SMTP user"
  sensitive   = true
}

output "smtp_user_secret_key" {
  value       = var.create_smtp_user ? aws_iam_access_key.smtp_user[0].ses_smtp_password_v4 : null
  description = "The secret SMTP password for the SMTP user"
  sensitive   = true
}

output "mail_from_domain" {
  value       = var.mail_from_domain != "" ? aws_ses_domain_mail_from.main[0].mail_from_domain : null
  description = "The MAIL FROM domain"
}