import 'package:claude_basic_app/features/todos/data/datasources/todo_local_datasource.dart';
import 'package:claude_basic_app/features/todos/data/models/todo_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';

TodoModel _model({
  required String id,
  required int createdAtMs,
  String title = '항목',
  bool isCompleted = false,
}) {
  return TodoModel(
    id: id,
    title: title,
    description: null,
    dueDateMs: null,
    isCompleted: isCompleted,
    createdAtMs: createdAtMs,
    updatedAtMs: createdAtMs,
  );
}

void main() {
  late Database db;
  late TodoLocalDataSource ds;

  setUp(() async {
    // 각 테스트 격리: 매번 새 in-memory factory를 만들어 이전 상태가 새지 않도록 한다.
    final factory = newDatabaseFactoryMemory();
    db = await factory.openDatabase('test.db');
    ds = TodoLocalDataSource(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('TodoLocalDataSource', () {
    test('upsert → watchAll 첫 emission에 항목 포함', () async {
      final m = _model(id: 'a', createdAtMs: 100);
      await ds.upsert(m);

      final list = await ds.watchAll().first;
      expect(list, hasLength(1));
      expect(list.first.id, 'a');
    });

    test('동일 id로 upsert 시 덮어쓴다', () async {
      await ds.upsert(_model(id: 'a', createdAtMs: 100, title: '원본'));
      await ds.upsert(_model(id: 'a', createdAtMs: 100, title: '수정'));

      final list = await ds.watchAll().first;
      expect(list, hasLength(1));
      expect(list.first.title, '수정');
    });

    test('deleteById 후 watchAll에서 사라진다', () async {
      await ds.upsert(_model(id: 'a', createdAtMs: 100));
      await ds.upsert(_model(id: 'b', createdAtMs: 200));

      await ds.deleteById('a');

      final list = await ds.watchAll().first;
      expect(list.map((m) => m.id), ['b']);
    });

    test('createdAtMs 내림차순으로 정렬된다', () async {
      await ds.upsert(_model(id: 'old', createdAtMs: 100));
      await ds.upsert(_model(id: 'new', createdAtMs: 300));
      await ds.upsert(_model(id: 'mid', createdAtMs: 200));

      final list = await ds.watchAll().first;
      expect(list.map((m) => m.id).toList(), ['new', 'mid', 'old']);
    });
  });
}
