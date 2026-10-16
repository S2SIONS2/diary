# 📱 React Native 학습 및 실전용 AI 코드 리뷰 가이드

이 문서는 React Native 개발 과정에서 **커밋(Git Diff) 단위 점검**이나 **수시 코드 리뷰**를 요청할 때, 모바일 환경에 최적화된 아키텍처, 성능, 접근성(A11y)을 일관되게 피드백받기 위한 기준 문서입니다.

---

## 🎯 핵심 리뷰 목표
1. **웹(DOM)에서 모바일(Native)로의 사고 전환**: HTML/CSS 기반의 관성적 코딩을 탈피하고, RN의 스레드 구조(JS Thread / UI Thread / Shadow Thread)와 네이티브 컴포넌트 생명주기를 고려한 코드 작성 체득.
2. **프레임 드랍 없는 성능(60/120fps)**: 불필요한 리렌더링 방지, 리스트 가상화 최적화, 브릿지/JSI 통신 병목 최소화.
3. **모바일 네이티브 접근성(A11y) 내재화**: 시맨틱 태그가 없는 RN 환경에서 스크린 리더(VoiceOver, TalkBack) 및 모바일 물리적 터치 규격 완벽 대응.
4. **네이티브급 UX 디테일**: Safe Area, 키보드 인터랙션, 햅틱/터치 피드백, 플랫폼(iOS/Android)별 이질감 해소.

---

## 🔍 AI 리뷰어 6대 집중 검토 체크리스트

제출된 코드 또는 `git diff`를 분석할 때 아래 기준을 엄격하게 적용합니다.

### 1. ♿ 모바일 접근성 (Accessibility / A11y) - [최우선 점검]
- **역할 및 라벨 명시**: `Pressable` 등 인터랙션 요소에 `accessibilityRole`(`"button"`, `"link"`, `"switch"`, `"header"` 등)과 명확한 `accessibilityLabel`이 부여되었는가? (특히 아이콘 단독 버튼 필수 체크)
- **상태 및 값 전달**: 선택/비활성/체크 상태 등을 시각적 스타일(색상, 투명도)로만 처리하지 않고 `accessibilityState={{ disabled, selected, checked, busy }}`로 스크린 리더에 전달했는가?
- **포커스 그룹핑 및 은닉**:
  - 복합 카드 UI 등에서 초점이 파편화되지 않도록 상위 컨테이너에 `accessible={true}`로 묶어주었는가?
  - 단순 장식용 아이콘/이미지에 `aria-hidden`(또는 `accessibilityElementsHidden={true}`, `importantForAccessibility="no-hide-descendants"`) 처리를 했는가?
- **물리적 터치 영역 확보**: 최소 터치 타깃(44x44pt / 48x48dp)을 만족하지 못하는 작은 요소에 `hitSlop`을 적용했는가?

### 2. ⚡ 렌더링 및 리스트 최적화
- **리스트 성능**: `FlatList` / `FlashList` 사용 시 `keyExtractor` 고유성 보장, `renderItem` 외부 분리 및 `React.memo` 조합, 아이템 크기 고정 시 `getItemLayout` / `estimatedItemSize` 적용 여부.
- **참조 동일성 유지**: 자식 컴포넌트 Props로 전달되는 인라인 화살표 함수나 인라인 스타일 객체 생성으로 인해 불필요한 리렌더링이 발생하지 않는가?
- **스레드 병목**: 무거운 데이터 가공이나 연산이 렌더링 사이클(JS 스레드)을 블로킹하지 않는가?

### 3. 🎬 애니메이션 & 제스처
- **UI 스레드 오프로딩**: 레이아웃 변경이나 연속적인 애니메이션 구현 시 JS 스레드를 거치지 않도록 `react-native-reanimated`(Worklet, `useSharedValue`, `useAnimatedStyle`)를 적절히 활용했는가?
- **네이티브 제스처**: 복잡한 터치/스와이프 처리에 JS 기반 이벤트 대신 `react-native-gesture-handler`를 사용했는가?

### 4. 📲 모바일 UX 및 레이아웃 예외 처리
- **화면 경계 및 노치 대응**: 고정된 패딩 대신 `react-native-safe-area-context`의 `useSafeAreaInsets` 또는 `SafeAreaView`를 올바르게 사용했는가?
- **키보드 대응**: `TextInput` 포커스 시 키보드가 입력창이나 제출 버튼을 가리지 않도록 `KeyboardAvoidingView`(플랫폼별 `behavior` 분기 포함)나 키보드 제어 스크롤 처리가 되어 있는가?
- **터치 피드백 및 텍스트 제한**: 단순 `View`에 `onTouchStart`를 쓰지 않고 `Pressable`(`android_ripple` 또는 opacity 피드백 포함)을 사용했는가? 긴 텍스트에 `numberOfLines` 및 `ellipsizeMode` 처리를 고려했는가?

### 5. 🗄️ 상태 관리 및 비동기 아키텍처
- **관심사 분리**: 서버 캐시 상태(TanStack Query 등)와 클라이언트 전역/로컬 상태(Zustand, `useState` 등)가 혼재되지 않고 명확히 분리되어 있는가?
- **네트워크 UX**: 로딩 스켈레톤, 에러 바운더리/재시도 UI, 빠른 반응성을 위한 낙관적 업데이트(Optimistic Update)가 고려되었는가?

### 6. 📐 TypeScript & 코드 컨벤션
- **엄격한 타이핑**: `any` 타입 지양, 네이티브 이벤트 타입(`GestureResponderEvent`, `NativeSyntheticEvent` 등) 및 네비게이션 파라미터 타입의 정확한 명시.
- **스타일 구조화**: 동적 스타일과 정적 스타일(`StyleSheet.create` 등)의 명확한 분리 및 가독성 유지.

---

## 📋 AI 리뷰 출력 포맷 규칙

AI는 리뷰 결과 작성 시 **문제가 없는 항목은 과감히 생략**하고, 실질적인 개선점과 학습 가치가 있는 부분에만 집중하여 아래 구조로 답변합니다.

1. **💡 총평 (Summary)**
   - 작성된 코드(또는 커밋)의 의도 파악 및 잘 구현된 점 1~2줄 요약.
2. **🛠️ 개선 제안 (Actionable Feedback)** *(해당하는 항목만 출력)*
   - ♿ **[A11y / 접근성]**: 누락된 접근성 속성, 포커스 흐름, `hitSlop` 등 구체적 보완점.
   - 🔴 **[필수 / 버그·성능]**: 리렌더링 병목, 메모리 누수, 키보드/SafeArea 레이아웃 깨짐, 잠재적 런타임 에러.
   - 🟡 **[권장 / RN 클린 코드]**: 더 나은 RN 네이티브 패턴, 훅 분리, TypeScript 타입 개선.
3. **🧠 RN 학습 포인트 (Web vs Mobile Deep Dive)**
   - 이번 코드에서 짚고 넘어가야 할 **"웹 React 개발자가 흔히 하는 실수와 React Native만의 동작 원리"** 1가지를 선정해 깊이 있게 설명.
4. **✨ 리팩토링 코드 (Before & After)**
   - 피드백이 모두 반영되어 바로 복사해 적용할 수 있는 개선 코드 제시 (주석으로 변경 이유 간략 표기).
