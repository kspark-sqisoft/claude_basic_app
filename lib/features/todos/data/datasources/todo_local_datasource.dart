import 'package:sembast/sembast.dart';

import '../../../../core/error/exceptions.dart';
import '../models/todo_model.dart';

// sembast 직접 호출만 담당. fpdart/Failure를 import하지 않는다 (책임 분리).
class TodoLocalDataSource {
  TodoLocalDataSource(this._db);

  final Database _db;

  static final StoreRef<String, Map<String, Object?>> _store =
      stringMapStoreFactory.store('todos');

  // id 키 기반 upsert. 동일 id면 sembast가 덮어쓴다.
  Future<void> upsert(TodoModel model) async {
    try {
      await _store.record(model.id).put(_db, model.toJson());
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  Future<void> deleteById(String id) async {
    try {
      await _store.record(id).delete(_db);
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  // createdAtMs 내림차순(최신순)으로 전체 변경을 스트림으로 방출.
  Stream<List<TodoModel>> watchAll() {
    final query = _store.query(
      finder: Finder(
        sortOrders: [SortOrder('createdAtMs', false)],
      ),
    );
    return query.onSnapshots(_db).map(
      (snapshots) =>
          snapshots.map((s) => TodoModel.fromJson(s.value)).toList(),
    );
  }
}
