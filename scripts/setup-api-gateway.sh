#!/bin/bash

set -e

# ✅ 환경변수 설정
REGION="${REGION:-ap-northeast-2}"
API_NAME="sjpark-api"
LAMBDA_FUNCTION_NAME="hello-sjpark"
STAGE_NAME="prod"

echo "🔍 API Gateway 이름: $API_NAME"
echo "🔍 리전: $REGION"
echo "🔍 연결할 Lambda 함수: $LAMBDA_FUNCTION_NAME"

# 1. API 존재 확인
API_ID=$(aws apigateway get-rest-apis --region $REGION \
  --query "items[?name=='$API_NAME'].id" --output text)

if [ -z "$API_ID" ]; then
  echo "🚀 API Gateway '$API_NAME' 생성 중..."
  API_ID=$(aws apigateway create-rest-api --name "$API_NAME" \
    --region $REGION --query 'id' --output text)
else
  echo "✅ 기존 API 사용: $API_ID"
fi

# 2. 루트 리소스 ID
ROOT_ID=$(aws apigateway get-resources --rest-api-id $API_ID \
  --region $REGION --query 'items[?path==`/`].id' --output text)

# 3. /hello 리소스
HELLO_ID=$(aws apigateway get-resources --rest-api-id $API_ID \
  --region $REGION --query "items[?path=='/hello'].id" --output text)

if [ -z "$HELLO_ID" ]; then
  echo "🔧 /hello 리소스 생성 중..."
  HELLO_ID=$(aws apigateway create-resource \
    --rest-api-id $API_ID \
    --region $REGION \
    --parent-id $ROOT_ID \
    --path-part hello \
    --query 'id' --output text)
else
  echo "✅ /hello 리소스 존재: $HELLO_ID"
fi

# 4. GET 메서드 생성
echo "🔄 기존 GET 메서드 삭제 및 재생성 시도..."
aws apigateway delete-method \
  --rest-api-id $API_ID \
  --resource-id $HELLO_ID \
  --http-method GET \
  --region $REGION 2>/dev/null || true

echo "🔗 GET 메서드 생성 중..."
aws apigateway put-method \
  --rest-api-id $API_ID \
  --resource-id $HELLO_ID \
  --http-method GET \
  --authorization-type "NONE" \
  --region $REGION

# 5. Lambda 비프록시 통합
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
LAMBDA_URI="arn:aws:apigateway:$REGION:lambda:path/2015-03-31/functions/arn:aws:lambda:$REGION:$ACCOUNT_ID:function:$LAMBDA_FUNCTION_NAME/invocations"

aws apigateway put-integration \
  --rest-api-id $API_ID \
  --resource-id $HELLO_ID \
  --http-method GET \
  --type AWS \
  --integration-http-method POST \
  --uri "$LAMBDA_URI" \
  --request-templates '{"application/json":"{\"statusCode\": 200}"}' \
  --region $REGION

# 6. Lambda 권한 부여 전 제거
aws lambda remove-permission \
  --function-name $LAMBDA_FUNCTION_NAME \
  --statement-id apigateway-access-hello \
  --region $REGION 2>/dev/null || true

aws lambda add-permission \
  --function-name $LAMBDA_FUNCTION_NAME \
  --statement-id apigateway-access-hello \
  --action lambda:InvokeFunction \
  --principal apigateway.amazonaws.com \
  --source-arn "arn:aws:execute-api:$REGION:$ACCOUNT_ID:$API_ID/*/GET/hello" \
  --region $REGION

# 7. GET 응답 구성 (CORS 헤더 포함)
aws apigateway delete-method-response \
  --rest-api-id $API_ID \
  --resource-id $HELLO_ID \
  --http-method GET \
  --status-code 200 \
  --region $REGION 2>/dev/null || true

aws apigateway delete-integration-response \
  --rest-api-id $API_ID \
  --resource-id $HELLO_ID \
  --http-method GET \
  --status-code 200 \
  --region $REGION 2>/dev/null || true

aws apigateway put-method-response \
  --rest-api-id $API_ID \
  --resource-id $HELLO_ID \
  --http-method GET \
  --status-code 200 \
  --response-models '{"application/json":"Empty"}' \
  --response-parameters 'method.response.header.Access-Control-Allow-Origin=true,method.response.header.Access-Control-Allow-Methods=true,method.response.header.Access-Control-Allow-Headers=true' \
  --region $REGION

aws apigateway put-integration-response \
  --rest-api-id $API_ID \
  --resource-id $HELLO_ID \
  --http-method GET \
  --status-code 200 \
  --response-parameters "method.response.header.Access-Control-Allow-Origin='*',method.response.header.Access-Control-Allow-Methods='GET,OPTIONS',method.response.header.Access-Control-Allow-Headers='*'" \
  --response-templates '{"application/json":"$input.body"}' \
  --region $REGION

# 8. OPTIONS 메서드 (CORS 대응)
echo "🔄 OPTIONS 메서드 삭제 후 재설정..."
aws apigateway delete-method \
  --rest-api-id $API_ID \
  --resource-id $HELLO_ID \
  --http-method OPTIONS \
  --region $REGION 2>/dev/null || true

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
  --response-parameters "method.response.header.Access-Control-Allow-Headers='*',method.response.header.Access-Control-Allow-Methods='GET,OPTIONS',method.response.header.Access-Control-Allow-Origin='*'" \
  --region $REGION

# 9. 배포
echo "🚀 API Gateway 배포 중..."
aws apigateway create-deployment \
  --rest-api-id $API_ID \
  --stage-name $STAGE_NAME \
  --region $REGION

# 10. 출력
echo "✅ API Gateway 엔드포인트:"
echo "➡️  https://${API_ID}.execute-api.${REGION}.amazonaws.com/${STAGE_NAME}/hello"
