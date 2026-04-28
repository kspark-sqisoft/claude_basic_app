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

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d windows
```

## 개발

```bash
flutter analyze
flutter test
dart run build_runner watch --delete-conflicting-outputs   # 코드 생성 watch
flutter build windows --release                            # release 산출물
```
