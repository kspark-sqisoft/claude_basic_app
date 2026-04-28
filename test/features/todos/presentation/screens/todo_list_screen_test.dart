import 'package:claude_basic_app/features/todos/domain/entities/todo.dart';
import 'package:claude_basic_app/features/todos/presentation/screens/todo_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../test_helpers/widget_test_harness.dart';

Todo _todo({
  required String id,
  required String title,
  required bool isCompleted,
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
  testWidgets('미완료 탭 선택 시 완료 항목은 보이지 않음', (tester) async {
    final repo = FakeTodoRepository(
      initial: [
        _todo(id: 'a', title: '일감 A', isCompleted: false),
        _todo(id: 'b', title: '일감 B', isCompleted: true),
      ],
    );
    addTearDown(repo.dispose);

    await tester.pumpWidget(
      wrapForTest(const TodoListScreen(), repository: repo),
    );
    await tester.pumpAndSettle();

    // 초기 전체 탭에서는 두 항목 모두 노출
    expect(find.text('일감 A'), findsOneWidget);
    expect(find.text('일감 B'), findsOneWidget);

    // 미완료 탭으로 전환
    await tester.tap(find.byKey(const Key('todo_filter_pending')));
    await tester.pumpAndSettle();

    expect(find.text('일감 A'), findsOneWidget);
    expect(find.text('일감 B'), findsNothing);
  });

  testWidgets('빈 목록 + 전체 필터 시 안내 메시지 노출', (tester) async {
    final repo = FakeTodoRepository();
    addTearDown(repo.dispose);

    await tester.pumpWidget(
      wrapForTest(const TodoListScreen(), repository: repo),
    );
    await tester.pumpAndSettle();

    expect(find.text('아직 등록된 할일이 없습니다.'), findsOneWidget);
  });

  testWidgets('검색어 입력 시 제목에 포함된 항목만 노출', (tester) async {
    final repo = FakeTodoRepository(
      initial: [
        _todo(id: 'a', title: '보고서 작성', isCompleted: false),
        _todo(id: 'b', title: '장보기', isCompleted: false),
      ],
    );
    addTearDown(repo.dispose);

    await tester.pumpWidget(
      wrapForTest(const TodoListScreen(), repository: repo),
    );
    await tester.pumpAndSettle();

    expect(find.text('보고서 작성'), findsOneWidget);
    expect(find.text('장보기'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('todo_search_field')), '보고');
    await tester.pumpAndSettle();

    expect(find.text('보고서 작성'), findsOneWidget);
    expect(find.text('장보기'), findsNothing);
  });

  testWidgets('미완료 탭 + 검색어가 결합되어 적용', (tester) async {
    final repo = FakeTodoRepository(
      initial: [
        _todo(id: 'a', title: '보고서 작성', isCompleted: false),
        _todo(id: 'b', title: '보고서 제출', isCompleted: true),
        _todo(id: 'c', title: '장보기', isCompleted: false),
      ],
    );
    addTearDown(repo.dispose);

    await tester.pumpWidget(
      wrapForTest(const TodoListScreen(), repository: repo),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('todo_filter_pending')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('todo_search_field')), '보고');
    await tester.pumpAndSettle();

    expect(find.text('보고서 작성'), findsOneWidget);
    expect(find.text('보고서 제출'), findsNothing);
    expect(find.text('장보기'), findsNothing);
  });

  testWidgets('검색어를 비우면 전체(필터 적용분)로 복귀', (tester) async {
    final repo = FakeTodoRepository(
      initial: [
        _todo(id: 'a', title: '보고서 작성', isCompleted: false),
        _todo(id: 'b', title: '장보기', isCompleted: false),
      ],
    );
    addTearDown(repo.dispose);

    await tester.pumpWidget(
      wrapForTest(const TodoListScreen(), repository: repo),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('todo_search_field')), '보고');
    await tester.pumpAndSettle();
    expect(find.text('장보기'), findsNothing);

    await tester.enterText(find.byKey(const Key('todo_search_field')), '');
    await tester.pumpAndSettle();

    expect(find.text('보고서 작성'), findsOneWidget);
    expect(find.text('장보기'), findsOneWidget);
  });
}
