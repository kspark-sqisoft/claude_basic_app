import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../entities/todo.dart';

// 도메인이 정의하는 Todo 영속성 인터페이스. 구현체는 data 레이어가 제공한다.
abstract class TodoRepository {
  // 전체 Todo 목록 변경을 스트림으로 방출한다.
  Stream<Either<Failure, List<Todo>>> watchAll();

  Future<Either<Failure, Unit>> add(Todo todo);

  Future<Either<Failure, Unit>> update(Todo todo);

  Future<Either<Failure, Unit>> delete(String id);
}
