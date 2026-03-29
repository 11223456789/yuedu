import 'analyze_by_jsoup.dart';
import 'analyze_by_xpath.dart';
import 'analyze_by_json_path.dart';
import 'js_engine.dart';

/// 书源规则解析引擎入口
class AnalyzeRule {
  final AnalyzeByJSoup _jsoup = AnalyzeByJSoup();
  final AnalyzeByXPath _xpath = AnalyzeByXPath();
  final AnalyzeByJSONPath _jsonPath = AnalyzeByJSONPath();
  final JsEngine _jsEngine = JsEngine();

  dynamic _content;
  String? _baseUrl;

  void setContent(dynamic content, {String? baseUrl}) {
    _content = content;
    _baseUrl = baseUrl;

    if (content is String) {
      final str = content as String;
      // 尝试判断是 HTML 还是 JSON
      if (str.trim().startsWith('{') || str.trim().startsWith('[')) {
        _jsonPath.parse(str);
      } else {
        _jsoup.parse(str, baseUrl: baseUrl);
        _xpath.parse(str);
      }
    }
  }

  /// 获取单个字符串值
  Future<String?> getString(String rule) async {
    if (rule.isEmpty) return null;

    // JS 规则
    if (rule.startsWith('<js>') && rule.endsWith('</js>')) {
      final js = rule.substring(4, rule.length - 5);
      return await _jsEngine.eval(js);
    }
    if (rule.startsWith('@js:')) {
      final js = rule.substring(4);
      return await _jsEngine.eval(js);
    }

    // 正则规则
    if (rule.startsWith('@regex:')) {
      return _applyRegex(_content?.toString() ?? '', rule.substring(7));
    }

    // JSONPath 规则
    if (rule.startsWith(r'$.') || rule.startsWith(r'@.')) {
      return _jsonPath.getString(rule);
    }

    // XPath 规则
    if (rule.startsWith('//')) {
      return _xpath.getString(rule);
    }

    // CSS 选择器规则（默认）
    return _jsoup.getString(rule);
  }

  /// 获取字符串列表
  Future<List<String>> getStringList(String rule) async {
    if (rule.isEmpty) return [];

    // JSONPath 规则
    if (rule.startsWith(r'$.') || rule.startsWith(r'@.')) {
      return _jsonPath.getStringList(rule);
    }

    // XPath 规则
    if (rule.startsWith('//')) {
      return _xpath.getStringList(rule);
    }

    // CSS 选择器规则（默认）
    return _jsoup.getStringList(rule);
  }

  /// 获取单个元素
  Future<dynamic> getElement(String rule) async {
    if (rule.isEmpty) return null;

    // JSONPath 规则
    if (rule.startsWith(r'$.') || rule.startsWith(r'@.')) {
      return _jsonPath.getObject(rule);
    }

    // XPath 规则
    if (rule.startsWith('//')) {
      return _xpath.getNode(rule);
    }

    // CSS 选择器规则（默认）
    return _jsoup.getElement(rule);
  }

  /// 获取元素列表
  Future<List<dynamic>> getElements(String rule) async {
    if (rule.isEmpty) return [];

    // JSONPath 规则
    if (rule.startsWith(r'$.') || rule.startsWith(r'@.')) {
      return _jsonPath.getObjectList(rule);
    }

    // XPath 规则
    if (rule.startsWith('//')) {
      return _xpath.getNodes(rule);
    }

    // CSS 选择器规则（默认）
    return _jsoup.getElements(rule);
  }

  /// 执行 JS
  Future<String?> evalJS(String jsStr, {Map<String, dynamic>? context}) {
    return _jsEngine.eval(jsStr, context: context);
  }

  /// 应用正则表达式
  String? _applyRegex(String text, String regexRule) {
    try {
      final parts = regexRule.split('##');
      final pattern = parts[0];
      final replacement = parts.length > 1 ? parts[1] : '';

      final regex = RegExp(pattern);
      if (replacement.isEmpty) {
        final match = regex.firstMatch(text);
        return match?.group(0);
      } else {
        return text.replaceAllMapped(regex, (m) {
          String result = replacement;
          for (int i = 0; i <= m.groupCount; i++) {
            result = result.replaceAll('\$$i', m.group(i) ?? '');
          }
          return result;
        });
      }
    } catch (_) {
      return null;
    }
  }
}
