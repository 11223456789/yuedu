import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 替换规则数据类
class ReplaceRule {
  int id;
  String name;
  String? group;
  bool isRegex;
  String pattern;
  String replacement;
  String? scope; // 作用范围：书名，可以为空表示全局
  bool enabled;
  int order;

  ReplaceRule({
    required this.id,
    required this.name,
    this.group,
    this.isRegex = true,
    required this.pattern,
    this.replacement = '',
    this.scope,
    this.enabled = true,
    this.order = 0,
  });

  factory ReplaceRule.fromJson(Map<String, dynamic> json) {
    return ReplaceRule(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      group: json['group'] as String?,
      isRegex: json['isRegex'] as bool? ?? true,
      pattern: json['pattern'] as String? ?? '',
      replacement: json['replacement'] as String? ?? '',
      scope: json['scope'] as String?,
      enabled: json['enabled'] as bool? ?? true,
      order: json['order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'group': group,
      'isRegex': isRegex,
      'pattern': pattern,
      'replacement': replacement,
      'scope': scope,
      'enabled': enabled,
      'order': order,
    };
  }

  ReplaceRule copyWith({
    int? id,
    String? name,
    String? group,
    bool? isRegex,
    String? pattern,
    String? replacement,
    String? scope,
    bool? enabled,
    int? order,
  }) {
    return ReplaceRule(
      id: id ?? this.id,
      name: name ?? this.name,
      group: group ?? this.group,
      isRegex: isRegex ?? this.isRegex,
      pattern: pattern ?? this.pattern,
      replacement: replacement ?? this.replacement,
      scope: scope ?? this.scope,
      enabled: enabled ?? this.enabled,
      order: order ?? this.order,
    );
  }

  /// 应用替换规则到文本
  String apply(String text) {
    if (!enabled || pattern.isEmpty) return text;
    
    try {
      if (isRegex) {
        final regex = RegExp(pattern, multiLine: true);
        return text.replaceAll(regex, replacement);
      } else {
        return text.replaceAll(pattern, replacement);
      }
    } catch (e) {
      print('替换规则应用失败: $e');
      return text;
    }
  }
}

/// 替换规则 DAO（使用 SharedPreferences 持久化存储）
class ReplaceRuleDao {
  static const String _key = 'replace_rules';
  
  final Map<int, ReplaceRule> _cache = {};
  bool _loaded = false;
  int _nextId = 1;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data != null) {
      try {
        final List<dynamic> list = jsonDecode(data);
        for (final item in list) {
          final rule = ReplaceRule.fromJson(item);
          _cache[rule.id] = rule;
          if (rule.id >= _nextId) {
            _nextId = rule.id + 1;
          }
        }
      } catch (_) {}
    }
    _loaded = true;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _cache.values.map((r) => r.toJson()).toList();
    await prefs.setString(_key, jsonEncode(list));
  }

  Future<List<ReplaceRule>> getAllRules() async {
    await _ensureLoaded();
    final rules = _cache.values.toList();
    rules.sort((a, b) => a.order.compareTo(b.order));
    return rules;
  }

  Future<List<ReplaceRule>> getEnabledRules({String? scope}) async {
    await _ensureLoaded();
    final rules = _cache.values
        .where((r) => r.enabled && (scope == null || r.scope == null || r.scope == scope))
        .toList();
    rules.sort((a, b) => a.order.compareTo(b.order));
    return rules;
  }

  Future<ReplaceRule?> getRule(int id) async {
    await _ensureLoaded();
    return _cache[id];
  }

  Future<void> insertOrUpdateRule(ReplaceRule rule) async {
    await _ensureLoaded();
    if (rule.id == 0) {
      rule = rule.copyWith(id: _nextId++);
    }
    _cache[rule.id] = rule;
    await _save();
  }

  Future<void> deleteRule(int id) async {
    await _ensureLoaded();
    _cache.remove(id);
    await _save();
  }

  Future<void> toggleEnabled(int id, bool enabled) async {
    await _ensureLoaded();
    final rule = _cache[id];
    if (rule != null) {
      _cache[id] = rule.copyWith(enabled: enabled);
      await _save();
    }
  }

  /// 应用所有启用的替换规则到文本
  Future<String> applyRules(String text, {String? scope}) async {
    final rules = await getEnabledRules(scope: scope);
    String result = text;
    for (final rule in rules) {
      result = rule.apply(result);
    }
    return result;
  }
}
