# PLAN: Todo App (Flutter Windows · sembast · Riverpod · freezed · forui)

## Context
현재 레포는 Flutter 프로젝트가 초기화되지 않은 템플릿 상태(`docs/`의 PRD/ARCHITECTURE/ADR/UI 가이드, `CLAUDE.md`만 존재)다.
사용자는 로컬 DB 기반의 가벼운 할일 관리 데스크톱 앱을 만들려 한다. 로그인은 없고, **할일 등록 / 수정 / 삭제 / 완료 토글**의 단일 도메인이며, 다음 결정이 확정됐다.

- 프로젝트명: `claude_basic_app` (현재 디렉토리명 유지)
- 스토리지: **sembast** (`sembast_io` factory, Windows 데스크톱)
- 상태: `flutter_riverpod` + `riverpod_generator` (`@riverpod`)
- 모델: `freezed` + `json_serializable`
- **UI 라이브러리: forui ^0.21.3** (shadcn 영감 미니멀 위젯셋, MaterialApp 위에 `FTheme` 빌더로 적용)
- forui 팔레트: **zinc**
- 차림 모드: **시스템 따르기** (`MediaQuery.platformBrightnessOf` 기반, 기본 라이트 fallback)
- 다이얼로그: **FDialog** (`showAdaptiveDialog`)
- Todo 필드: `title` (필수), `description`, `dueDate`, `createdAt`, `updatedAt`, `isCompleted`
- 필터: 전체 / 미완료 / 완료 **탭** 전환 (`FTabs`)
- 입력: 리스트 상단 **인라인 입력바** (`FTextField` + `FButton`)

CLAUDE.md의 features 기반 클린 아키텍처(`presentation → domain ← data`), TDD, conventional commits 규칙을 그대로 따른다.

> **참고:** forui 공식 문서는 "Cupertino/Material widgets alongside Forui widgets"가 가능하다고 안내한다. 본 계획은 가능한 곳은 모두 forui 컴포넌트를 사용하되, `MaterialApp.router` 자체와 `showAdaptiveDialog` 같은 진입점 primitive는 그대로 유지한다.

---

## 1. 프로젝트 초기화

```bash
flutter create --platforms=windows --org com.example --project-name claude_basic_app .
```
- 생성된 `lib/main.dart`, `test/widget_test.dart`, 루트 `README.md`(템플릿)는 모두 본 계획대로 덮어쓴다.
- `windows/runner/main.cpp`에서 최소 창 크기를 1024×640으로 지정.
- Flutter 3.41.0+ 필요 (forui ≥0.18.0 요구사항).

### pubspec.yaml 의존성

런타임:
- `flutter_riverpod`, `riverpod_annotation`
- `freezed_annotation`, `json_annotation`
- `sembast`, `path_provider`
- `go_router`
- `fpdart` (`Either<Failure, T>` 용 — ADR-002 준수)
- `intl` (날짜 포맷)
- **`forui: ^0.21.3`**

dev:
- `build_runner`
- `riverpod_generator`
- `freezed`, `json_serializable`
- `flutter_test`, `mocktail`, `riverpod_test`

설치/생성:
```
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

---

## 2. 디렉토리 구조

`docs/ARCHITECTURE.md`의 구조를 그대로 따른다. 본 앱에서 채울 파일만 명시한다.

```
lib/
├── main.dart                       # WidgetsFlutterBinding.ensureInitialized + ProviderScope + runApp(MyApp)
├── app/
│   ├── app.dart                    # MaterialApp.router + builder: FTheme(FToaster(FTooltipGroup(child)))
│   ├── router.dart                 # go_router (단일 라우트: /)
│   └── theme.dart                  # FThemeData lookup: FThemes.zinc.light.desktop / .dark.desktop
├── core/
│   ├── error/
│   │   ├── failure.dart            # sealed Failure (DatabaseFailure, ValidationFailure)
│   │   └── exceptions.dart         # CacheException 등 datasource 단 throw
│   ├── usecase/
│   │   └── usecase.dart            # abstract class UseCase<R, P> { Future<Either<Failure, R>> call(P); }
│   └── database/
│       └── sembast_provider.dart   # @riverpod Future<Database> appDatabase(ref) — getApplicationDocumentsDirectory + databaseFactoryIo
└── features/todos/
    ├── data/
    │   ├── datasources/
    │   │   └── todo_local_datasource.dart   # StoreRef<String, Map<String,Object?>>('todos') CRUD
    │   ├── models/
    │   │   └── todo_model.dart              # freezed + json_serializable, toEntity / fromEntity
    │   └── repositories/
    │       └── todo_repository_impl.dart    # try/catch → Either<Failure, T>
    ├── domain/
    │   ├── entities/
    │   │   └── todo.dart                    # freezed entity (순수 Dart, Flutter import 금지)
    │   ├── repositories/
    │   │   └── todo_repository.dart         # abstract class
    │   └── usecases/
    │       ├── watch_todos.dart             # Stream<Either<Failure, List<Todo>>>
    │       ├── add_todo.dart
    │       ├── update_todo.dart
    │       ├── delete_todo.dart
    │       └── toggle_todo_completed.dart
    └── presentation/
        ├── providers/
        │   ├── todo_repository_provider.dart # @riverpod TodoRepository (datasource 주입)
        │   ├── todo_filter_provider.dart     # @riverpod enum {all, pending, completed}
        │   └── todo_list_notifier.dart       # @riverpod AsyncNotifier — watch 후 필터 적용
        ├── screens/
        │   └── todo_list_screen.dart         # FScaffold(header: FHeader, content: ...)
        └── widgets/
            ├── todo_input_bar.dart           # FTextField + FButton(추가, Enter도 동일 동작)
            ├── todo_filter_tabs.dart         # FTabs(controller) — 전체/미완료/완료
            ├── todo_list_item.dart           # FTile or Row: FCheckbox + 제목 + 마감일 + FPopover(액션)
            └── todo_edit_dialog.dart         # showAdaptiveDialog → FDialog(title/메모/마감일 + 삭제/저장)
