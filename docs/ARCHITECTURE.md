# 아키텍처

## 디렉토리 구조
```
lib/
├── main.dart                      # 진입점. ProviderScope로 앱을 감싼다.
├── app/                           # 앱 전역 설정
│   ├── app.dart                   # MaterialApp.router 루트 위젯
│   ├── router.dart                # go_router 라우트 정의
│   └── theme.dart                 # ThemeData (라이트/다크)
├── core/                          # 모든 feature가 공유하는 기반 코드
│   ├── constants/                 # 앱 전역 상수
│   ├── error/                     # Failure, Exception 정의
│   ├── network/                   # Dio 클라이언트, 인터셉터
│   ├── usecase/                   # UseCase 베이스 클래스
│   └── utils/                     # 순수 유틸 함수
├── features/                      # 기능 모듈 (1 feature = 1 디렉토리)
│   └── {feature_name}/
│       ├── data/                  # 외부 세계와의 어댑터
│       │   ├── datasources/       # API/DB/파일 호출 (remote, local)
│       │   ├── models/            # DTO + fromJson/toEntity 매퍼 (freezed)
│       │   └── repositories/      # domain의 repository 인터페이스 구현
│       ├── domain/                # 순수 비즈니스 로직 (Flutter import 금지)
│       │   ├── entities/          # 도메인 엔티티 (freezed, 불변)
│       │   ├── repositories/      # repository 추상 인터페이스
│       │   └── usecases/          # 단일 책임 UseCase
│       └── presentation/          # UI + 상태
│           ├── providers/         # Riverpod Notifier/Provider (@riverpod)
│           ├── screens/           # 화면(Page) 단위 위젯
│           └── widgets/           # 해당 feature 전용 위젯
└── shared/                        # 여러 feature가 공유하는 UI 자산
    ├── widgets/                   # 공통 버튼/카드/다이얼로그
    └── extensions/                # BuildContext, String 확장
test/
├── core/
└── features/
    └── {feature_name}/
        ├── data/                  # repository 구현 테스트 (datasource는 mock)
        ├── domain/                # UseCase 단위 테스트
        └── presentation/          # Notifier + 위젯 테스트
windows/                           # Flutter가 생성한 Windows 빌드 설정
```

## 패턴
- **클린 아키텍처 3계층**: presentation → domain ← data. domain은 순수 Dart, 외부 의존성 0.
- **UseCase 단위 책임**: 하나의 동작(예: `LoginUser`, `FetchTodoList`)을 하나의 UseCase 클래스로. presentation은 UseCase만 호출한다.
- **Repository 패턴**: data 레이어가 domain의 추상 repository를 구현한다. 외부 변경(API, DB 교체)이 domain/presentation에 전파되지 않는다.
- **Riverpod 코드 생성**: `@riverpod` 어노테이션 + `riverpod_generator`. AsyncNotifier로 비동기 상태를 다룬다.
- **Either / Result 타입**: UseCase는 `Future<Either<Failure, T>>`(또는 `Result<T>`) 반환으로 에러를 명시적으로 표현한다. presentation은 `AsyncValue.guard`로 감싼다.
- **불변 모델**: 모든 엔티티/DTO/상태는 `freezed`로 정의 (값 동등성, copyWith, sealed union).

## 데이터 흐름
```
User 입력 (Widget)
  ↓
ConsumerWidget → ref.read(notifierProvider.notifier).메서드()
  ↓
Notifier (presentation/providers)
  ↓ ref.read(useCaseProvider)
UseCase (domain/usecases)
  ↓ repository 인터페이스 호출
RepositoryImpl (data/repositories)
  ↓
DataSource (data/datasources)
  ↓
외부 (HTTP API / SQLite / 파일시스템)
  ↑
DTO (Model) → toEntity() → Entity
  ↑
UseCase가 Either<Failure, Entity> 반환
  ↑
Notifier 상태 업데이트 (AsyncValue<Entity>)
  ↑
ref.watch로 구독 중인 Widget 재빌드 (when으로 분기)
```

## 상태 관리
- 모든 상태는 Riverpod Provider로 노출한다.
- 동기 단순 상태: `@riverpod` 함수형 Provider 또는 `Notifier`.
- 비동기 상태: `AsyncNotifier` + `AsyncValue<T>`. UI는 `state.when(data:, loading:, error:)`로 분기.
- 위젯 내부의 임시 UI 상태(텍스트 필드 컨트롤러, 애니메이션)는 `StatefulWidget` 사용 가능.
- Provider 간 의존은 `ref.watch` (반응적) 또는 `ref.read` (1회성)로 명시한다.
- 화면 종료 시 정리할 리소스는 `ref.onDispose`에 등록한다.

## 에러 처리
- 외부 호출 실패는 datasource에서 `Exception` throw.
- repository가 이를 catch해 `Failure` 객체로 변환하고 `Left(failure)` 반환.
- presentation은 `AsyncValue.guard`로 감싸 자동으로 error 상태로 전환되도록 한다.
- 사용자 노출 메시지는 `core/error/Failure`의 message 필드에서 직접 가져오고, 위젯에서 i18n 가공한다.

## 라우팅
- `go_router`로 선언적 라우팅 정의 (`lib/app/router.dart`).
- 라우트 가드(인증 등)는 `redirect` 콜백에서 Riverpod Provider를 읽어 처리한다.
- Windows 데스크톱 특성상 deep link보다 화면 전환 + 다이얼로그/패널 위주.
