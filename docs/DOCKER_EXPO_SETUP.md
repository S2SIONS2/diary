# 🐳 Diary 프로젝트 Docker & Expo 개발 환경 가이드

> **프로젝트 개요**: 본 문서는 **Diary** 모바일 앱(React Native + Expo SDK 57)의 도커(Docker) 기반 개발 환경 및 Expo 설정, 실행 방법, 문제 해결(트러블슈팅) 내용을 정리한 가이드입니다.

---

## 📌 1. 아키텍처 및 주요 기술 스택

| 분류 | 기술 및 버전 | 설명 |
| :--- | :--- | :--- |
| **Core Framework** | React Native 0.86.3, Expo SDK ~57.0.26 | 최신 React 19 기반 모바일 앱 개발 환경 |
| **State & Data** | Zustand, TanStack React Query | 전역 상태 관리 및 서버 비동기 데이터 캐싱 |
| **Container Engine** | Docker & Docker Compose | 일관된 개발 환경 제공 및 종속성 격리 |
| **Bundler / Watcher** | Metro Bundler + Polling Watcher | Windows 호스트와 Linux 도커 간 핫 리로드(Fast Refresh) 동기화 |
| **Tunneling** | @expo/ngrok | 로컬 네트워크(동일 Wi-Fi) 제약 없이 모바일 기기(Expo Go) 접속 지원 |

---

## ⚙️ 2. 도커(Docker) 구성 상세

### 2.1. Dockerfile (`Dockerfile`)
Node.js 20 경량화 이미지를 기반으로 Expo 개발 및 터널링에 필요한 최소한의 시스템 패키지만 설치하여 구성되었습니다.

```dockerfile
FROM node:20-slim

# git, curl 및 ngrok 터널링 구동에 필요한 라이브러리 설치
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 터널링에 필요한 ngrok 글로벌 설치
RUN npm install -g @expo/ngrok

COPY . /app

# Expo 및 Metro 번들러 포트 노출
EXPOSE 8081 19000 19001 19002

# 엔트리포인트 실행 권한 부여 및 지정
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
```

#### 핵심 포인트
- **`@expo/ngrok`**: 최신 Expo는 프로젝트 로컬 CLI(`npx expo`)를 사용하므로 레거시 글로벌 `expo-cli`를 설치하지 않고, 터널 구동에 필요한 `@expo/ngrok`만 설치합니다.
- **포트 노출 (EXPOSE)**:
  - `8081`: Metro Bundler 기본 포트 (Fast Refresh, 웹 브라우저 접속)
  - `19000`: Expo 개발 도구 메인 포트
  - `19001`: Metro 번들러 리버스 프록시 포트
  - `19002`: Expo DevTools 웹 대시보드 포트

---

### 2.2. Docker Compose (`docker-compose.yml`)
Windows 호스트와 도커 컨테이너 간의 파일 동기화 성능 및 핫 리로드 보장을 위해 **Docker Compose Watch**와 **네임드 볼륨**을 채택했습니다.

```yaml
services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: diary-expo-app
    working_dir: /app

    volumes:
      # 호스트의 node_modules와 도커의 node_modules가 충돌하지 않도록 도커 전용 네임드 볼륨 분리
      - app_node_modules:/app/node_modules

    ports:
      - "8081:8081"
      - "19000:19000"
      - "19001:19001"
      - "19002:19002"

    env_file:
      - path: .env
        required: false

    environment:
      - NODE_ENV=development
      - EXPO_DEVTOOLS_LISTEN_ADDRESS=0.0.0.0
      # [Windows 호스트 파일 감지 보장 설정]
      - CHOKIDAR_USEPOLLING=true
      - WATCHPACK_POLLING=true
      - WATCHMAN_DISABLED=1

    # 터널 및 CLI 단축키(r: 리로드, w: 웹 등) 입력 활성화
    stdin_open: true
    tty: true

    # Docker Compose Watch: 파일 변경 즉시 컨테이너에 Linux inotify 이벤트 동기화
    develop:
      watch:
        - action: sync
          path: .
          target: /app
          ignore:
            - node_modules/
            - .git/
            - .expo/

volumes:
  app_node_modules:
```

