import 'analyze_by_jsoup.dart';
import 'analyze_by_xpath.dart';
import 'analyze_by_json_path.dart';
import 'js_engine.dart';

/// 解析模式
enum RuleMode {
  defaultMode, // CSS选择器（默认）
  xpath,      // XPath
  jsonPath,   // JSONPath
  js,         // JavaScript
  regex,      // 正则表达式
}

/// 单条源规则（对应 legado 的 SourceRule）
class SourceRule {
  String rule;
  RuleMode mode;
  String replaceRegex = '';
  String replacement = '';
  bool replaceFirst = false;
  final Map<String, String> putMap = {};
  final List<String> ruleParam = [];
  final List<int> ruleType = [];

  static const int _getRuleType = -2;
  static const int _jsRuleType = -1;
  static const int _defaultRuleType = 0;

  SourceRule(this.rule, {this.mode = RuleMode.defaultMode});

  /// 从规则字符串解析
  factory SourceRule.parse(String ruleStr, {RuleMode initialMode = RuleMode.defaultMode}) {
    final sourceRule = SourceRule('', mode: initialMode);
    sourceRule._parse(ruleStr);
    return sourceRule;
  }

  void _parse(String ruleStr) {
    var currentMode = mode;
    var workingRule = ruleStr;

    // 显式模式指定
    if (workingRule.startsWith('@CSS:')) {
      currentMode = RuleMode.defaultMode;
      workingRule = workingRule.substring(5);
    } else if (workingRule.startsWith('@@')) {
      currentMode = RuleMode.defaultMode;
      workingRule = workingRule.substring(2);
    } else if (workingRule.startsWith('@XPath:')) {
      currentMode = RuleMode.xpath;
      workingRule = workingRule.substring(7);
    } else if (workingRule.startsWith('@Json:')) {
      currentMode = RuleMode.jsonPath;
      workingRule = workingRule.substring(6);
    }

    // 自动检测模式
    if (currentMode == RuleMode.defaultMode) {
      if (workingRule.startsWith('//')) {
        currentMode = RuleMode.xpath;
      } else if (workingRule.startsWith(r'$.') || workingRule.startsWith(r'$[')) {
        currentMode = RuleMode.jsonPath;
      }
    }

    mode = currentMode;

    // 分离 @put:{...} 变量注入
    workingRule = _splitPutRule(workingRule);

    // 分离 @get:{...}, {{...}}, $n 正则捕获组
    int start = 0;
    final evalPattern = RegExp(r'@get:\{[^}]+\}|\{\{[\w\W]*?\}\}');
    
    Match? evalMatch = evalPattern.firstMatch(workingRule);
    if (evalMatch != null) {
      if (currentMode != RuleMode.js && currentMode != RuleMode.regex &&
          (evalMatch.start == 0 || !workingRule.substring(0, evalMatch.start).contains('##'))) {
        mode = RuleMode.regex;
      }
      
      while (evalMatch != null) {
        if (evalMatch.start > start) {
          final tmp = workingRule.substring(start, evalMatch.start);
          _splitRegex(tmp);
        }
        final matchStr = evalMatch.group(0)!;
        if (matchStr.startsWith('@get:')) {
          ruleType.add(_getRuleType);
          ruleParam.add(matchStr.substring(6, matchStr.length - 1));
        } else if (matchStr.startsWith('{{') && matchStr.endsWith('}}')) {
          ruleType.add(_jsRuleType);
          ruleParam.add(matchStr.substring(2, matchStr.length - 2));
        } else {
          _splitRegex(matchStr);
        }
        start = evalMatch.end;
        evalMatch = evalPattern.matchAsPrefix(workingRule, start);
      }
    }

    if (workingRule.length > start) {
      _splitRegex(workingRule.substring(start));
    }

    // 分离 ##regex##replacement
    final parts = rule.split('##');
    rule = parts[0].trim();
    if (parts.length > 1) replaceRegex = parts[1];
    if (parts.length > 2) replacement = parts[2];
    if (parts.length > 3) replaceFirst = true;
  }

