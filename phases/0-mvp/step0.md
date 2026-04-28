# Step 0: project-setup

## 읽어야 할 파일

먼저 아래 파일들을 읽고 프로젝트의 기획·아키텍처·설계 의도를 파악하라:

- `/CLAUDE.md`
- `/docs/PRD.md`
- `/docs/ARCHITECTURE.md`
- `/docs/ADR.md`
- `/docs/UI_GUIDE.md`
- `/docs/plans/PLAN_todo_app.md`
- `/.gitignore`

특히 ADR-003(Riverpod codegen), ADR-004(freezed), ADR-006(sembast), ADR-007(forui) 결정 사항을 확인하고, CLAUDE.md의 CRITICAL 규칙(features 클린 아키텍처, domain 순수성, `@riverpod` 어노테이션 강제)을 숙지하라.

## 작업

이 step은 **Flutter 프로젝트를 초기화하고 의존성을 모두 설치**하는 단계다. 비즈니스 코드는 작성하지 않는다.

### 1) Flutter 프로젝트 생성

레포 루트에서 다음을 실행한다:

```bash
flutter create --platforms=windows --org com.example --project-name claude_basic_app .
```

생성 후 `lib/main.dart`, `test/widget_test.dart`, 루트 `README.md`(템플릿 부분)는 본 step에서 정리한다. `windows/`, `pubspec.yaml`은 Flutter가 만든 골격을 그대로 둔다.

### 2) `pubspec.yaml` 의존성 작성

`flutter create`로 생성된 `pubspec.yaml`을 다음 의존성으로 갱신한다.

런타임 (`dependencies`):
- `flutter` (sdk)
- `flutter_riverpod`
- `riverpod_annotation`
- `freezed_annotation`
- `json_annotation`
- `sembast`
- `path_provider`
- `go_router`
- `fpdart`
- `intl`
- `uuid`
- `forui: ^0.21.3`

개발 (`dev_dependencies`):
- `flutter_test` (sdk)
- `flutter_lints`
- `build_runner`
- `riverpod_generator`
- `freezed`
- `json_serializable`
- `mocktail`

버전은 모두 최신 stable로 잡되, `forui`만 명시적으로 `^0.21.3`로 핀.

### 3) `lib/main.dart` 임시 골격

이 step에서는 빈 `ProviderScope` + 자리표시자 화면만 둔다. 실제 FTheme/router는 step 1에서 채운다.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: _Bootstrap()));
}

class _Bootstrap extends StatelessWidget {
  const _Bootstrap();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(body: Center(child: Text('claude_basic_app — bootstrap'))),
    );
  }
}
```

### 4) `test/widget_test.dart` 정리

Flutter가 생성한 카운터 위젯 테스트는 본 프로젝트에 맞지 않는다. **삭제하거나** `_Bootstrap`이 정상적으로 빌드되는지만 확인하는 최소 smoke test로 교체한다.

```dart
// 'claude_basic_app — bootstrap' 텍스트가 표시되는지만 확인
```

### 5) 루트 `README.md` 정리

현재 README.md는 git status에 따르면 deleted 상태다. 한 단락짜리 README를 새로 작성한다 (이름·요약·실행 커맨드만):

```markdown
# claude_basic_app

Windows 데스크톱용 로컬 할일 관리 앱 (Flutter · Riverpod · sembast · forui).

## 실행

flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d windows
```

### 6) build_runner 1차 실행

이 step에서는 아직 `*.freezed.dart`/`*.g.dart`를 만들 코드가 없으므로 build_runner 실행은 **선택**이다. AC에 포함하지 않는다. (step 2 이후로 미룬다.)

### 생성/수정 대상 파일

- `pubspec.yaml` (Flutter create 결과를 의존성 블록만 본 step 사양으로 교체)
- `pubspec.lock` (생성됨 — 그대로 커밋)
- `analysis_options.yaml` (Flutter 기본값 그대로 OK, `flutter_lints` 활성)
- `lib/main.dart` (위 골격으로 교체)
- `test/widget_test.dart` (smoke test로 교체)
- `README.md` (위 내용으로 새로 작성)
- `windows/` 디렉토리 일체 (Flutter가 생성한 그대로 커밋)
- `analysis_options.yaml` 등 기타 Flutter 생성 파일

## Acceptance Criteria

```bash
flutter pub get        # 의존성 충돌 없이 성공
flutter analyze        # 경고 0건
flutter test           # smoke test 통과
```

## 검증 절차

1. 위 AC 커맨드를 모두 실행한다.
2. `flutter run -d windows`를 직접 실행해 빈 화면이 뜨는지는 검증하지 않아도 된다 (이 step의 목표는 빌드/테스트 통과).
3. 디렉토리 구조가 다음을 포함하는지 확인:
   - `lib/main.dart`
   - `test/widget_test.dart`
   - `windows/runner/main.cpp`
   - `pubspec.yaml`에 forui, sembast, riverpod 등 모두 포함
4. `phases/0-mvp/index.json`의 step 0을 업데이트:
   - 성공 → `"status": "completed"`, `"summary": "Flutter 프로젝트 초기화 완료. pubspec.yaml에 forui ^0.21.3, sembast, flutter_riverpod, freezed, fpdart, uuid 등 의존성 추가. lib/main.dart에 빈 ProviderScope 골격 작성. flutter analyze/test 통과."`
   - 실패 3회 → `"status": "error"`, `"error_message": "..."`
   - 사용자 개입 필요 (Visual Studio Build Tools 미설치 등) → `"status": "blocked"`, `"blocked_reason": "..."`

## 금지사항

- **비즈니스 로직(features/, core/)을 이 step에서 작성하지 마라.** 이유: 이 step은 init 전용이며 step 1~5에서 다룬다.
- **freezed/riverpod 코드 생성 결과 파일을 손으로 만들지 마라.** 이유: build_runner가 덮어쓴다. (이 step에선 아예 안 만든다.)
- **forui import를 main.dart에 끼워넣지 마라.** 이유: FTheme 적용은 step 1의 책임. 이 step에선 의존성만 등록.
- **`pubspec.yaml`의 `flutter_lints`를 끄지 마라.** 이유: analyze 0건 정책의 기준.
- **flutter create 시 `--platforms`에 windows 외 플랫폼을 추가하지 마라.** 이유: PRD MVP 범위는 Windows 전용.
- **기존 `docs/`, `CLAUDE.md`, `scripts/`, `.claude/`, `phases/`를 건드리지 마라.** 이유: 이 step의 책임 범위 밖.
