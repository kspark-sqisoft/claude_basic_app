# UI 디자인 가이드 (Flutter Windows Desktop · forui)

본 프로젝트는 **forui** (^0.21.3, zinc 팔레트) 를 메인 UI 라이브러리로 사용한다. 색·타이포·간격은 모두 `FThemeData` 토큰을 통해 접근하고, 위젯은 `F*` 컴포넌트를 우선 사용한다.

## 디자인 원칙
1. **데스크톱 도구처럼 보여야 한다.** 모바일 앱을 큰 창에 띄운 느낌이 아니라, 매일 쓰는 워크스테이션 도구. forui의 미니멀 톤을 그대로 살린다.
2. **키보드 우선.** 자주 쓰는 액션(추가/저장/삭제)은 단축키 + 명확한 포커스 링(`FTheme.colorScheme.ring`).
3. **정보 밀도를 두려워하지 마라.** 데스크톱 화면은 넓다. 카드 패딩을 과하게 키우지 않는다.
4. **테마 토큰만 쓴다.** 위젯 안에서 색·폰트 크기 하드코딩 금지. 변경은 `lib/app/theme.dart`에서 한 번만.

## AI 슬롭 안티패턴 — 하지 마라
| 금지 사항 | 이유 |
|-----------|------|
| `BackdropFilter` blur (glass morphism) | AI 템플릿의 가장 흔한 징후 |
| `ShaderMask` 그라데이션 텍스트 | AI 디자인의 1번 특징 |
| "Powered by AI" 배지 | 기능이 아니라 장식. 사용자에게 가치 없음 |
| `BoxShadow` 글로우 애니메이션 | 네온 글로우 = AI 슬롭 |
| 보라/인디고 브랜드 색상 | "AI = 보라색" 클리셰 |
| 모든 카드에 `BorderRadius.circular(24)` | 균일하게 둥근 모서리는 템플릿 느낌 |
| 배경 gradient orb (blur 처리된 큰 원형 장식) | 모든 AI 랜딩에 있는 장식 |
| 화면 중앙에 큰 일러스트 + 한 줄 카피 | 모바일 온보딩 패턴. 데스크톱 도구에 부적합 |

## forui 도입 방식
- `MaterialApp.router`의 `builder`에서 `FTheme(FToaster(FTooltipGroup(child)))`로 래핑.
- 시스템 모드 추적: `MediaQuery.platformBrightnessOf(context)` 으로 분기 후 `FThemes.zinc.light.desktop` / `FThemes.zinc.dark.desktop` 선택.
- forui와 Material 위젯은 공존 가능하다(공식 문서 명시). 단, 진입점 primitive(`MaterialApp.router`, `showAdaptiveDialog`) 외에는 가능한 모두 `F*` 위젯을 우선 사용한다.

## 색상 (FTheme colorScheme 토큰)
위젯에서는 `final colors = context.theme.colorScheme;` 으로 접근.

| 용도 | 토큰 |
|------|------|
| 페이지 배경 | `colors.background` |
| 본문 텍스트 | `colors.foreground` |
| 카드/패널 배경 | `colors.card` |
| 카드 위 텍스트 | `colors.cardForeground` |
| 보조/뮤트 텍스트 | `colors.mutedForeground` |
| 보더/디바이더 | `colors.border` |
| 포커스 링 | `colors.ring` |
| 주요 액션 (Primary 버튼) | `colors.primary` / `colors.primaryForeground` |
| 위험/삭제 액션 | `colors.destructive` / `colors.destructiveForeground` |
| 팝오버/다이얼로그 배경 | `colors.popover` / `colors.popoverForeground` |

> **참고:** forui의 zinc 팔레트는 라이트/다크 모두 무채색 기반. 시맨틱(성공/경고)이 추가로 필요하면 `colors.primary`(브랜드)와 `colors.destructive`(에러)만 사용하고, 성공/경고는 텍스트 라벨로 표현하거나 별도 토큰 정의는 후속 ADR에서 결정한다.

## 컴포넌트 매핑 (Material → forui)
| 자리 | forui 위젯 | 비고 |
|------|------------|------|
| 페이지 컨테이너 | `FScaffold` + `FHeader` | Material `Scaffold`/`AppBar` 대체 |
| 카드 | `FCard` | 라벨/제목/콘텐츠 슬롯 제공 |
| 리스트 항목 | `FTile` | leading/title/subtitle/trailing 구조 |
| 기본 버튼 | `FButton` (`primary`/`outline`/`ghost`/`destructive`) | Material `FilledButton`/`TextButton` 대체 |
| 입력 필드 | `FTextField` | `decoration` 대신 forui 옵션 |
| 체크박스 | `FCheckbox` | |
| 스위치 | `FSwitch` | |
| 라디오 | `FRadio` | |
| 셀렉트 | `FSelect` | |
| 탭 | `FTabs` | controller 기반 |
| 다이얼로그 | `showAdaptiveDialog` + `FDialog` | actions 슬롯에 `FButton.outline` + `FButton.primary` |
| 팝오버/우클릭 메뉴 | `FPopover` | |
| 토스트 | `FToaster` (앱 진입점에서 등록) | 호출은 `showFToast` |
| 캘린더/날짜 | `FCalendar` / `FDatePicker` | 마감일 입력에 사용 |