#### 주요 설정 설명
1. **`develop.watch` (Docker Compose Watch)**:
   - 일반 바인드 마운트(`.:/app`) 사용 시 Windows 파일시스템과 WSL2/Docker 간 inotify 이벤트 누락으로 인해 Fast Refresh가 동작하지 않는 문제를 완벽히 해결합니다.
   - 소스 코드가 수정되면 지정된 파일만 `/app`으로 즉각 동기화(sync)됩니다.
2. **`app_node_modules` 네임드 볼륨**:
   - 호스트 머신의 `node_modules`와 컨테이너 내부의 Linux용 `node_modules`가 서로 덮어씌워져 발생하는 빌드 오류를 방지합니다.
3. **`stdin_open: true`, `tty: true`**:
   - 컨테이너 실행 중 터미널에서 Expo 대화형 단축키(`r`: Reload, `m`: Toggle Menu, `w`: Web 열기 등)를 직접 누를 수 있습니다.

---

### 2.3. 엔트리포인트 (`entrypoint.sh`)
컨테이너가 시작될 때 인증 정보 확인 및 실행 모드(터널 모드 vs 일반 모드)를 자동 분기합니다.

```bash
#!/bin/sh
set -e

# 1. Expo 로그인 처리
if [ -n "$EXPO_TOKEN" ]; then
  echo "🔑 EXPO_TOKEN 환경변수를 감지했습니다. 인증을 확인합니다..."
  npx expo whoami || echo "⚠️ 토큰 확인 실패. 토큰 유효성을 확인해주세요."
elif [ -n "$EXPO_USERNAME" ] && [ -n "$EXPO_PASSWORD" ]; then
  echo "🔑 사용자 계정 정보로 Expo 로그인을 시도합니다..."
  npx expo login -u "$EXPO_USERNAME" -p "$EXPO_PASSWORD" || echo "⚠️ 로그인 실패. 계정 정보를 확인해주세요."
else
  echo "ℹ️ 설정된 Expo 로그인 정보가 없습니다. 게스트 모드로 진행합니다."
fi

# 2. Ngrok 토큰 안내
if [ -n "$NGROK_AUTHTOKEN" ]; then
  echo "🔑 NGROK_AUTHTOKEN 환경변수를 감지했습니다."
fi

# 3. Expo 서버 시작
if [ $# -eq 0 ] || [ "$1" = "npm" -a "$2" = "start" ]; then
  if [ "$EXPO_TUNNEL" = "true" ]; then
    echo "🚀 Expo 개발 서버를 터널(Tunnel) 모드로 시작합니다..."
    exec npx expo start --tunnel --clear
  else
    echo "🚀 Expo 개발 서버를 시작합니다 (기본 LAN 모드)..."
    exec npx expo start --clear
  fi
fi

# 그 외 커스텀 명령어 전달 시 그대로 실행
exec "$@"
```

---

## 📱 3. Expo 및 Metro 번들러 설정

### 3.1. Metro 번들러 설정 (`metro.config.js`)
컨테이너 환경에서 Fast Refresh가 안정적으로 동작하도록 폴링(Polling) 감시자를 활성화했습니다.

```javascript
const { getDefaultConfig } = require('expo/metro-config');
const path = require('path');

const config = getDefaultConfig(__dirname);

// Docker 컨테이너 환경에서 프로젝트 루트 경로를 감시
config.watchFolders = [path.resolve(__dirname)];

// Windows 호스트 -> Linux Docker 컨테이너 inotify 이벤트 누락 방지
config.watchers = {
  watchman: {
    enabled: false,
  },
  node: {
    polling: true,
  },
};

module.exports = config;
```

