import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/database/sembast_provider.dart';
import '../domain/repositories/todo_repository.dart';
import 'datasources/todo_local_datasource.dart';
import 'repositories/todo_repository_impl.dart';

part 'providers.g.dart';

// 데이터 레이어 외곽에서만 의존성을 조립한다. datasource/repository 자체는
// 생성자 주입 기반이라 테스트 시 fake로 갈아끼울 수 있다.
@riverpod
Future<TodoLocalDataSource> todoLocalDataSource(Ref ref) async {
  final db = await ref.watch(appDatabaseProvider.future);
  return TodoLocalDataSource(db);
}

@riverpod
Future<TodoRepository> todoRepository(Ref ref) async {
  final ds = await ref.watch(todoLocalDataSourceProvider.future);
  return TodoRepositoryImpl(ds);
}