  String _splitPutRule(String ruleStr) {
    final putPattern = RegExp(r'@put:(\{[^}]+\})', caseSensitive: false);
    return ruleStr.replaceAllMapped(putPattern, (match) {
      final putJson = match.group(1)!;
      try {
        final decoded = _jsonDecode(putJson);
        if (decoded is Map) {
          decoded.forEach((key, value) => putMap[key.toString()] = value.toString());
        }
      } catch (_) {}
      return '';
    });
  }

  void _splitRegex(String ruleStr) {
    int start = 0;
    final regexPattern = RegExp(r'\$\d{1,2}');
    final parts = ruleStr.split('##');
    final regexMatch = regexPattern.firstMatch(parts[0]);

    if (regexMatch != null && mode != RuleMode.js && mode != RuleMode.regex) {
      mode = RuleMode.regex;
      
    Match? m = regexMatch;
    while (m != null) {
      if (m.start > start) {
        ruleType.add(_defaultRuleType);
        ruleParam.add(parts[0].substring(start, m.start));
      }
      ruleType.add(int.parse(m.group(0)!.substring(1)));
      ruleParam.add(m.group(0)!);
      start = m.end;
      m = regexPattern.matchAsPrefix(parts[0], start);
      }
    }

    if (parts[0].length > start) {
      ruleType.add(_defaultRuleType);
      ruleParam.add(parts[0].substring(start));
    }
  }

  /// 构建最终规则（替换 @get, {{}}, $n）
  void makeUpRule(dynamic result, String Function(String) getStringFn, dynamic Function(String, dynamic) evalJsFn) {
    if (ruleParam.isEmpty) return;

    final buffer = StringBuffer();
    for (int i = ruleParam.length - 1; i >= 0; i--) {
      final regType = ruleType[i];
      final param = ruleParam[i];

      String value;
      if (regType > _defaultRuleType) {
        // $n 正则捕获组引用
        final list = result is List ? result : null;
        value = (list != null && list.length > regType) 
            ? (list[regType]?.toString() ?? param)
            : param;
      } else if (regType == _jsRuleType) {
        // {{js}} 内嵌 JS
        if (_isRule(param)) {
          value = getStringFn(param);
        } else {
          final jsResult = evalJsFn(param, result);
          value = jsResult?.toString() ?? param;
        }
      } else if (regType == _getRuleType) {
        // @get:{rule} 嵌套规则获取
        value = getStringFn(param);
      } else {
        value = param;
      }
      buffer.write(value);
    }

    rule = buffer.toString();

    // 重新分离 ## 正则替换
    final parts = rule.split('##');
    rule = parts[0].trim();
    if (parts.length > 1) replaceRegex = parts[1];
    if (parts.length > 2) replacement = parts[2];
    if (parts.length > 3) replaceFirst = true;
  }

  bool _isRule(String s) =>
      s.startsWith('@') || s.startsWith(r'$.') || s.startsWith(r'$[') || s.startsWith('//');

  dynamic _jsonDecode(String str) {
    // 简单 JSON 解析
    final first = str.trim();
    if ((first.startsWith('{') && first.endsWith('}')) ||
        (first.startsWith('[') && first.endsWith(']'))) {
      // 使用 dart:convert 已在 import 中可用
      // 这里返回原始字符串，由调用方处理
    }
    return str;
  }
}

/// 书源规则解析引擎入口（完全复刻 legado 的 AnalyzeRule）
class AnalyzeRule {
  final AnalyzeByJSoup _jsoup = AnalyzeByJSoup();
  final AnalyzeByXPath _xpath = AnalyzeByXPath();
  final AnalyzeByJSONPath _jsonPath = AnalyzeByJSONPath();
  final JsEngine _jsEngine = JsEngine();

  dynamic _content;
  String? _baseUrl;
  String? _redirectUrl;
  bool _isJSON = false;

  // 变量存储
  final Map<String, String> _variables = {};

  // 规则缓存
  final Map<String, List<SourceRule>> _ruleCache = {};
  final Map<String, RegExp> _regexCache = {};

