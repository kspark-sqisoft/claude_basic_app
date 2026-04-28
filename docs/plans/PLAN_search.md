# PLAN: Todo 검색 기능 (phase 1-search)

## Context
phase `0-mvp`로 등록·수정·삭제·완료 토글·필터(전체/미완료/완료) 기능이 main에 머지됐다. 다음 사용자 요구는 **할일 검색**이다. PRD의 MVP 제외 항목에서 "검색"을 제거하고 핵심 기능 5번으로 승격한다(PRD 갱신).

검색은 본 앱이 단일 사용자/단일 PC 기준의 가벼운 도구라는 PRD 전제(데이터 양 제한적)와 정렬·필터를 이미 클라이언트 측에서 적용하고 있는 현 구조 위에서 가장 자연스럽게 **presentation 레이어의 클라이언트 필터링**으로 구현한다(ADR-008).

## 결정 사항

| 항목 | 결정 | 근거 |
|------|------|------|
| 검색 대상 | **제목(title)만** | 사용자 선택. 단순 + 빠름. description까지 확장은 후속 phase |
| 매칭 방식 | 대소문자 무시 contains, 공백 trim | 단순 검색 UX. fuzzy/regex는 과함 |
| 검색 UI 위치 | **`FHeader(actions: [...])` 우측** | UI_GUIDE 패턴, 본문 레이아웃 변동 최소 (ADR-008) |
| 적용 주체 | **`TodoListNotifier`** (presentation 클라이언트 필터) | repository/UseCase 시그니처 불변, 변경 범위 한정 |
| 디바운스 | 없음 (즉시 반영) | 메모리 필터라 비용 무시 가능 |
| 단축키 | `Ctrl+F` 검색 포커스, `Esc` 검색어 초기화 | UI_GUIDE 데스크톱 단축키 표 갱신 |

## 변경 범위

### presentation
- `lib/features/todos/presentation/providers/todo_search_query_provider.dart` (신규)
  - `@riverpod class TodoSearchQueryNotifier extends _$TodoSearchQueryNotifier { @override String build() => ''; void set(String q) => state = q; }`
- `lib/features/todos/presentation/providers/todo_list_notifier.dart` (수정)
  - `build()`에서 `ref.watch(todoSearchQueryNotifierProvider)` 추가 watch
  - 필터링 함수가 `(filter, query)` 두 축을 모두 적용하도록 변경
  - 빈 query = 검색 미적용 (기존 동작 유지)
- `lib/features/todos/presentation/widgets/todo_search_field.dart` (신규)
  - `FTextField` 단일 필드 + clear 아이콘. 변경 시 `ref.read(todoSearchQueryNotifierProvider.notifier).set(value)` 호출
  - 너비는 `SizedBox(width: 240)` 정도로 제약 (헤더 잠식 방지)
- `lib/features/todos/presentation/screens/todo_list_screen.dart` (수정)
  - `FHeader(title: ..., actions: [TodoSearchField()])`

### domain / data
- 변경 없음

### 문서
- `docs/PRD.md` — 핵심 기능 5번 추가, MVP 제외에서 "검색" 제거 (본 phase 시작 시 이미 반영)
- `docs/ADR.md` — ADR-008 추가 (본 phase 시작 시 이미 반영)
- `docs/UI_GUIDE.md` — 헤더 액션 영역 단락 + Ctrl+F 단축키 추가 (본 phase 시작 시 이미 반영)

## Step 설계

phase `1-search`는 **단일 step** (`step 0: search-feature`)으로 진행한다. 도메인/데이터 변경이 없고 presentation에만 닿는 작은 기능이라 잘게 쪼개면 오히려 오버헤드.

### Step 0: search-feature
- presentation 코드 변경 4건 (provider 신규, list notifier 수정, search field 위젯 신규, screen 수정)
- 위젯 테스트 갱신
  - 신규: `todo_search_field_test.dart` — 입력 시 provider state 갱신
  - 갱신: `todo_list_screen_test.dart` — 검색어 입력 시 매칭/비매칭 분기, 필터 탭과 결합
- 빌드/테스트/분석 모두 통과
- AC: `dart run build_runner build` + `flutter analyze` 0건 + `flutter test` 통과 + `flutter build windows --debug` 성공

## 검증 방법

- `flutter test` 전체 통과 (기존 47건 + 신규 2~3건)
- `flutter analyze` 경고 0건
- `flutter build windows --debug` 성공
- 수동 시나리오 (`flutter run -d windows`):
  1. 헤더 우측 검색 필드에 "보고" 입력 → "보고서 작성"만 남음
  2. 필터 탭을 "미완료"로 → 검색어 유지된 채 미완료 + 매칭 항목만
  3. 검색 필드에 `Esc` → 검색어 초기화, 전체 복귀
  4. 빈 검색어 → 모든 항목 (필터 적용분 제외하고)

## 주의 / 위험

- **domain/data 시그니처를 바꾸지 마라.** 변경 범위는 presentation으로 한정 (ADR-008).
- **검색 query를 sembast Finder로 푸시다운하지 마라.** 본 phase는 메모리 필터. 데이터 양이 늘어 성능 이슈가 발생하면 별도 ADR.
- **검색 입력에 디바운스를 넣지 마라.** 메모리 필터라 즉시 반영이 자연스럽다. (디바운스가 필요해질 정도면 ADR-008 재검토.)
- **`AsyncValue` 처리 누락 주의.** `TodoListNotifier`가 stream provider이므로 검색어가 바뀌어도 stream 재구독은 일어나지 않게 — `ref.watch(todoSearchQueryNotifierProvider)` 결과는 `_applyFilter` 입력에만 사용.