---

### 3.2. 환경 변수 설정 (`.env`)
프로젝트 루트의 `.env` 파일에 Expo 인증 토큰 및 터널링 설정을 관리합니다.

| 환경 변수 | 권장 여부 | 설명 |
| :--- | :--- | :--- |
| `EXPO_TOKEN` | **강력 권장** | [expo.dev/settings/access-tokens](https://expo.dev/settings/access-tokens)에서 발급받은 Personal Access Token |
| `EXPO_TUNNEL` | 선택 (`true`) | `true` 설정 시 동일 네트워크가 아니어도 스마트폰 Expo Go로 접속 가능 |
| `NGROK_AUTHTOKEN` | 권장 | [ngrok.com](https://ngrok.com)에서 발급한 인증 토큰 (터널 연결 세션 안정화) |
| `EXPO_USERNAME` / `EXPO_PASSWORD` | 선택 | 토큰 대신 계정 ID/PW로 로그인할 때 사용 (2단계 인증 미사용 시) |

---

## 🚀 4. 프로젝트 실행 및 관리 명령어

### 4.1. 컨테이너 빌드 및 실행 (`--watch` 모드 필수)
> **⭐ 가장 추천하는 실행 명령어**: 컨테이너 구동과 실시간 파일 동기화(Watch)를 한 번에 실행합니다.
>
> ⚠️ **주의**: 그냥 `docker compose up`만 실행하면 파일 감시 프로세스가 켜지지 않아 코드를 수정해도 컨테이너에 반영되지 않습니다. 반드시 `--watch`를 붙여야 합니다!

```powershell
# 컨테이너 실행 + 실시간 파일 동기화(Watch) 한 번에 실행 (가장 추천)
docker compose up --watch
```

| 명령어 | 동작 방식 | 언제 사용하는가? |
| :--- | :--- | :--- |
| **`docker compose up --watch`** | 컨테이너를 올림과 동시에 실시간 파일 감시·동기화를 켬 | **평소 일상 개발 시 (가장 권장)** |
| `docker compose watch` | 이미 백그라운드로 떠 있는 컨테이너에 파일 감시기만 따로 붙임 | 컨테이너를 `-d`로 먼저 띄웠을 때 |
| `docker compose up` *(비권장)* | 컨테이너만 띄우고 파일 감시를 안 함 (코드 수정 반영 안 됨!) | 파일 수정 없는 단순 배포/테스트 시 |
| `docker compose down` | 컨테이너 안전하게 종료 | 개발 종료 시 |

### 4.2. 실행 로그 및 대화형 터미널 접속
```powershell
# 실시간 로그 확인 (QR 코드 및 대화형 키 입력)
docker compose logs -f app

# 또는 컨테이너에 직접 접속하여 단축키 사용
docker attach diary-expo-app
```

### 4.3. 새로운 패키지 설치 시 (중요)
호스트와 컨테이너의 `node_modules`가 분리되어 있으므로, 새로운 라이브러리를 설치할 때는 아래 명령어를 사용합니다:
```powershell
# 컨테이너 내부에서 npm install 수행
docker compose run --rm app npm install <패키지명>
```

### 4.4. 컨테이너 중지 및 리셋
```powershell
# 컨테이너 중지
docker compose down

# 캐시/볼륨까지 완전히 초기화 후 재빌드
docker compose down -v
docker compose build --no-cache
```

---

## 💡 5. 모바일 기기(실기기) 연결 가이드

1. **스마트폰에 Expo Go 앱 설치**:
   - iOS: App Store에서 `Expo Go` 검색 및 설치
   - Android: Play Store에서 `Expo Go` 검색 및 설치
2. **접속 방식**:
   - **터널 모드 (`EXPO_TUNNEL=true`)**: PC와 스마트폰이 다른 Wi-Fi나 LTE/5G 데이터 환경에 있어도 QR 코드 스캔으로 즉시 연결됩니다.
   - **LAN 모드**: PC와 스마트폰이 반드시 동일한 Wi-Fi 네트워크에 연결되어 있어야 합니다.
3. 터미널에 출력된 **QR 코드를 카메라(iOS) 또는 Expo Go 앱(Android)으로 스캔**하면 번들링이 시작되고 앱이 실행됩니다.

---

## ❓ 6. 초보자를 위한 핵심 설계 원리 (Why?)

### 💡 Why 1. 왜 `node_modules`를 네임드 볼륨(`app_node_modules`)으로 따로 뗐을까?
- **OS 바이너리 충돌 방지**: Windows 환경(`.dll`)과 Linux 컨테이너(`.so`)의 C/C++ 네이티브 모듈(esbuild, rollup 등)이 서로 덮어쓰여 크래시가 발생하는 문제를 방지합니다.
- **파일 I/O 성능 극대화**: Windows NTFS와 WSL2 가상머신 간의 수만 개 파일 공유 오버헤드를 없애고, Linux 전용 ext4 볼륨에 저장하여 네이티브 속도를 냅니다.

### 💡 Why 2. 왜 일반 마운트 대신 Compose Watch와 Polling을 쓸까?
- **Windows ↔ Linux 파일 이벤트 누락 방지**: Windows(VS Code)에서 `Ctrl + S`로 파일을 저장해도 WSL2 Linux 커널의 `inotify`로 이벤트가 전달되지 않아 Fast Refresh가 안 되는 고질적 문제를 해결합니다.
- Compose Watch가 파일을 감지해 컨테이너로 강제 동기화하고, `metro.config.js`의 Node Polling이 1~2초마다 수정 시간을 직접 훑어보아 이중 안전장치를 제공합니다.

### 💡 Why 3. 왜 터널링(`@expo/ngrok`, `EXPO_TUNNEL=true`)이 필수적일까?
- **도커 사설망 및 공용 Wi-Fi 격리 우회**: 컨테이너의 내부망은 폰에서 직접 보이지 않고, 카페나 회사 Wi-Fi는 보안(AP Isolation)상 기기 간 통신을 차단합니다.
- ngrok 터널을 뚫으면 스마트폰이 LTE/5G나 다른 Wi-Fi에 있어도 QR 스캔 한 번으로 전 세계 어디서든 도커 컨테이너의 Metro 번들러에 연결됩니다.

### 💡 Why 4. 새 패키지 설치 시 왜 `docker compose run`을 써야 할까?
- `node_modules`가 도커 내부 볼륨에 격리되어 있으므로, 윈도우 터미널에서 `npm install`을 해도 컨테이너 안에는 반영되지 않습니다.
- 따라서 반드시 컨테이너 내부 환경(`docker compose run --rm app npm install <패키지명>`)에서 설치해야 합니다.

### 💡 Why 5. 왜 그냥 `docker compose up`이 아니라 `--watch`를 붙여야 할까?
- **바인드 마운트 미사용 구조**: 우리 설정(`docker-compose.yml`)에서는 Windows-Linux 파일 충돌을 막기 위해 전통적인 `volumes: - .:/app`을 주석 처리해 두었습니다.
- **감시 프로세스 활성화 플래그**: Docker Compose는 `develop.watch` 설정이 적혀 있더라도, 명령어에 `--watch`를 명시하지 않으면 **파일 감시(Watch) 프로세스를 아예 켜지 않습니다!**
- **결과 차이**:
  - `docker compose up`만 치면: 이미지를 빌드했던 최초 시점의 코드만 컨테이너에 머물며, 호스트에서 코드를 수정해도 컨테이너로 절대 넘어가지 않습니다.
  - `docker compose up --watch`를 치면: 컨테이너 실행과 동시에 Docker 엔진이 내 프로젝트 폴더의 변경 사항을 1초도 안 걸려 컨테이너 안으로 즉각 쏴줍니다.