  void setContent(dynamic content, {String? baseUrl, String? redirectUrl}) {
    _content = content;
    _baseUrl = baseUrl;
    _redirectUrl = redirectUrl;

    if (content is String) {
      final str = content as String;
      _isJSON = _isJsonString(str);
      if (_isJSON) {
        _jsonPath.parse(str);
      } else {
        _jsoup.parse(str, baseUrl: baseUrl);
        _xpath.parse(str);
      }
    }
  }

  bool _isJsonString(String str) {
    final trimmed = str.trim();
    return (trimmed.startsWith('{') && trimmed.endsWith('}')) ||
           (trimmed.startsWith('[') && trimmed.endsWith(']'));
  }

  /// 获取单个字符串值（核心方法）
  Future<String?> getString(String ruleStr, {bool isUrl = false}) async {
    if (ruleStr.isEmpty) return '';

    final ruleList = _splitSourceRule(ruleStr);
    return await _getStringFromList(ruleList, isUrl: isUrl);
  }

  Future<String> _getStringFromList(List<SourceRule> ruleList, {bool isUrl = false}) async {
    dynamic result = _content;

    for (final sourceRule in ruleList) {
      // 注入 @put 变量
      for (final entry in sourceRule.putMap.entries) {
        _variables[entry.key] = await getString(entry.value) ?? '';
      }

      // 构建最终规则
      sourceRule.makeUpRule(result, (r) async => await getString(r), (js, res) async {
        return await _evalJS(js, res);
      });

      if (result == null) continue;

      final rule = sourceRule.rule;
      if (rule.isEmpty && sourceRule.replaceRegex.isEmpty) continue;

      // 根据模式执行解析
      String? parsedResult;
      switch (sourceRule.mode) {
        case RuleMode.js:
          parsedResult = (await _evalJS(rule, result))?.toString();
          break;
        case RuleMode.regex:
          parsedResult = _applyRegex(result.toString(), sourceRule);
          break;
        case RuleMode.jsonPath:
          parsedResult = _jsonPath.getString(rule);
          break;
        case RuleMode.xpath:
          parsedResult = _xpath.getString(rule);
          break;
        case RuleMode.defaultMode:
        default:
          if (isUrl) {
            parsedResult = _jsoup.getStringWithUrl(rule);
          } else {
            parsedResult = _jsoup.getString(rule);
          }
      }

      result = parsedResult ?? result;

      // 应用正则替换
      if (sourceRule.replaceRegex.isNotEmpty && result != null) {
        result = _applyReplaceRegex(result.toString(), sourceRule);
      }
    }

    final resultStr = result?.toString() ?? '';
    
    // URL 绝对路径解析
    if (isUrl && resultStr.isNotEmpty) {
      return _resolveUrl(resultStr);
    }

    return resultStr.isNotEmpty ? resultStr : null;
  }

  /// 获取字符串列表
  Future<List<String>> getStringList(String ruleStr, {bool isUrl = false}) async {
    if (ruleStr.isEmpty) return [];

    final ruleList = _splitSourceRule(ruleStr);
    return await _getStringListFromList(ruleList, isUrl: isUrl);
  }

  Future<List<String>> _getStringListFromList(List<SourceRule> ruleList, {bool isUrl = false}) async {
    dynamic result = _content;

    for (final sourceRule in ruleList) {
      for (final entry in sourceRule.putMap.entries) {
        _variables[entry.key] = await getString(entry.value) ?? '';
      }

      sourceRule.makeUpRule(result, (r) async => await getString(r), (js, res) async {
        return await _evalJS(js, res);
      });

      if (result == null) continue;

      final rule = sourceRule.rule;
      if (rule.isEmpty && sourceRule.replaceRegex.isEmpty) continue;

      List<String>? parsedResult;
      switch (sourceRule.mode) {
        case RuleMode.js:
          final jsResult = await _evalJS(rule, result);
          if (jsResult is List) {
            parsedResult = jsResult.map((e) => e.toString()).toList();
          } else if (jsResult is String) {
            parsedResult = jsResult.split('\n').where((s) => s.isNotEmpty).toList();
          } else {
            parsedResult = jsResult != null ? [jsResult.toString()] : [];
          }
          break;
        case RuleMode.regex:
          parsedResult = _applyRegexToList(result.toString(), sourceRule);
          break;
        case RuleMode.jsonPath:
          parsedResult = _jsonPath.getStringList(rule);
          break;
        case RuleMode.xpath:
          parsedResult = _xpath.getStringList(rule);
          break;
        case RuleMode.defaultMode:
        default:
          parsedResult = _jsoup.getStringList(rule);
      }

      result = parsedResult ?? result;

      // 对列表中每个元素应用正则替换
      if (sourceRule.replaceRegex.isNotEmpty && result is List) {
        result = (result as List).map((item) => 
          _applyReplaceRegex(item.toString(), sourceRule)
        ).toList();
      }
    }

    if (result is! List) {
      if (result is String && result.isNotEmpty) {
        result = (result as String).split('\n').where((s) => s.isNotEmpty).toList();
      } else {
        result = [];
      }
    }

    if (isUrl) {
      return (result as List).map((url) => _resolveUrl(url.toString())).toSet().toList();
    }

    return result.cast<String>();
  }

