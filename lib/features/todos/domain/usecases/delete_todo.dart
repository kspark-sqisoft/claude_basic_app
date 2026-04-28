import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/todo_repository.dart';

// id 기준으로 Todo를 삭제한다.
class DeleteTodo implements UseCase<Unit, String> {
  DeleteTodo(this._repo);

  final TodoRepository _repo;

  @override
  Future<Either<Failure, Unit>> call(String params) => _repo.delete(params);
}
