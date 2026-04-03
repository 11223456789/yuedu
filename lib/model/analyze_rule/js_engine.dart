import 'dart:convert';
import 'package:flutter_js/flutter_js.dart';

/// JavaScript 引擎（使用 flutter_js 实现真正的 JS 执行）
class JsEngine {
  static final JsEngine _instance = JsEngine._internal();
  factory JsEngine() => _instance;
  JsEngine._internal();

  JavascriptRuntime? _runtime;
  bool _initialized = false;

  /// 初始化 JS 引擎
  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    
    _runtime = getJavascriptRuntime();
    
    // 注入基础工具函数
    await _injectBaseUtils();
    
    _initialized = true;
  }

  /// 注入基础工具函数
  Future<void> _injectBaseUtils() async {
    final baseUtils = '''
      // 基础工具函数
      function javaString(obj) {
        return String(obj);
      }
      
      function javaGet(obj, key) {
        if (obj === null || obj === undefined) return '';
        if (typeof obj === 'string') {
          try {
            obj = JSON.parse(obj);
          } catch(e) {
            return '';
          }
        }
        return obj[key] || '';
      }
      
      // 正则替换函数
      String.prototype.replaceAll = function(search, replacement) {
        return this.split(search).join(replacement);
      };
      
      // 编码函数
      function encodeURIComponent(str) {
        return encodeURIComponent(str);
      }
      
      function decodeURIComponent(str) {
        return decodeURIComponent(str);
      }
      
      // 基础选择器（简化版）
      function select(css, html) {
        // 简化实现，实际应该使用完整的 CSS 选择器
        return html;
      }
    ''';
    
    await _runtime!.evaluate(baseUtils);
  }

  /// 执行 JavaScript 代码
  /// 
  /// [code] - JS 代码
  /// [input] - 输入数据（可通过 input 变量访问）
  Future<dynamic> eval(String code, {dynamic input}) async {
    await _ensureInitialized();
    
    try {
      // 设置输入变量
      if (input != null) {
        final inputJson = jsonEncode(input);
        await _runtime!.evaluate('var input = $inputJson;');
        await _runtime!.evaluate('var result = $inputJson;');
      } else {
        await _runtime!.evaluate('var input = "";');
        await _runtime!.evaluate('var result = "";');
      }
      
      // 执行代码
      final wrappedCode = '''
        (function() {
          try {
            $code
            return result !== undefined ? result : input;
          } catch(e) {
            return 'Error: ' + e.message;
          }
        })()
      ''';
      
      final result = await _runtime!.evaluate(wrappedCode);
      
      // 处理结果
      return _convertResult(result);
    } catch (e) {
      print('JS 执行错误: $e');
      return input?.toString() ?? '';
    }
  }

  /// 执行带有 @js: 前缀的代码
  Future<dynamic> evalJsPrefix(String code, {dynamic input}) async {
    if (code.startsWith('@js:')) {
      code = code.substring(4);
    }
    return eval(code, input: input);
  }

  /// 执行 {{}} 内的 JS 代码
  Future<String> evalInlineJs(String code, {dynamic input}) async {
    final result = await eval(code, input: input);
    return result?.toString() ?? '';
  }

  /// 转换 JS 结果
  dynamic _convertResult(dynamic result) {
    if (result == null) return null;
    
    // 处理 JsEvalResult
    if (result is JsEvalResult) {
      final str = result.stringResult;
      try {
        // 尝试解析为 JSON
        return jsonDecode(str);
      } catch (e) {
        return str;
      }
    }
    
    return result;
  }

  /// 释放资源
  void dispose() {
    _runtime?.dispose();
    _runtime = null;
    _initialized = false;
  }

  /// 重置引擎
  Future<void> reset() async {
    dispose();
    await _ensureInitialized();
  }
}

/// 全局 JS 引擎实例
final jsEngine = JsEngine();
