import json
import boto3
import os

# Configuration from environment variables
INSTANCE_ID = os.environ.get('EC2_ID')
EC2_REGION = os.environ.get('EC2_REGION', 'us-west-2')

ec2 = boto3.client('ec2', region_name=EC2_REGION)

# CORS headers for API Gateway responses
CORS_HEADERS = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
    'Access-Control-Allow-Methods': 'GET,POST,OPTIONS'
}


def build_response(status_code, body):
    """Build API Gateway response with CORS headers."""
    return {
        'statusCode': status_code,
        'headers': CORS_HEADERS,
        'body': json.dumps(body)
    }


def get_action_from_event(event):
    """Extract action from request - supports query params, body, and path-based routing."""
    # Check if this is a /vpn/status path (GET request)
    path = event.get('path', '')
    http_method = event.get('httpMethod', '')

    if path.endswith('/status') and http_method == 'GET':
        return 'status'

    # Check query string parameters
    query_params = event.get('queryStringParameters')
    if query_params and query_params.get('action'):
        return query_params.get('action', '').lower()

    # Check request body (API Gateway proxy sends body as JSON string)
    body = event.get('body')
    if body:
        try:
            if isinstance(body, str):
                body = json.loads(body)
            if isinstance(body, dict) and body.get('action'):
                return body.get('action', '').lower()
        except (json.JSONDecodeError, TypeError):
            pass

    # Direct invocation format (for testing)
    if event.get('action'):
        return event.get('action', '').lower()

    return ''


def lambda_handler(event, context):
    """Handle VPN control requests: start, stop, or status."""
    request_id = context.aws_request_id if context else 'local'
    print(f"[{request_id}] Received event:", json.dumps(event))

    # Validate configuration
    if not INSTANCE_ID:
        print(f"[{request_id}] Error: EC2_ID environment variable not set")
        return build_response(500, {
            'error': 'Server configuration error',
            'message': 'EC2_ID environment variable not configured'
        })

    action = get_action_from_event(event)

    if action not in ['start', 'stop', 'status']:
        print(f"[{request_id}] Invalid action: '{action}'")
        return build_response(400, {
            'error': 'Invalid action',
            'message': "Use 'start', 'stop', or 'status'.",
            'validActions': ['start', 'stop', 'status']
        })

    try:
        if action == 'start':
            ec2.start_instances(InstanceIds=[INSTANCE_ID])
            message = f"Instance {INSTANCE_ID} is starting."
            print(f"[{request_id}] Started instance {INSTANCE_ID}")

        elif action == 'stop':
            ec2.stop_instances(InstanceIds=[INSTANCE_ID])
            message = f"Instance {INSTANCE_ID} is stopping."
            print(f"[{request_id}] Stopped instance {INSTANCE_ID}")

        elif action == 'status':
            response = ec2.describe_instances(InstanceIds=[INSTANCE_ID])
            instance = response['Reservations'][0]['Instances'][0]
            state = instance['State']['Name']
            message = f"Instance {INSTANCE_ID} is currently {state}."
            print(f"[{request_id}] Instance {INSTANCE_ID} status: {state}")

            return build_response(200, {
                'message': message,
                'instanceId': INSTANCE_ID,
                'state': state,
                'action': action
            })

        return build_response(200, {
            'message': message,
            'instanceId': INSTANCE_ID,
            'action': action
        })

    except ec2.exceptions.ClientError as e:
        error_code = e.response['Error']['Code']
        error_message = e.response['Error']['Message']
        print(f"[{request_id}] EC2 ClientError: {error_code} - {error_message}")
        return build_response(500, {
            'error': 'EC2 operation failed',
            'code': error_code,
            'message': error_message
        })
    except Exception as e:
        print(f"[{request_id}] Unexpected error: {str(e)}")
        return build_response(500, {
            'error': 'Internal server error',
            'message': str(e)
        })
