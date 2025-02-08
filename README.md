# AWS SES Terraform Module

This module creates a complete AWS SES setup including domain verification, DKIM configuration, SPF records, and optional SMTP user creation.

## Features

- SES Domain Identity setup with DKIM
- Automatic Route53 DNS records for domain verification
- SPF record configuration
- Optional MAIL FROM domain setup
- Optional SMTP user creation with IAM permissions
- CloudWatch metrics integration
- SNS notifications for bounces and complaints
- Configurable DNS TTL values

## Usage

```hcl
module "ses" {
  source          = "path/to/module"
  domain_name     = "example.com"
  route53_zone_id = "Z1234567890"
  
  enable_metrics       = true
  enable_notifications = true
  create_smtp_user     = true
  
  tags = {
    Environment = "production"
  }
}
```

## Requirements

- AWS provider
- Route53 hosted zone for the domain
- Terraform 0.12 or later

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| domain_name | Domain name for SES identity | string | n/a | yes |
| route53_zone_id | Route53 hosted zone ID for DNS records | string | n/a | yes |
| create_smtp_user | Whether to create SMTP user for SES | bool | false | no |
| ttl | TTL for DNS records | number | 600 | no |
| tags | Tags to apply to resources | map(string) | {} | no |
| enable_metrics | Enable CloudWatch metrics for SES | bool | true | no |
| enable_notifications | Enable SNS notifications for bounces and complaints | bool | false | no |
| mail_from_domain | Subdomain for MAIL FROM setup | string | "" | no |

## Outputs

Check outputs.tf for available outputs.

## Best Practices

This module follows AWS best practices by:
- Implementing SPF and DKIM for email authentication
- Using least-privilege IAM policies
- Enabling monitoring and notifications
- Supporting tags for resource management
