import 'package:xpath_selector/xpath_selector.dart';
import 'package:xpath_selector_html_parser/xpath_selector_html_parser.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as html_dom;

/// XPath 解析器（对应 legado 的 AnalyzeByXPath）
class AnalyzeByXPath {
  HtmlXPath? _xpath;

  void parse(String htmlStr) {
    try {
      _xpath = HtmlXPath.html(htmlStr);
    } catch (_) {
      _xpath = null;
    }
  }

  /// 获取单个字符串值
  String? getString(String rule) {
    if (_xpath == null || rule.isEmpty) return null;
    try {
      final result = _xpath!.query(rule);
      final node = result.node;
      if (node == null) return null;
      return _nodeToText(node);
    } catch (_) {
      return null;
    }
  }

  /// 获取字符串列表
  List<String> getStringList(String rule) {
    if (_xpath == null || rule.isEmpty) return [];
    try {
      final result = _xpath!.query(rule);
      return result.nodes
          .map(_nodeToText)
          .where((s) => s != null && s.isNotEmpty)
          .cast<String>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// 获取单个节点元素
  html_dom.Element? getElement(String rule) {
    if (_xpath == null || rule.isEmpty) return null;
    try {
      final result = _xpath!.query(rule);
      final node = result.node;
      if (node == null) return null;
      // 从 HtmlNodeTree 中获取 Element
      if (node is HtmlNodeTree) {
        return node.element;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// 获取节点元素列表
  List<html_dom.Element> getElements(String rule) {
    if (_xpath == null || rule.isEmpty) return [];
    try {
      final result = _xpath!.query(rule);
      return result.nodes
          .whereType<HtmlNodeTree>()
          .map((n) => n.element)
          .toList();
    } catch (_) {
      return [];
    }
  }

  String? _nodeToText(XPathNode node) {
    return node.text?.trim();
  }
}
