import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/todo.dart';
import '../providers/todo_list_notifier.dart';
import 'todo_edit_dialog.dart';

// 단일 Todo 행. 좌측 체크박스 + 제목/메타. 행을 탭하면 수정 다이얼로그가 열린다.
class TodoListItem extends ConsumerWidget {
  const TodoListItem({required this.todo, super.key});

  final Todo todo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.colors;
    final dateFormat = DateFormat('yyyy-MM-dd');

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => showTodoEditDialog(context: context, todo: todo),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FCheckbox(
              key: Key('todo_checkbox_${todo.id}'),
              value: todo.isCompleted,
              onChange: (_) async {
                try {
                  await ref
                      .read(todoListProvider.notifier)
                      .toggle(todo);
                } on Failure catch (failure) {
                  if (!context.mounted) return;
                  showFToast(context: context, title: Text(failure.message));
                }
              },
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    todo.title,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: colors.foreground,
                      decoration: todo.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  if (todo.dueDate != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      dateFormat.format(todo.dueDate!),
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.mutedForeground,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
