exports.handler = async (event) => {
  return {
    statusCode: 200,
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Headers': '*',     // ✅ 중요: 사전 요청 허용
      'Access-Control-Allow-Methods': 'GET,OPTIONS', // ✅ 중요: 허용 메서드
    },
    body: JSON.stringify({ message: "Hello SJ PARK from Lambda!" }),
  };
};
