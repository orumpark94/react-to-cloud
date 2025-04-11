

![image](https://github.com/user-attachments/assets/8433b15f-fff4-4009-9714-9d07e4229246)

# 구성 목표

이 프로젝트는 GitHub Actions를 활용하여 React 애플리케이션을 AWS S3에 정적 웹 호스팅하고, AWS Lambda와 API Gateway를 통해 서버리스 백엔드를 구성하는 자동화된 CI/CD 파이프라인을 구축하는 것을 목표로 합니다.


# 구성 순서도

![image](https://github.com/user-attachments/assets/e486c5db-1ec5-40ac-bb9e-53bfae6c1af6)

react app S3 build → deploy

![image](https://github.com/user-attachments/assets/f6eb718b-3af8-4f42-af46-2e0c8286947c)

→ react app deploy 완료

![image](https://github.com/user-attachments/assets/f91f77b7-aa5e-4a1a-bea6-ad187818ccbc)

→ 기본 index.html 파일 수정

![image](https://github.com/user-attachments/assets/5055f5b7-16b0-4d98-be01-4adf6bb1a239)

→Lambda 코드 및 API Gateway 코드 deploy

![image](https://github.com/user-attachments/assets/e90a6952-a0c6-4101-b035-9d7a83055ce6)
![image](https://github.com/user-attachments/assets/feaa086a-809b-436b-9661-06975d2a4a47)

→ 코드 내용

# 실행 결과

![image](https://github.com/user-attachments/assets/81cc1cea-6073-48fe-a1e3-c8b2d0d4896b)

→ s3 버킷 위 react app 

![image](https://github.com/user-attachments/assets/5b1f1845-fcb7-404e-b43a-812ec5a9bec7)

→ Lambda 구성 완료

![image](https://github.com/user-attachments/assets/73ec1c91-67f7-47c0-8513-6ac5c06d145c)

→ API Gateway 구성 완료

![image](https://github.com/user-attachments/assets/52e0d000-86ec-4c6d-a251-58fdcf40077f)

→ 구성 완료된 웹 서버
