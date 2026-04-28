# Step 5: todos-presentation

## 읽어야 할 파일

- `/CLAUDE.md`
- `/docs/ARCHITECTURE.md` (상태 관리 / 데이터 흐름)
- `/docs/ADR.md` (ADR-003 Riverpod codegen, ADR-007 forui)
- `/docs/UI_GUIDE.md` ← forui 컴포넌트 매핑/예시 필독
- `/docs/PRD.md` (핵심 기능 4개, 디자인)
- `/docs/plans/PLAN_todo_app.md` (3.3~3.6 절)
- 이전 step 산출물:
  - `lib/app/{theme,app,router}.dart`
  - `lib/features/todos/presentation/screens/todo_list_screen.dart` (자리표시자)
  - `lib/features/todos/domain/usecases/*` 5종
  - `lib/features/todos/data/providers.dart` (`todoRepositoryProvider`)

## 작업

이 step의 목표: **`features/todos/presentation/` 레이어 전체**(filter/list provider, 화면, 위젯) 작성 + widget test. 자리표시자 `TodoListScreen`을 본 구현으로 교체.

### 1) Provider 계층

#### `lib/features/todos/presentation/providers/todo_filter_provider.dart`

```dart
enum TodoFilter { all, pending, completed }

@riverpod
class TodoFilterNotifier extends _$TodoFilterNotifier {
  @override
  TodoFilter build() => TodoFilter.all;
  void set(TodoFilter f) => state = f;
}
```

#### `lib/features/todos/presentation/providers/todo_list_notifier.dart`

```dart
@riverpod
class TodoListNotifier extends _$TodoListNotifier {
  @override
  Stream<List<Todo>> build() async* {
    final repo = await ref.watch(todoRepositoryProvider.future);
    final filter = ref.watch(todoFilterNotifierProvider);
    final watch = WatchTodos(repo);
    yield* watch(const NoParams()).map((either) =>
      either.match(
        (failure) => throw failure,           // AsyncValue.error로 래핑
        (todos) => _applyFilter(todos, filter),
      ),
    );
  }

  Future<void> add({required String title, String? description, DateTime? dueDate}) async {
    final repo = await ref.read(todoRepositoryProvider.future);
    final usecase = AddTodo(repo, idGenerator: const Uuid().v4, now: DateTime.now);
    final result = await usecase(AddTodoParams(title: title, description: description, dueDate: dueDate));
    result.match((f) => throw f, (_) {});
  }

  Future<void> update(Todo t) async { ... }
  Future<void> toggle(Todo t) async { ... }   // ToggleTodoCompleted UseCase
  Future<void> delete(String id) async { ... }
}

List<Todo> _applyFilter(List<Todo> todos, TodoFilter f) => switch (f) {
  TodoFilter.all => todos,
  TodoFilter.pending => todos.where((t) => !t.isCompleted).toList(),
  TodoFilter.completed => todos.where((t) => t.isCompleted).toList(),
};
```

> Riverpod codegen이 `Stream<List<Todo>>` 반환을 자동으로 `AsyncValue<List<Todo>>`로 노출한다. 위젯에서 `ref.watch(todoListNotifierProvider).when(...)` 사용.
>
> `add/update/toggle/delete` 메서드는 `state` 직접 갱신 안 한다 — 스트림(repo.watchAll)이 sembast 변경을 자동 반영하기 때문.

### 2) 화면

#### `lib/features/todos/presentation/screens/todo_list_screen.dart` (교체)

`FScaffold` + `FHeader`. 본문은 `ConstrainedBox(maxWidth: 1024)` 내부에 `Column`:
1. `TodoInputBar`
2. 8px gap
3. `TodoFilterTabs`
4. 16px gap
5. `Expanded(child: ref.watch(todoListNotifierProvider).when(data: ListView.separated, loading: ..., error: ...))`

각 항목은 `TodoListItem`. 빈 상태(filter 결과 0건)는 짧은 안내 텍스트.

### 3) 위젯

#### `lib/features/todos/presentation/widgets/todo_input_bar.dart`
- `FTextField` + `FButton.primary(label: '추가')`. Enter / 버튼 둘 다 동일 동작.
- `ConsumerStatefulWidget` — 컨트롤러 보관.
- 빈 문자열이거나 trim 후 빈 문자열이면 동작 무시(또는 토스트). `ValidationFailure`는 `showFToast` 또는 inline 메시지로.

#### `lib/features/todos/presentation/widgets/todo_filter_tabs.dart`
- `FTabs` (controller 기반) — 전체/미완료/완료. 선택 시 `ref.read(todoFilterNotifierProvider.notifier).set(...)`.

#### `lib/features/todos/presentation/widgets/todo_list_item.dart`
- `FTile` 또는 `Row`: `FCheckbox(value: t.isCompleted, onChange: ...)` + 제목(`isCompleted`면 `decoration: TextDecoration.lineThrough`) + 마감일(있으면 `intl`로 포맷).
- 클릭 시 `TodoEditDialog` 표시.

#### `lib/features/todos/presentation/widgets/todo_edit_dialog.dart`
- `showAdaptiveDialog` 안에서 `FDialog`. body에 제목 `FTextField`, 메모 `FTextField`(maxLines 3), 마감일 트리거(`FCalendar` 또는 단순 `FButton`로 `showAdaptiveDialog(showFCalendar...)` 띄움).
- actions: `FButton.outline('취소')`, `FButton.destructive('삭제')`, `FButton.primary('저장')`.

