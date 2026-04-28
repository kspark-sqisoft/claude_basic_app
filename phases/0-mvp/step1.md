# Step 1: app-shell

## 읽어야 할 파일

먼저 아래 파일들을 읽고 프로젝트의 기획·아키텍처·디자인 시스템을 파악하라:

- `/CLAUDE.md`
- `/docs/PRD.md`
- `/docs/ARCHITECTURE.md`
- `/docs/ADR.md`
- `/docs/UI_GUIDE.md` ← forui 토큰/컴포넌트 매핑 표 필독
- `/docs/plans/PLAN_todo_app.md` (3.1 forui 통합 섹션)
- 이전 step 산출물:
  - `pubspec.yaml`
  - `lib/main.dart`
  - `test/widget_test.dart`
  - `windows/runner/main.cpp`

## 작업

이 step의 목표: **앱 진입점·테마·라우터를 forui 기반으로 정비하고, 자리표시자 TodoListScreen을 띄운다.** Todo 도메인 코드는 아직 작성하지 않는다.

### 1) `lib/app/theme.dart`

forui `FThemeData`를 brightness 기반으로 반환하는 함수 작성:

```dart
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

FThemeData appFTheme(Brightness brightness) =>
    brightness == Brightness.dark
        ? FThemes.zinc.dark.desktop
        : FThemes.zinc.light.desktop;
```

ADR-007에 따라 팔레트는 zinc, 변형은 desktop.

### 2) `lib/app/router.dart`

`go_router` 단일 라우트(`/`) 정의를 Riverpod provider로 노출한다. `@riverpod` 어노테이션 사용:

```dart
@riverpod
GoRouter router(RouterRef ref) {
  return GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, __) => const TodoListScreen()),
    ],
  );
}
```

`TodoListScreen`은 step 5에서 본격 구현하므로 이 step에선 `lib/features/todos/presentation/screens/todo_list_screen.dart`에 **자리표시자 컴포넌트**만 만든다:

```dart
class TodoListScreen extends StatelessWidget {
  const TodoListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FScaffold(
      header: FHeader(title: const Text('Todo')),
      child: const Center(child: Text('coming soon')),
    );
  }
}
```

### 3) `lib/app/app.dart`

`MaterialApp.router` + `builder`에서 FTheme 래핑. 시스템 brightness 추적:

```dart
class TodoApp extends ConsumerWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Todo',
      themeMode: ThemeMode.system,
      theme: ThemeData(brightness: Brightness.light, useMaterial3: true),
      darkTheme: ThemeData(brightness: Brightness.dark, useMaterial3: true),
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) {
        final brightness = MediaQuery.platformBrightnessOf(context);
        return FTheme(
          data: appFTheme(brightness),
          child: FToaster(child: FTooltipGroup(child: child!)),
        );
      },
    );
  }
}
```

> forui API는 0.21.x 기준이다. `FToaster`/`FTooltipGroup` 시그니처가 minor 업데이트로 달라졌다면 `pub.dev/documentation/forui/0.21.3/`를 그대로 따른다. 동일 버전을 pin했으므로 이 step 시점에는 위 시그니처가 유효하다.

### 4) `lib/main.dart` 갱신

step 0의 임시 골격을 다음으로 교체:

```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: TodoApp()));
}
```

### 5) `windows/runner/main.cpp` — 최소 창 크기

생성된 main.cpp에서 `window.CreateAndShow(L"claude_basic_app", origin, size);` 의 `size`를 `Size(1024, 640)`으로 설정 (또는 동등). PRD 비기능 요구사항(데스크톱 1024×640 최소 창) 충족.

### 6) build_runner 1차 실행

`router_provider`가 `@riverpod` 어노테이션을 쓰므로 `*.g.dart`가 생성된다.

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 생성/수정 대상 파일

- `lib/app/theme.dart` (신규)
- `lib/app/app.dart` (신규)
- `lib/app/router.dart` (신규)
- `lib/app/router.g.dart` (build_runner 자동 생성 — 수동 편집 금지)
- `lib/features/todos/presentation/screens/todo_list_screen.dart` (자리표시자, 신규)
- `lib/main.dart` (갱신)
- `windows/runner/main.cpp` (창 크기만)
- `test/widget_test.dart` (TodoApp 시작 smoke test로 갱신)

### 7) widget smoke test

`TodoApp`이 ProviderScope 안에서 빌드되어 'Todo' 헤더가 보이는지만 확인:

```dart
testWidgets('TodoApp boots and renders header', (tester) async {
  await tester.pumpWidget(const ProviderScope(child: TodoApp()));
  await tester.pump();
  expect(find.text('Todo'), findsOneWidget);
});
```

## Acceptance Criteria

```bash
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```

세 커맨드 모두 성공 + analyze 경고 0건.

## 검증 절차

1. 위 AC 커맨드 실행.
2. 아키텍처 체크리스트:
   - `lib/app/`(전역)과 `lib/features/`(기능)가 분리되었는가?
   - `router_provider`는 `@riverpod` 어노테이션으로 정의했는가?
   - `MaterialApp.router`의 `builder`에서만 FTheme이 래핑되었는가?
   - 색·폰트 하드코딩이 위젯 내부에 없는가? (있으면 안 됨)
3. `phases/0-mvp/index.json`의 step 1 업데이트:
   - 성공 → `"status": "completed"`, `"summary": "lib/app/{theme,app,router}.dart 작성. forui FTheme(zinc, 시스템 모드) 적용. routerProvider(@riverpod) 단일 라우트로 자리표시자 TodoListScreen 노출. FScaffold + FHeader 사용. windows/runner/main.cpp 창 크기 1024x640. build_runner 1차 실행으로 *.g.dart 생성."`
   - error/blocked 시 동일 패턴.

## 금지사항

- **레거시 `Provider(...)` 인스턴스를 직접 만들지 마라.** 이유: CLAUDE.md CRITICAL — `@riverpod` 어노테이션 강제.
- **`router.g.dart`를 손으로 편집하지 마라.** 이유: build_runner가 덮어쓴다.
- **자리표시자 TodoListScreen 안에 sembast/repository 호출을 끼워넣지 마라.** 이유: 이 step의 책임 범위 밖. step 5에서 처리.
- **`MaterialApp.router`를 `MaterialApp`(home: ...)으로 대체하지 마라.** 이유: ADR-005 — go_router 채택.
- **forui와 fluent_ui를 동시에 도입하지 마라.** 이유: UI_GUIDE — 한 앱에서 두 디자인 시스템 혼용 금지.
- **`Theme.of(context)` 색상 하드코딩으로 forui 토큰을 우회하지 마라.** 이유: UI_GUIDE — 색상은 FTheme colorScheme 토큰만 사용.
- **`presentation/screens/todo_list_screen.dart`에 비즈니스 로직(repository/usecase 호출)을 두지 마라.** 이유: step 5의 책임.
