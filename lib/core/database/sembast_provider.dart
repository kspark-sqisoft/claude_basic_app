import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sembast/sembast_io.dart';

part 'sembast_provider.g.dart';

// 앱 전역에서 공유되는 sembast Database 인스턴스를 노출한다.
// keepAlive: autoDispose로 두면 화면 전환 시 close/open이 반복되며
// 트랜잭션 충돌 위험이 있으므로 명시적으로 유지한다.
@Riverpod(keepAlive: true)
Future<Database> appDatabase(Ref ref) async {
  final docDir = await getApplicationDocumentsDirectory();
  final dbDir = Directory(p.join(docDir.path, 'claude_basic_app'));
  if (!await dbDir.exists()) {
    await dbDir.create(recursive: true);
  }
  final dbPath = p.join(dbDir.path, 'todos.db');
  return databaseFactoryIo.openDatabase(dbPath);
}
