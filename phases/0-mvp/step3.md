# Step 3: todos-domain

## 읽어야 할 파일

- `/CLAUDE.md` ← CRITICAL: domain은 외부 패키지 import 금지
- `/docs/ARCHITECTURE.md`
- `/docs/ADR.md` (ADR-002, ADR-004)
- `/docs/plans/PLAN_todo_app.md` (3.1 Domain 절)
- 이전 step 산출물:
  - `lib/core/error/failure.dart`, `lib/core/error/exceptions.dart`
  - `lib/core/usecase/usecase.dart`

## 작업

이 step의 목표: **`features/todos/domain/` 레이어 전체를 TDD로 작성**한다. 순수 Dart로만 작성하며, **flutter / flutter_riverpod / sembast / forui / path_provider 등 어떤 외부 패키지도 import 금지**한다. 허용되는 import: `package:freezed_annotation/freezed_annotation.dart`, `package:fpdart/fpdart.dart`, `package:meta/meta.dart`, 그리고 `lib/core/`.

### 1) `lib/features/todos/domain/entities/todo.dart`

`freezed` 엔티티:

```dart
@freezed
class Todo with _$Todo {
  const factory Todo({
    required String id,
    required String title,
    String? description,
    DateTime? dueDate,
    required bool isCompleted,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Todo;
}
```

- 모든 필드는 entity 자체에 보관. 변환 로직은 data 레이어 책임.

### 2) `lib/features/todos/domain/repositories/todo_repository.dart`

추상 인터페이스. 순수 Dart:

```dart
abstract class TodoRepository {
  Stream<Either<Failure, List<Todo>>> watchAll();
  Future<Either<Failure, Unit>> add(Todo todo);
  Future<Either<Failure, Unit>> update(Todo todo);
  Future<Either<Failure, Unit>> delete(String id);
}
```

- `Unit`은 fpdart의 unit 타입. void 대신 Either 안에 담기 위해 사용.
- 토글은 별도 메서드를 두지 않는다. notifier가 `update()`로 처리.

### 3) `lib/features/todos/domain/usecases/`

각각 단일 책임:

```dart
// watch_todos.dart
class WatchTodos implements StreamUseCase<List<Todo>, NoParams> {
  WatchTodos(this._repo);
  final TodoRepository _repo;
  @override
  Stream<Either<Failure, List<Todo>>> call(NoParams params) => _repo.watchAll();
}

// add_todo.dart
class AddTodoParams { final String title; final String? description; final DateTime? dueDate; ... }
class AddTodo implements UseCase<Todo, AddTodoParams> { ... }

// update_todo.dart
class UpdateTodo implements UseCase<Unit, Todo> { ... }

// delete_todo.dart
class DeleteTodo implements UseCase<Unit, String> { ... }

// toggle_todo_completed.dart
class ToggleTodoCompleted implements UseCase<Todo, Todo> {
  // 입력 Todo의 isCompleted를 반전 + updatedAt 갱신 후 repository.update 호출. 반환은 새 Todo.
}
```

세부 구현 규칙:
- `AddTodo`는 내부에서 `id`(uuid v4), `createdAt`/`updatedAt`(DateTime.now)를 채워 새 Todo를 만든 뒤 repository.add 호출. **uuid 생성기는 생성자 인자로 주입**(`String Function() idGenerator`)해 테스트 가능하게.
- `AddTodo` 안에서 `DateTime.now()`도 인자로 주입(`DateTime Function() now`).
- `title` trim 후 빈 문자열이면 `Left(ValidationFailure('제목은 비울 수 없습니다.'))`.
- `ToggleTodoCompleted`도 `now` 주입.

### 4) 단위 테스트 (TDD: 각 UseCase별 먼저 작성)

`test/features/todos/domain/usecases/`:
- `add_todo_test.dart` — title 정상/공백/오직 공백, repository 성공/실패 경로.
- `update_todo_test.dart` — 정상 + repository 실패.
- `delete_todo_test.dart` — 정상 + 실패.
- `toggle_todo_completed_test.dart` — `isCompleted` 반전, `updatedAt` 갱신, repository.update가 호출됐는지 검증.
- `watch_todos_test.dart` — repository 스트림이 그대로 패스스루.

`mocktail`로 `MockTodoRepository extends Mock implements TodoRepository` 작성. fpdart의 `Right(unit)`을 stub.

`test/features/todos/domain/entities/todo_test.dart`:
- copyWith로 `isCompleted` 토글, 동등성 검증.

### 5) build_runner

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 생성/수정 대상 파일

- `lib/features/todos/domain/entities/todo.dart` + `todo.freezed.dart`
- `lib/features/todos/domain/repositories/todo_repository.dart`
- `lib/features/todos/domain/usecases/watch_todos.dart`
- `lib/features/todos/domain/usecases/add_todo.dart`
- `lib/features/todos/domain/usecases/update_todo.dart`
- `lib/features/todos/domain/usecases/delete_todo.dart`
- `lib/features/todos/domain/usecases/toggle_todo_completed.dart`
- `test/features/todos/domain/entities/todo_test.dart`
- `test/features/todos/domain/usecases/*_test.dart` (5개)

## Acceptance Criteria

```bash
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```

추가로:
- `grep -r "package:flutter" lib/features/todos/domain/ test/features/todos/domain/` 의 결과가 0건 (단, `flutter_test`는 test/에서 OK).
- `grep -r "package:flutter_riverpod\|package:sembast\|package:forui\|package:path_provider" lib/features/todos/domain/` 의 결과가 0건.

## 검증 절차

1. 위 AC + grep 검증.
2. 아키텍처 체크리스트:
   - domain 레이어가 순수 Dart인가? (외부 패키지 import 0)
   - 모든 UseCase가 `Either<Failure, T>` 반환?
   - `WatchTodos`만 `StreamUseCase` 상속?
   - `AddTodo`/`ToggleTodoCompleted`의 시간/uuid 의존성이 인자로 주입돼 테스트 가능?
   - title trim/공백 검증이 ValidationFailure로 분기?
3. `phases/0-mvp/index.json`의 step 3 업데이트:
   - 성공 → `"status": "completed"`, `"summary": "todos/domain 레이어 작성. Todo entity(freezed), TodoRepository 인터페이스, UseCase 5종(WatchTodos/AddTodo/UpdateTodo/DeleteTodo/ToggleTodoCompleted) 모두 Either<Failure,T> 반환. uuid/now 주입식 + ValidationFailure 검증. 모든 단위 테스트 통과."`

## 금지사항

- **`package:flutter/...`, `package:flutter_riverpod/...`, `package:sembast/...`, `package:forui/...` import 절대 금지.** 이유: CLAUDE.md CRITICAL — domain은 순수 Dart.
- **UseCase 안에서 `DateTime.now()`나 `Uuid().v4()`를 직접 호출하지 마라.** 이유: 테스트 가능성을 위해 생성자 주입.
- **`toggle_todo_completed`를 `repository.update`로 직접 변환하지 말고 별도 UseCase로 두라.** 이유: 비즈니스 의도(반전 + updatedAt 갱신)를 캡슐화.
- **Repository 인터페이스를 features 디렉토리 외부에 두지 마라.** 이유: domain 인터페이스는 그 feature의 책임.
- **freezed 자동 생성 파일을 손으로 편집하지 마라.** 이유: build_runner 덮어씀.
- **mocktail의 fallback value 등록을 빼먹지 마라** (Todo, AddTodoParams 등 커스텀 타입 stub 시 필요). 이유: mocktail 런타임 에러.
