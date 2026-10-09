#!/bin/sh
set -e

# ==============================================================================
# Expo 자동 로그인 처리
# ==============================================================================
# 1) EXPO_TOKEN 환경변수가 제공된 경우 (공식 권장 방식)
if [ -n "$EXPO_TOKEN" ]; then
  echo "🔑 EXPO_TOKEN 환경변수를 감지했습니다. 인증을 확인합니다..."
  npx expo whoami || echo "⚠️ 토큰 확인 실패. 토큰 유효성을 확인해주세요."
# 2) 계정 아이디와 비밀번호가 제공된 경우
elif [ -n "$EXPO_USERNAME" ] && [ -n "$EXPO_PASSWORD" ]; then
  echo "🔑 사용자 계정 정보로 Expo 로그인을 시도합니다..."
  npx expo login -u "$EXPO_USERNAME" -p "$EXPO_PASSWORD" || echo "⚠️ 로그인 실패. 계정 정보를 확인해주세요."
else
  echo "ℹ️ 설정된 Expo 로그인 정보(EXPO_TOKEN 또는 계정 정보)가 없습니다. 게스트 모드로 진행합니다."
fi

# ==============================================================================
# Ngrok 토큰 안내 (Expo CLI는 NGROK_AUTHTOKEN 환경변수를 자동 인식합니다)
# ==============================================================================
if [ -n "$NGROK_AUTHTOKEN" ]; then
  echo "🔑 NGROK_AUTHTOKEN 환경변수를 감지했습니다."
fi

# ==============================================================================
# 명령어 실행
# ==============================================================================
# 전달된 명령어가 없거나 'npm start'인 경우
if [ $# -eq 0 ] || [ "$1" = "npm" -a "$2" = "start" ]; then
  if [ "$EXPO_TUNNEL" = "true" ]; then
    echo "🚀 Expo 개발 서버를 터널(Tunnel) 모드로 시작합니다..."
    exec npx expo start --tunnel --clear
  else
    echo "🚀 Expo 개발 서버를 시작합니다 (기본 LAN 모드)..."
    exec npx expo start --clear
  fi
fi

# 그 외 명령어(예: docker compose run app npm install 등)는 전달받은 그대로 실행
exec "$@"
