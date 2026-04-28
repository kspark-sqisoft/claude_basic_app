# Step 0: search-feature

## 읽어야 할 파일

먼저 아래 파일들을 읽고 프로젝트의 기획·아키텍처·이전 구현을 파악하라:

- `/CLAUDE.md`
- `/docs/PRD.md` (5번 검색 기능 명세)
- `/docs/ARCHITECTURE.md`
- `/docs/ADR.md` (특히 ADR-008 검색 처리 위치)
- `/docs/UI_GUIDE.md` (헤더 액션 영역 / 단축키 표)
- `/docs/plans/PLAN_search.md` ← 본 phase 설계서, 결정/변경 범위 표 필독
- 기존 코드:
  - `lib/features/todos/presentation/providers/todo_filter_provider.dart`
  - `lib/features/todos/presentation/providers/todo_list_notifier.dart`
  - `lib/features/todos/presentation/screens/todo_list_screen.dart`
  - `lib/features/todos/presentation/widgets/todo_filter_tabs.dart`
  - `lib/features/todos/presentation/widgets/todo_input_bar.dart`
  - `test/test_helpers/widget_test_harness.dart`
  - `test/features/todos/presentation/screens/todo_list_screen_test.dart`

검색이 추가되어도 **domain / data 레이어는 절대 손대지 않는다** (ADR-008). 변경 범위는 presentation에 한정.

## 작업

### 1) `lib/features/todos/presentation/providers/todo_search_query_provider.dart` (신규)

`@riverpod`로 검색어 String state 관리:

```dart
@riverpod
class TodoSearchQueryNotifier extends _$TodoSearchQueryNotifier {
  @override
  String build() => '';
  void set(String query) => state = query;
  void clear() => state = '';
}
```

### 2) `lib/features/todos/presentation/providers/todo_list_notifier.dart` (수정)

`build()`에서 `ref.watch(todoSearchQueryNotifierProvider)`도 watch하고, 기존 `_applyFilter`에 검색어 결합 로직을 추가한다. 시그니처는:

```dart
List<Todo> _applyFilterAndSearch(List<Todo> todos, TodoFilter filter, String query) {
  final filtered = switch (filter) { ... };  // 기존 필터 그대로
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return filtered;
  return filtered.where((t) => t.title.toLowerCase().contains(q)).toList();
}
```

- 빈 query는 검색 미적용 (기존 동작 유지). 트리밍은 양 끝 공백만.
- 검색은 **title만** 대상. description은 손대지 않는다(PLAN_search.md 결정).
- stream 재구독을 일으키지 마라 — 검색어는 emit 시점에만 적용.

### 3) `lib/features/todos/presentation/widgets/todo_search_field.dart` (신규)

`ConsumerStatefulWidget`. `FTextField` 단일 필드:

```dart
class TodoSearchField extends ConsumerStatefulWidget { ... }

// State:
// - TextEditingController _ctrl;
// - initState: _ctrl = TextEditingController(text: ref.read(todoSearchQueryNotifierProvider));
// - dispose: _ctrl.dispose();
// - build:
//     SizedBox(
//       width: 240,
//       child: FTextField(
//         controller: _ctrl,
//         hint: '제목 검색',
//         onChange: (v) => ref.read(todoSearchQueryNotifierProvider.notifier).set(v),
//         // forui 0.21.x의 정확한 옵션명/clear 슬롯은 pub.dev 레퍼런스 확인.
//       ),
//     )
```

요구:
- 너비 `SizedBox(width: 240)` 정도로 제약 — 헤더 우측을 잠식하지 않도록.
- 입력값이 비어 있을 때 / 비울 때 query state도 같이 빈 문자열 (`onChange('')`로 자동 처리됨).
- forui의 정확한 prop 시그니처는 0.21.3 레퍼런스(`pub.dev/documentation/forui/0.21.3/`)를 따른다. `hint` / `placeholder` 등 이름이 다르면 그쪽이 정답.

### 4) `lib/features/todos/presentation/screens/todo_list_screen.dart` (수정)

`FHeader`의 `actions` 슬롯에 `TodoSearchField`를 배치:

```dart
FScaffold(
  header: FHeader(
    title: const Text('Todo'),
    actions: const [TodoSearchField()],
  ),
  child: ...,
)
```

> forui 0.21.x의 `FHeader`가 `actions: List<Widget>` 슬롯을 지원하지 않는 경우, `prefixActions` / `suffixActions` 등 동등 슬롯에 배치한다. 그조차 없으면 본문 상단에 `Row(children: [Text('Todo'), Spacer(), TodoSearchField()])`로 자체 헤더를 구성한다 — 단, **헤더 우측 정렬 원칙은 유지**.

### 5) 위젯 테스트

#### `test/features/todos/presentation/widgets/todo_search_field_test.dart` (신규)
- 텍스트 입력 → `todoSearchQueryNotifierProvider` state가 같은 값으로 갱신되는지.
- 빈 문자열 입력 → state도 빈 문자열.

