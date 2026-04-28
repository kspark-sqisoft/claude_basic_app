# 프로젝트: {프로젝트명}

## 기술 스택
- Flutter 3.x (Windows desktop target)
- Dart 3.x (sound null safety)
- 상태 관리: Riverpod (`flutter_riverpod` + `riverpod_generator`)
- 라우팅: `go_router`
- 코드 생성: `freezed`, `json_serializable`, `riverpod_generator` (build_runner)
- 로컬 저장소: {예: `shared_preferences`, `sqflite_common_ffi`, `drift`}
- HTTP: {예: `dio` 또는 `http`}

## 아키텍처 규칙
- CRITICAL: features 기반 클린 아키텍처를 따른다. 모든 기능은 `lib/features/{feature}/{data,domain,presentation}` 3계층으로 분리한다.
- CRITICAL: 의존성 방향은 `presentation → domain ← data`. domain 레이어는 어떤 외부 패키지(Flutter, Riverpod, dio 등)도 import 하지 않는다 (순수 Dart).
- CRITICAL: presentation 레이어는 repository 구현체나 datasource를 직접 참조하지 않는다. 반드시 domain의 UseCase 또는 repository 인터페이스를 통해서만 접근한다.
- CRITICAL: 상태 관리는 Riverpod만 사용한다. `setState`, `ChangeNotifier`, `InheritedWidget` 직접 사용 금지 (위젯 내부 임시 UI 상태 제외).
- CRITICAL: Provider는 반드시 `riverpod_generator`의 `@riverpod` 어노테이션 방식으로 정의한다. 레거시 `Provider(...)` 인스턴스 직접 생성 금지.
- features 간 직접 import 금지. 공유가 필요한 모델/위젯은 `lib/core/` 또는 `lib/shared/`로 승격시킨다.
- 모든 비동기 결과는 `AsyncValue<T>`로 다루고, UI에서는 `when(data:, loading:, error:)`로 분기한다.
- 데이터 모델(DTO)과 도메인 엔티티(Entity)는 분리한다. 변환은 `data/models/` 안의 mapper에서만 수행한다.

## 개발 프로세스
- CRITICAL: 새 기능 구현 시 반드시 테스트를 먼저 작성하고, 테스트가 통과하는 구현을 작성할 것 (TDD). UseCase와 Notifier는 단위 테스트, 위젯은 widget test로 검증한다.
- 코드 생성 파일(`*.g.dart`, `*.freezed.dart`)은 수동 편집 금지. 변경 시 `dart run build_runner build --delete-conflicting-outputs` 로 재생성한다.
- 커밋 메시지는 conventional commits 형식을 따를 것 (feat:, fix:, docs:, refactor:, test:, chore:)
- PR 머지 전 `flutter analyze` 경고 0건, `flutter test` 통과, `flutter build windows` 성공을 확인한다.

## 명령어
flutter pub get                                          # 의존성 설치
flutter run -d windows                                   # Windows 데스크톱 실행
flutter build windows --release                          # Windows release 빌드
flutter analyze                                          # 정적 분석 (lint)
flutter test                                             # 단위/위젯 테스트
dart format .                                            # 포매팅
dart run build_runner build --delete-conflicting-outputs # 코드 생성
dart run build_runner watch --delete-conflicting-outputs # 코드 생성 watch
