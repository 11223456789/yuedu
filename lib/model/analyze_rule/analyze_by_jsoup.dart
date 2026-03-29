import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';

/// CSS 选择器解析器（对应 legado 的 AnalyzeByJSoup）
class AnalyzeByJSoup {
  Document? _doc;
  Element? _element;

  void parse(String htmlStr, {String? baseUrl}) {
    _doc = html_parser.parse(htmlStr, generateSpans: false);
    _element = null;
  }

  void parseElement(Element element) {
    _element = element;
    _doc = null;
  }

  Element? get _root => _element ?? _doc?.documentElement;

  /// 获取单个字符串值
  String? getString(String rule) {
    if (rule.isEmpty) return null;
    final parts = _splitRule(rule);
    dynamic current = _root;
    for (final part in parts) {
      current = _applyPart(current, part);
      if (current == null) return null;
    }
    return _toText(current);
  }

  /// 获取字符串列表
  List<String> getStringList(String rule) {
    if (rule.isEmpty) return [];
    final parts = _splitRule(rule);
    dynamic current = _root;
    for (int i = 0; i < parts.length - 1; i++) {
      current = _applyPart(current, parts[i]);
      if (current == null) return [];
    }
    final lastPart = parts.last;
    final elements = _getElements(current, lastPart);
    return elements.map((e) => _toText(e) ?? '').where((s) => s.isNotEmpty).toList();
  }

  /// 获取单个元素
  Element? getElement(String rule) {
    if (rule.isEmpty) return null;
    final parts = _splitRule(rule);
    dynamic current = _root;
    for (final part in parts) {
      current = _applyPart(current, part);
      if (current == null) return null;
    }
    if (current is Element) return current;
    if (current is List && current.isNotEmpty) return current.first as Element?;
    return null;
  }

  /// 获取元素列表
  List<Element> getElements(String rule) {
    if (rule.isEmpty) return [];
    final parts = _splitRule(rule);
    dynamic current = _root;
    for (int i = 0; i < parts.length - 1; i++) {
      current = _applyPart(current, parts[i]);
      if (current == null) return [];
    }
    return _getElements(current, parts.last);
  }

  List<String> _splitRule(String rule) {
    // 用 @ 分割规则链，但保留 @text、@href 等属性提取
    return rule.split(RegExp(r'(?<!@)@(?!text|href|src|alt|title|class|id|style|data-\w+)')).map((s) => s.trim()).toList();
  }

  dynamic _applyPart(dynamic current, String part) {
    if (current == null) return null;

    // 属性提取：@attr
    if (part.startsWith('@')) {
      final attr = part.substring(1);
      if (current is Element) return current.attributes[attr];
      if (current is List) {
        return (current as List).map((e) => (e as Element).attributes[attr]).toList();
      }
      return null;
    }

    // 文本提取
    if (part == 'text' || part == 'Text') {
      if (current is Element) return current.text.trim();
      if (current is List) return (current as List).map((e) => (e as Element).text.trim()).toList();
      return null;
    }

    // 索引：[0]、last、[0:3]
    final indexMatch = RegExp(r'^\[(-?\d+)\]$').firstMatch(part);
    if (indexMatch != null) {
      final idx = int.parse(indexMatch.group(1)!);
      if (current is List) {
        final list = current as List;
        final realIdx = idx < 0 ? list.length + idx : idx;
        return realIdx >= 0 && realIdx < list.length ? list[realIdx] : null;
      }
      return null;
    }

    // CSS 选择器
    final root = current is Element ? current : (current is Document ? current.documentElement : null);
    if (root == null) return null;

    // 处理 :eq(n) 伪类（Jsoup 特有）
    final eqMatch = RegExp(r'^(.*):eq\((\d+)\)$').firstMatch(part);
    if (eqMatch != null) {
      final selector = eqMatch.group(1)!;
      final idx = int.parse(eqMatch.group(2)!);
      final elements = root.querySelectorAll(selector.isEmpty ? '*' : selector);
      return idx < elements.length ? elements[idx] : null;
    }

    try {
      final elements = root.querySelectorAll(part);
      return elements.isEmpty ? null : elements;
    } catch (_) {
      return null;
    }
  }

  List<Element> _getElements(dynamic current, String part) {
    if (current == null) return [];
    final result = _applyPart(current, part);
    if (result is Element) return [result];
    if (result is List) return result.whereType<Element>().toList();
    return [];
  }

  String? _toText(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.trim();
    if (value is Element) return value.text.trim();
    if (value is List && value.isNotEmpty) {
      return _toText(value.first);
    }
    return null;
  }
}
