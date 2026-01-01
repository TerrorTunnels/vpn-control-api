#!/bin/bash
# VPN Control API Test Harness
# Usage: ./test.sh [command]
# Commands: status, start, stop, all

set -e

# Configuration - set these or export as environment variables
API_ENDPOINT="${API_ENDPOINT:-https://toggle-vpn.your-domain.com}"
API_KEY="${API_KEY:-}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check for API key
if [[ -z "$API_KEY" ]]; then
    echo -e "${RED}Error: API_KEY environment variable is required${NC}"
    echo ""
    echo "Usage:"
    echo "  API_KEY=your-api-key ./test.sh [command]"
    echo ""
    echo "Commands:"
    echo "  status  - Get VPN instance status"
    echo "  start   - Start the VPN instance"
    echo "  stop    - Stop the VPN instance"
    echo "  all     - Run all tests in sequence"
    echo ""
    echo "Environment variables:"
    echo "  API_KEY      - Required: Your API Gateway API key"
    echo "  API_ENDPOINT - Optional: API endpoint (default: https://toggle-vpn.your-domain.com)"
    exit 1
fi

# Helper function to make requests
request() {
    local method=$1
    local endpoint=$2
    local data=$3

    echo -e "${BLUE}>>> $method $endpoint${NC}"
    if [[ -n "$data" ]]; then
        echo -e "${YELLOW}    Body: $data${NC}"
    fi
    echo ""

    local start_time=$(date +%s%N)

    if [[ "$method" == "GET" ]]; then
        response=$(curl -s -w "\n%{http_code}" \
            -X GET "${API_ENDPOINT}${endpoint}" \
            -H "x-api-key: ${API_KEY}")
    else
        response=$(curl -s -w "\n%{http_code}" \
            -X POST "${API_ENDPOINT}${endpoint}" \
            -H "x-api-key: ${API_KEY}" \
            -H "Content-Type: application/json" \
            -d "$data")
    fi

    local end_time=$(date +%s%N)
    local duration=$(( (end_time - start_time) / 1000000 ))

    # Split response body and status code
    local http_code=$(echo "$response" | tail -n1)
    local body=$(echo "$response" | sed '$d')

    # Color based on status code
    if [[ "$http_code" =~ ^2 ]]; then
        echo -e "${GREEN}<<< HTTP $http_code${NC} (${duration}ms)"
    elif [[ "$http_code" =~ ^4 ]]; then
        echo -e "${YELLOW}<<< HTTP $http_code${NC} (${duration}ms)"
    else
        echo -e "${RED}<<< HTTP $http_code${NC} (${duration}ms)"
    fi

    # Pretty print JSON if jq is available
    if command -v jq &> /dev/null; then
        echo "$body" | jq . 2>/dev/null || echo "$body"
    else
        echo "$body"
    fi
    echo ""
}

# Test functions
test_status() {
    echo -e "${GREEN}=== Testing Status Endpoint ===${NC}"
    request "GET" "/vpn/status"
}

test_start() {
    echo -e "${GREEN}=== Testing Start Endpoint ===${NC}"
    request "POST" "/vpn" '{"action": "start"}'
}

test_stop() {
    echo -e "${GREEN}=== Testing Stop Endpoint ===${NC}"
    request "POST" "/vpn" '{"action": "stop"}'
}

test_invalid() {
    echo -e "${GREEN}=== Testing Invalid Action (should return 400) ===${NC}"
    request "POST" "/vpn" '{"action": "invalid"}'
}

test_all() {
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  VPN Control API Test Suite${NC}"
    echo -e "${GREEN}  Endpoint: ${API_ENDPOINT}${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""

    test_status
    sleep 1

    test_invalid
    sleep 1

    echo -e "${YELLOW}Note: Start/Stop tests will actually control your EC2 instance.${NC}"
    echo -e "${YELLOW}Run './test.sh start' or './test.sh stop' individually to test those.${NC}"
    echo ""

    echo -e "${GREEN}=== Test Suite Complete ===${NC}"
}

# Main
case "${1:-status}" in
    status)
        test_status
        ;;
    start)
        test_start
        ;;
    stop)
        test_stop
        ;;
    invalid)
        test_invalid
        ;;
    all)
        test_all
        ;;
    *)
        echo "Unknown command: $1"
        echo "Valid commands: status, start, stop, invalid, all"
        exit 1
        ;;
esac