  /// 获取元素列表
  Future<List<dynamic>> getElements(String ruleStr) async {
    if (ruleStr.isEmpty) return [];

    final ruleList = _splitSourceRule(ruleStr);
    dynamic result = _content;

    for (final sourceRule in ruleList) {
      for (final entry in sourceRule.putMap.entries) {
        _variables[entry.key] = await getString(entry.value) ?? '';
      }

      sourceRule.makeUpRule(result, (r) async => await getString(r), (js, res) async {
        return await _evalJS(js, res);
      });

      if (result == null) continue;

      final rule = sourceRule.rule;
      switch (sourceRule.mode) {
        case RuleMode.js:
          result = await _evalJS(rule, result);
          break;
        case RuleMode.jsonPath:
          result = _jsonPath.getObjectList(rule);
          break;
        case RuleMode.xpath:
          result = _xpath.getNodes(rule);
          break;
        case RuleMode.defaultMode:
        default:
          result = _jsoup.getElements(rule);
      }

      if (sourceRule.replaceRegex.isNotEmpty && result is List) {
        result = (result as List).map((item) => 
          _applyReplaceRegex(item.toString(), sourceRule)
        ).toList();
      }
    }

    return result is List ? result : (result != null ? [result] : []);
  }

  /// 获取单个元素
  Future<dynamic> getElement(String ruleStr) async {
    if (ruleStr.isEmpty) return null;

    final ruleList = _splitSourceRule(ruleStr);
    dynamic result = _content;

    for (final sourceRule in ruleList) {
      for (final entry in sourceRule.putMap.entries) {
        _variables[entry.key] = await getString(entry.value) ?? '';
      }

      sourceRule.makeUpRule(result, (r) async => await getString(r), (js, res) async {
        return await _evalJS(js, res);
      });

      if (result == null) continue;

      final rule = sourceRule.rule;
      switch (sourceRule.mode) {
        case RuleMode.js:
          result = await _evalJS(rule, result);
          break;
        case RuleMode.jsonPath:
          result = _jsonPath.getObject(rule);
          break;
        case RuleMode.xpath:
          result = _xpath.getNode(rule);
          break;
        case RuleMode.defaultMode:
        default:
          result = _jsoup.getElement(rule);
      }

      if (sourceRule.replaceRegex.isNotEmpty && result != null) {
        result = _applyReplaceRegex(result.toString(), sourceRule);
      }
    }

    return result;
  }

