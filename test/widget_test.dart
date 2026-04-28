import 'package:claude_basic_app/app/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('TodoApp boots and renders header', (tester) async {
    // ProviderScope 아래에서 TodoApp이 빌드되고 'Todo' 헤더가 보이는지 확인
    await tester.pumpWidget(const ProviderScope(child: TodoApp()));
    await tester.pump();
    expect(find.text('Todo'), findsOneWidget);
  });
}
