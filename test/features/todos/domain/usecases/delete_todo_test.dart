import 'package:claude_basic_app/core/error/failure.dart';
import 'package:claude_basic_app/features/todos/domain/repositories/todo_repository.dart';
import 'package:claude_basic_app/features/todos/domain/usecases/delete_todo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockTodoRepository extends Mock implements TodoRepository {}

void main() {
  late _MockTodoRepository repo;
  late DeleteTodo usecase;

  setUp(() {
    repo = _MockTodoRepository();
    usecase = DeleteTodo(repo);
  });

  group('DeleteTodo', () {
    test('repository.delete를 호출하고 Right(unit)을 반환한다', () async {
      when(() => repo.delete(any())).thenAnswer((_) async => const Right(unit));

      final result = await usecase.call('id-1');

      verify(() => repo.delete('id-1')).called(1);
      expect(result, equals(const Right<Failure, Unit>(unit)));
    });

    test('repository가 실패하면 Left(Failure)를 그대로 반환한다', () async {
      when(() => repo.delete(any())).thenAnswer(
        (_) async => const Left(Failure.unexpected('not found')),
      );

      final result = await usecase.call('id-x');

      expect(
        result,
        equals(const Left<Failure, Unit>(Failure.unexpected('not found'))),
      );
    });
  });
}
