import 'package:claude_basic_app/core/error/failure.dart';
import 'package:claude_basic_app/core/usecase/usecase.dart';
import 'package:claude_basic_app/features/todos/domain/entities/todo.dart';
import 'package:claude_basic_app/features/todos/domain/repositories/todo_repository.dart';
import 'package:claude_basic_app/features/todos/domain/usecases/watch_todos.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockTodoRepository extends Mock implements TodoRepository {}

void main() {
  late _MockTodoRepository repo;
  late WatchTodos usecase;

  setUp(() {
    repo = _MockTodoRepository();
    usecase = WatchTodos(repo);
  });

  group('WatchTodos', () {
    test('repository.watchAll() 스트림을 그대로 패스스루한다', () async {
      final t = Todo(
        id: 'a',
        title: 'A',
        description: null,
        dueDate: null,
        isCompleted: false,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      final source = Stream<Either<Failure, List<Todo>>>.fromIterable([
        Right([t]),
        const Left(Failure.database('err')),
      ]);
      when(() => repo.watchAll()).thenAnswer((_) => source);

      final emitted = await usecase.call(const NoParams()).toList();

      expect(emitted, hasLength(2));
      // Right 분기는 리스트 내부의 Todo가 동일 instance인지 검증.
      emitted.first.match(
        (_) => fail('첫 이벤트는 Right여야 한다'),
        (list) => expect(list, equals([t])),
      );
      expect(emitted[1], equals(const Left<Failure, List<Todo>>(Failure.database('err'))));
      verify(() => repo.watchAll()).called(1);
    });
  });
}
