import 'dart:convert';
import 'package:json_path/json_path.dart';

/// JSONPath 解析器（对应 legado 的 AnalyzeByJSONPath）
class AnalyzeByJSONPath {
  dynamic _jsonObj;

  void parse(String jsonStr) {
    try {
      _jsonObj = jsonDecode(jsonStr);
    } catch (_) {
      _jsonObj = null;
    }
  }

  void parseObject(dynamic obj) {
    _jsonObj = obj;
  }

  /// 获取单个字符串值
  String? getString(String rule) {
    if (_jsonObj == null || rule.isEmpty) return null;
    final results = _query(rule);
    if (results.isEmpty) return null;
    final first = results.first;
    if (first == null) return null;
    return first.toString();
  }

  /// 获取字符串列表
  List<String> getStringList(String rule) {
    if (_jsonObj == null || rule.isEmpty) return [];
    final results = _query(rule);
    return results
        .where((r) => r != null)
        .map((r) => r.toString())
        .toList();
  }

  /// 获取原始对象
  dynamic getObject(String rule) {
    if (_jsonObj == null || rule.isEmpty) return null;
    final results = _query(rule);
    return results.isEmpty ? null : results.first;
  }

  /// 获取对象列表
  List<dynamic> getObjectList(String rule) {
    if (_jsonObj == null || rule.isEmpty) return [];
    return _query(rule);
  }

  List<dynamic> _query(String rule) {
    try {
      // 支持 $.xxx 和 @.xxx 格式
      String path = rule.trim();
      if (path.startsWith('@.')) {
        path = '\$${path.substring(1)}';
      } else if (!path.startsWith('\$')) {
        path = '\$.$path';
      }

      final jsonPath = JsonPath(path);
      return jsonPath.read(_jsonObj).map((m) => m.value).toList();
    } catch (_) {
      return [];
    }
  }
}
