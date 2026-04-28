import 'package:claude_basic_app/core/error/failure.dart';
import 'package:claude_basic_app/features/todos/domain/entities/todo.dart';
import 'package:claude_basic_app/features/todos/domain/repositories/todo_repository.dart';
import 'package:claude_basic_app/features/todos/domain/usecases/update_todo.dart';
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
  late UpdateTodo usecase;
  final now = DateTime(2026, 1, 3);

  Todo sample() => Todo(
    id: 'id-1',
    title: '제목',
    description: null,
    dueDate: null,
    isCompleted: false,
    createdAt: now,
    updatedAt: now,
  );

  setUp(() {
    repo = _MockTodoRepository();
    usecase = UpdateTodo(repo);
  });

  group('UpdateTodo', () {
    test('repository.update를 호출하고 Right(unit)을 그대로 반환한다', () async {
      when(() => repo.update(any())).thenAnswer((_) async => const Right(unit));

      final todo = sample();
      final result = await usecase.call(todo);

      verify(() => repo.update(todo)).called(1);
      expect(result, equals(const Right<Failure, Unit>(unit)));
    });

    test('repository가 실패하면 Left(Failure)를 그대로 반환한다', () async {
      when(() => repo.update(any())).thenAnswer(
        (_) async => const Left(Failure.database('locked')),
      );

      final result = await usecase.call(sample());

      expect(
        result,
        equals(const Left<Failure, Unit>(Failure.database('locked'))),
      );
    });
  });
}
