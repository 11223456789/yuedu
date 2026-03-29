import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import '../../help/http/http_client.dart';

/// JavaScript 执行引擎（模拟 legado 的 JsExtensions）
class JsEngine {
  static final JsEngine _instance = JsEngine._();
  factory JsEngine() => _instance;
  JsEngine._();

  // TODO: 集成 flutter_js 包后实现真实的 JS 执行
  // 目前提供基础的 JS 扩展函数模拟

  final Map<String, dynamic> _context = {};

  /// 设置 JS 上下文变量
  void setContext(Map<String, dynamic> context) {
    _context.addAll(context);
  }

  /// 清除上下文
  void clearContext() {
    _context.clear();
  }

  /// 执行 JS 代码
  Future<String?> eval(String jsStr, {Map<String, dynamic>? context}) async {
    if (context != null) {
      _context.addAll(context);
    }

    // 简单的 JS 扩展函数模拟
    // 实际项目中应使用 flutter_js 执行真实 JS
    try {
      // 模拟一些简单的 JS 函数
      if (jsStr.contains('base64Encode')) {
        final match = RegExp(r'base64Encode\((.*?)\)').firstMatch(jsStr);
        if (match != null) {
          final input = _evalSimple(match.group(1)!);
          final bytes = utf8.encode(input.toString());
          return base64.encode(bytes);
        }
      }
      if (jsStr.contains('base64Decode')) {
        final match = RegExp(r'base64Decode\((.*?)\)').firstMatch(jsStr);
        if (match != null) {
          final input = _evalSimple(match.group(1)!);
          final bytes = base64.decode(input.toString());
          return utf8.decode(bytes);
        }
      }
      if (jsStr.contains('md5Encode')) {
        final match = RegExp(r'md5Encode\((.*?)\)').firstMatch(jsStr);
        if (match != null) {
          final input = _evalSimple(match.group(1)!);
          return md5.convert(utf8.encode(input.toString())).toString();
        }
      }
      // 简单返回字符串
      if (jsStr.startsWith('"') || jsStr.startsWith("'")) {
        return jsStr.substring(1, jsStr.length - 1);
      }
      return jsStr;
    } catch (e) {
      return null;
    }
  }

  dynamic _evalSimple(String expr) {
    expr = expr.trim();
    // 字符串字面量
    if ((expr.startsWith('"') && expr.endsWith('"')) ||
        (expr.startsWith("'") && expr.endsWith("'"))) {
      return expr.substring(1, expr.length - 1);
    }
    // 上下文变量
    if (_context.containsKey(expr)) {
      return _context[expr];
    }
    return expr;
  }

  // ========== JS 扩展函数（对应 legado JsExtensions）==========

  /// AJAX 请求
  Future<String?> ajax(
    String url, {
    String method = 'GET',
    Map<String, String>? headers,
    dynamic body,
  }) async {
    try {
      final client = AppHttpClient();
      final response = method.toUpperCase() == 'POST'
          ? await client.post(url, data: body, headers: headers)
          : await client.get(url, headers: headers);
      return response.data;
    } catch (_) {
      return null;
    }
  }

  /// Base64 编码
  String base64Encode(String input) {
    return base64.encode(utf8.encode(input));
  }

  /// Base64 解码
  String base64Decode(String input) {
    return utf8.decode(base64.decode(input));
  }

  /// MD5 编码
  String md5Encode(String input) {
    return md5.convert(utf8.encode(input)).toString();
  }

  /// AES 加密（简化版）
  String encrypt(String input, String key) {
    // 简化实现，实际应使用 encrypt 包
    final keyBytes = utf8.encode(key.padRight(16, '\x00')).sublist(0, 16);
    final inputBytes = utf8.encode(input);
    final result = <int>[];
    for (int i = 0; i < inputBytes.length; i++) {
      result.add(inputBytes[i] ^ keyBytes[i % 16]);
    }
    return base64.encode(result);
  }

  /// AES 解密（简化版）
  String decrypt(String input, String key) {
    try {
      final keyBytes = utf8.encode(key.padRight(16, '\x00')).sublist(0, 16);
      final inputBytes = base64.decode(input);
      final result = <int>[];
      for (int i = 0; i < inputBytes.length; i++) {
        result.add(inputBytes[i] ^ keyBytes[i % 16]);
      }
      return utf8.decode(result);
    } catch (_) {
      return '';
    }
  }
}
