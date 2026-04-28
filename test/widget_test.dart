import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('bootstrap placeholder renders', (tester) async {
    // 부트스트랩 골격이 ProviderScope 아래에서 정상적으로 빌드되는지 확인
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Center(child: Text('claude_basic_app — bootstrap')),
          ),
        ),
      ),
    );

    expect(find.text('claude_basic_app — bootstrap'), findsOneWidget);
  });
}
