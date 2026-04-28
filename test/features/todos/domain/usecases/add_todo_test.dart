import 'package:claude_basic_app/core/error/failure.dart';
import 'package:claude_basic_app/features/todos/domain/entities/todo.dart';
import 'package:claude_basic_app/features/todos/domain/repositories/todo_repository.dart';
import 'package:claude_basic_app/features/todos/domain/usecases/add_todo.dart';
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
  final fixedNow = DateTime(2026, 1, 2, 10, 30);
  String idGen() => 'fixed-id';
  DateTime nowGen() => fixedNow;

  setUp(() {
    repo = _MockTodoRepository();
  });

  AddTodo build() => AddTodo(repo, idGenerator: idGen, now: nowGen);

  group('AddTodo', () {
    test('정상 입력이면 새 Todo를 만들어 repository.add를 호출하고 Right(todo)를 반환한다', () async {
      when(() => repo.add(any())).thenAnswer((_) async => const Right(unit));

      final result = await build().call(
        const AddTodoParams(title: '보고서 작성', description: '주간 보고'),
      );

      final captured = verify(() => repo.add(captureAny())).captured.single as Todo;
      expect(captured.id, 'fixed-id');
      expect(captured.title, '보고서 작성');
      expect(captured.description, '주간 보고');
      expect(captured.isCompleted, isFalse);
      expect(captured.createdAt, fixedNow);
      expect(captured.updatedAt, fixedNow);

      expect(result.isRight(), isTrue);
      result.match((_) => fail('Right여야 한다'), (todo) {
        expect(todo, equals(captured));
      });
    });

    test('title이 공백만 있으면 ValidationFailure를 반환하고 repository를 호출하지 않는다', () async {
      final result = await build().call(const AddTodoParams(title: '   '));

      expect(
        result,
        equals(const Left<Failure, Todo>(Failure.validation('제목은 비울 수 없습니다.'))),
      );
      verifyNever(() => repo.add(any()));
    });

    test('title이 빈 문자열이면 ValidationFailure를 반환한다', () async {
      final result = await build().call(const AddTodoParams(title: ''));
      expect(result.isLeft(), isTrue);
      verifyNever(() => repo.add(any()));
    });

    test('title 앞뒤 공백은 trim한 뒤 저장한다', () async {
      when(() => repo.add(any())).thenAnswer((_) async => const Right(unit));

      await build().call(const AddTodoParams(title: '  앞뒤공백  '));

      final captured = verify(() => repo.add(captureAny())).captured.single as Todo;
      expect(captured.title, '앞뒤공백');
    });

    test('repository가 실패하면 Left(Failure)를 그대로 반환한다', () async {
      when(() => repo.add(any())).thenAnswer(
        (_) async => const Left(Failure.database('disk error')),
      );

      final result = await build().call(const AddTodoParams(title: '정상 제목'));

      expect(
        result,
        equals(const Left<Failure, Todo>(Failure.database('disk error'))),
      );
    });
  });
}