  /// 分解规则为 SourceRule 列表
  List<SourceRule> _splitSourceRule(String ruleStr) {
    if (ruleStr.isEmpty) return [];

    // 检查缓存
    if (_ruleCache.containsKey(ruleStr)) {
      return _ruleCache[ruleStr]!;
    }

    final ruleList = <SourceRule>[];
    var currentMode = RuleMode.defaultMode;
    int start = 0;

    // JS 模式匹配：<js>...</js> 或 @js:...
    final jsPattern = RegExp(r'<js>([\s\S]*?)</js>|@js:([^\s@]+)');
    
    for (final match in jsPattern.allMatches(ruleStr)) {
      if (match.start > start) {
        final tmp = ruleStr.substring(start, match.start).trim();
        if (tmp.isNotEmpty) {
          ruleList.add(SourceRule(tmp, mode: currentMode));
        }
      }
      // 提取 JS 代码
      final jsCode = match.group(1) ?? match.group(2) ?? match.group(0)!;
      final cleanJs = jsCode.startsWith('<js>') 
          ? jsCode.substring(4, jsCode.length - 5)
          : (jsCode.startsWith('@js:') ? jsCode.substring(4) : jsCode);
      ruleList.add(SourceRule(cleanJs.trim(), mode: RuleMode.js));
      start = match.end;
    }

    if (ruleStr.length > start) {
      final tmp = ruleStr.substring(start).trim();
      if (tmp.isNotEmpty) {
        ruleList.add(SourceRule(tmp, mode: currentMode));
      }
    }

    // 缓存（限制大小）
    if (_ruleCache.length < 200) {
      _ruleCache[ruleStr] = ruleList;
    }

    return ruleList;
  }

  /// 执行 JS
  Future<dynamic> _evalJS(String jsStr, [dynamic result]) async {
    if (jsStr.isEmpty) return null;
    
    final context = <String, dynamic>{
      'result': result,
      'baseUrl': _baseUrl,
      'src': _content,
      ..._variables,
    };

    return await _jsEngine.eval(jsStr, context: context);
  }

  /// 应用正则提取
  String? _applyRegex(String text, SourceRule sourceRule) {
    try {
      final regex = RegExp(sourceRule.rule);
      final match = regex.firstMatch(text);
      if (match == null) return null;
      if (sourceRule.replacement.isEmpty) {
        return match.group(0);
      }
      var result = sourceRule.replacement;
      for (int i = 0; i <= match.groupCount; i++) {
        result = result.replaceAll('\$$i', match.group(i) ?? '');
      }
      return result;
    } catch (_) {
      return null;
    }
  }

  List<String> _applyRegexToList(String text, SourceRule sourceRule) {
    try {
      final regex = RegExp(sourceRule.rule);
      final matches = regex.allMatches(text);
      if (sourceRule.replacement.isEmpty) {
        return matches.map((m) => m.group(0)!).toList();
      }
      return matches.map((m) {
        var result = sourceRule.replacement;
        for (int i = 0; i <= m.groupCount; i++) {
          result = result.replaceAll('\$$i', m.group(i) ?? '');
        }
        return result;
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// 应用正则替换
  String _applyReplaceRegex(String text, SourceRule sourceRule) {
    if (sourceRule.replaceRegex.isEmpty) return text;

    try {
      final regex = _getCompiledRegex(sourceRule.replaceRegex);
      if (regex == null) return text;

      if (sourceRule.replaceFirst) {
        final match = regex.firstMatch(text);
        if (match != null) {
          return text.replaceFirst(regex, sourceRule.replacement);
        }
        return sourceRule.replacement;
      } else {
        return text.replaceAll(regex, sourceRule.replacement);
      }
    } catch (_) {
      return text.replaceAll(sourceRule.replaceRegex, sourceRule.replacement);
    }
  }

  RegExp? _getCompiledRegex(String pattern) {
    if (_regexCache.containsKey(pattern)) {
      return _regexCache[pattern];
    }
    try {
      final regex = RegExp(pattern);
      if (_regexCache.length < 50) {
        _regexCache[pattern] = regex;
      }
      return regex;
    } catch (_) {
      return null;
    }
  }

  String _resolveUrl(String url) {
    if (url.isEmpty) return _baseUrl ?? url;
    if (url.startsWith('http://') || url.startsWith('https://') || url.startsWith('data:')) {
      return url;
    }
    try {
      final base = _redirectUrl ?? _baseUrl;
      if (base != null) {
        return Uri.parse(base).resolve(url).toString();
      }
    } catch (_) {}
    return url;
  }

  /// 变量操作
  void putVariable(String key, String value) {
    _variables[key] = value;
  }

  String? getVariable(String key) {
    return _variables[key];
  }

  void clearVariables() {
    _variables.clear();
  }
}
