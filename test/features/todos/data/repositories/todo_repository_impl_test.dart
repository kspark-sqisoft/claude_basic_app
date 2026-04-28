import 'package:claude_basic_app/core/error/exceptions.dart';
import 'package:claude_basic_app/core/error/failure.dart';
import 'package:claude_basic_app/features/todos/data/datasources/todo_local_datasource.dart';
import 'package:claude_basic_app/features/todos/data/models/todo_model.dart';
import 'package:claude_basic_app/features/todos/data/repositories/todo_repository_impl.dart';
import 'package:claude_basic_app/features/todos/domain/entities/todo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockDataSource extends Mock implements TodoLocalDataSource {}

class _FakeTodoModel extends Fake implements TodoModel {}

Todo _entity({String id = 't-1', bool isCompleted = false}) {
  final now = DateTime.fromMillisecondsSinceEpoch(1735603200000);
  return Todo(
    id: id,
    title: '샘플',
    description: null,
    dueDate: null,
    isCompleted: isCompleted,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeTodoModel());
  });

  late _MockDataSource ds;
  late TodoRepositoryImpl repo;

  setUp(() {
    ds = _MockDataSource();
    repo = TodoRepositoryImpl(ds);
  });

  group('add', () {
    test('정상 시 Right(unit)', () async {
      when(() => ds.upsert(any())).thenAnswer((_) async {});

      final result = await repo.add(_entity());

      expect(result, const Right<Failure, Unit>(unit));
      verify(() => ds.upsert(any())).called(1);
    });

    test('CacheException → Left(DatabaseFailure)', () async {
      when(() => ds.upsert(any())).thenThrow(const CacheException('disk full'));

      final result = await repo.add(_entity());

      expect(
        result,
        const Left<Failure, Unit>(Failure.database('disk full')),
      );
    });

    test('알 수 없는 예외 → Left(UnexpectedFailure)', () async {
      when(() => ds.upsert(any())).thenThrow(StateError('boom'));

      final result = await repo.add(_entity());

      expect(result.isLeft(), isTrue);
      result.match(
        (failure) => expect(failure, isA<UnexpectedFailure>()),
        (_) => fail('Right가 아니어야 함'),
      );
    });
  });

  group('update', () {
    test('정상 시 Right(unit) — upsert 경로 사용', () async {
      when(() => ds.upsert(any())).thenAnswer((_) async {});

      final result = await repo.update(_entity(isCompleted: true));

      expect(result, const Right<Failure, Unit>(unit));
      verify(() => ds.upsert(any())).called(1);
    });
  });

  group('delete', () {
    test('정상 시 Right(unit)', () async {
      when(() => ds.deleteById(any())).thenAnswer((_) async {});

      final result = await repo.delete('t-1');

      expect(result, const Right<Failure, Unit>(unit));
      verify(() => ds.deleteById('t-1')).called(1);
    });

    test('CacheException → Left(DatabaseFailure)', () async {
      when(() => ds.deleteById(any()))
          .thenThrow(const CacheException('not found'));

      final result = await repo.delete('t-1');

      expect(
        result,
        const Left<Failure, Unit>(Failure.database('not found')),
      );
    });
  });

  group('watchAll', () {
    test('datasource models를 entity로 매핑해 Right로 방출', () async {
      final models = [
        TodoModel(
          id: 'a',
          title: 'A',
          description: null,
          dueDateMs: null,
          isCompleted: false,
          createdAtMs: 100,
          updatedAtMs: 100,
        ),
      ];
      when(() => ds.watchAll()).thenAnswer((_) => Stream.value(models));

      final emission = await repo.watchAll().first;

      expect(emission.isRight(), isTrue);
      emission.match(
        (_) => fail('Left가 아니어야 함'),
        (todos) {
          expect(todos, hasLength(1));
          expect(todos.first.id, 'a');
        },
      );
    });

    test('스트림 에러 → Left(DatabaseFailure)', () async {
      when(() => ds.watchAll()).thenAnswer(
        (_) => Stream<List<TodoModel>>.error(
          const CacheException('stream broken'),
        ),
      );

      final emission = await repo.watchAll().first;

      expect(emission.isLeft(), isTrue);
      emission.match(
        (failure) => expect(failure, isA<DatabaseFailure>()),
        (_) => fail('Right가 아니어야 함'),
      );
    });
  });
}
