# Archival and DLQ Example

This example demonstrates a production-grade SES setup with email archiving and error handling:
- S3 archival of all emails with lifecycle policies
- Dead Letter Queue (DLQ) for failed message processing
- SQS queues for asynchronous message handling
- CloudWatch alarms for operational monitoring
- SNS notifications for operations team

## Features

### Email Archiving
- Automatic archival to S3
- 90-day transition to Glacier storage
- 365-day retention policy
- Structured storage format for easy querying

### Error Handling
- Main processing queue with retry logic
- Dead Letter Queue after 3 failed attempts
- Automatic alerting on DLQ messages
- Long polling enabled for efficient processing

### Monitoring
- CloudWatch alarms for DLQ monitoring
- SNS notifications for operations team
- Metrics for queue depth and processing failures

## Usage

```bash
terraform init
terraform plan -var="environment=production"
terraform apply -var="environment=production"
```

## Post-deployment Tasks

1. Subscribe to the alerts SNS topic
2. Set up queue consumers for the main processing queue
3. Implement DLQ monitoring and cleanup procedures
4. Configure S3 bucket access policies as needed

## Architecture

```
SES → SNS → SQS → Processing Queue
                ↓
                DLQ → CloudWatch Alarm → SNS Alert

SES → S3 (Archive) → Glacier (90 days)
```

## Notes

- Adjust retention periods in lifecycle policies as needed
- Monitor S3 storage costs for archived emails
- Implement proper DLQ message handling procedures
- Consider adding additional CloudWatch alarms for main queue metrics