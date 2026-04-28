import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/usecase/usecase.dart';
import '../../data/providers.dart';
import '../../domain/entities/todo.dart';
import '../../domain/usecases/add_todo.dart';
import '../../domain/usecases/delete_todo.dart';
import '../../domain/usecases/toggle_todo_completed.dart';
import '../../domain/usecases/update_todo.dart';
import '../../domain/usecases/watch_todos.dart';
import 'todo_filter_provider.dart';

part 'todo_list_notifier.g.dart';

// 화면이 구독하는 통합 Notifier. WatchTodos 스트림을 필터와 결합해 노출하고,
// 변경 액션은 UseCase를 통해 repository에 위임한다.
@riverpod
class TodoListNotifier extends _$TodoListNotifier {
  static const _uuid = Uuid();

  @override
  Stream<List<Todo>> build() async* {
    final repo = await ref.watch(todoRepositoryProvider.future);
    final filter = ref.watch(todoFilterProvider);
    final watch = WatchTodos(repo);
    yield* watch(const NoParams()).map(
      (either) => either.match<List<Todo>>(
        (failure) => throw failure,
        (todos) => _applyFilter(todos, filter),
      ),
    );
  }

  Future<void> add({
    required String title,
    String? description,
    DateTime? dueDate,
  }) async {
    final repo = await ref.read(todoRepositoryProvider.future);
    final usecase = AddTodo(
      repo,
      idGenerator: _uuid.v4,
      now: DateTime.now,
    );
    final result = await usecase(
      AddTodoParams(title: title, description: description, dueDate: dueDate),
    );
    result.match((failure) => throw failure, (_) {});
  }

  // 부모 AsyncNotifier의 update 시그니처와 충돌해 save로 명명한다.
  Future<void> save(Todo todo) async {
    final repo = await ref.read(todoRepositoryProvider.future);
    final next = todo.copyWith(updatedAt: DateTime.now());
    final result = await UpdateTodo(repo)(next);
    result.match((failure) => throw failure, (_) {});
  }

  Future<void> toggle(Todo todo) async {
    final repo = await ref.read(todoRepositoryProvider.future);
    final usecase = ToggleTodoCompleted(repo, now: DateTime.now);
    final result = await usecase(todo);
    result.match((failure) => throw failure, (_) {});
  }

  Future<void> delete(String id) async {
    final repo = await ref.read(todoRepositoryProvider.future);
    final result = await DeleteTodo(repo)(id);
    result.match((failure) => throw failure, (_) {});
  }
}

List<Todo> _applyFilter(List<Todo> todos, TodoFilter filter) => switch (filter) {
  TodoFilter.all => todos,
  TodoFilter.pending => todos.where((t) => !t.isCompleted).toList(),
  TodoFilter.completed => todos.where((t) => t.isCompleted).toList(),
};