```

---

## 3. 핵심 설계 포인트

### 3.1 forui 통합 (theme + app 진입)

`lib/app/theme.dart`
```dart
// forui 팔레트 zinc, 시스템 모드. desktop 변형 사용(폰트 크기/터치 영역 차이).
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

FThemeData appFTheme(Brightness brightness) =>
    brightness == Brightness.dark
        ? FThemes.zinc.dark.desktop
        : FThemes.zinc.light.desktop;
```

`lib/app/app.dart`
```dart
class TodoApp extends ConsumerWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Todo',
      // FTheme이 색/타이포 토큰을 제공하지만, MaterialApp의 ThemeData도
      // 살아있어야 Material 다이얼로그 등이 일관되게 보인다.
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

### 3.2 Domain — Todo entity
```dart
@freezed
class Todo with _$Todo {
  const factory Todo({
    required String id,           // uuid v4 또는 sembast key 기반
    required String title,
    String? description,
    DateTime? dueDate,
    required bool isCompleted,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Todo;
}
```
- `lib/features/todos/domain/`은 **flutter/riverpod/sembast/forui import 금지**. 순수 Dart로만 작성.
- `freezed_annotation`은 순수 Dart 패키지이므로 허용.

### 3.3 Data — sembast 접근
- `StoreRef<String, Map<String, Object?>> store = stringMapStoreFactory.store('todos');`
- 키는 entity의 `id`를 그대로 사용 → `store.record(todo.id).put(db, model.toJson())`.
- 변경 스트림: `store.query(finder: Finder(sortOrders: [SortOrder('createdAt', false)])).onSnapshots(db)` → `RecordSnapshot` 리스트를 `TodoModel` → `Todo`로 매핑.
- 모든 throw는 `CacheException`으로 통일, repository에서 `DatabaseFailure`로 변환.

### 3.4 Presentation — 상태 흐름
- `appDatabaseProvider` (Future<Database>) → `todoLocalDataSourceProvider` → `todoRepositoryProvider`.
- `todoListNotifierProvider`(AsyncNotifier):
  - `build()`에서 `repository.watch()` 스트림을 구독, `ref.watch(todoFilterProvider)`에 따라 `pending/completed` 필터링.
  - 메서드: `add(title, {description, dueDate})`, `update(Todo)`, `toggle(id)`, `delete(id)` — 내부에서 UseCase 호출, `AsyncValue.guard`로 감싼다.
- 화면은 `state.when(data:, loading:, error:)`만 사용.

### 3.5 forui 위젯 매핑
| 자리 | forui 위젯 | 비고 |
|------|------------|------|
| 페이지 | `FScaffold(header: FHeader(title: Text('Todo')))` | 페이지 제목 + 본문 |
| 입력바 | `FTextField` + `FButton.primary` | Enter 키와 버튼 둘 다 추가 트리거 |
| 필터 탭 | `FTabs` (controller 기반) | 전체/미완료/완료 |
| 리스트 항목 | `FTile`(또는 Row + `FCheckbox`) | leading=FCheckbox, title=제목, subtitle=마감일, trailing=`FPopover` 액션 |
| 수정/삭제 | `showAdaptiveDialog` + `FDialog` | actions에 `FButton.outline('삭제')` + `FButton.primary('저장')` |
| 마감일 | `FDatePicker` 또는 `FCalendar` | 다이얼로그 안에서 사용 |

