이 프로젝트(Flutter Windows desktop / features 기반 클린 아키텍처 / Riverpod)의 변경 사항을 리뷰하라.

먼저 다음 문서들을 읽어라:
- `/CLAUDE.md`
- `/docs/ARCHITECTURE.md`
- `/docs/ADR.md`
- `/docs/UI_GUIDE.md` (UI 변경이 포함된 경우)

그런 다음 변경된 파일들을 확인하고, 아래 체크리스트로 검증하라:

## 체크리스트

1. **아키텍처 준수**: ARCHITECTURE.md의 `lib/features/{f}/{data,domain,presentation}` 구조를 따르고 있는가?
2. **레이어 의존 방향**: `presentation → domain ← data` 방향을 지키는가? domain 레이어가 Flutter/Riverpod/외부 패키지를 import하지 않는가?
3. **기술 스택 준수**: ADR에 정의된 기술(Riverpod, freezed, go_router 등)을 벗어나지 않았는가?
4. **Riverpod 패턴**: Provider는 `@riverpod` 어노테이션으로 정의되어 있는가? 비동기 상태는 `AsyncValue<T>`로 다루는가?
5. **모델 분리**: data 레이어의 DTO와 domain 레이어의 Entity가 분리되어 있고, mapper를 통해 변환하는가?
6. **테스트 존재**: 새 UseCase/Notifier/Repository에 대한 테스트가 작성되어 있는가?
7. **CRITICAL 규칙**: CLAUDE.md의 CRITICAL 규칙을 위반하지 않았는가?
8. **정적 분석**: `flutter analyze`가 경고 없이 통과하는가?
9. **빌드 가능**: `flutter build windows --debug`가 에러 없이 통과하는가?
10. **UI 가이드 준수**(UI 변경 시): UI_GUIDE.md의 안티패턴(BackdropFilter blur, gradient text, 글로우 등)을 피했는가?

## 출력 형식

| 항목 | 결과 | 비고 |
|------|------|------|
| 아키텍처 준수 | ✅/❌ | {상세} |
| 레이어 의존 방향 | ✅/❌ | {상세} |
| 기술 스택 준수 | ✅/❌ | {상세} |
| Riverpod 패턴 | ✅/❌ | {상세} |
| 모델 분리 (DTO/Entity) | ✅/❌ | {상세} |
| 테스트 존재 | ✅/❌ | {상세} |
| CRITICAL 규칙 | ✅/❌ | {상세} |
| flutter analyze | ✅/❌ | {상세} |
| flutter build windows | ✅/❌ | {상세} |
| UI 가이드 준수 | ✅/❌/N/A | {상세} |

위반 사항이 있으면 수정 방안을 구체적으로 제시하라 (파일 경로, 변경할 코드 시그니처 포함).
