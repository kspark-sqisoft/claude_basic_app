import 'package:freezed_annotation/freezed_annotation.dart';

part 'todo.freezed.dart';

// 도메인 엔티티. 외부 표현(JSON/DB row)과 분리되어 데이터 레이어가 매핑한다.
@freezed
abstract class Todo with _$Todo {
  const factory Todo({
    required String id,
    required String title,
    String? description,
    DateTime? dueDate,
    required bool isCompleted,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Todo;
}
