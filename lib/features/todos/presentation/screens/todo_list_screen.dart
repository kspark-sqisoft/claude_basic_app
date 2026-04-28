import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

import '../providers/todo_filter_provider.dart';
import '../providers/todo_list_notifier.dart';
import '../widgets/todo_filter_tabs.dart';
import '../widgets/todo_input_bar.dart';
import '../widgets/todo_list_item.dart';
import '../widgets/todo_search_field.dart';

// 메인 화면. 좌측 정렬 1024px 고정폭 컬럼으로 입력 → 필터 → 목록을 수직 배치한다.
class TodoListScreen extends ConsumerWidget {
  const TodoListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncTodos = ref.watch(todoListProvider);
    final filter = ref.watch(todoFilterProvider);
    final colors = context.theme.colors;

    return FScaffold(
      header: const FHeader(
        title: Text('Todo'),
        suffixes: [TodoSearchField()],
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1024),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const TodoInputBar(),
            const SizedBox(height: 8),
            const TodoFilterTabs(),
            const SizedBox(height: 16),
            Expanded(
              child: asyncTodos.when(
                data: (todos) {
                  if (todos.isEmpty) {
                    return Center(
                      child: Text(
                        _emptyMessage(filter),
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.mutedForeground,
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    itemCount: todos.length,
                    separatorBuilder: (_, _) => const FDivider(),
                    itemBuilder: (_, index) =>
                        TodoListItem(todo: todos[index]),
                  );
                },
                loading: () => const Center(child: SizedBox.shrink()),
                error: (error, _) => Center(
                  child: Text(
                    '$error',
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.destructive,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _emptyMessage(TodoFilter filter) => switch (filter) {
    TodoFilter.all => '아직 등록된 할일이 없습니다.',
    TodoFilter.pending => '미완료 할일이 없습니다.',
    TodoFilter.completed => '완료한 할일이 없습니다.',
  };
}
