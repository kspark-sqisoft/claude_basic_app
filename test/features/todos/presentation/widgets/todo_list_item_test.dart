import 'package:claude_basic_app/features/todos/domain/entities/todo.dart';
import 'package:claude_basic_app/features/todos/presentation/widgets/todo_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../test_helpers/widget_test_harness.dart';

Todo _todo({
  String id = 't-1',
  String title = '샘플',
  bool isCompleted = false,
}) {
  final now = DateTime.fromMillisecondsSinceEpoch(1735603200000);
  return Todo(
    id: id,
    title: title,
    description: null,
    dueDate: null,
    isCompleted: isCompleted,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  testWidgets('체크박스 클릭 시 toggle 호출 → repository 항목이 완료 처리됨', (tester) async {
    final initial = _todo(id: 't-1', isCompleted: false);
    final repo = FakeTodoRepository(initial: [initial]);
    addTearDown(repo.dispose);

    await tester.pumpWidget(
      wrapForTest(
        Scaffold(body: TodoListItem(todo: initial)),
        repository: repo,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('todo_checkbox_t-1')));
    await tester.pumpAndSettle();

    expect(repo.current.single.isCompleted, isTrue);
  });

  testWidgets('완료된 항목은 제목에 lineThrough 적용', (tester) async {
    final completed = _todo(id: 't-2', title: '끝난 일', isCompleted: true);
    final repo = FakeTodoRepository(initial: [completed]);
    addTearDown(repo.dispose);

    await tester.pumpWidget(
      wrapForTest(
        Scaffold(body: TodoListItem(todo: completed)),
        repository: repo,
      ),
    );
    await tester.pumpAndSettle();

    final textWidget = tester.widget<Text>(find.text('끝난 일'));
    expect(textWidget.style?.decoration, TextDecoration.lineThrough);
  });
}
