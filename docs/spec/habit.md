# 🌿 습관 트래커 기능 명세서 (Habit Spec)

## 1. 개요
일상의 긍정적인 루틴을 만들고 지속할 수 있도록 돕는 기능. 옵션 3(하이브리드 구조)에 따라 일일 체크는 스케줄표/다이어리에 자연스럽게 임베딩되고, 추가 및 분석은 AI 모달과 연계됩니다.

## 2. 데이터 모델 (`src/types/habit.ts`)
```typescript
export interface Habit {
  id: string;
  title: string;
  icon?: string; // 이모지 또는 아이콘 이름
  category: 'cleaning' | 'morning' | 'fitness' | 'focus' | 'mindfulness' | 'custom';
  frequency: 'daily' | 'weekdays' | 'weekends' | number[]; // 0=일 ~ 6=토
  targetCount: number; // 1일 목표 실천 횟수 (기본 1)
  createdAt: string;
  isArchived: boolean;
}

export interface HabitLog {
  date: string; // YYYY-MM-DD
  habitId: string;
  completed: boolean;
  completedAt?: string;
}

export interface HabitStreak {
  habitId: string;
  currentStreak: number;
  longestStreak: number;
  totalCompletedCount: number;
  monthlyCompletionRate: number; // 0 ~ 100%
}
```

## 3. UI 컴포넌트 규격
1. **`HabitTrackerBar` (스케줄표 중단 임베디드)**
   - 가로 스크롤 Chip 리스트.
   - 각 Chip: 이모지 아이콘 + 습관명 + 스트릭 불꽃(🔥) + 체크 원형 버튼.
   - 우측 끝: `[+ 루틴 추가]` 버튼 (AI 추천 마법사 및 수동 추가 트리거).
2. **`WeeklyHabitTracker` (다이어리 좌측 상단 임베디드)**
   - 월~일 7일간의 미니 잔디/체크 매트릭스.
   - 오늘 요일 하이라이트 및 빠른 체크 기능.
