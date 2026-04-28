import 'package:claude_basic_app/features/todos/presentation/widgets/todo_input_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../test_helpers/widget_test_harness.dart';

void main() {
  testWidgets('빈 문자열 제출 시 add 호출되지 않음', (tester) async {
    final repo = FakeTodoRepository();
    addTearDown(repo.dispose);

    await tester.pumpWidget(
      wrapForTest(
        const Scaffold(body: TodoInputBar()),
        repository: repo,
      ),
    );
    await tester.pumpAndSettle();

    // 컨트롤러 비어있는 상태로 추가 버튼 클릭
    await tester.tap(find.byKey(const Key('todo_input_add_button')));
    await tester.pumpAndSettle();

    expect(repo.current, isEmpty);
  });

  testWidgets('Enter 제출 시 repository에 추가됨', (tester) async {
    final repo = FakeTodoRepository();
    addTearDown(repo.dispose);

    await tester.pumpWidget(
      wrapForTest(
        const Scaffold(body: TodoInputBar()),
        repository: repo,
      ),
    );
    await tester.pumpAndSettle();

    final field = find.byKey(const Key('todo_input_field'));
    await tester.enterText(field, '새 할일');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(repo.current, hasLength(1));
    expect(repo.current.single.title, '새 할일');
  });

  testWidgets('추가 버튼 클릭 시 repository에 추가됨', (tester) async {
    final repo = FakeTodoRepository();
    addTearDown(repo.dispose);

    await tester.pumpWidget(
      wrapForTest(
        const Scaffold(body: TodoInputBar()),
        repository: repo,
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('todo_input_field')), '버튼 추가');
    await tester.tap(find.byKey(const Key('todo_input_add_button')));
    await tester.pumpAndSettle();

    expect(repo.current.single.title, '버튼 추가');
  });
}
