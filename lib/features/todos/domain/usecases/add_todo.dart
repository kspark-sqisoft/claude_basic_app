import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/todo.dart';
import '../repositories/todo_repository.dart';

class AddTodoParams {
  const AddTodoParams({
    required this.title,
    this.description,
    this.dueDate,
  });

  final String title;
  final String? description;
  final DateTime? dueDate;
}

// 새 Todo를 만들어 저장한다. id/시간은 외부에서 주입한 생성기로 채워 테스트 가능하게 한다.
class AddTodo implements UseCase<Todo, AddTodoParams> {
  AddTodo(
    this._repo, {
    required String Function() idGenerator,
    required DateTime Function() now,
  }) : _idGenerator = idGenerator,
       _now = now;

  final TodoRepository _repo;
  final String Function() _idGenerator;
  final DateTime Function() _now;

  @override
  Future<Either<Failure, Todo>> call(AddTodoParams params) async {
    final trimmed = params.title.trim();
    if (trimmed.isEmpty) {
      return const Left(Failure.validation('제목은 비울 수 없습니다.'));
    }

    final timestamp = _now();
    final todo = Todo(
      id: _idGenerator(),
      title: trimmed,
      description: params.description,
      dueDate: params.dueDate,
      isCompleted: false,
      createdAt: timestamp,
      updatedAt: timestamp,
    );

    final result = await _repo.add(todo);
    return result.map((_) => todo);
  }
}
