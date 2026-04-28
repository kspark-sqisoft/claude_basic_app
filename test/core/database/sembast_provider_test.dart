import 'package:claude_basic_app/core/database/sembast_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';

void main() {
  group('appDatabaseProvider', () {
    test('override한 in-memory Database가 열린 상태로 반환된다', () async {
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWith(
            (ref) => databaseFactoryMemory.openDatabase('test.db'),
          ),
        ],
      );
      addTearDown(container.dispose);

      final db = await container.read(appDatabaseProvider.future);

      expect(db, isA<Database>());
      // 간단한 read/write로 실제 사용 가능한지 확인
      final store = StoreRef<String, int>('counters');
      await store.record('a').put(db, 1);
      expect(await store.record('a').get(db), 1);

      await db.close();
    });
  });
}
