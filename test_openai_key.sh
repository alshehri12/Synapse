#!/bin/bash
# Test OpenAI API Key directly
# This script tests if your OpenAI API key works with the moderations endpoint

echo "🔍 Testing OpenAI API Key..."
echo ""

# Get API key from Info.plist
API_KEY=$(plutil -p Synapse/Info.plist | grep "OpenAIAPIKey" | cut -d'"' -f4)

if [ -z "$API_KEY" ]; then
    echo "❌ ERROR: Could not find OpenAI API key in Info.plist"
    exit 1
fi

echo "🔑 API Key found (first 20 chars): ${API_KEY:0:20}..."
echo ""
echo "📤 Sending test request to OpenAI Moderations API..."
echo ""

# Make request to OpenAI
response=$(curl -s -w "\nHTTP_STATUS:%{http_code}" \
  https://api.openai.com/v1/moderations \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $API_KEY" \
  -d '{
    "input": "This is a test message"
  }')

# Extract HTTP status code
http_status=$(echo "$response" | grep "HTTP_STATUS:" | cut -d':' -f2)
body=$(echo "$response" | sed '/HTTP_STATUS:/d')

echo "📥 Response Status: $http_status"
echo ""

if [ "$http_status" = "200" ]; then
    echo "✅ SUCCESS! Your API key is working correctly!"
    echo ""
    echo "Response body:"
    echo "$body" | python3 -m json.tool 2>/dev/null || echo "$body"
elif [ "$http_status" = "400" ]; then
    echo "❌ ERROR 400: Bad Request"
    echo ""
    echo "This usually means:"
    echo "  1. Invalid API key format"
    echo "  2. API key has been revoked or expired"
    echo "  3. API key doesn't have access to moderations endpoint"
    echo ""
    echo "Error response:"
    echo "$body" | python3 -m json.tool 2>/dev/null || echo "$body"
    echo ""
    echo "🔧 SOLUTION:"
    echo "  1. Go to: https://platform.openai.com/api-keys"
    echo "  2. Check if your key is still active"
    echo "  3. Generate a new API key"
    echo "  4. Update it in Synapse/Info.plist"
elif [ "$http_status" = "401" ]; then
    echo "❌ ERROR 401: Unauthorized"
    echo ""
    echo "Your API key is invalid or has been revoked."
    echo ""
    echo "🔧 SOLUTION:"
    echo "  1. Go to: https://platform.openai.com/api-keys"
    echo "  2. Generate a new API key"
    echo "  3. Update it in Synapse/Info.plist"
elif [ "$http_status" = "429" ]; then
    echo "⚠️ ERROR 429: Rate Limited"
    echo ""
    echo "You've hit your rate limit. Wait a few minutes and try again."
else
    echo "❌ ERROR: Unexpected status code: $http_status"
    echo ""
    echo "Response:"
    echo "$body"
fi

echo ""
echo "─────────────────────────────────────────────"
echo "Next steps:"
echo "1. If you see 'SUCCESS' above, your API key works!"
echo "2. If you see an error, follow the solution steps"
echo "3. After fixing, rebuild and test the app"
