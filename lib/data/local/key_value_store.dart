/// Key-value contract used by repositories. UI must not depend on this directly.
abstract class KeyValueStore {
  T? read<T>(String key);
  Future<void> write(String key, dynamic value);
  Future<void> remove(String key);
}

class MemoryStore implements KeyValueStore {
  final Map<String, dynamic> _data = {};

  @override
  T? read<T>(String key) {
    final value = _data[key];
    if (value is T?) return value;
    return value as T?;
  }

  @override
  Future<void> write(String key, dynamic value) async {
    _data[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    _data.remove(key);
  }
}
