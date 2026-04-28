import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'todo_search_query_provider.g.dart';

// 헤더 검색 입력의 source-of-truth. presentation 전용 상태이므로 도메인 레이어로 노출하지 않는다.
@riverpod
class TodoSearchQueryNotifier extends _$TodoSearchQueryNotifier {
  @override
  String build() => '';

  void set(String query) => state = query;

  void clear() => state = '';
}
