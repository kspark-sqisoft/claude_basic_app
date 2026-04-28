import 'package:claude_basic_app/core/error/failure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Failure', () {
    test('동일 메시지를 가진 DatabaseFailure는 동등하다', () {
      const a = Failure.database('disk full');
      const b = Failure.database('disk full');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('메시지가 다른 DatabaseFailure는 동등하지 않다', () {
      const a = Failure.database('disk full');
      const b = Failure.database('locked');
      expect(a, isNot(equals(b)));
    });

    test('서로 다른 sealed 변형은 동등하지 않다', () {
      const db = Failure.database('x');
      const validation = Failure.validation('x');
      expect(db, isNot(equals(validation)));
    });

    test('sealed switch로 패턴 매칭이 가능하다', () {
      const Failure f = Failure.validation('empty');
      final label = switch (f) {
        DatabaseFailure() => 'db',
        ValidationFailure() => 'validation',
        UnexpectedFailure() => 'unexpected',
      };
      expect(label, 'validation');
    });
  });
}
