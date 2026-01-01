# VPN Control API

This repository contains an AWS Lambda function and complete infrastructure-as-code (AWS SAM) for controlling a personal OpenVPN server on AWS. It's part of a larger project created during a sabbatical in Taipei to build a complete VPN solution with iOS app control.

> **Note:** The initial Lambda function was generated with ChatGPT/Claude assistance in February 2025, with API Gateway setup left as manual steps. In January 2026, [Claude Code](https://claude.ai/code) generated the complete AWS SAM deployment solution, transforming this from a "some assembly required" project into a fully deployable infrastructure-as-code package.

## Overview

This API provides a secure interface to control an EC2 instance running OpenVPN through:
- REST API endpoints using API Gateway
- Lambda function for EC2 control
- API key authentication with usage plans
- Rate limiting and throttling
- CloudWatch monitoring

The API is designed to work with:
- [VPN Infrastructure](https://github.com/rjamestaylor/vpn-infra-tf) created via Terraform
- [VPNControl iOS App](https://github.com/rjamestaylor/VPNControl-ios) for remote management

## Architecture

```
iOS App (VPNControl)
        │
        ▼
┌─────────────────────┐
│   API Gateway       │
│  ┌───────────────┐  │
│  │  API Key Auth │  │
│  │  Rate Limiting│  │
│  └───────────────┘  │
└─────────┬───────────┘
          │
          ▼
┌─────────────────────┐
│   Lambda Function   │
│   (handler.py)      │
└─────────┬───────────┘
          │
          ▼
┌─────────────────────┐
│   EC2 Instance      │
│   (OpenVPN Server)  │
└─────────────────────┘
```

## API Endpoints

| Method | Endpoint       | Description           |
|--------|----------------|-----------------------|
| POST   | `/vpn`         | Start or stop the VPN |
| GET    | `/vpn/status`  | Get instance status   |

### Actions

- `start`: Start the VPN instance
- `stop`: Stop the VPN instance
- `status`: Get current instance state

## Prerequisites

- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) configured with credentials
- [AWS SAM CLI](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-sam-cli.html)
- An EC2 instance ID for your VPN server
- Python 3.11+ (for local development)

## Quick Start

### 1. Deploy to AWS

```bash
# Set your EC2 instance ID and deploy (with optional custom domain)
EC2_INSTANCE_ID=i-1234567890abcdef0 CustomDomainName=toggle-vpn.your-domain.com make deploy
```

Or use the guided deployment for interactive setup:

```bash
make deploy-guided
```

> **Note:** The `CustomDomainName` parameter is optional. If provided, it creates a base path mapping to an existing API Gateway custom domain.

### 2. Get Your API Key

```bash
make get-api-key
```

### 3. Get API Endpoints

```bash
make outputs
```

## Deployment Options

### Using Make (Recommended)

```bash
# Build the application
make build

# Validate the SAM template
make validate

# Deploy with custom settings
EC2_INSTANCE_ID=i-xxx EC2_REGION=us-west-2 STAGE=prod make deploy

# View deployment outputs
make outputs

# Tail Lambda logs
make logs

# Delete the stack
make delete
```

### Using SAM CLI Directly

```bash
# Build
sam build

# Deploy
sam deploy \
  --stack-name vpn-control-api \
  --capabilities CAPABILITY_IAM \
  --resolve-s3 \
  --parameter-overrides \
    EC2InstanceId=i-1234567890abcdef0 \
    EC2Region=us-west-2 \
    StageName=prod
```

### Configuration Parameters

| Parameter          | Default     | Description                              |
|--------------------|-------------|------------------------------------------|
| EC2InstanceId      | (required)  | EC2 instance ID to control               |
| EC2Region          | us-west-2   | AWS region of the EC2 instance           |
| StageName          | prod        | API Gateway stage name                   |
| ThrottleRateLimit  | 10          | Max requests per second                  |
| ThrottleBurstLimit | 20          | Max concurrent requests                  |
| QuotaLimit         | 1000        | Max requests per month                   |
| CustomDomainName   | (empty)     | Custom domain name (e.g., toggle-vpn.your-domain.com) |

## Usage Examples

### Start VPN Instance

```bash
curl -X POST "https://your-api-id.execute-api.us-west-2.amazonaws.com/prod/vpn" \
     -H "x-api-key: your-api-key" \
     -H "Content-Type: application/json" \
     -d '{"action": "start"}'
```

### Check Status

```bash
curl -X GET "https://your-api-id.execute-api.us-west-2.amazonaws.com/prod/vpn/status" \
     -H "x-api-key: your-api-key"
```

### Stop VPN Instance

```bash
curl -X POST "https://your-api-id.execute-api.us-west-2.amazonaws.com/prod/vpn" \
     -H "x-api-key: your-api-key" \
     -H "Content-Type: application/json" \
     -d '{"action": "stop"}'
```

## Response Format

### Successful Response

```json
{
    "message": "Instance i-1234567890abcdef0 is starting.",
    "instanceId": "i-1234567890abcdef0",
    "action": "start"
}
```

### Status Response

```json
{
    "message": "Instance i-1234567890abcdef0 is currently running.",
    "instanceId": "i-1234567890abcdef0",
    "state": "running",
    "action": "status"
}
```

### Error Response

```json
{
    "error": "Invalid action",
    "message": "Use 'start', 'stop', or 'status'.",
    "validActions": ["start", "stop", "status"]
}
```

## Local Development

### Setup

```bash
# Create local environment configuration
cp env.json.example env.json
# Edit env.json with your EC2 instance ID
```

### Run Locally

```bash
# Start local API Gateway
make local

# Test a specific event
sam local invoke VPNControlFunction --event events/status.json --env-vars env.json
```

## Security

### Built-in Security Features

1. **API Key Authentication**: All endpoints require a valid API key via `x-api-key` header
2. **Usage Plans**: Rate limiting (10 req/sec) and monthly quotas (1000 req/month)
3. **IAM Least Privilege**: Lambda has minimal EC2 permissions for the specific instance
4. **CORS Configuration**: Configured for cross-origin requests
5. **CloudWatch Logging**: All requests and errors are logged

### Security Best Practices

- **Never commit API keys** to source control
- **Rotate API keys** periodically via the AWS Console
- **Restrict instance scope** - IAM policy limits actions to your specific EC2 instance
- **Enable CloudWatch alarms** for unusual activity
- **Consider VPC endpoints** for enhanced network security

## Monitoring

### CloudWatch Logs

Lambda function logs are available at:
```
/aws/lambda/{stack-name}-vpn-control
```

API Gateway logs (when enabled):
```
/aws/apigateway/{stack-name}
```

### Tail Logs in Real-Time

```bash
make logs
```

### Key Metrics to Monitor

- API Gateway 4xx/5xx error rates
- Lambda execution duration and errors
- Throttling and API key usage

## Project Structure

```
vpn-control-api/
├── handler.py           # Lambda function code
├── template.yaml        # SAM/CloudFormation template
├── samconfig.toml       # SAM CLI configuration
├── Makefile             # Build and deployment commands
├── requirements.txt     # Python dependencies
├── env.json.example     # Local development config template
├── events/              # Test events for local development
│   ├── start.json
│   ├── stop.json
│   └── status.json
└── README.md
```

## Troubleshooting

### "EC2_ID environment variable not configured"

The Lambda function's EC2_ID environment variable is not set. Redeploy with the correct EC2InstanceId parameter.

### "Invalid instance ID" errors

Verify your EC2 instance ID format matches `i-` followed by 8-17 alphanumeric characters.

### 403 Forbidden

- Check that you're including the `x-api-key` header
- Verify the API key is correct and associated with the usage plan
- Check if you've exceeded rate limits or quota

### Lambda timeout

The default timeout is 30 seconds. If EC2 operations are slow, consider increasing the timeout in `template.yaml`.

## Related Projects

- [VPN Infrastructure Terraform](https://github.com/rjamestaylor/vpn-infra-tf)
- [VPNControl iOS App](https://github.com/rjamestaylor/VPNControl-ios)

## Contributing

1. Fork the repository
2. Create a feature branch
3. Submit a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- AWS for the serverless platform
- ChatGPT and Claude for initial Lambda function code generation (February 2025)
- [Claude Code](https://claude.ai/code) for complete AWS SAM infrastructure-as-code solution (January 2026)
