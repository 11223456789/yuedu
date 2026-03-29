import 'dart:convert';
import 'package:dio/dio.dart';
import '../../help/http/http_client.dart';

/// 解析书源规则中的 URL 字符串，支持 GET/POST、变量替换、Header 注入
class AnalyzeUrl {
  final String url;
  final String method;
  final Map<String, String> headers;
  final dynamic body;
  final String? charset;
  final Map<String, String> variables;

  AnalyzeUrl._({
    required this.url,
    required this.method,
    required this.headers,
    this.body,
    this.charset,
    required this.variables,
  });

  /// 从规则字符串解析 AnalyzeUrl
  /// 格式：url,{header:{...},method:POST,body:...,charset:utf-8}
  factory AnalyzeUrl.fromRule(
    String ruleUrl, {
    String? baseUrl,
    Map<String, String>? sourceHeaders,
    Map<String, String>? variables,
  }) {
    final vars = variables ?? {};
    String processedUrl = _replaceVariables(ruleUrl.trim(), vars);

    String method = 'GET';
    Map<String, String> headers = Map.from(sourceHeaders ?? {});
    dynamic body;
    String? charset;

    // 解析 URL 后面的 JSON 配置 {header:{...},method:POST,...}
    final configMatch = RegExp(r',\s*(\{.*\})\s*$').firstMatch(processedUrl);
    if (configMatch != null) {
      processedUrl = processedUrl.substring(0, configMatch.start).trim();
      try {
        final config = jsonDecode(configMatch.group(1)!) as Map<String, dynamic>;
        if (config['method'] != null) {
          method = (config['method'] as String).toUpperCase();
        }
        if (config['header'] != null) {
          final h = config['header'];
          if (h is Map) {
            h.forEach((k, v) => headers[k.toString()] = v.toString());
          } else if (h is String) {
            // header 可能是 JSON 字符串
            try {
              final hMap = jsonDecode(h) as Map;
              hMap.forEach((k, v) => headers[k.toString()] = v.toString());
            } catch (_) {}
          }
        }
        if (config['body'] != null) {
          body = config['body'];
          if (body is Map) {
            body = body.entries.map((e) => '${e.key}=${e.value}').join('&');
          }
        }
        if (config['charset'] != null) {
          charset = config['charset'] as String;
        }
      } catch (_) {}
    }

    // 处理相对 URL
    if (baseUrl != null && !processedUrl.startsWith('http')) {
      processedUrl = _resolveUrl(baseUrl, processedUrl);
    }

    return AnalyzeUrl._(
      url: processedUrl,
      method: method,
      headers: headers,
      body: body,
      charset: charset,
      variables: vars,
    );
  }

  /// 发起 HTTP 请求
  Future<Response<String>> getResponse({String? concurrentRate}) {
    final client = AppHttpClient();
    if (method == 'POST') {
      return client.post(
        url,
        data: body,
        headers: headers,
        concurrentRate: concurrentRate,
      );
    } else {
      return client.get(
        url,
        headers: headers,
        concurrentRate: concurrentRate,
      );
    }
  }

  /// 替换 {变量名} 占位符
  static String _replaceVariables(String text, Map<String, String> vars) {
    return text.replaceAllMapped(RegExp(r'\{(\w+)\}'), (m) {
      return vars[m.group(1)] ?? m.group(0)!;
    });
  }

  /// 解析相对 URL
  static String _resolveUrl(String base, String relative) {
    try {
      return Uri.parse(base).resolve(relative).toString();
    } catch (_) {
      return relative;
    }
  }
}
