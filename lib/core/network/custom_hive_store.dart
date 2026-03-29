import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:hive/hive.dart';

class CustomHiveStore extends Store {
  final Box<Map<dynamic, dynamic>> _box;

  CustomHiveStore(this._box);

  @override
  Map<String, dynamic>? get(String dataId) {
    final data = _box.get(dataId);
    if (data == null) return null;
    return Map<String, dynamic>.from(data);
  }

  @override
  void put(String dataId, Map<String, dynamic>? value) {
    if (value == null) {
      _box.delete(dataId);
    } else {
      _box.put(dataId, value);
    }
  }

  @override
  void putAll(Map<String, Map<String, dynamic>?> data) {
    data.forEach((key, value) {
      put(key, value);
    });
  }

  @override
  void delete(String dataId) {
    _box.delete(dataId);
  }

  @override
  void reset() {
    _box.clear();
  }

  @override
  Map<String, Map<String, dynamic>?> toMap() {
    final map = <String, Map<String, dynamic>?>{};
    _box.toMap().forEach((key, value) {
      if (key is String) {
        map[key] = Map<String, dynamic>.from(value);
      }
    });
    return map;
  }
}
