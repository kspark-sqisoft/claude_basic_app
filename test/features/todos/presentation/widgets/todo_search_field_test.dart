import 'package:claude_basic_app/features/todos/presentation/providers/todo_search_query_provider.dart';
import 'package:claude_basic_app/features/todos/presentation/widgets/todo_search_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../test_helpers/widget_test_harness.dart';

void main() {
  testWidgets('입력 시 todoSearchQueryProvider state가 같은 값으로 갱신', (
    tester,
  ) async {
    late ProviderContainer container;
    await tester.pumpWidget(
      wrapForTest(
        Scaffold(
          body: Consumer(
            builder: (context, ref, _) {
              container = ProviderScope.containerOf(context);
              return const TodoSearchField();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(container.read(todoSearchQueryProvider), '');

    await tester.enterText(find.byKey(const Key('todo_search_field')), '보고');
    await tester.pump();

    expect(container.read(todoSearchQueryProvider), '보고');
  });

  testWidgets('빈 문자열 입력 시 state도 빈 문자열', (tester) async {
    late ProviderContainer container;
    await tester.pumpWidget(
      wrapForTest(
        Scaffold(
          body: Consumer(
            builder: (context, ref, _) {
              container = ProviderScope.containerOf(context);
              return const TodoSearchField();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('todo_search_field')), '검색');
    await tester.pump();
    expect(container.read(todoSearchQueryProvider), '검색');

    await tester.enterText(find.byKey(const Key('todo_search_field')), '');
    await tester.pump();
    expect(container.read(todoSearchQueryProvider), '');
  });
}
