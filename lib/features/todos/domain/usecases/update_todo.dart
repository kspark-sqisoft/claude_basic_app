import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/todo.dart';
import '../repositories/todo_repository.dart';

// 기존 Todo의 변경 사항을 그대로 저장한다. updatedAt은 호출자가 책임진다.
class UpdateTodo implements UseCase<Unit, Todo> {
  UpdateTodo(this._repo);

  final TodoRepository _repo;

  @override
  Future<Either<Failure, Unit>> call(Todo params) => _repo.update(params);
}
