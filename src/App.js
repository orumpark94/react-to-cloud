import React, { useEffect, useState } from 'react';
import './App.css'; // 기존 스타일 유지

function App() {
  const [lambdaMessage, setLambdaMessage] = useState('⏳ 로딩 중...');

  useEffect(() => {
    fetch('https://093mfwagdb.execute-api.ap-northeast-2.amazonaws.com/prod/hello') 
      .then((res) => res.json())
      .then((data) => setLambdaMessage(data.message))
      .catch(() => setLambdaMessage('❌ Lambda API 호출 실패'));
  }, []);

  return (
    <div className="App">
      <header className="App-header">
        <h1>Hello SJ PARK WEBSITE 👋</h1>
        <p style={{ marginTop: '20px', fontSize: '1.2rem' }}>
          🔽 <strong>Lambda에서 응답된 메시지</strong>
        </p>
        <p style={{ backgroundColor: '#222', padding: '10px 20px', borderRadius: '8px', color: '#0f0' }}>
          {lambdaMessage}
        </p>
      </header>
    </div>
  );
}

export default App;