> forui의 정확한 API(예: `FButtonStyle.primary` vs 명시 enum, `FTextField` 옵션명)는 `pub.dev/documentation/forui/0.21.3/`를 따른다. 시그니처가 다르면 그쪽이 정답.

### 4) Widget 테스트

`test/features/todos/presentation/`:

테스트 헬퍼: `testHarness.dart` 또는 inline로
```dart
Widget wrap(Widget child) => ProviderScope(
  overrides: [
    todoRepositoryProvider.overrideWith((ref) async => FakeTodoRepository()),
  ],
  child: MaterialApp(
    builder: (context, child) => FTheme(
      data: FThemes.zinc.light.desktop,
      child: child!,
    ),
    home: child,
  ),
);
```

`FakeTodoRepository`는 in-memory `StreamController` 기반 — 또는 step 4의 in-memory sembast를 테스트용으로 재사용.

테스트 시나리오:
- `todo_input_bar_test.dart`: 텍스트 입력 → Enter → notifier.add 호출(또는 fake repo에 추가됨).
- `todo_list_item_test.dart`: 체크박스 토글 → notifier.toggle 호출. 완료 항목은 취소선.
- `todo_edit_dialog_test.dart`: 저장 → notifier.update / 삭제 → notifier.delete.
- `todo_list_screen_test.dart`: pending 탭에서 완료 항목 안 보임.

mocktail로 notifier mock도 가능. 또는 ProviderContainer + listen으로 직접 검증.

### 5) build_runner

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 생성/수정 대상 파일

- `lib/features/todos/presentation/providers/todo_filter_provider.dart` + `.g.dart`
- `lib/features/todos/presentation/providers/todo_list_notifier.dart` + `.g.dart`
- `lib/features/todos/presentation/screens/todo_list_screen.dart` (교체)
- `lib/features/todos/presentation/widgets/todo_input_bar.dart`
- `lib/features/todos/presentation/widgets/todo_filter_tabs.dart`
- `lib/features/todos/presentation/widgets/todo_list_item.dart`
- `lib/features/todos/presentation/widgets/todo_edit_dialog.dart`
- `test/features/todos/presentation/widgets/*_test.dart`
- `test/features/todos/presentation/screens/todo_list_screen_test.dart`
- `test/test_helpers/widget_test_harness.dart` (FTheme + ProviderScope 래퍼)

## Acceptance Criteria

```bash
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter build windows --debug
```

debug 빌드까지 성공해야 한다 (시각적 실행은 step 6에서).

## 검증 절차

1. 위 AC 커맨드 실행.
2. 아키텍처 체크리스트:
   - presentation은 UseCase / repository만 호출하고 datasource를 직접 import하지 않는가?
   - 모든 Provider가 `@riverpod` 어노테이션 기반인가? (레거시 `Provider(...)` 0건)
   - 비동기 결과를 `AsyncValue<T>.when()`으로 분기하는가?
   - 색상 하드코딩 없이 `context.theme.colorScheme` 또는 forui 토큰을 사용하는가?
   - 위젯은 `ConsumerWidget` / `ConsumerStatefulWidget` 기반인가? `setState`는 위젯 내부 임시 UI 상태(텍스트 컨트롤러 등)에만?
3. `phases/0-mvp/index.json`의 step 5 업데이트:
   - 성공 → `"status": "completed"`, `"summary": "todos/presentation 레이어 작성. TodoFilterNotifier(@riverpod, enum: all/pending/completed), TodoListNotifier(@riverpod, Stream<List<Todo>>), TodoListScreen(FScaffold+FHeader+FTabs+FCheckbox), TodoInputBar/TodoFilterTabs/TodoListItem/TodoEditDialog 위젯. FDialog로 수정/삭제. 위젯 테스트 통과 + flutter build windows --debug 성공."`

## 금지사항

- **presentation에서 `TodoLocalDataSource` 또는 `TodoRepositoryImpl`을 직접 import하지 마라.** 이유: CLAUDE.md CRITICAL — UseCase 또는 repository **인터페이스**만 통해.
- **`Provider(...)` 인스턴스 직접 생성 금지, `ChangeNotifier`/`InheritedWidget` 사용 금지.** 이유: ADR-003.
- **`setState`로 todo 데이터를 보관하지 마라.** 이유: 상태는 Riverpod에 둔다. setState는 텍스트 필드 컨트롤러나 다이얼로그 내부 일시적 UI 상태에 한해 OK.
- **색상/폰트를 16진수 또는 named Color로 하드코딩하지 마라.** 이유: UI_GUIDE — FTheme 토큰만 사용. 변경은 `lib/app/theme.dart` 한 곳.
- **AI 슬롭 안티패턴(blur/glow/그라데이션 텍스트/보라 컬러/모든 카드 24px 라운드)을 도입하지 마라.** 이유: UI_GUIDE 안티패턴 표.
- **위젯 테스트에서 실제 sembast 파일을 만들지 마라.** 이유: 격리. fake repository 또는 in-memory sembast.
- **`ref.read`로 스트림 데이터를 가져오지 마라.** 이유: stream provider는 `ref.watch`. read는 액션 호출(메서드 트리거)에만.
- **`watchTodos`의 스트림을 화면 단에서 바로 구독하지 마라.** 이유: notifier가 필터링 로직을 책임. 화면은 notifierProvider만 본다.
