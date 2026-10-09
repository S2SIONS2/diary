# 🤖 AI 서비스 명세서 (AI Feature Spec)

## 1. 개요
앱 내에 탑재되는 두 가지 핵심 AI 기능의 세부 규격과 프롬프트/데이터 I/O 정의.

---

## 2. Feature ①: AI 루틴 추천 마법사 (`AiRoutineWizardModal`)
- **목적**: 사용자가 목표 선택 시 현실적이고 실천 가능한 5가지 루틴을 생성하여 원터치 등록 지원.
- **트리거**: 스케줄표 습관 체크바 우측 `[+]` -> `[✨ AI 루틴 추천 받기]`.
- **입력**:
  - `goalCategory`: '깨끗한 집' | '미라클 모닝' | '운동/체력' | '업무/공부 몰입' | '마음 챙김' | 직접 입력 키워드
  - `existingHabits`: 현재 등록된 습관 목록 (중복 방지)
- **출력 (JSON)**:
  ```typescript
  export interface RecommendedRoutine {
    title: string;
    icon: string; // 예: 🧹, 🌅, 🏃, 📚, 🧘
    category: string;
    description: string; // "아침에 일어나서 침대 시트 정리하기 (2분)"
    frequency: 'daily' | 'weekdays';
    estimatedMinutes: number;
  }
  ```
- **UX 인터랙션**: 5개 항목 중 원하는 항목 다중 체크 후 `[선택한 루틴 추가]` 버튼 클릭 시 즉시 스토어에 등록.
- **오프라인 Fallback**: 네트워크 단절 시 카테고리별 검증된 기본 프리셋 5종 즉시 제공.

---

## 3. Feature ②: AI 월간 리뷰 자동 요약 리포트 (`AiMonthlyReviewModal`)
- **목적**: 1개월간의 습관 달성률 통계, 다이어리 일기 텍스트, 스케줄 일정 태그를 3중 교차 분석하여 자책 없는 인사이트와 실천 가능한 제안 제공.
- **트리거**: 캘린더 화면 상단 `✨ [AI 월간 리뷰]` 버튼.
- **입력**:
  - `monthlyStats`: 습관별 달성률(%), 최고 스트릭, 요일별 실패/성공률
  - `diaryEntries`: 해당 월 작성된 일기 본문 텍스트 배열
  - `scheduleTags`: 해당 월의 일정 카테고리 및 타이밍 (야근, 외근, 휴일 등 라이프스타일 맥락)
- **출력 (3단 리포트 JSON)**:
  ```typescript
  export interface MonthlyAiReviewReport {
    month: string; // YYYY-MM
    celebration: {
      bestHabit: string;
      longestStreak: number;
      message: string; // 칭찬 및 격려 메시지
    };
    patternAnalysis: {
      vulnerableDay: string; // 예: "목요일"
      vulnerableReason: string; // "야근과 마감으로 인한 피로 누적"
      insight: string; // 구체적 분석 텍스트
    };
    nextMonthSuggestion: {
      actionTitle: string; // "목요일 루틴을 5분 스트레칭으로 가볍게 낮추기"
      reason: string;
    };
  }
  ```
- **UX 인터랙션**: 리포트 카드 팝업 확인 후 `[다이어리에 리포트 스크랩]` 버튼 클릭 시 해당 월 말일 일기에 카드 형태로 영구 보관.
- **오프라인 Fallback**: 
  - 네트워크 단절 시 로컬 계산 기반 **[기본 수치 통계 카드]**(총 실천율 %, 최장 스트릭 달성 습관, 요일별 완주율 그래프)를 우선 표시.
  - 상단에 "오프라인 상태입니다. 네트워크 연결 시 AI 심층 분석이 가능합니다" 안내 배너 및 `[재시도]` 버튼 제공.
