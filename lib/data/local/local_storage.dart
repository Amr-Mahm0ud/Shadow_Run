import 'package:get_storage/get_storage.dart';

import 'key_value_store.dart';

/// GetStorage-backed adapter for production.
class LocalStorage implements KeyValueStore {
  LocalStorage({GetStorage? box}) : _box = box ?? GetStorage();

  final GetStorage _box;

  @override
  T? read<T>(String key) => _box.read<T>(key);

  @override
  Future<void> write(String key, dynamic value) async {
    await _box.write(key, value);
  }

  @override
  Future<void> remove(String key) async {
    await _box.remove(key);
  }
}
