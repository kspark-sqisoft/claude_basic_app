import 'package:freezed_annotation/freezed_annotation.dart';

part 'failure.freezed.dart';

// 도메인/데이터 레이어가 presentation으로 전달하는 사용자 노출 가능한 실패 표현.
// network 실패는 본 MVP가 완전 오프라인이므로 정의하지 않는다.
@freezed
sealed class Failure with _$Failure {
  const factory Failure.database(String message) = DatabaseFailure;
  const factory Failure.validation(String message) = ValidationFailure;
  const factory Failure.unexpected(String message) = UnexpectedFailure;
}
