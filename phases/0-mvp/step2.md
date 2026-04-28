# Step 2: core-foundation

## 읽어야 할 파일

- `/CLAUDE.md`
- `/docs/ARCHITECTURE.md` ← 패턴/에러 처리 섹션
- `/docs/ADR.md` (특히 ADR-002, ADR-006)
- `/docs/plans/PLAN_todo_app.md` (3.2~3.3 절)
- 이전 step 산출물:
  - `pubspec.yaml`
  - `lib/main.dart`, `lib/app/app.dart`, `lib/app/router.dart`

## 작업

이 step은 **모든 feature가 공유하는 기반 코드**(`lib/core/`)를 작성한다. Todo 도메인은 다음 step에서 다룬다.

### 1) `lib/core/error/failure.dart`

`fpdart`의 `Either<Failure, T>`에 사용할 sealed Failure 정의. `freezed`의 sealed union 사용:

```dart
@freezed
sealed class Failure with _$Failure {
  const factory Failure.database(String message) = DatabaseFailure;
  const factory Failure.validation(String message) = ValidationFailure;
  const factory Failure.unexpected(String message) = UnexpectedFailure;
}
```

- 모든 Failure는 사용자 노출용 `message`를 포함.
- 본 MVP는 네트워크가 없으므로 `NetworkFailure`는 생략.

### 2) `lib/core/error/exceptions.dart`

datasource 단에서 throw하는 raw exception. 외부 패키지 의존 없는 단순 클래스:

```dart
class CacheException implements Exception {
  final String message;
  const CacheException(this.message);
  @override
  String toString() => 'CacheException: $message';
}
```

### 3) `lib/core/usecase/usecase.dart`

UseCase 베이스 클래스. ADR-002의 Either 반환 규약 강제:

```dart
abstract class UseCase<R, P> {
  Future<Either<Failure, R>> call(P params);
}

abstract class StreamUseCase<R, P> {
  Stream<Either<Failure, R>> call(P params);
}

class NoParams {
  const NoParams();
}
```

- Future/Stream 두 변형을 둔다. `WatchTodos` 같은 스트림 UseCase는 `StreamUseCase`를 상속.

### 4) `lib/core/database/sembast_provider.dart`

sembast Database 인스턴스를 Riverpod에 노출:

```dart
@Riverpod(keepAlive: true)
Future<Database> appDatabase(AppDatabaseRef ref) async {
  final dir = await getApplicationDocumentsDirectory();
  final path = p.join(dir.path, 'claude_basic_app', 'todos.db');
  return databaseFactoryIo.openDatabase(path);
}
```

- `keepAlive: true` 권장. autoDispose면 Database가 close 후 재오픈되며 트랜잭션 충돌 위험.
- 디렉토리가 없으면 `Directory(...).create(recursive: true)`로 보장.

### 5) 단위 테스트

#### `test/core/error/failure_test.dart`
- Failure 동등성/copyWith 동작 (freezed가 자동 생성한 것을 확인하는 1~2개 케이스).
- `DatabaseFailure('a') == DatabaseFailure('a')`, `!=` `DatabaseFailure('b')`.

#### `test/core/database/sembast_provider_test.dart`
- ProviderContainer로 `appDatabaseProvider`를 read한 결과가 열린 Database이고, 임시 디렉토리 기반 in-memory factory로 override해서 검증한다. **실제 path_provider를 테스트에서 호출하지 마라.** 대신 별도 `appDatabaseProvider.overrideWith((ref) async => databaseFactoryMemory.openDatabase('test.db'))` 로 override.

테스트는 `mocktail`을 쓸 부분이 거의 없다. fpdart는 dev에서 실제 인스턴스로 동작.

### 6) build_runner

freezed Failure가 `.freezed.dart`를 생성하고, `appDatabaseProvider`가 `.g.dart`를 생성한다.

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 생성/수정 대상 파일

- `lib/core/error/failure.dart` + `failure.freezed.dart` (자동)
- `lib/core/error/exceptions.dart`
- `lib/core/usecase/usecase.dart`
- `lib/core/database/sembast_provider.dart` + `sembast_provider.g.dart` (자동)
- `test/core/error/failure_test.dart`
- `test/core/database/sembast_provider_test.dart`

## Acceptance Criteria

```bash
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```

## 검증 절차

1. 위 AC 커맨드 실행.
2. 아키텍처 체크리스트:
   - `lib/core/`만 만지고 `lib/features/`는 손대지 않았는가?
   - Failure는 `freezed` sealed union으로 정의했는가?
   - `appDatabaseProvider`는 `@Riverpod(keepAlive: true)`로 정의했는가?
   - UseCase 베이스는 `Future<Either<Failure, R>>` / `Stream<Either<Failure, R>>` 시그니처를 강제하는가?
3. `phases/0-mvp/index.json`의 step 2 업데이트:
   - 성공 → `"status": "completed"`, `"summary": "core 레이어 작성. Failure(sealed: DatabaseFailure/ValidationFailure/UnexpectedFailure), CacheException, UseCase<R,P>/StreamUseCase<R,P> 베이스, appDatabaseProvider(@Riverpod keepAlive=true, sembast_io). Failure 동등성 + sembast provider override 테스트 통과."`

## 금지사항

- **`lib/core/`에서 forui import 금지.** 이유: 디자인 시스템은 presentation 레이어 책임.
- **`lib/core/`에서 features/ 디렉토리를 import하지 마라.** 이유: 의존성 방향이 거꾸로 — features가 core를 import해야 한다.
- **`appDatabaseProvider`에서 path_provider를 import할 때 `package:flutter/...`을 동시에 끌고 들어오지 마라.** 이유: provider는 외부 패키지를 명시적으로 의존하므로 OK이지만, FlutterBinding 초기화는 main.dart 책임 — provider 함수에서 ensureInitialized() 호출 금지.
- **Failure를 string 비교로 분기하지 마라.** 이유: sealed union의 `switch` 매칭으로 type-safe하게 분기.
- **UseCase에서 Either가 아닌 raw 값/예외를 반환하지 마라.** 이유: ADR-002 위반.
- **path를 `\\`로 하드코딩하지 마라.** 이유: `package:path/path.dart`의 `p.join`을 사용해 OS-agnostic하게.
