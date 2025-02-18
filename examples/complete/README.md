# Complete SES Example

This example demonstrates a comprehensive setup of AWS SES with the following features:
- Email sending capability with DKIM and SPF
- CloudWatch dashboard for monitoring
- SNS notifications for bounces and complaints
- Email alerts for operations team
- SMTP user for sending emails

## Usage

```bash
terraform init
terraform plan -var="aws_region=us-west-2"
terraform apply -var="aws_region=us-west-2"
```

## Post-deployment Steps

1. Confirm the SNS subscription emails you'll receive
2. Access the CloudWatch dashboard named "ses-monitoring"
3. Retrieve SMTP credentials from the outputs (sensitive values)

## Monitoring

The CloudWatch dashboard includes:
- Bounce and complaint rates
- Email sending volume
- Success and failure metrics

## Notes

- Update the alert email address in `main.tf` before deploying
- The module creates DNS records automatically
- Allow up to 72 hours for full domain verification