### 3.6 화면 레이아웃 (UI_GUIDE forui 버전 준수)
```
┌──────────────────────────────────────────────────────────┐
│  Todo                                                     │ ← FHeader
│  ┌─────────────────────────────────────────┐  ┌────────┐ │
│  │ + 새 할일을 입력하고 Enter…             │  │ 추가   │ │ ← FTextField + FButton
│  └─────────────────────────────────────────┘  └────────┘ │
│  [ 전체 ][ 미완료 ][ 완료 ]                                │ ← FTabs
│  ┌─────────────────────────────────────────────────────┐ │
│  │ ☐  보고서 작성              내일 18:00         …    │ │
│  │ ☑  장보기 (취소선)          —                  …    │ │ ← FTile
│  └─────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────┘
```
- 좌측 정렬, `ConstrainedBox(maxWidth: 1024)` 중앙 배치.
- 색상은 `Theme.of(context)`가 아니라 **`context.theme.colorScheme`** (forui 확장)으로 접근. 하드코딩 금지.
- AI 슬롭 안티패턴(blur/glow/그라데이션 텍스트/보라 브랜드/유리 효과 등) 그대로 금지.

### 3.7 라우팅
- `/` 단일 라우트로 `TodoListScreen`. 다이얼로그는 `showAdaptiveDialog`. go_router는 향후 확장 대비 골격만 둔다.

---

## 4. 작업 순서 (TDD)

각 단계마다 테스트 먼저 작성 → 구현 → `flutter analyze` & `flutter test` 통과 확인.

1. **프로젝트 init & 의존성 설치** — `flutter create` 후 `pubspec.yaml`에 forui 포함, build_runner 1차 실행.
2. **core 레이어** — `Failure`, `UseCase` 베이스, `appDatabaseProvider`. 테스트: `appDatabaseProvider`가 임시 디렉토리에서 Database를 생성하는지(통합).
3. **domain 레이어** — `Todo` entity, `TodoRepository` 추상. 테스트: entity 동등성/copyWith.
4. **UseCase** — `add/update/delete/toggle/watch`. 테스트: `mocktail`로 repository mock, 정상/실패 경로.
5. **data 레이어** — `TodoModel`(toEntity/fromEntity), `TodoLocalDataSource`, `TodoRepositoryImpl`. 테스트: sembast `databaseFactoryMemory`로 in-memory DB에 대해 CRUD.
6. **presentation providers** — `TodoFilterProvider`, `TodoListNotifier`. 테스트: ProviderContainer로 add → 상태 갱신 / 필터 전환.
7. **테마/라우터/main 연결** — `theme.dart`(forui 팔레트), `app.dart`(FTheme builder), `router.dart`, `main.dart`에서 ProviderScope 시작.
8. **위젯** — `TodoInputBar`, `TodoFilterTabs`, `TodoListItem`, `TodoEditDialog`, `TodoListScreen`. widget test 시 `FTheme(data: FThemes.zinc.light.desktop, child: ...)` 로 래핑. 시나리오: 항목 추가 → 리스트 표시 / 체크 토글 / 다이얼로그 수정 / 삭제.
9. **문서 업데이트** — `docs/PRD.md` 전면 채움(5.1), `docs/UI_GUIDE.md` forui 기준 재작성(5.2), `docs/ADR.md`에 ADR-007(forui 채택) 추가(5.3).
10. **수동 검증** — `flutter run -d windows` 로 전 시나리오 클릭, 시스템 다크/라이트 전환 시 색상 반응 확인.

---

## 5. 문서 갱신 (이번 작업 범위 포함)

### 5.1 `docs/PRD.md` — **전면 채움** (현재 모든 필드가 `{}` 템플릿)
다음 값으로 채운다:

- **프로젝트명**: Todo (claude_basic_app)
- **목표**: 외부 서비스 의존 없이 로컬에서 동작하는 가벼운 할일 관리 데스크톱 도구.
- **사용자**: Windows 데스크톱에서 작업하는 개인 사용자(개발자/지식 노동자). 동기화/협업 없이 자기 PC에서만 사용.
- **플랫폼**:
  - 1차 타겟: Windows 10/11 (x64)
  - 배포 방식: MVP는 `flutter build windows --release` 산출물(exe + 동봉 폴더). MSIX 패키징은 후속.
- **핵심 기능**:
  1. 할일 등록 (제목 필수, 메모/마감일 선택)
  2. 할일 수정 (다이얼로그)
  3. 할일 삭제
  4. 완료 여부 토글 + 필터 탭(전체/미완료/완료)
- **MVP 제외**:
  - macOS / Linux 데스크톱, 모바일 빌드
  - 클라우드 동기화, 다기기 동기화
  - 알림/리마인더, 검색, 태그·카테고리·우선순위
  - 자동 업데이트, 로그인/계정
