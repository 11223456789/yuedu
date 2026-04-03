import 'dart:convert';
import 'package:flutter_js/flutter_js.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

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

    // 注入 legado 兼容的工具函数
    await _injectLegadoUtils();

    _initialized = true;
  }

  /// 注入 legado 兼容的工具函数
  Future<void> _injectLegadoUtils() async {
    final utils = '''
      // 基础工具对象
      var java = {
        // 日志输出
        log: function(msg) {
          console.log(msg);
          return msg;
        },

        // 字符串转整数
        parseInt: function(str) {
          return parseInt(str) || 0;
        },

        // 字符串转浮点数
        parseFloat: function(str) {
          return parseFloat(str) || 0;
        },

        // 获取字符串（兼容）
        getString: function(obj) {
          if (typeof obj === 'string') return obj;
          if (obj === null || obj === undefined) return '';
          return JSON.stringify(obj);
        },

        // 时间格式化（简化版）
        timeFormat: function(timestamp) {
          if (!timestamp) return '';
          var date = new Date(parseInt(timestamp));
          return date.toLocaleString();
        },

        // URL 编码
        encodeURIComponent: function(str) {
          return encodeURIComponent(str);
        },

        // URL 解码
        decodeURIComponent: function(str) {
          return decodeURIComponent(str);
        },

        // Base64 编码
        base64Encode: function(str) {
          return btoa(str);
        },

        // Base64 解码
        base64Decode: function(str) {
          return atob(str);
        },

        // AES 解密（调用 Dart 端）
        aesBase64DecodeToString: function(data, key, transformation, iv) {
          // 标记需要 Dart 端处理
          return '__AES_DECRYPT__:' + JSON.stringify({
            data: data,
            key: key,
            transformation: transformation,
            iv: iv
          });
        },

        // 网络请求（简化版，调用 Dart 端）
        ajax: function(url) {
          // 标记需要 Dart 端处理
          return '__AJAX__:' + url;
        },

        // 获取登录信息（占位）
        getLoginInfoMap: function() {
          return {};
        },

        // 获取书源 key（占位）
        getKey: function() {
          return '';
        },

        // 设置登录 header（占位）
        putLoginHeader: function(header) {
          console.log('Login header:', header);
        }
      };

      // 全局函数
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

      // 兼容旧版 String 方法
      if (!String.prototype.trim) {
        String.prototype.trim = function() {
          return this.replace(/^\s+|\s+$/g, '');
        };
      }
    ''';

    await _runtime!.evaluate(utils);
  }

  /// 执行 JavaScript 代码
  ///
  /// [code] - JS 代码
  /// [input] - 输入数据（可通过 input/result 变量访问）
  /// [baseUrl] - 基础 URL
  Future<dynamic> eval(String code, {dynamic input, String? baseUrl}) async {
    await _ensureInitialized();

    try {
      // 设置输入变量
      final inputJson = input != null ? jsonEncode(input) : '""';
      await _runtime!.evaluate('var input = $inputJson;');
      await _runtime!.evaluate('var result = $inputJson;');
      if (baseUrl != null) {
        await _runtime!.evaluate('var baseUrl = "$baseUrl";');
      }

      // 执行代码
      final wrappedCode = '''
        (function() {
          try {
            $code
            return result !== undefined ? result : input;
          } catch(e) {
            console.error('JS Error:', e.message);
            return 'Error: ' + e.message;
          }
        })()
      ''';

      final result = await _runtime!.evaluate(wrappedCode);

      // 处理需要 Dart 端特殊处理的结果
      final processedResult = await _processSpecialResults(result);

      return _convertResult(processedResult);
    } catch (e) {
      print('JS 执行错误: $e');
      return input?.toString() ?? '';
    }
  }

  /// 处理特殊结果（如 AES 解密、AJAX 请求等）
  Future<dynamic> _processSpecialResults(dynamic result) async {
    if (result == null) return null;

    final resultStr = result.toString();

    // 处理 AES 解密请求
    if (resultStr.startsWith('__AES_DECRYPT__:')) {
      try {
        final jsonStr = resultStr.substring('__AES_DECRYPT__:'.length);
        final params = jsonDecode(jsonStr);
        return await _aesDecrypt(
          params['data'],
          params['key'],
          params['transformation'],
          params['iv'],
        );
      } catch (e) {
        print('AES 解密错误: $e');
        return resultStr;
      }
    }

    // 处理 AJAX 请求
    if (resultStr.startsWith('__AJAX__:')) {
      try {
        final url = resultStr.substring('__AJAX__:'.length);
        return await _ajaxRequest(url);
      } catch (e) {
        print('AJAX 请求错误: $e');
        return resultStr;
      }
    }

    return result;
  }

  /// AES 解密
  Future<String> _aesDecrypt(String data, String key, String transformation, String iv) async {
    try {
      // 这里需要实现 AES 解密
      // 由于加密算法复杂，先返回占位符
      print('AES 解密请求: data=$data, key=$key, transformation=$transformation, iv=$iv');
      return data; // 暂时返回原数据
    } catch (e) {
      print('AES 解密失败: $e');
      return data;
    }
  }

  /// AJAX 请求
  Future<String> _ajaxRequest(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      return response.body;
    } catch (e) {
      print('AJAX 请求失败: $e');
      return '';
    }
  }

  /// 执行带有 @js: 前缀的代码
  Future<dynamic> evalJsPrefix(String code, {dynamic input, String? baseUrl}) async {
    if (code.startsWith('@js:')) {
      code = code.substring(4);
    }
    return eval(code, input: input, baseUrl: baseUrl);
  }

  /// 执行 {{}} 内的 JS 代码
  Future<String> evalInlineJs(String code, {dynamic input, String? baseUrl}) async {
    final result = await eval(code, input: input, baseUrl: baseUrl);
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
