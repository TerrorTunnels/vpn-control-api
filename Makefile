# VPN Control API - Makefile
# Requires AWS SAM CLI: https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-sam-cli.html

.PHONY: help build deploy delete logs local validate clean test-local

# Default target
help:
	@echo "VPN Control API - Available targets:"
	@echo ""
	@echo "  make build          - Build the SAM application"
	@echo "  make deploy         - Deploy to AWS (requires EC2_INSTANCE_ID)"
	@echo "  make deploy-guided  - Interactive deployment with prompts"
	@echo "  make delete         - Delete the CloudFormation stack"
	@echo "  make logs           - Tail Lambda function logs"
	@echo "  make local          - Start local API Gateway for testing"
	@echo "  make validate       - Validate the SAM template"
	@echo "  make clean          - Remove build artifacts"
	@echo "  make test-local     - Run local test invocation"
	@echo "  make get-api-key    - Retrieve the API key value after deployment"
	@echo ""
	@echo "Environment variables:"
	@echo "  EC2_INSTANCE_ID     - Required for deployment (e.g., i-1234567890abcdef0)"
	@echo "  EC2_REGION          - AWS region (default: us-west-2)"
	@echo "  STAGE               - Deployment stage (default: prod)"
	@echo "  STACK_NAME          - CloudFormation stack name (default: vpn-control-api)"
	@echo "  CustomDomainName    - Custom domain to map API to (optional)"
	@echo ""
	@echo "Example:"
	@echo "  EC2_INSTANCE_ID=i-1234567890abcdef0 CustomDomainName=toggle-vpn.example.com make deploy"

# Variables with defaults
STACK_NAME ?= vpn-control-api
EC2_REGION ?= us-west-2
STAGE ?= prod

# Validate required variables for deployment
check-instance-id:
ifndef EC2_INSTANCE_ID
	$(error EC2_INSTANCE_ID is required. Example: EC2_INSTANCE_ID=i-1234567890abcdef0 make deploy)
endif

# Build the SAM application
build:
	sam build

# Validate the SAM template
validate:
	sam validate --lint

# Deploy to AWS
deploy: check-instance-id build
	sam deploy \
		--stack-name $(STACK_NAME) \
		--capabilities CAPABILITY_IAM \
		--resolve-s3 \
		--parameter-overrides \
			EC2InstanceId=$(EC2_INSTANCE_ID) \
			EC2Region=$(EC2_REGION) \
			StageName=$(STAGE) \
			$(if $(CustomDomainName),CustomDomainName=$(CustomDomainName),)

# Interactive guided deployment
deploy-guided: build
	sam deploy --guided

# Delete the stack
delete:
	sam delete --stack-name $(STACK_NAME)

# Tail Lambda logs
logs:
	sam logs --stack-name $(STACK_NAME) --tail

# Start local API for testing
local: build
	@echo "Starting local API Gateway..."
	@echo "Note: Set EC2_ID environment variable for the Lambda function"
	sam local start-api --env-vars env.json 2>/dev/null || \
		(echo "Create env.json with: {\"VPNControlFunction\": {\"EC2_ID\": \"i-xxx\", \"EC2_REGION\": \"us-west-2\"}}" && exit 1)

# Local test invocation
test-local: build
	@echo "Testing status action..."
	sam local invoke VPNControlFunction --event events/status.json --env-vars env.json 2>/dev/null || \
		echo "Create events/status.json and env.json for local testing"

# Get the API key value after deployment
get-api-key:
	@echo "Retrieving API key..."
	@aws cloudformation describe-stacks \
		--stack-name $(STACK_NAME) \
		--query "Stacks[0].Outputs[?OutputKey=='ApiKeyId'].OutputValue" \
		--output text | xargs -I {} aws apigateway get-api-key --api-key {} --include-value --query 'value' --output text

# Show stack outputs (endpoints, etc.)
outputs:
	@aws cloudformation describe-stacks \
		--stack-name $(STACK_NAME) \
		--query "Stacks[0].Outputs" \
		--output table

# Clean build artifacts
clean:
	rm -rf .aws-sam/
	rm -f packaged.yaml packaged-template.yaml
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete 2>/dev/null || true
