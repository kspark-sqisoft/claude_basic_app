import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/todos/presentation/screens/todo_list_screen.dart';

part 'router.g.dart';

// 단일 라우트 '/'에 자리표시자 TodoListScreen을 노출한다.
@riverpod
GoRouter router(Ref ref) {
  return GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => const TodoListScreen()),
    ],
  );
}
