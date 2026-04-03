import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;

/// JSoup 风格的 HTML 解析器
class AnalyzeByJSoup {
  String? _html;
  dom.Document? _document;

  void parse(String html, {String? baseUrl}) {
    _html = html;
    try {
      if (baseUrl != null) {
        _document = html_parser.parse(html, sourceUrl: baseUrl);
      } else {
        _document = html_parser.parse(html);
      }
    } catch (_) {
      _document = null;
    }
  }

  /// 获取单个字符串值（支持 legado 链式规则）
  /// 规则格式: selector@attr1@attr2 或 selector##regex##replacement
  String? getString(String rule) {
    if (rule.isEmpty || _document == null) return '';

    // 分离 ## 正则替换
    final parts = rule.split('##');
    final mainRule = parts[0].trim();
    final replaceRegex = parts.length > 1 ? parts[1] : '';
    final replacement = parts.length > 2 ? parts[2] : '';
    final replaceFirst = parts.length > 3;

    // 分离 @ 链式规则
    final chainParts = mainRule.split('@');
    
    if (chainParts.isEmpty) return '';

    var result = _selectSingle(chainParts[0]);
    
    // 处理后续的 @ 操作
    for (int i = 1; i < chainParts.length; i++) {
      final operation = chainParts[i];
      if (operation.isEmpty) continue;
      result = _applyOperation(result, operation);
      if (result == null) break;
    }

    if (result != null && replaceRegex.isNotEmpty) {
      result = _applyRegexReplace(result.toString(), replaceRegex, replacement, replaceFirst);
    }

    return result?.toString();
  }

  /// 获取带 URL 的字符串（自动解析相对路径）
  String? getStringWithUrl(String rule) {
    return getString(rule);
  }

  /// 获取字符串列表
  List<String> getStringList(String rule) {
    if (rule.isEmpty || _document == null) return [];

    final parts = rule.split('##');
    final mainRule = parts[0].trim();
    final replaceRegex = parts.length > 1 ? parts[1] : '';
    final replacement = parts.length > 2 ? parts[2] : '';
    final replaceFirst = parts.length > 3;

    final chainParts = mainRule.split('@');
    if (chainParts.isEmpty) return [];

    final dynamicResults = _selectAll(chainParts[0]);
    List<String> results = [];

    // 对每个结果应用 @ 操作
    if (chainParts.length > 1) {
      results = dynamicResults.map((item) {
        dynamic current = item;
        for (int i = 1; i < chainParts.length; i++) {
          final op = chainParts[i];
          if (op.isEmpty) continue;
          current = _applyOperation(current, op);
          if (current == null) return item?.toString() ?? '';
        }
        return current?.toString() ?? '';
      }).where((s) => s.isNotEmpty).toList();
    } else {
      results = dynamicResults.map((item) => item?.toString() ?? '').where((s) => s.isNotEmpty).toList();
    }

    // 应用正则替换
    if (replaceRegex.isNotEmpty) {
      results = results.map((s) => 
        _applyRegexReplace(s, replaceRegex, replacement, replaceFirst) ?? s
      ).toList();
    }

    return results;
  }

  /// 获取元素列表
  List<dynamic> getElements(String rule) {
    if (rule.isEmpty || _document == null) return [];

    final chainParts = rule.split('@');
    if (chainParts.isEmpty) return [];

    final elements = _queryAll(chainParts[0]);
    List<dynamic> result = elements.cast<dynamic>().toList();

    if (chainParts.length > 1) {
      result = result.expand((el) {
        dynamic current = el;
        List<dynamic> results = [];
        
        for (int i = 1; i < chainParts.length; i++) {
          final op = chainParts[i];
          if (op.isEmpty) continue;
          
          if (_isListOp(op)) {
            // 列表操作（如 tag.a）返回子元素列表
            final subElements = _applyListOperation(el, op);
            results.addAll(subElements);
            break;
          } else {
            current = _applyOperation(current, op);
            if (current == null) return <dynamic>[el];
          }
        }
        
        if (results.isNotEmpty) return results;
        return current != null ? [current] : [el];
      }).toList();
    }

    return result;
  }

  /// 获取单个元素
  dynamic getElement(String rule) {
    if (rule.isEmpty || _document == null) return null;

    final chainParts = rule.split('@');
    if (chainParts.isEmpty) return null;

    var element = _queryOne(chainParts[0]);
    
    for (int i = 1; i < chainParts.length; i++) {
      final op = chainParts[i];
      if (op.isEmpty) continue;
      
      if (_isElementOp(op)) {
        element = _applyElementOperation(element, op);
      } else {
        element = _applyOperation(element, op);
      }
      if (element == null) break;
    }

    return element;
  }

