# Architecture Decision Records

## 철학
타입 안전성과 테스트 가능성을 최우선으로 한다. 외부 의존성은 추상화 뒤에 두고, domain 레이어는 어떤 프레임워크에도 의존하지 않는다. 데스크톱 사용자 경험(빠른 콜드 스타트, 키보드 친화, 정보 밀도 높은 레이아웃)을 모바일 패턴보다 우선한다. 로컬 우선(Local-first) — MVP는 외부 네트워크 호출 0건.

---

### ADR-001: Flutter 채택 (Windows desktop target)
**결정**: Flutter 3.x를 사용해 Windows 데스크톱 앱을 빌드한다.
**이유**: 단일 코드베이스로 향후 macOS/Linux 확장 가능, Dart의 강력한 타입 시스템, 풍부한 위젯 생태계, 빠른 hot reload 개발 경험.
**트레이드오프**: 네이티브 Win32 API 직접 접근은 FFI 또는 platform channel 필요. 번들 크기가 native 대비 크고(수십 MB), 일부 Windows 전용 시스템 통합(레지스트리, 작업 스케줄러)은 별도 작업 필요.

### ADR-002: Features 기반 클린 아키텍처
**결정**: `lib/features/{feature}/{data,domain,presentation}` 3계층 구조를 채택한다. domain은 순수 Dart로 유지하고, 의존성 방향은 `presentation → domain ← data`로 강제한다.
**이유**: 기능 단위 응집도가 높아 신규 개발/삭제가 쉽고, domain이 프레임워크에 의존하지 않아 테스트가 빠르고 안정적. 신규 팀원도 feature 디렉토리만 보면 전체 구조를 파악 가능.
**트레이드오프**: 작은 기능 하나 추가에도 entity/repository/usecase/notifier가 필요해 보일러플레이트가 늘어난다. 초기 작업량 증가.

### ADR-003: Riverpod (코드 생성 방식) 상태 관리
**결정**: `flutter_riverpod` + `riverpod_generator`(`@riverpod` 어노테이션) 조합을 사용한다. 모든 비동기 상태는 `AsyncNotifier`와 `AsyncValue<T>`로 표현한다.
**이유**: Provider 간 의존을 컴파일 타임에 검증, BuildContext 없이 테스트 가능, AutoDispose 기본화로 메모리 누수 방지. 코드 생성으로 타입 안전성 + 보일러플레이트 감소.
**트레이드오프**: build_runner 실행 단계 필요. 학습 곡선 존재(특히 family, AsyncNotifier 패턴). `provider`/`bloc` 대비 Flutter 표준이 아님.

### ADR-004: freezed + json_serializable로 모델 정의
**결정**: 엔티티/DTO/상태 모두 `freezed`로 정의한다. JSON 직렬화는 `json_serializable`을 함께 사용한다.
**이유**: 불변성, 값 동등성, copyWith, sealed union을 한 번에 해결. UseCase 결과를 sealed class로 표현해 패턴 매칭으로 안전하게 분기 가능.
**트레이드오프**: 코드 생성 의존, 빌드 시간 증가, 생성 파일이 git diff를 시끄럽게 한다.

### ADR-005: 라우팅에 go_router 사용
**결정**: `go_router`로 선언적 라우트를 정의한다. 라우트 가드는 `redirect` 콜백에서 Riverpod Provider를 읽어 처리한다.
**이유**: Navigator 2.0의 복잡성을 추상화, URL 패턴 기반의 명확한 라우트 정의, Riverpod과 자연스러운 통합.
**트레이드오프**: Windows 데스크톱은 URL 기반 라우팅의 이점이 적어 일부 기능은 과해 보일 수 있음.

### ADR-006: 로컬 DB로 sembast 채택
**결정**: 로컬 영속 저장소로 `sembast`(NoSQL/JSON 기반, 단일 파일) + `sembast_io` 팩토리를 사용한다. Database 파일은 `getApplicationDocumentsDirectory()`(`%APPDATA%\com.example\claude_basic_app\todos.db`)에 위치.
**이유**: 본 앱은 단일 사용자/단일 PC 기준의 가벼운 할일 관리 도구라 관계형 스키마·마이그레이션이 과하다. sembast는 의존성이 가볍고, 트랜잭션·스트림(`onSnapshots`)을 기본 제공해 Riverpod의 `AsyncNotifier`/스트림 구독 패턴과 자연스럽게 맞물린다. 테스트 시 `databaseFactoryMemory`로 in-memory DB를 즉시 띄워 repository 단위 테스트가 빠르다.
**트레이드오프**: 관계형 쿼리/조인 불가. 데이터 양이 수만 건을 넘어가면 인덱스/필터 성능이 떨어질 수 있어 그 시점에 drift(SQLite) 등으로 이주 필요.

### ADR-007: UI 라이브러리로 forui 채택
**결정**: UI 컴포넌트 라이브러리로 `forui ^0.21.3`(zinc 팔레트)을 도입한다. `MaterialApp.router`의 `builder`에서 `FTheme(FToaster(FTooltipGroup(child)))`로 래핑하고, 시스템 brightness에 따라 `FThemes.zinc.light.desktop` / `.dark.desktop`을 선택한다. 다이얼로그는 `showAdaptiveDialog` + `FDialog` 조합을 사용한다.
**이유**: shadcn/ui 영감의 미니멀 톤이 Material의 모바일 톤보다 데스크톱 워크스테이션 도구 컨셉에 부합한다(정보 밀도, 무채색 + 단일 포인트). forui는 데스크톱·터치 양쪽 변형(`.desktop`/`.touch`)을 제공하고, Material 위젯과 공존 가능해 점진 도입이 안전하다.
**트레이드오프**: forui는 0.x 메이저 전 단계라 minor 업데이트에서 API 변경 위험. 일부 진입점(`MaterialApp.router`, `showAdaptiveDialog`)은 Material을 그대로 써야 해 두 시스템이 공존한다. 팀 학습 곡선 일부 증가.

### ADR-008: 검색 처리 위치는 presentation 클라이언트 필터링
**결정**: 할일 검색은 **presentation 레이어의 `TodoListNotifier`**에서 메모리 상 클라이언트 필터링으로 처리한다. `todoSearchQueryNotifierProvider`(@riverpod, `String` state)를 추가하고, 기존 `todoFilterNotifierProvider`와 함께 watch한 뒤 `title.toLowerCase().contains(query.trim().toLowerCase())` 조건으로 결합 필터링한다. data 레이어와 sembast Finder는 변경하지 않는다.
**이유**: 본 MVP의 데이터 양은 단일 사용자/단일 PC 기준 수십~수백 건 수준이라 메모리 필터링이 충분히 빠르고, repository 인터페이스/UseCase 시그니처를 건드리지 않아 변경 범위가 presentation에 한정된다. 검색은 UI 상태(타이핑 중 즉시 반응)에 가까워 stream 재구독보다 클라이언트 필터가 자연스럽다.
**트레이드오프**: 데이터가 수천 건 이상으로 늘면 메모리 비용/응답성이 떨어진다. 그 시점에는 `WatchTodos`에 `query` 파라미터를 추가하고 sembast `Finder(filter: Filter.matches('title', regex))` 로 푸시다운하는 별도 ADR로 이주한다.
