import 'package:xpath_selector/xpath_selector.dart';
import 'package:xpath_selector_html_parser/xpath_selector_html_parser.dart';
import 'package:html/parser.dart' as html_parser;

/// XPath 解析器（对应 legado 的 AnalyzeByXPath）
class AnalyzeByXPath {
  XPathNode? _root;

  void parse(String htmlStr) {
    try {
      final doc = html_parser.parse(htmlStr);
      _root = HtmlXPath.node(doc);
    } catch (_) {
      _root = null;
    }
  }

  /// 获取单个字符串值
  String? getString(String rule) {
    if (_root == null || rule.isEmpty) return null;
    try {
      final result = _root!.queryXPath(rule);
      final node = result.node;
      if (node == null) return null;
      return _nodeToText(node);
    } catch (_) {
      return null;
    }
  }

  /// 获取字符串列表
  List<String> getStringList(String rule) {
    if (_root == null || rule.isEmpty) return [];
    try {
      final result = _root!.queryXPath(rule);
      return result.nodes
          .map(_nodeToText)
          .where((s) => s != null && s.isNotEmpty)
          .cast<String>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// 获取节点
  XPathNode? getNode(String rule) {
    if (_root == null || rule.isEmpty) return null;
    try {
      return _root!.queryXPath(rule).node;
    } catch (_) {
      return null;
    }
  }

  /// 获取节点列表
  List<XPathNode> getNodes(String rule) {
    if (_root == null || rule.isEmpty) return [];
    try {
      return _root!.queryXPath(rule).nodes;
    } catch (_) {
      return [];
    }
  }

  String? _nodeToText(XPathNode node) {
    return node.text?.trim();
  }
}
