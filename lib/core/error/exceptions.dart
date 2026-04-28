// datasource 단에서 외부(파일/DB) 호출 실패 시 throw하는 raw 예외.
// repository 구현이 이를 catch해 Failure로 변환한다.
class CacheException implements Exception {
  final String message;
  const CacheException(this.message);

  @override
  String toString() => 'CacheException: $message';
}
