import 'package:claude_basic_app/features/todos/domain/entities/todo.dart';
import 'package:claude_basic_app/features/todos/presentation/widgets/todo_edit_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../test_helpers/widget_test_harness.dart';

Todo _todo({String id = 't-1', String title = '원본'}) {
  final now = DateTime.fromMillisecondsSinceEpoch(1735603200000);
  return Todo(
    id: id,
    title: title,
    description: null,
    dueDate: null,
    isCompleted: false,
    createdAt: now,
    updatedAt: now,
  );
}

Widget _trigger(BuildContext context, Todo todo) {
  return ElevatedButton(
    onPressed: () => showTodoEditDialog(context: context, todo: todo),
    child: const Text('open'),
  );
}

void main() {
  testWidgets('저장 버튼 클릭 시 update 호출 → 제목이 갱신됨', (tester) async {
    final initial = _todo(id: 't-1', title: '원본');
    final repo = FakeTodoRepository(initial: [initial]);
    addTearDown(repo.dispose);

    await tester.pumpWidget(
      wrapForTest(
        Scaffold(
          body: Builder(builder: (ctx) => _trigger(ctx, initial)),
        ),
        repository: repo,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('todo_edit_title')),
      '수정됨',
    );
    await tester.tap(find.byKey(const Key('todo_edit_save')));
    await tester.pumpAndSettle();

    expect(repo.current.single.title, '수정됨');
  });

  testWidgets('삭제 버튼 클릭 시 delete 호출 → repository 비워짐', (tester) async {
    final initial = _todo(id: 't-1', title: '원본');
    final repo = FakeTodoRepository(initial: [initial]);
    addTearDown(repo.dispose);

    await tester.pumpWidget(
      wrapForTest(
        Scaffold(
          body: Builder(builder: (ctx) => _trigger(ctx, initial)),
        ),
        repository: repo,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('todo_edit_delete')));
    await tester.pumpAndSettle();

    expect(repo.current, isEmpty);
  });
}
