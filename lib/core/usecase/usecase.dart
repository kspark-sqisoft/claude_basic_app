import 'package:fpdart/fpdart.dart';

import '../error/failure.dart';

// 단일 책임 동기/비동기 UseCase 베이스. presentation은 이 시그니처를 통해서만 도메인을 호출한다.
abstract class UseCase<R, P> {
  Future<Either<Failure, R>> call(P params);
}

// 스트림 형태로 결과가 흘러나오는 UseCase (예: WatchTodos).
abstract class StreamUseCase<R, P> {
  Stream<Either<Failure, R>> call(P params);
}

// 파라미터가 필요 없는 UseCase에 사용한다.
class NoParams {
  const NoParams();
}
