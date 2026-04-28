import 'package:claude_basic_app/app/app.dart';
import 'package:claude_basic_app/features/todos/data/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers/widget_test_harness.dart';

void main() {
  testWidgets('TodoApp boots and renders header', (tester) async {
    final repo = FakeTodoRepository();
    addTearDown(repo.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todoRepositoryProvider.overrideWith((ref) async => repo),
        ],
        child: const TodoApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Todo'), findsOneWidget);
  });
}
