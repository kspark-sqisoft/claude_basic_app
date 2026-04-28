# Step 6: final-verification

## 읽어야 할 파일

- `/CLAUDE.md`
- `/docs/PRD.md` (검증 대상 핵심 기능 4개)
- `/docs/plans/PLAN_todo_app.md` (6장 검증 방법)
- 이전 step 산출물 전부:
  - `lib/main.dart`, `lib/app/*`
  - `lib/core/*`
  - `lib/features/todos/**`
  - `test/**`
  - `windows/runner/main.cpp`

## 작업

이 step의 목표: **MVP 전체가 빌드/테스트/정적 분석을 모두 통과하는지 확정**하고 README를 갱신해 외부 사용자가 클론 후 5분 안에 실행할 수 있게 한다. **새 기능 추가 금지.**

### 1) 전체 검증

```bash
dart run build_runner build --delete-conflicting-outputs
flutter pub get
flutter analyze
flutter test
flutter build windows --debug
```

위 5개가 모두 성공해야 한다.

- analyze 경고 0건. 경고가 남아있으면 본 step에서 해결한다 (사소한 dead import, prefer_const, missing_required_param 등).
- test 실패가 있으면 해당 step의 코드를 최소 수정해 통과시킨다. 그러나 **새 기능을 추가하거나 시그니처를 바꾸지 마라.** 단순한 수정(누락된 import, off-by-one, mock setup 누락)에 한해.

### 2) README.md 갱신

step 0에서 만든 최소 README를 다음으로 확장:

```markdown
# claude_basic_app — Todo

Windows 데스크톱용 로컬 할일 관리 앱. 외부 서비스 의존 0, 모든 데이터는 로컬 sembast 파일에 저장.

## 기술 스택

- Flutter 3.x (Windows desktop)
- Riverpod (`@riverpod` codegen)
- freezed + json_serializable
- sembast (`%APPDATA%\com.example\claude_basic_app\todos.db`)
- forui (zinc 팔레트, 시스템 라이트/다크)
- go_router

## 구조

자세한 내용은 `docs/ARCHITECTURE.md` 참조. features/ 클린 아키텍처 (presentation → domain ← data).

## 실행

flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d windows

## 개발

flutter analyze
flutter test
dart run build_runner watch --delete-conflicting-outputs   # 코드 생성 watch
flutter build windows --release                            # release 산출물
```

(코드 펜스는 마크다운 fence로 작성)

### 3) 수동 검증 시나리오 (선택)

execute.py가 자동화하지 않는 부분이라 본 step의 AC는 아니지만, 가능한 경우 다음 시나리오를 실행해본다:

1. `flutter run -d windows` 후
2. 입력바에 "보고서 작성" 입력 → Enter → 리스트 최상단에 추가
3. 체크박스 토글 → 완료 탭에서만 보임 + 취소선
4. 항목 클릭 → 다이얼로그 → 메모 추가 → 저장 → 반영
5. 다이얼로그에서 [삭제] → 즉시 제거
6. 앱 종료 후 재시작 → 데이터 유지

이 시나리오에서 문제 발견 시 `phases/0-mvp/index.json`의 step 6을 `blocked`로 두고 어떤 시나리오가 실패했는지 `blocked_reason`에 기록한다.

### 생성/수정 대상 파일

- `README.md` (확장)
- (필요 시) 이전 step의 사소한 수정 — 단, 시그니처 변경 금지

## Acceptance Criteria

```bash
dart run build_runner build --delete-conflicting-outputs
flutter pub get
flutter analyze
flutter test
flutter build windows --debug
```

다섯 커맨드 모두 성공 + analyze 경고 0건 + 모든 테스트 통과.

## 검증 절차

1. 위 AC 커맨드 실행.
2. 최종 체크리스트:
   - `lib/features/todos/{data,domain,presentation}` 3계층 모두 존재?
   - domain에 외부 패키지 import 0건? (`grep -r "package:flutter\|package:flutter_riverpod\|package:sembast\|package:forui" lib/features/todos/domain/`)
   - 모든 Provider가 `@riverpod` 어노테이션? (`grep -r "Provider<\|StateProvider\|ChangeNotifier" lib/`로 레거시 패턴 0건 확인)
   - `*.g.dart`/`*.freezed.dart`가 git 추적에서 제외 (`.gitignore` 확인)?
   - README에 실행 커맨드가 명시?
3. `phases/0-mvp/index.json`의 step 6 업데이트:
   - 성공 → `"status": "completed"`, `"summary": "MVP 전체 검증 통과: flutter analyze 0경고, 전체 테스트 통과, flutter build windows --debug 성공. README.md 확장(스택/구조/실행/개발 커맨드). 수동 시나리오는 별도 검증 권장."`
   - 빌드/테스트가 끝까지 통과 안 하면 `error` + `error_message`. Visual Studio Build Tools나 Windows SDK 미설치 등 외부 요인이면 `blocked` + `blocked_reason`.

## 금지사항

- **새 기능을 추가하지 마라.** 이유: 본 step은 검증 전용. 빠진 기능은 별도 phase(`1-...`)로.
- **public API 시그니처(UseCase/Repository/Notifier)를 변경하지 마라.** 이유: 검증 단계에서 변경하면 회귀 가능. 사소한 import/lint만 수정.
- **`*.g.dart`/`*.freezed.dart`를 손으로 편집하지 마라.** 이유: build_runner 덮어씀.
- **release 빌드를 강행하지 마라.** 이유: 본 step의 AC는 debug까지만. release는 후속 phase 또는 수동.
- **테스트를 `skip`하거나 expect를 약화시키지 마라.** 이유: AC 우회. 진짜 실패 원인을 고친다.
- **README에 미구현 기능을 적지 마라** (예: "곧 알림 기능 추가" 등). 이유: PRD MVP 제외 항목과 어긋남.
