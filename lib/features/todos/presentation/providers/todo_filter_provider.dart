import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'todo_filter_provider.g.dart';

// 상단 탭에서 선택된 보기 모드. presentation 전용 상태이므로 도메인 레이어로 노출하지 않는다.
enum TodoFilter { all, pending, completed }

@riverpod
class TodoFilterNotifier extends _$TodoFilterNotifier {
  @override
  TodoFilter build() => TodoFilter.all;

  void set(TodoFilter filter) => state = filter;
}
