# Step 4: todos-data

## 읽어야 할 파일

- `/CLAUDE.md`
- `/docs/ARCHITECTURE.md`
- `/docs/ADR.md` (ADR-006: sembast)
- `/docs/plans/PLAN_todo_app.md` (3.2 Data 절)
- 이전 step 산출물:
  - `lib/core/error/failure.dart`, `lib/core/error/exceptions.dart`
  - `lib/core/database/sembast_provider.dart`
  - `lib/features/todos/domain/entities/todo.dart`
  - `lib/features/todos/domain/repositories/todo_repository.dart`

## 작업

이 step의 목표: **`features/todos/data/` 레이어 전체**(DTO, datasource, repository 구현)를 sembast로 작성하고, `databaseFactoryMemory` 기반 in-memory 테스트로 CRUD를 검증한다.

### 1) `lib/features/todos/data/models/todo_model.dart`

DTO + freezed + json_serializable + entity 변환:

```dart
@freezed
class TodoModel with _$TodoModel {
  const TodoModel._();
  const factory TodoModel({
    required String id,
    required String title,
    String? description,
    int? dueDateMs,        // sembast에 ISO String 또는 epoch ms 중 하나로 통일. 본 프로젝트는 epoch ms.
    required bool isCompleted,
    required int createdAtMs,
    required int updatedAtMs,
  }) = _TodoModel;

  factory TodoModel.fromJson(Map<String, dynamic> json) => _$TodoModelFromJson(json);
  factory TodoModel.fromEntity(Todo t) => TodoModel(
    id: t.id,
    title: t.title,
    description: t.description,
    dueDateMs: t.dueDate?.millisecondsSinceEpoch,
    isCompleted: t.isCompleted,
    createdAtMs: t.createdAt.millisecondsSinceEpoch,
    updatedAtMs: t.updatedAt.millisecondsSinceEpoch,
  );

  Todo toEntity() => Todo(
    id: id,
    title: title,
    description: description,
    dueDate: dueDateMs == null ? null : DateTime.fromMillisecondsSinceEpoch(dueDateMs!),
    isCompleted: isCompleted,
    createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMs),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAtMs),
  );
}
```

> 시간 필드는 epoch ms (`int`)로 저장한다. 이유: sembast가 native 지원하는 primitive로 정렬·비교가 안전. ISO 문자열로 저장하면 정렬 시 zone 차이로 깨질 수 있다.

### 2) `lib/features/todos/data/datasources/todo_local_datasource.dart`

sembast 직접 호출. Database를 생성자 주입:

```dart
class TodoLocalDataSource {
  TodoLocalDataSource(this._db);
  final Database _db;
  static final _store = stringMapStoreFactory.store('todos');

  Future<void> upsert(TodoModel m) async { ... }       // _store.record(m.id).put(_db, m.toJson())
  Future<void> deleteById(String id) async { ... }
  Stream<List<TodoModel>> watchAll() { ... }           // _store.query(...).onSnapshots(_db) → snapshots → TodoModel
}
```

- 모든 메서드는 실패 시 `CacheException(message)` throw.
- `watchAll`은 `Finder(sortOrders: [SortOrder('createdAtMs', false)])` 로 최신순.
- 구현 안에 fpdart/Failure import 금지 — datasource는 raw exception, 변환은 repository 책임.

### 3) `lib/features/todos/data/repositories/todo_repository_impl.dart`

`TodoRepository` 구현. try/catch → Either:

```dart
class TodoRepositoryImpl implements TodoRepository {
  TodoRepositoryImpl(this._ds);
  final TodoLocalDataSource _ds;

  @override
  Stream<Either<Failure, List<Todo>>> watchAll() {
    return _ds.watchAll()
      .map((models) => Right<Failure, List<Todo>>(models.map((m) => m.toEntity()).toList()))
      .handleError((Object e, StackTrace _) => Left<Failure, List<Todo>>(DatabaseFailure(e.toString())));
    // 또는 transform StreamTransformer로 동등 처리
  }

  @override
  Future<Either<Failure, Unit>> add(Todo todo) async {
    try { await _ds.upsert(TodoModel.fromEntity(todo)); return const Right(unit); }
    on CacheException catch (e) { return Left(DatabaseFailure(e.message)); }
    catch (e) { return Left(UnexpectedFailure(e.toString())); }
  }
  // update/delete 동일 패턴
}
```

- `update`는 동일하게 `upsert`로 처리(키 동일이면 sembast가 덮어씀).

### 4) Riverpod provider 노출 (data 레이어 진입점)