- **비기능 요구사항**:
  - 콜드 스타트 2초 이내 (release 빌드)
  - 완전 오프라인 동작
  - 데이터 저장 위치: `%APPDATA%\com.example\claude_basic_app\todos.db` (sembast 파일)
  - 최소 사양: Windows 10 1809+, RAM 4GB
- **디자인**:
  - forui(zinc 팔레트) 기반 미니멀 데스크톱 도구 톤
  - 시스템 다크/라이트 모드 자동 추적
  - AI 슬롭 안티패턴(blur/glow/그라데이션 텍스트 등) 금지 — UI_GUIDE 규칙 준수

### 5.2 `docs/UI_GUIDE.md` → forui 기준으로 **재작성**
- "Material vs 자체 디자인" 섹션을 "forui 기반 컴포넌트 매핑"으로 교체
- 색상 표는 FTheme 토큰명(`primary`, `mutedForeground`, `border` 등) 기준으로 변경
- 컴포넌트 예시(카드/버튼/입력)는 `FCard`, `FButton`, `FTextField`로 교체
- 안티패턴 표(BackdropFilter blur 등)는 유지

### 5.3 `docs/ADR.md` → **ADR-007: UI 라이브러리로 forui 채택** 추가
- **결정**: forui ^0.21.3 채택, 팔레트는 zinc, MaterialApp.router builder에서 FTheme로 래핑.
- **이유**: shadcn 영감의 미니멀 톤이 데스크톱 도구 컨셉과 부합. Material Design의 모바일 톤보다 정보 밀도 높은 데스크톱 UI에 적합. Material 위젯과 공존 가능해 점진 도입 안전.
- **트레이드오프**: 0.x 메이저 전 단계라 minor에서 API 깨질 위험. 일부 Material 진입점(showAdaptiveDialog 등)을 그대로 써야 해 두 시스템이 공존.

---

## 6. 주의 / 의존성 위험

- **domain 순수성**: `freezed_annotation` OK. `forui`/`flutter`/`riverpod`/`sembast`는 domain 레이어에서 import 금지.
- **forui 버전 변동**: 0.x 패키지라 마이너 업데이트에서 API 변경 가능. `pubspec.yaml`에서 `^0.21.3`으로 마이너 변경까지 허용하되, build 깨지면 즉시 핀(`0.21.3`).
- **sembast 경로**: `path_provider`의 `getApplicationDocumentsDirectory()`는 Flutter binding 필요 → main 시작에 `WidgetsFlutterBinding.ensureInitialized()`.
- **Stream 기반 watch**: `store.query().onSnapshots(db)`는 finder 변경 시 새 스트림 필요. 필터는 클라이언트(notifier) 측에서 처리하고 DB 쿼리는 항상 전체 + 정렬로 단순화.
- **`*.g.dart`/`*.freezed.dart`** 는 `.gitignore`에서 무시됨(현재 설정). CI/신규 클론 시 `build_runner` 실행 필요.
- **flutter analyze 0 경고** 목표 — `flutter_lints` 기본 룰셋 사용.

---

## 7. 검증 방법

- 단위/위젯: `flutter test` — UseCase, RepositoryImpl, Notifier, TodoListScreen 통과.
  - 위젯 테스트는 `FTheme(data: FThemes.zinc.light.desktop, child: MaterialApp(home: ...))` 래퍼 헬퍼로 감싼다.
- 정적 분석: `flutter analyze` 경고 0건.
- 데스크톱 실행: `flutter run -d windows` 로 다음 시나리오 수동 확인:
  1. 인라인 입력바에 제목 입력 → Enter 또는 [추가] 클릭 → 리스트 최상단에 추가.
  2. `FCheckbox` 토글 → 완료 탭에서만 보이고 취소선 처리.
  3. 항목 클릭 → `FDialog`에서 제목/메모/마감일 수정 → 저장 시 반영.
  4. 다이얼로그 [삭제] → 리스트에서 즉시 제거.
  5. 앱 재시작 후 데이터 유지 (sembast 파일은 `%APPDATA%\com.example\claude_basic_app\todos.db` 위치).
  6. Windows 시스템을 다크/라이트로 전환 시 forui 팔레트가 즉시 반영.
- 릴리즈 빌드: `flutter build windows --release` 성공.

---

## 8. 후속 작업 (이번 범위 외)

- 검색, 우선순위, 카테고리/태그
- 알림(마감일 도달 시 시스템 알림)
- 데이터 export/import (JSON)
- macOS / Linux 빌드
- 수동 테마 토글 버튼 (상단 헤더에 해/달 아이콘)
