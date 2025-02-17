## Building the VPN Control REST API 

*Note: ChatGPT didn't create code to implement the API Gateway, but did provide step-by-step instructions on how to implement the API Gateway REST-API, as follows:*

Here’s a high-level plan for setting up an AWS API Gateway + Lambda solution to start and stop a specific EC2 instance when invoked with an API key.

Solution Overview
	1.	API Gateway: A REST API that provides two endpoints (/start and /stop) secured with an API key.
	2.	Lambda Function: A Python-based Lambda function that handles the API requests and interacts with EC2.
	3.	IAM Role & Permissions: A role allowing the Lambda function to start and stop EC2 instances.
	4.	API Key Security: API Gateway requires a valid API key for invocation.

Implementation Steps

Step 1: Create an IAM Role for Lambda
	1.	Go to the IAM Console → Create a role.
	2.	Select AWS Service → Lambda.
	3.	Attach the following policies:
	•	AWSLambdaBasicExecutionRole
	•	A custom policy for EC2 start/stop permissions:

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


	4.	Attach the policy to the Lambda role.

Step 2: Create a Lambda Function
	1.	Go to AWS Lambda Console → Create a function.
	2.	Select Author from scratch.
	3.	Use Python 3.9+ as the runtime.
	4.	Attach the IAM role created in Step 1.
	5.	Add the [handler.py](handler.py) code

Step 3: Create an API Gateway
	1.	Go to API Gateway Console → Create REST API.
	2.	Create a resource ”/vpn”.
	3.	Add a POST method.
	4.	Set Integration Type to “Lambda Function.”
	5.	Select the created Lambda function.

Step 4: Secure API with API Key
	1.	In API Gateway, go to Method Request and:
	•	Set “API Key Required” to true.
	2.	Create an API Key in API Gateway.
	3.	Attach the API Key to a Usage Plan.

Step 5: Deploy the API
	1.	Click Deploy API.
	2.	Create a new stage (e.g., “prod”).
	3.	Copy the Invoke URL.

Using the API

Start EC2 Instance

curl -X POST "https://your-api-id.execute-api.your-region.amazonaws.com/prod/vpn" \
     -H "x-api-key: your-api-key" \
     -H "Content-Type: application/json" \
     -d '{"action": "start"}'

Stop EC2 Instance

curl -X POST "https://your-api-id.execute-api.your-region.amazonaws.com/prod/vpn" \
     -H "x-api-key: your-api-key" \
     -H "Content-Type: application/json" \
     -d '{"action": "stop"}'

Next Steps
	•	You can configure CloudWatch Alarms to monitor instance status.
	•	Enable IAM authentication instead of an API key for better security.
	•	Set up a custom domain for the API.

Would you like me to refine any part of this implementation? 🚀