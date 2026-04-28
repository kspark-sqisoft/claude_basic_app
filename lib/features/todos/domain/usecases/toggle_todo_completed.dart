import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/todo.dart';
import '../repositories/todo_repository.dart';

// 입력 Todo의 isCompleted를 반전하고 updatedAt을 갱신한 뒤 저장한다.
class ToggleTodoCompleted implements UseCase<Todo, Todo> {
  ToggleTodoCompleted(
    this._repo, {
    required DateTime Function() now,
  }) : _now = now;

  final TodoRepository _repo;
  final DateTime Function() _now;

  @override
  Future<Either<Failure, Todo>> call(Todo params) async {
    final toggled = params.copyWith(
      isCompleted: !params.isCompleted,
      updatedAt: _now(),
    );
    final result = await _repo.update(toggled);
    return result.map((_) => toggled);
  }
}
