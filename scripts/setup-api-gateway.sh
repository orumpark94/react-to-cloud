# 4.5 OPTIONS 메서드 설정 (CORS 대응용)
OPTIONS_EXISTS=$(aws apigateway get-method \
  --rest-api-id $API_ID \
  --resource-id $HELLO_ID \
  --http-method OPTIONS \
  --region $REGION 2>/dev/null || true)

if [ -z "$OPTIONS_EXISTS" ]; then
  echo "🛠 OPTIONS 메서드 생성 중 (CORS 대응)..."

  aws apigateway put-method \
    --rest-api-id $API_ID \
    --resource-id $HELLO_ID \
    --http-method OPTIONS \
    --authorization-type "NONE" \
    --region $REGION

  aws apigateway put-integration \
    --rest-api-id $API_ID \
    --resource-id $HELLO_ID \
    --http-method OPTIONS \
    --type MOCK \
    --request-templates '{"application/json":"{\"statusCode\": 200}"}' \
    --region $REGION

  aws apigateway put-method-response \
    --rest-api-id $API_ID \
    --resource-id $HELLO_ID \
    --http-method OPTIONS \
    --status-code 200 \
    --response-models '{"application/json":"Empty"}' \
    --response-parameters 'method.response.header.Access-Control-Allow-Headers=true,method.response.header.Access-Control-Allow-Methods=true,method.response.header.Access-Control-Allow-Origin=true' \
    --region $REGION

  aws apigateway put-integration-response \
    --rest-api-id $API_ID \
    --resource-id $HELLO_ID \
    --http-method OPTIONS \
    --status-code 200 \
    --response-parameters 'method.response.header.Access-Control-Allow-Headers="*",method.response.header.Access-Control-Allow-Methods="GET,OPTIONS",method.response.header.Access-Control-Allow-Origin="*"' \
    --region $REGION

else
  echo "✅ OPTIONS 메서드 이미 존재, 스킵합니다"
fi
