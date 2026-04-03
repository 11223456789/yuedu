import 'dart:convert';
import 'package:flutter_js/flutter_js.dart';
import 'package:http/http.dart' as http;
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
    // 使用原始字符串避免 $ 转义问题
    final utils = r"""
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

        // 网络请求（调用 Dart 端）
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
    """;

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
  /// 
  /// 支持多种模式：AES/CBC/PKCS5Padding, AES/ECB/PKCS5Padding 等
  Future<String> _aesDecrypt(String data, String key, String transformation, String iv) async {
    try {
      print('AES 解密: data=$data, key=$key, transformation=$transformation, iv=$iv');
      
      // 解析 transformation 字符串 (如 "AES/CBC/PKCS5Padding")
      final parts = transformation.split('/');
      if (parts.length < 2) {
        print('不支持的 transformation: $transformation');
        return data;
      }
      
      final mode = parts[1]; // CBC, ECB, etc.
      final padding = parts.length > 2 ? parts[2] : 'PKCS5Padding';
      
      // Base64 解码数据
      final encryptedBytes = base64Decode(data);
      final keyBytes = utf8.encode(key);
      final ivBytes = utf8.encode(iv);
      
      // 创建 AES 密钥
      final aesKey = encrypt.Key(keyBytes);
      final aesIV = encrypt.IV(ivBytes);
      
      // 根据模式选择加密器
      late final encrypt.Encrypter encrypter;
      
      if (mode == 'CBC') {
        encrypter = encrypt.Encrypter(
          encrypt.AES(aesKey, mode: encrypt.AESMode.cbc, padding: padding.toLowerCase()),
        );
      } else if (mode == 'ECB') {
        encrypter = encrypt.Encrypter(
          encrypt.AES(aesKey, mode: encrypt.AESMode.ecb, padding: padding.toLowerCase()),
        );
      } else if (mode == 'CFB') {
        encrypter = encrypt.Encrypter(
          encrypt.AES(aesKey, mode: encrypt.AESMode.cfb64, padding: padding.toLowerCase()),
        );
      } else if (mode == 'OFB') {
        encrypter = encrypt.Encrypter(
          encrypt.AES(aesKey, mode: encrypt.AESMode.ofb64Gctr, padding: padding.toLowerCase()),
        );
      } else if (mode == 'CTR') {
        encrypter = encrypt.Encrypter(
          encrypt.AES(aesKey, mode: encrypt.AESMode.ctr, padding: padding.toLowerCase()),
        );
      } else {
        // 默认使用 CBC
        encrypter = encrypt.Encrypter(
          encrypt.AES(aesKey, mode: encrypt.AESMode.cbc, padding: 'pkcs7'),
        );
      }
      
      // 解密
      final encrypted = encrypt.Encrypted(encryptedBytes);
      final decrypted = encrypter.decrypt(encrypted, iv: aesIV);
      
      print('AES 解密成功');
      return decrypted;
    } catch (e) {
      print('AES 解密失败: $e');
      // 如果解密失败，返回原始数据
      return data;
    }
  }

  /// AJAX 请求
  /// 
  /// 支持 GET/POST 请求，支持自定义 headers 和 body
  Future<String> _ajaxRequest(String url) async {
    try {
      print('AJAX 请求: $url');
      
      // 解析 URL 和选项
      String requestUrl = url;
      String method = 'GET';
      Map<String, String> headers = {};
      String? body;
      
      // 检查是否包含选项（逗号分隔）
      if (url.contains(',')) {
        final commaIndex = url.indexOf(',');
        requestUrl = url.substring(0, commaIndex).trim();
        final optionsStr = url.substring(commaIndex + 1).trim();
        
        // 解析选项 JSON
        try {
          final options = jsonDecode(optionsStr);
          if (options is Map) {
            // 解析 method
            if (options['method'] != null) {
              method = options['method'].toString().toUpperCase();
            }
            
            // 解析 headers
            if (options['headers'] != null) {
              final headersObj = options['headers'];
              if (headersObj is Map) {
                headersObj.forEach((key, value) {
                  headers[key.toString()] = value.toString();
                });
              } else if (headersObj is String) {
                // 尝试解析 JSON 字符串
                try {
                  final headersMap = jsonDecode(headersObj);
                  if (headersMap is Map) {
                    headersMap.forEach((key, value) {
                      headers[key.toString()] = value.toString();
                    });
                  }
                } catch (_) {}
              }
            }
            
            // 解析 body
            if (options['body'] != null) {
              body = options['body'].toString();
            }
          }
        } catch (e) {
          print('解析 AJAX 选项失败: $e');
        }
      }
      
      // 设置默认 User-Agent
      if (!headers.containsKey('User-Agent')) {
        headers['User-Agent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36';
      }
      
      // 发送请求
      late final http.Response response;
      
      if (method == 'POST') {
        response = await http.post(
          Uri.parse(requestUrl),
          headers: headers,
          body: body,
        );
      } else if (method == 'PUT') {
        response = await http.put(
          Uri.parse(requestUrl),
          headers: headers,
          body: body,
        );
      } else if (method == 'DELETE') {
        response = await http.delete(
          Uri.parse(requestUrl),
          headers: headers,
        );
      } else {
        // GET 请求
        response = await http.get(
          Uri.parse(requestUrl),
          headers: headers,
        );
      }
      
      print('AJAX 请求成功: ${response.statusCode}');
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
