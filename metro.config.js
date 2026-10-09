const { getDefaultConfig } = require('expo/metro-config');
const path = require('path');

const config = getDefaultConfig(__dirname);

// Docker 컨테이너 환경에서 프로젝트 루트 경로를 확실히 감시
config.watchFolders = [path.resolve(__dirname)];

// [중요] Windows 호스트 파일시스템 -> Linux Docker 컨테이너 inotify 이벤트 누락 해결
// Watchman 비활성화 및 Node 폴링(Polling) 강제 활성화
config.watchers = {
  watchman: {
    enabled: false,
  },
  node: {
    polling: true,
  },
};

module.exports = config;
