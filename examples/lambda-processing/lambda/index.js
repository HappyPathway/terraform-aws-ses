// Lambda function to process SES bounce and complaint notifications
// and forward them to Slack

const https = require('https');
const url = require('url');

exports.handler = async (event) => {
    const message = JSON.parse(event.Records[0].Sns.Message);
    const slackWebhookUrl = process.env.SLACK_WEBHOOK_URL;
    const domain = process.env.DOMAIN_NAME;
    
    // Format message based on notification type
    let slackMessage;
    if (message.notificationType === 'Bounce') {
        slackMessage = formatBounceMessage(message.bounce, domain);
    } else if (message.notificationType === 'Complaint') {
        slackMessage = formatComplaintMessage(message.complaint, domain);
    }
    
    // Send to Slack
    if (slackMessage) {
        await sendToSlack(slackWebhookUrl, slackMessage);
    }
    
    return {
        statusCode: 200,
        body: JSON.stringify('Notification processed successfully')
    };
};

function formatBounceMessage(bounce, domain) {
    return {
        attachments: [{
            color: '#FF0000',
            title: `Email Bounce Detected for ${domain}`,
            fields: [
                {
                    title: 'Bounce Type',
                    value: bounce.bounceType,
                    short: true
                },
                {
                    title: 'Bounce Subtype',
                    value: bounce.bounceSubType,
                    short: true
                },
                {
                    title: 'Recipients',
                    value: bounce.bouncedRecipients.map(r => r.emailAddress).join(', '),
                    short: false
                },
                {
                    title: 'Timestamp',
                    value: bounce.timestamp,
                    short: true
                }
            ]
        }]
    };
}

function formatComplaintMessage(complaint, domain) {
    return {
        attachments: [{
            color: '#FFA500',
            title: `Email Complaint Received for ${domain}`,
            fields: [
                {
                    title: 'Complaint Type',
                    value: complaint.complaintFeedbackType || 'Not specified',
                    short: true
                },
                {
                    title: 'Recipients',
                    value: complaint.complainedRecipients.map(r => r.emailAddress).join(', '),
                    short: false
                },
                {
                    title: 'Timestamp',
                    value: complaint.timestamp,
                    short: true
                }
            ]
        }]
    };
}

async function sendToSlack(webhookUrl, message) {
    const { hostname, pathname } = url.parse(webhookUrl);
    
    const options = {
        hostname,
        path: pathname,
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        }
    };
    
    return new Promise((resolve, reject) => {
        const req = https.request(options, (res) => {
            let data = '';
            res.on('data', (chunk) => data += chunk);
            res.on('end', () => resolve(data));
        });
        
        req.on('error', (error) => reject(error));
        req.write(JSON.stringify(message));
        req.end();
    });
}