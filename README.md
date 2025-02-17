# VPN Control API

This repository contains the AWS Lambda function and API Gateway setup instructions for controlling a personal OpenVPN server on AWS. It's part of a larger project created during a sabbatical in Taipei to build a complete VPN solution with iOS app control. The Lambda code was generated with assistance from AI tools (ChatGPT and Claude).

## Overview

This API provides a secure interface to control an EC2 instance running OpenVPN through:
- REST API endpoints using API Gateway
- Lambda function for EC2 control
- API key authentication
- Status monitoring capabilities

The API is designed to work with:
- [VPN Infrastructure](https://github.com/rjamestaylor/vpn-infra-tf) created via Terraform
- [VPNControl iOS App](https://github.com/rjamestaylor/VPNControl-ios) for remote management

## API Endpoints

The API provides these endpoints:

```
POST /vpn
GET  /vpn/status
```

### Actions
- `start`: Start the VPN instance
- `stop`: Stop the VPN instance
- `status`: Get current instance state

## Lambda Function

The Lambda function (`handler.py`) manages EC2 instance operations:

```python
def lambda_handler(event, context):
    action = ""
    if "queryStringParameters" in event and event["queryStringParameters"] is not None:
        action = event["queryStringParameters"].get("action", "").lower()
    elif "action" in event and event["action"] is not None:
        action = event.get("action", "").lower()
    
    # Handle start/stop/status actions
    try:
        if action == "start":
            ec2.start_instances(InstanceIds=[INSTANCE_ID])
            message = f"Instance {INSTANCE_ID} is starting."
        # ... additional action handling
```

## Setup Instructions

### Step 1: Create IAM Role

1. Go to IAM Console → Create role
2. Select AWS Service → Lambda
3. Attach these policies:
   - AWSLambdaBasicExecutionRole
   - Custom EC2 control policy:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:StartInstances",
                "ec2:StopInstances",
                "ec2:DescribeInstances"
            ],
            "Resource": "arn:aws:ec2:your-region:your-account-id:instance/*"
        }
    ]
}
```

### Step 2: Deploy Lambda Function

1. Create new Lambda function:
   - Author from scratch
   - Runtime: Python 3.9+
   - Attach IAM role from Step 1

2. Set environment variables:
   - `EC2_ID`: Your VPN instance ID

3. Upload `handler.py` code

### Step 3: Create API Gateway

1. Create REST API
2. Create resource "/vpn"
3. Add methods:
   - POST for control actions
   - GET for status
4. Integration setup:
   - Type: Lambda Function
   - Lambda Proxy integration: Yes
   - Lambda Function: Select your function

### Step 4: Security Configuration

1. Enable API key requirement:
   - Method Request settings
   - Set "API Key Required" to true

2. Create API key:
   - API Gateway → API Keys
   - Create new key
   - Add to Usage Plan

3. CORS configuration (if needed):
   - Enable CORS in API Gateway
   - Allow necessary headers

### Step 5: Deployment

1. Deploy API:
   - Create new stage (e.g., "prod")
   - Note the Invoke URL
   - Save API key for client use

## Usage Examples

### Start VPN Instance
```bash
curl -X POST "https://your-api-id.execute-api.your-region.amazonaws.com/prod/vpn" \
     -H "x-api-key: your-api-key" \
     -H "Content-Type: application/json" \
     -d '{"action": "start"}'
```

### Check Status
```bash
curl -X GET "https://your-api-id.execute-api.your-region.amazonaws.com/prod/vpn/status" \
     -H "x-api-key: your-api-key"
```

### Stop VPN Instance
```bash
curl -X POST "https://your-api-id.execute-api.your-region.amazonaws.com/prod/vpn" \
     -H "x-api-key: your-api-key" \
     -H "Content-Type: application/json" \
     -d '{"action": "stop"}'
```

## Response Format

Successful response:
```json
{
    "statusCode": 200,
    "body": {
        "message": "Instance i-1234567890abcdef0 is starting."
    }
}
```

Error response:
```json
{
    "statusCode": 400,
    "body": {
        "message": "Invalid action. Use 'start', 'stop', or 'status'."
    }
}
```

## Security Considerations

1. API Key Protection:
   - Never commit API keys to source control
   - Rotate keys periodically
   - Use Usage Plans to limit request rates

2. IAM Permissions:
   - Follow principle of least privilege
   - Restrict EC2 actions to specific instance
   - Enable CloudWatch logging

3. Network Security:
   - Enable HTTPS only
   - Configure CORS appropriately
   - Consider VPC endpoints for added security

## Monitoring and Maintenance

1. CloudWatch Logs:
   - Lambda function logs
   - API Gateway access logs
   - Errors and debugging information

2. Metrics to Monitor:
   - API Gateway 4xx/5xx errors
   - Lambda execution duration
   - Lambda throttling
   - API key usage

## Related Projects

- [VPN Infrastructure Terraform](https://github.com/rjamestaylor/vpn-infra-tf)
- [VPNControl iOS App](https://github.com/rjamestaylor/VPNControl-ios)

## Contributing

1. Fork the repository
2. Create a feature branch
3. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- AWS for the serverless platform
- ChatGPT and Claude for code generation assistance

## Contact

For questions or suggestions, please open an issue in the repository.