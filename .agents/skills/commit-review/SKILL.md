---
name: commit-review
description: 사용자가 커밋에 대한 코드 리뷰 및 Notion 기록을 요청할 때(예 "커밋 리뷰해줘", "코드 리뷰 노션에 올려줘" 등), Git diff를 분석하여 RN 코드 리뷰 가이드 및 기능 명세서 기준으로 리뷰를 수행하고 Notion '코드 리뷰' 하위 페이지에 저장합니다.
---

# Commit Review & Notion Sync Skill

이 스킬은 사용자가 명시적으로 코드 리뷰를 요청했을 때만 실행되는 반자동 워크플로우입니다.

## Notion 연동 정보
- **부모 페이지 (다이어리 > 코드 리뷰)**:
  - Page ID: `3fb4700e-1708-8054-8e2b-dc5e371e9af1`
  - URL: `https://app.notion.com/p/3fb4700e170880548e2bdc5e371e9af1`
- Notion 도구: `notion-mcp-server`의 `API-post-page` 도구를 사용하여 새 페이지를 생성합니다.

---

## 🛠️ 실행 단계 (Workflow)

### 1단계: 커밋 및 Diff 정보 수집
- 사용자가 특정 커밋 해시를 지정하지 않았다면 기본값으로 최근 커밋(`HEAD`)을 조회합니다.
  - 실행: `git show HEAD --stat` 및 `git show HEAD --patch` (단, package-lock.json 등 자동생성 파일은 배제 권장)
- 커밋 메시지, 작성자, 날짜, 변경 통계를 파악합니다.

### 2단계: 기준 문서 검토
- **[docs/RN_CODE_REVIEW_GUIDE.md](file:///d:/dev/projects/app/diary/docs/RN_CODE_REVIEW_GUIDE.md)**: 모바일 접근성(A11y), 렌더링 최적화, 애니메이션, 모바일 UX 예외처리, 상태관리, TS 컨벤션 등 6대 체크리스트와 4단계 출력 포맷 준수.
- **`docs/spec/*.md` (필요 시)**: 변경된 코드가 명세에 정의된 데이터 모델, I/O, UI 플로우와 부합하는지 점검. (※ 주의: 명세서 내용을 바탕으로 미구현 기능을 새로 구현하라고 강요하지 않으며, 작성된 코드의 정합성만 검토)

### 3단계: 코드 리뷰 작성
[RN_CODE_REVIEW_GUIDE.md](file:///d:/dev/projects/app/diary/docs/RN_CODE_REVIEW_GUIDE.md) 포맷에 맞추어 다음 순서로 작성합니다:
1. **💡 총평 (Summary)**
2. **🛠️ 개선 제안 (Actionable Feedback)** (♿ A11y / 🔴 필수 / 🟡 권장)
3. **🧠 RN 학습 포인트 (Web vs Mobile Deep Dive)**
4. **✨ 리팩토링 코드 (Before & After)**

### 4단계: Notion '코드 리뷰' 하위 페이지 생성
`call_mcp_tool`로 `notion-mcp-server`의 `API-post-page`를 호출합니다.
- **parent**: `{"page_id": "3fb4700e-1708-8054-8e2b-dc5e371e9af1"}`
- **icon**: `{"type": "emoji", "emoji": "📝"}`
- **properties**:
  ```json
  {
    "title": {
      "title": [
        {
          "type": "text",
          "text": { "content": "[YYYY-MM-DD | SHA] 커밋 메시지 요약" }
        }
      ]
    }
  }
  ```
- **children**: 작성된 리뷰를 Notion 블록(callout, heading, paragraph, bulleted_list_item, code 등) 구조로 변환하여 전달합니다. 블록 개수가 100개를 초과할 경우 `API-patch-block-children`으로 추가합니다.

### 5단계: 사용자 보고
- Notion에 성공적으로 생성된 페이지 링크를 사용자에게 제공하고, 채팅창에도 리뷰 핵심 요약을 브리핑합니다.
