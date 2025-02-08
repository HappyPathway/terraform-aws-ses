variable "domain_name" {
  type        = string
  description = "Domain name for SES identity"
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]{0,61}[a-z0-9]\\.[a-z]{2,}$", var.domain_name))
    error_message = "Domain name must be a valid domain name."
  }
}

variable "route53_zone_id" {
  type        = string
  description = "Route53 hosted zone ID for DNS records"
}

variable "create_smtp_user" {
  type        = bool
  description = "Whether to create SMTP user for SES"
  default     = false
}

variable "ttl" {
  type        = number
  description = "TTL for DNS records"
  default     = 600
  validation {
    condition     = var.ttl >= 60
    error_message = "TTL must be at least 60 seconds."
  }
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources"
  default     = {}
}

variable "enable_metrics" {
  type        = bool
  description = "Enable CloudWatch metrics for SES"
  default     = true
}

variable "mail_from_domain" {
  type        = string
  description = "Subdomain for MAIL FROM setup"
  default     = ""
}

variable "enable_notifications" {
  type        = bool
  description = "Enable SNS notifications for bounces and complaints"
  default     = false
}