## 컴포넌트 예시
### 카드
```dart
FCard(
  title: const Text('할일'),
  subtitle: const Text('오늘 처리'),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // 본문…
    ],
  ),
)
```

### 버튼
```dart
// Primary
FButton(
  style: FButtonStyle.primary,
  onPress: () {},
  label: const Text('추가'),
)

// Outline (다이얼로그 보조 액션)
FButton(
  style: FButtonStyle.outline,
  onPress: () => Navigator.pop(context),
  label: const Text('취소'),
)

// Destructive
FButton(
  style: FButtonStyle.destructive,
  onPress: onDelete,
  label: const Text('삭제'),
)
```

### 입력 필드
```dart
FTextField(
  controller: controller,
  hint: '새 할일을 입력하고 Enter…',
  onSubmit: (_) => submit(),
)
```

### 다이얼로그 (수정/삭제)
```dart
showAdaptiveDialog<void>(
  context: context,
  builder: (ctx) => FDialog(
    title: const Text('할일 수정'),
    body: TodoEditForm(todo: todo),
    actions: [
      FButton(
        style: FButtonStyle.destructive,
        onPress: () => onDelete(ctx),
        label: const Text('삭제'),
      ),
      FButton(
        style: FButtonStyle.primary,
        onPress: () => onSave(ctx),
        label: const Text('저장'),
      ),
    ],
  ),
);
```

### 탭 (필터)
```dart
FTabs(
  controller: tabController,
  tabs: const [
    FTabEntry(label: Text('전체')),
    FTabEntry(label: Text('미완료')),
    FTabEntry(label: Text('완료')),
  ],
)
```

> 정확한 prop 이름과 시그니처는 `pub.dev/documentation/forui/0.21.3/` 레퍼런스를 따른다. 본 가이드는 패턴 예시이며 minor 업데이트 시 동기화한다.

## 레이아웃
- **최대 콘텐츠 너비**: 1024px (`ConstrainedBox(maxWidth: 1024)`).
- **정렬**: 좌측 정렬 기본. 데스크톱 화면 중앙 정렬 금지(랜딩 페이지처럼 보임). 1024 너비 컬럼 자체를 페이지 좌측 또는 좌우 패딩 안에서 렌더.
- **간격 단위**: 4의 배수 (`SizedBox(height: 4/8/12/16/24/32)`).
- **사이드바 + 메인 영역 2단 구조**가 필요해지면 `Row` + `Expanded`. 현재 MVP는 단일 컬럼.
- **최소 창 크기**: `windows/runner/main.cpp`에서 1024×640 지정.

## 타이포그래피
forui의 `FTypography`를 통해 접근하거나, 단순한 경우 `Text(..., style: TextStyle(...))`도 허용한다. 색은 항상 colorScheme 토큰 사용.

| 용도 | 스타일 (참고) |
|------|--------------|
| 페이지 제목 (FHeader) | `fontSize: 24, fontWeight: FontWeight.w600` |
| 섹션 제목 | `fontSize: 16, fontWeight: FontWeight.w600` |
| 본문 | `fontSize: 14, height: 1.5` |
| 카드 라벨 | `fontSize: 12, color: colors.mutedForeground` |
| 캡션/메타 | `fontSize: 12, color: colors.mutedForeground` |

## 애니메이션
- 허용: `AnimatedSwitcher`(150~200ms fade), `AnimatedContainer`(200ms), `Hero`.
- 금지: `BoxShadow` 펄스, 무한 회전, 그라데이션 흐름, 자동 재생 캐러셀.
- 곡선 기본: `Curves.easeOut` 또는 `Curves.easeInOut`.

## 아이콘
- `Icons` (Material) 또는 forui가 권장하는 [`forui_assets`](https://pub.dev/packages/forui_assets) (Lucide 아이콘 셋, shadcn과 동일).
- `flutter_svg`로 SVG 로드 시 `strokeWidth` 1.5 권장.
- 아이콘 컨테이너(둥근 배경 박스)로 감싸지 않는다.
- 색상은 텍스트와 동일 톤 (`colors.foreground` 또는 `colors.mutedForeground`).

## 데스크톱 특화
- **우클릭 컨텍스트 메뉴**: forui `FPopover` 또는 Material `MenuAnchor` + `MenuItemButton`.
- **키보드 단축키**: `CallbackShortcuts` 또는 `Shortcuts` + `Actions`. MVP 권장 단축키:
  - `Ctrl+N` → 인라인 입력바 포커스
  - `Enter` → 입력바에서 저장
  - `Esc` → 다이얼로그 닫기
- **창 크기/위치 기억**: 후속 작업에서 `window_manager` 검토.
- **시스템 트레이/다중 창**: 별도 ADR로 결정.
