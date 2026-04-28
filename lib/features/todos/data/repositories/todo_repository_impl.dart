import 'dart:async';

import 'package:fpdart/fpdart.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/todo.dart';
import '../../domain/repositories/todo_repository.dart';
import '../datasources/todo_local_datasource.dart';
import '../models/todo_model.dart';

// data 레이어 ↔ domain 레이어의 경계. raw 예외를 Failure로 변환한다.
class TodoRepositoryImpl implements TodoRepository {
  TodoRepositoryImpl(this._ds);

  final TodoLocalDataSource _ds;

  @override
  Stream<Either<Failure, List<Todo>>> watchAll() {
    // 데이터 이벤트는 Right로, 스트림 에러는 Left로 변환해 단일 채널로 흘려보낸다.
    return _ds.watchAll().transform(
      StreamTransformer<List<TodoModel>, Either<Failure, List<Todo>>>.fromHandlers(
        handleData: (models, sink) => sink.add(
          Right(models.map((m) => m.toEntity()).toList()),
        ),
        handleError: (error, _, sink) => sink.add(
          Left(Failure.database(error.toString())),
        ),
      ),
    );
  }

  @override
  Future<Either<Failure, Unit>> add(Todo todo) async {
    return _guard(() => _ds.upsert(TodoModel.fromEntity(todo)));
  }

  @override
  Future<Either<Failure, Unit>> update(Todo todo) async {
    // sembast는 동일 키 put이 곧 덮어쓰기이므로 add와 동일 경로.
    return _guard(() => _ds.upsert(TodoModel.fromEntity(todo)));
  }

  @override
  Future<Either<Failure, Unit>> delete(String id) async {
    return _guard(() => _ds.deleteById(id));
  }

  Future<Either<Failure, Unit>> _guard(Future<void> Function() op) async {
    try {
      await op();
      return const Right(unit);
    } on CacheException catch (e) {
      return Left(Failure.database(e.message));
    } catch (e) {
      return Left(Failure.unexpected(e.toString()));
    }
  }
}