`lib/features/todos/data/datasources/todo_local_datasource.dart`와 같은 위치에 provider를 둘지, 별도 파일로 둘지 — **별도 파일**로 분리한다(테스트 시 datasource를 fake로 갈아끼우기 쉽게):

`lib/features/todos/data/providers.dart` (신규)
```dart
@riverpod
Future<TodoLocalDataSource> todoLocalDataSource(TodoLocalDataSourceRef ref) async {
  final db = await ref.watch(appDatabaseProvider.future);
  return TodoLocalDataSource(db);
}

@riverpod
Future<TodoRepository> todoRepository(TodoRepositoryRef ref) async {
  final ds = await ref.watch(todoLocalDataSourceProvider.future);
  return TodoRepositoryImpl(ds);
}
```

> 두 provider는 `Future<...>` 반환. presentation 단에서 `ref.watch(todoRepositoryProvider.future)`로 await 후 사용하거나 `AsyncValue` 처리.

### 5) 단위 테스트

`test/features/todos/data/`:

#### `models/todo_model_test.dart`
- `fromEntity → toEntity` 왕복 시 동등 (단, DateTime은 ms 정밀도까지만 비교).
- `fromJson/toJson` 왕복.

#### `datasources/todo_local_datasource_test.dart`
- `databaseFactoryMemory.openDatabase('test.db')` 로 in-memory DB 생성.
- upsert → watchAll 첫 번째 emission에 해당 항목 포함.
- deleteById → watchAll에서 사라짐.
- 정렬: createdAtMs 내림차순.

#### `repositories/todo_repository_impl_test.dart`
- mocktail로 `MockTodoLocalDataSource extends Mock implements TodoLocalDataSource`.
- datasource가 throw하면 `Left(DatabaseFailure)` 반환.
- 정상 시 `Right(unit)` 또는 `Right(List<Todo>)`.

### 6) build_runner

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 생성/수정 대상 파일

- `lib/features/todos/data/models/todo_model.dart` (+ `.freezed.dart` + `.g.dart`)
- `lib/features/todos/data/datasources/todo_local_datasource.dart`
- `lib/features/todos/data/repositories/todo_repository_impl.dart`
- `lib/features/todos/data/providers.dart` (+ `.g.dart`)
- `test/features/todos/data/models/todo_model_test.dart`
- `test/features/todos/data/datasources/todo_local_datasource_test.dart`
- `test/features/todos/data/repositories/todo_repository_impl_test.dart`

## Acceptance Criteria

```bash
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```

## 검증 절차

1. 위 AC 커맨드 실행.
2. 아키텍처 체크리스트:
   - data 레이어가 domain 인터페이스(`TodoRepository`)를 구현하고 있는가?
   - datasource는 raw `CacheException`만 throw하고 Failure를 모르는가?
   - repository는 try/catch로 Either로 변환하는가?
   - sembast Database는 provider 주입으로 받는가? (직접 openDatabase 호출 금지)
   - DTO와 entity가 분리되어 있고 mapper(`fromEntity`/`toEntity`)가 model 안에 있는가?
3. `phases/0-mvp/index.json`의 step 4 업데이트:
   - 성공 → `"status": "completed"`, `"summary": "todos/data 레이어 작성. TodoModel(freezed+json_serializable, epoch ms 시간), TodoLocalDataSource(stringMapStoreFactory store('todos'), CacheException throw), TodoRepositoryImpl(Either 변환), todoLocalDataSource/todoRepository provider(@riverpod). databaseFactoryMemory 기반 CRUD 테스트 통과."`

## 금지사항

- **datasource에서 fpdart/Failure를 import하지 마라.** 이유: 레이어 책임 분리 — datasource는 raw 예외, repository만 Failure를 안다.
- **datasource 안에서 `getApplicationDocumentsDirectory()`를 호출하지 마라.** 이유: Database는 step 2의 `appDatabaseProvider`가 만든 것을 받아만 쓴다.
- **TodoModel과 Todo entity를 같은 파일에 합치지 마라.** 이유: ARCHITECTURE — DTO와 Entity 분리.
- **시간 필드를 ISO String으로 저장하지 마라.** 이유: sembast 정렬/비교 안정성.
- **`ref.read(appDatabaseProvider.future)`를 datasource 내부에서 호출하지 마라.** 이유: 의존성은 생성자 주입. provider는 외곽(`providers.dart`)에서만.
- **테스트에서 실제 파일시스템 경로를 만들지 마라.** 이유: 격리·속도. `databaseFactoryMemory` 사용.
- **`store.add()`로 sembast 자동 키를 쓰지 마라.** 이유: id 생성은 domain `AddTodo`(uuid)의 책임. `store.record(id).put` 으로 명시적 키.