  // ========== 选择器操作 ==========

  /// 选择单个元素/文本
  dynamic _selectSingle(String selector) {
    if (selector.isEmpty) return _html ?? '';
    
    switch (selector.toLowerCase()) {
      case 'text':
      case 'textnodes':
        return _getAllText(_document!);
      case 'ownText':
        return _getOwnText(_document!);
      case 'html':
        return _html ?? '';
      default:
        final elements = _queryAll(selector);
        if (elements.isEmpty) {
          // 如果选择器没找到元素，返回空字符串
          return '';
        }
        return _getElementTextOrValue(elements.first);
    }
  }

  /// 选择多个元素/文本
  List<dynamic> _selectAll(String selector) {
    if (selector.isEmpty) return [_html ?? ''];
    
    switch (selector.toLowerCase()) {
      case 'text':
      case 'textnodes':
        return [_getAllText(_document!)];
      case 'html':
        return [_html ?? ''];
      default:
        final elements = _queryAll(selector);
        if (elements.isEmpty) return [];
        return elements.map((el) => _getElementTextOrValue(el)).toList();
    }
  }

  /// 查询所有匹配元素
  List<dom.Element> _queryAll(String selector) {
    if (_document == null || selector.isEmpty) return [];
    try {
      final elements = _document!.querySelectorAll(selector);
      return elements.cast<dom.Element>().toList();
    } catch (_) {
      return [];
    }
  }

  /// 查询单个匹配元素
  dom.Element? _queryOne(String selector) {
    if (_document == null || selector.isEmpty) return null;
    try {
      return _document!.querySelector(selector);
    } catch (_) {
      return null;
    }
  }

  // ========== @ 操作处理 ==========

  bool _isListOp(String op) =>
      op.startsWith('tag.') || op.startsWith('child') || op.startsWith('children');

  bool _isElementOp(String op) =>
      op.startsWith('tag.') || op.startsWith('child') || 
      op.startsWith('parent') || op.startsWith('prev') || 
      op.startsWith('next') || op.startsWith('sibling');

  /// 应用操作到单个值
  dynamic _applyOperation(dynamic value, String operation) {
    if (value == null) return null;

    final lowerOp = operation.toLowerCase();

    // 文本操作
    switch (lowerOp) {
      case 'text':
      case 'textnodes':
        return _extractText(value);
      case 'owntext':
      case 'own-text':
      case 'own_text':
        return _extractOwnText(value);
      case 'html':
        return _extractHtml(value);
      case 'outerhtml':
      case 'outer-html':
      case 'outer_html':
        return _extractOuterHtml(value);
      case 'data':
        if (value is dom.Element) {
          return value.text?.toString() ?? value.toString();
        }
        return value.toString();
      case 'tagname':
      case 'tag-name':
      case 'tag_name':
        return value is dom.Element ? value.localName : '';
    }

    // 属性提取
    if (lowerOp.startsWith('attr-') || lowerOp.startsWith('attr.')) {
      final attrName = lowerOp.substring(5);
      return _getAttribute(value, attrName);
    }

    // 标签选择
    if (lowerOp.startsWith('tag.')) {
      final tagName = lowerOp.substring(4);
      return _getChildByTag(value, tagName);
    }

    // class 选择
    if (lowerOp.startsWith('class.')) {
      final className = lowerOp.substring(6);
      return _getChildByClass(value, className);
    }

    // ID 选择
    if (lowerOp.startsWith('#')) {
      return _getChildById(value, lowerOp.substring(1));
    }

    // 默认尝试属性获取
    return _getAttribute(value, operation);
  }

  /// 应用列表操作
  List<dynamic> _applyListOperation(dynamic element, String operation) {
    if (element is! dom.Element) return [];
    
    final lowerOp = operation.toLowerCase();

    if (lowerOp.startsWith('tag.')) {
      final tagName = lowerOp.substring(4);
      return element.getElementsByTagName(tagName).map((e) => e as dynamic).toList();
    }

    return [];
  }

  /// 应用元素操作
  dynamic _applyElementOperation(dynamic element, String operation) {
    if (element is! dom.Element) return null;

    final lowerOp = operation.toLowerCase();

    if (lowerOp.startsWith('tag.')) {
      final tagName = lowerOp.substring(4);
      final children = element.getElementsByTagName(tagName);
      return children.isNotEmpty ? children.first : null;
    }

    if (lowerOp == 'parent' || lowerOp == '..') {
      return element.parent;
    }

    if (lowerOp == 'children' || lowerOp == '>') {
      return element.children.toList();
    }

    return null;
  }

  // ========== 提取方法 ==========

  String _getText(dynamic element) {
    final buffer = StringBuffer();
    _collectText(element, buffer);
    return buffer.toString().trim();
  }

