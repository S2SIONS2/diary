# ==============================================================================
# React Native + Expo 개발용 Dockerfile
# ==============================================================================

# 1. Node.js 베이스 이미지 설정
FROM node:20-slim

# 2. 필수 시스템 패키지 설치
# git, curl 및 ngrok 터널링 구동에 필요한 라이브러리 설치
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# 3. 작업 디렉토리 지정
WORKDIR /app

# 4. 터널링에 필요한 라이브러리 설치
# (최신 Expo는 프로젝트 내부의 로컬 CLI(npx expo)를 사용하므로 레거시 글로벌 expo-cli는 불필요합니다)
RUN npm install -g @expo/ngrok

# 5. 소스 코드 복사 (Compose Watch 사용 시 초기 컨테이너 파일 보장)
COPY . /app

# 6. Expo 및 Metro 번들러 포트 노출
EXPOSE 8081 19000 19001 19002

# 7. 진입점(Entrypoint) 스크립트 복사 및 실행 권한 부여
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# 7. 엔트리포인트 지정 (자동 로그인 및 터널 모드 시작 처리)
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
