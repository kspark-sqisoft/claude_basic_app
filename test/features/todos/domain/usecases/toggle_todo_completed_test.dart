import 'package:claude_basic_app/core/error/failure.dart';
import 'package:claude_basic_app/features/todos/domain/entities/todo.dart';
import 'package:claude_basic_app/features/todos/domain/repositories/todo_repository.dart';
import 'package:claude_basic_app/features/todos/domain/usecases/toggle_todo_completed.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockTodoRepository extends Mock implements TodoRepository {}

class _FakeTodo extends Fake implements Todo {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeTodo());
  });

  late _MockTodoRepository repo;
  final created = DateTime(2026, 1, 1);
  final updated = DateTime(2026, 1, 2);
  final newNow = DateTime(2026, 1, 5, 12, 0);
  DateTime nowGen() => newNow;

  Todo sample({bool isCompleted = false}) => Todo(
    id: 'id-1',
    title: '할일',
    description: null,
    dueDate: null,
    isCompleted: isCompleted,
    createdAt: created,
    updatedAt: updated,
  );

  setUp(() {
    repo = _MockTodoRepository();
  });

  ToggleTodoCompleted build() => ToggleTodoCompleted(repo, now: nowGen);

  group('ToggleTodoCompleted', () {
    test('isCompleted가 false면 true로 반전하고 updatedAt이 갱신된다', () async {
      when(() => repo.update(any())).thenAnswer((_) async => const Right(unit));

      final result = await build().call(sample(isCompleted: false));

      final captured = verify(() => repo.update(captureAny())).captured.single as Todo;
      expect(captured.isCompleted, isTrue);
      expect(captured.updatedAt, newNow);
      expect(captured.createdAt, created); // createdAt은 유지

      result.match((_) => fail('Right여야 한다'), (todo) {
        expect(todo, equals(captured));
      });
    });

    test('isCompleted가 true면 false로 반전된다', () async {
      when(() => repo.update(any())).thenAnswer((_) async => const Right(unit));

      await build().call(sample(isCompleted: true));

      final captured = verify(() => repo.update(captureAny())).captured.single as Todo;
      expect(captured.isCompleted, isFalse);
    });

    test('repository가 실패하면 Left(Failure)를 그대로 반환한다', () async {
      when(() => repo.update(any())).thenAnswer(
        (_) async => const Left(Failure.database('locked')),
      );

      final result = await build().call(sample());

      expect(
        result,
        equals(const Left<Failure, Todo>(Failure.database('locked'))),
      );
    });
  });
}