  void _collectText(dynamic node, StringBuffer buffer) {
    if (node is dom.Text) {
      buffer.write(node.text);
    } else if (node is dom.Element) {
      for (final child in node.nodes) {
        _collectText(child, buffer);
      }
    } else if (node is dom.Document) {
      if (node.body != null) {
        for (final child in node.body!.nodes) {
          _collectText(child, buffer);
        }
      }
    }
  }

  String _getOwnText(dynamic element) {
    if (element is dom.Element) {
      return element.nodes
          .whereType<dom.Text>()
          .map((t) => t.text)
          .join()
          .trim();
    } else if (element is dom.Document) {
      return element.body?.text?.trim() ?? '';
    }
    return element?.toString()?.trim() ?? '';
  }

  String _getAllText(dynamic node) {
    if (node is dom.Element) {
      return node.text?.trim() ?? '';
    } else if (node is dom.Document) {
      return node.body?.text?.trim() ?? '';
    } else if (node is dom.Node) {
      return node.text?.trim() ?? '';
    }
    return node?.toString()?.trim() ?? '';
  }

  dynamic _getElementTextOrValue(dynamic element) {
    if (element is dom.Element) {
      // input/select/textarea 等表单元素
      if (element.localName == 'input' || element.localName == 'textarea') {
        return element.attributes['value'] ?? _getText(element);
      }
      if (element.localName == 'select') {
        final selected = element.querySelector('option[selected]');
        return selected?.attributes['value'] ?? selected?.text ?? _getText(element);
      }
      return _getText(element);
    }
    return element?.toString() ?? '';
  }

  String? _extractText(dynamic value) {
    if (value is dom.Element) return _getText(value);
    if (value is dom.Document) return _getAllText(value);
    if (value is String) return value.trim();
    return value?.toString()?.trim();
  }

  String? _extractOwnText(dynamic value) {
    if (value is dom.Element) return _getOwnText(value);
    if (value is String) return value.trim();
    return value?.toString()?.trim();
  }

  String? _extractHtml(dynamic value) {
    if (value is dom.Element) return value.innerHtml;
    if (value is dom.Document) return value.body?.innerHtml;
    if (value is String) return value;
    return value?.toString();
  }

  String? _extractOuterHtml(dynamic value) {
    if (value is dom.Element) return value.outerHtml;
    if (value is dom.Document) return value.outerHtml;
    if (value is String) return value;
    return value?.toString();
  }

  String? _getAttribute(dynamic value, String attrName) {
    if (value is dom.Element) {
      // 特殊属性名映射
      final mappedAttr = _mapAttributeName(attrName);
      return value.attributes[mappedAttr] ?? value.attributes[attrName];
    }
    return null;
  }

  String _mapAttributeName(String attr) {
    const mappings = {
      'href': 'href',
      'src': 'src',
      'url': 'href', // url 映射为 href
      'link': 'href', // link 映射为 href
      'img': 'src',   // img 映射为 src
      'image': 'src', // image 映射为 src
      'alt': 'alt',
      'title': 'title',
      'value': 'value',
      'id': 'id',
      'class': 'className',
      'style': 'style',
      'data-src': 'data-src',
      'data-url': 'data-url',
      'data-href': 'data-href',
      'data-original': 'data-original',
      'content': 'content',
      'rel': 'rel',
      'target': 'target',
    };
    return mappings[attr.toLowerCase()] ?? attr;
  }

  dynamic _getChildByTag(dynamic parent, String tagName) {
    if (parent is dom.Element) {
      final children = parent.getElementsByTagName(tagName);
      if (children.isNotEmpty) return _getElementTextOrValue(children.first);
    }
    return null;
  }

  dynamic _getChildByClass(dynamic parent, String className) {
    if (parent is dom.Element) {
      final child = parent.querySelector('.$className');
      if (child != null) return _getElementTextOrValue(child);
    }
    return null;
  }

  dynamic _getChildById(dynamic parent, String id) {
    if (parent is dom.Element) {
      final child = parent.querySelector('#$id');
      if (child != null) return _getElementTextOrValue(child);
    }
    return null;
  }

  /// 正则替换
  String? _applyRegexReplace(String text, String regex, String replacement, bool firstOnly) {
    if (regex.isEmpty) return text;
    try {
      final pattern = RegExp(regex);
      if (firstOnly) {
        final match = pattern.firstMatch(text);
        if (match != null) {
          return text.replaceFirst(pattern, replacement);
        }
        return text.replaceAll(pattern, replacement);
      }
      return text.replaceAll(pattern, replacement);
    } catch (_) {
      return text.replaceAll(regex, replacement);
    }
  }
}