#### `test/features/todos/presentation/screens/todo_list_screen_test.dart` (수정)
- 기존 케이스 유지.
- 추가: 항목 2건(`보고서 작성`, `장보기`)을 fake repo에 두고 검색어 "보고" 입력 → "보고서 작성"만 표시, "장보기"는 안 보임.
- 추가: 필터 탭 "미완료" + 검색어 "보고" → 두 조건 결합 적용.
- 추가: 검색어 비우면 다시 전체 표시.

테스트는 `test/test_helpers/widget_test_harness.dart`의 기존 헬퍼를 그대로 재사용. fake repository도 기존 것 그대로.

### 6) build_runner 실행

새 `@riverpod` provider가 추가되므로 `*.g.dart` 재생성 필요:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 생성/수정 대상 파일

신규:
- `lib/features/todos/presentation/providers/todo_search_query_provider.dart` (+ `.g.dart` 자동)
- `lib/features/todos/presentation/widgets/todo_search_field.dart`
- `test/features/todos/presentation/widgets/todo_search_field_test.dart`

수정:
- `lib/features/todos/presentation/providers/todo_list_notifier.dart` (+ `.g.dart` 재생성)
- `lib/features/todos/presentation/screens/todo_list_screen.dart`
- `test/features/todos/presentation/screens/todo_list_screen_test.dart`

문서(이미 본 phase 작업 시작 시점에 워킹트리에서 변경됨 — 첫 커밋에 함께 포함된다):
- `docs/PRD.md`
- `docs/ADR.md`
- `docs/UI_GUIDE.md`
- `docs/plans/PLAN_search.md`

## Acceptance Criteria

```bash
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter build windows --debug
```

네 커맨드 모두 성공 + analyze 경고 0건 + 모든 테스트 통과 (기존 47건 + 신규 2~3건).

## 검증 절차

1. 위 AC 커맨드 실행.
2. 아키텍처 체크리스트:
   - **domain/data 레이어 변경 0건**? (`git diff main -- lib/features/todos/domain lib/features/todos/data`가 비어야 함, providers.dart 제외하고)
   - 새 provider는 `@riverpod` 어노테이션? (`Provider(...)` / `ChangeNotifier` 0건)
   - 검색은 메모리 필터로만 처리? (sembast `Finder` / `Filter.matches` 0건)
   - `TodoSearchField`가 `SizedBox(width: ...)`로 폭을 제약?
   - 색·폰트 하드코딩 없이 forui 토큰 사용?
3. `phases/1-search/index.json`의 step 0 업데이트:
   - 성공 → `"status": "completed"`, `"summary": "검색 기능 추가. todoSearchQueryNotifier(@riverpod, String state) 신규, TodoListNotifier가 (filter, query) 결합 필터링. TodoSearchField(FTextField, width 240) 위젯 신규, FHeader actions에 배치. domain/data 변경 0건. 위젯 테스트 N건 + 전체 테스트 통과, flutter analyze 0건, flutter build windows --debug 성공. 문서 4건(PRD/ADR-008/UI_GUIDE/PLAN_search) 함께 커밋."`
   - error/blocked 시 동일 패턴.

## 금지사항

- **domain 또는 data 레이어를 변경하지 마라.** 이유: ADR-008 — 검색은 presentation 클라이언트 필터 한정. UseCase / Repository / DataSource / Model 시그니처 모두 불변.
- **sembast `Finder` / `Filter.matches` 등으로 푸시다운하지 마라.** 이유: ADR-008 — 데이터 양이 늘어 성능 이슈가 발생하면 별도 ADR로 이주.
- **검색 입력에 디바운스를 넣지 마라.** 이유: 메모리 필터는 즉시 반영이 자연스럽다. 디바운스가 필요해지면 ADR-008 재검토 신호.
- **description 필드를 검색 대상에 포함하지 마라.** 이유: PRD 5번 — 본 MVP의 검색은 **title만**. description 검색은 후속 phase.
- **stream provider를 검색어로 재구독시키지 마라.** 이유: 메모리 필터는 emit 시점에 적용. `ref.watch(searchQuery)`는 `_applyFilterAndSearch` 입력에만 사용한다.
- **`TodoSearchField`에서 `setState`로 query를 보관하지 마라.** 이유: ADR-003 — 상태는 Riverpod에 둔다. 위젯 내부 컨트롤러는 OK이지만 query 자체의 source-of-truth는 provider.
- **헤더 actions 영역을 잠식하지 마라** (필드 폭 무제약 금지). 이유: UI_GUIDE — `SizedBox(width: 240)` 등 명시적 제약.
- **`*.g.dart` / `*.freezed.dart`를 손으로 편집하지 마라.** 이유: build_runner 덮어씀.
- **기존 위젯 테스트 47건을 깨뜨리지 마라.** 이유: 회귀 금지. 검색어 빈 문자열일 때 기존 동작과 동일해야 한다.
