import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/todo.dart';
import '../repositories/todo_repository.dart';

// 전체 Todo 목록 스트림. 필터링/정렬은 presentation에서 책임진다.
class WatchTodos implements StreamUseCase<List<Todo>, NoParams> {
  WatchTodos(this._repo);

  final TodoRepository _repo;

  @override
  Stream<Either<Failure, List<Todo>>> call(NoParams params) => _repo.watchAll();
}
