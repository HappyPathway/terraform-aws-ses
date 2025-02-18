# Lambda Processing Example

This example demonstrates AWS SES integration with Lambda for processing bounce and complaint notifications, featuring:
- Automatic notification processing with Lambda
- Slack notifications for bounces and complaints
- SES template for standardized emails
- CloudWatch logs for monitoring

## Prerequisites

1. Create a Slack webhook URL for notifications
2. Update the webhook URL in `main.tf`
3. Install Node.js dependencies:
```bash
cd lambda
npm install
zip -r email_processor.zip index.js node_modules/
```

## Usage

```bash
terraform init
terraform plan
terraform apply
```

## Lambda Function

The included Lambda function (`lambda/index.js`):
- Processes SES bounce and complaint notifications
- Formats messages for Slack
- Includes error handling and retries
- Provides detailed logging

## Testing

To test the setup:
1. Send a test email through SES
2. Create a test bounce by sending to bounce@simulator.amazonses.com
3. Check Slack for notifications
4. Review CloudWatch logs for Lambda execution