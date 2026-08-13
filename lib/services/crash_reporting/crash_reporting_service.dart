/// Crash reporting facade. Real SDK in Phase 14 when credentials exist.
class CrashReportingService {
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    Map<String, Object?> context = const {},
  }) async {
    assert(() {
      // ignore: avoid_print
      print('[crash] $error context=$context\n$stack');
      return true;
    }());
  }

  Future<void> setCustomKey(String key, Object value) async {}
}
