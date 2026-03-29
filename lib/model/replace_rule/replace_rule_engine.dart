import 'dart:async';

/// 替换规则
class ReplaceRule {
  final int id;
  final String name;
  final String group;
  final String pattern;
  final String replacement;
  final bool isRegex;
  final bool enabled;
  final String? scope;
  final int sortOrder;

  ReplaceRule({
    required this.id,
    required this.name,
    this.group = '',
    required this.pattern,
    required this.replacement,
    this.isRegex = false,
    this.enabled = true,
    this.scope,
    this.sortOrder = 0,
  });
}

/// 替换规则引擎
class ReplaceRuleEngine {
  ReplaceRuleEngine._();

  static const int _timeoutMs = 5000;

  /// 应用所有启用的替换规则
  static String applyAll(String text, List<ReplaceRule> rules, {String? bookUrl}) {
    String result = text;

    for (final rule in rules) {
      if (!rule.enabled) continue;

      if (rule.scope != null && rule.scope!.isNotEmpty) {
        if (bookUrl != null && !bookUrl.contains(rule.scope!)) {
          continue;
        }
      }

      try {
        result = _applyWithTimeout(result, rule);
      } catch (e) {
        if (e is TimeoutException) {
          print('替换规则"${rule.name}"执行超时，已跳过');
        } else {
          print('替换规则"${rule.name}"执行错误: $e');
        }
      }
    }

    return result;
  }

  /// 带超时保护的单个规则应用
  static String _applyWithTimeout(String text, ReplaceRule rule) {
    return Future.sync(() => _applyRule(text, rule))
        .timeout(const Duration(milliseconds: _timeoutMs))
        .catchError((error) {
      if (error is TimeoutException) {
        throw TimeoutException('规则执行超时');
      }
      throw error;
    }) as String;
  }

  /// 应用单个规则
  static String _applyRule(String text, ReplaceRule rule) {
    if (rule.isRegex) {
      try {
        final regex = RegExp(rule.pattern);
        return text.replaceAllMapped(regex, (match) {
          String result = rule.replacement;
          for (int i = 0; i <= match.groupCount; i++) {
            result = result.replaceAll('\$$i', match.group(i) ?? '');
          }
          return result;
        });
      } catch (e) {
        print('正则表达式错误: $e');
        return text;
      }
    } else {
      return text.replaceAll(rule.pattern, rule.replacement);
    }
  }

  /// 测试单个规则
  static String testRule(String text, ReplaceRule rule) {
    try {
      return _applyRule(text, rule);
    } catch (e) {
      return '错误: $e';
    }
  }

  /// 按分组对规则进行排序
  static List<ReplaceRule> sortRules(List<ReplaceRule> rules) {
    final sorted = List<ReplaceRule>.from(rules);
    sorted.sort((a, b) {
      final groupCompare = a.group.compareTo(b.group);
      if (groupCompare != 0) return groupCompare;
      return a.sortOrder.compareTo(b.sortOrder);
    });
    return sorted;
  }

  /// 获取启用的规则
  static List<ReplaceRule> getEnabledRules(List<ReplaceRule> rules) {
    return rules.where((rule) => rule.enabled).toList();
  }

  /// 获取指定分组的规则
  static List<ReplaceRule> getRulesByGroup(List<ReplaceRule> rules, String group) {
    return rules.where((rule) => rule.group == group).toList();
  }
}
