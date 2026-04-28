import 'package:claude_basic_app/features/todos/data/models/todo_model.dart';
import 'package:claude_basic_app/features/todos/domain/entities/todo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TodoModel', () {
    final entity = Todo(
      id: 't-1',
      title: '보고서 작성',
      description: '주간 회의용',
      dueDate: DateTime.fromMillisecondsSinceEpoch(1735689600000),
      isCompleted: false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(1735603200000),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(1735603200000),
    );

    test('fromEntity → toEntity 왕복 시 동등', () {
      final model = TodoModel.fromEntity(entity);
      expect(model.toEntity(), entity);
    });

    test('fromEntity는 dueDate가 null이면 dueDateMs도 null', () {
      final noDue = entity.copyWith(dueDate: null);
      final model = TodoModel.fromEntity(noDue);
      expect(model.dueDateMs, isNull);
      expect(model.toEntity().dueDate, isNull);
    });

    test('toJson → fromJson 왕복 시 동등', () {
      final model = TodoModel.fromEntity(entity);
      final json = model.toJson();
      final restored = TodoModel.fromJson(json);
      expect(restored, model);
    });

    test('json 필드가 epoch ms (int) 형태로 직렬화된다', () {
      final model = TodoModel.fromEntity(entity);
      final json = model.toJson();
      expect(json['createdAtMs'], isA<int>());
      expect(json['updatedAtMs'], isA<int>());
      expect(json['dueDateMs'], isA<int>());
    });
  });
}
