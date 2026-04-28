import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/todo.dart';

part 'todo_model.freezed.dart';
part 'todo_model.g.dart';

// sembast에 그대로 직렬화되는 DTO. 시간 필드는 정렬/비교 안정성을 위해
// epoch millisecond(int)로 저장한다. (ADR-006: sembast)
@freezed
abstract class TodoModel with _$TodoModel {
  const TodoModel._();

  const factory TodoModel({
    required String id,
    required String title,
    String? description,
    int? dueDateMs,
    required bool isCompleted,
    required int createdAtMs,
    required int updatedAtMs,
  }) = _TodoModel;

  factory TodoModel.fromJson(Map<String, dynamic> json) =>
      _$TodoModelFromJson(json);

  factory TodoModel.fromEntity(Todo t) => TodoModel(
    id: t.id,
    title: t.title,
    description: t.description,
    dueDateMs: t.dueDate?.millisecondsSinceEpoch,
    isCompleted: t.isCompleted,
    createdAtMs: t.createdAt.millisecondsSinceEpoch,
    updatedAtMs: t.updatedAt.millisecondsSinceEpoch,
  );

  Todo toEntity() => Todo(
    id: id,
    title: title,
    description: description,
    dueDate: dueDateMs == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(dueDateMs!),
    isCompleted: isCompleted,
    createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMs),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAtMs),
  );
}
