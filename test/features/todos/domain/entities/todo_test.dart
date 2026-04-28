import 'package:claude_basic_app/features/todos/domain/entities/todo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Todo entity', () {
    final now = DateTime(2026, 1, 1, 9, 0);

    Todo baseTodo() => Todo(
      id: 'id-1',
      title: '할일',
      description: null,
      dueDate: null,
      isCompleted: false,
      createdAt: now,
      updatedAt: now,
    );

    test('동일 필드를 가진 Todo는 동등하다', () {
      final a = baseTodo();
      final b = baseTodo();
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('copyWith로 isCompleted를 토글할 수 있다', () {
      final original = baseTodo();
      final toggled = original.copyWith(isCompleted: true);
      expect(toggled.isCompleted, isTrue);
      expect(original.isCompleted, isFalse); // 불변성
      expect(toggled.id, equals(original.id));
    });

    test('서로 다른 id를 가진 Todo는 동등하지 않다', () {
      final a = baseTodo();
      final b = baseTodo().copyWith(id: 'id-2');
      expect(a, isNot(equals(b)));
    });
  });
}
