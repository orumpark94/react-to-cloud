#!/bin/bash

set -e
REGION="ap-northeast-2"
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

# ✅ 4. GET 메서드 존재 확인 후 스킵 or 생성
METHOD_EXISTS=$(aws apigateway get-method \
  --rest-api-id $API_ID \
  --resource-id $HELLO_ID \
  --http-method GET \
  --region $REGION 2>/dev/null || true)

if [ -z "$METHOD_EXISTS" ]; then
  echo "🔗 GET 메서드 생성 중..."
  aws apigateway put-method \
    --rest-api-id $API_ID \
    --resource-id $HELLO_ID \
    --http-method GET \
    --authorization-type "NONE" \
    --region $REGION
else
  echo "✅ GET 메서드 이미 존재, 스킵합니다"
fi

# 5. Lambda 통합
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
LAMBDA_URI="arn:aws:apigateway:$REGION:lambda:path/2015-03-31/functions/arn:aws:lambda:$REGION:$ACCOUNT_ID:function:$LAMBDA_FUNCTION_NAME/invocations"

aws apigateway put-integration \
  --rest-api-id $API_ID \
  --resource-id $HELLO_ID \
  --http-method GET \
  --type AWS_PROXY \
  --integration-http-method POST \
  --uri "$LAMBDA_URI" \
  --region $REGION

# 6. Lambda 권한 부여
aws lambda add-permission \
  --function-name $LAMBDA_FUNCTION_NAME \
  --statement-id apigateway-access-hello \
  --action lambda:InvokeFunction \
  --principal apigateway.amazonaws.com \
  --source-arn "arn:aws:execute-api:$REGION:$ACCOUNT_ID:$API_ID/*/GET/hello" \
  --region $REGION || echo "✅ Lambda 권한 이미 존재"

# 7. 배포
echo "🚀 API Gateway 배포 중..."
aws apigateway create-deployment \
  --rest-api-id $API_ID \
  --stage-name $STAGE_NAME \
  --region $REGION

# 8. 출력
echo "✅ API Gateway 엔드포인트:"
echo "➡️  https://${API_ID}.execute-api.${REGION}.amazonaws.com/${STAGE_NAME}/hello"
