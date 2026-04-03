import 'dart:convert';
import 'js_engine.dart';
import '../../data/database/daos/book_source_dao.dart' show BookSource;

/// URL 解析器（复刻 legado 的 AnalyzeUrl）
class AnalyzeUrl {
  final JsEngine _jsEngine = JsEngine();
  
  /// 解析 URL
  /// 支持格式：
  /// - 普通字符串直接返回
  /// - {key} 变量替换（从变量 map 中取值）
  /// - {{js}} JS 表达式执行
  /// - @get:{rule} 嵌套规则获取
  Future<String> analyzeUrl(
    String url, {
    Map<String, String>? variables,
    dynamic Function(String)? getString,
    bool encode = true,
  }) async {
    if (url.isEmpty) return '';
    
    // 处理 {{js}} 和 {key}
    var result = await _replaceVariables(url, variables: variables, getString: getString);
    
    // URL 编码处理（只编码特殊字符，保留已有编码）
    if (encode && result.isNotEmpty) {
      result = _smartEncode(result);
    }
    
    return result;
  }

  /// 替换 URL 中的变量和 JS 表达式
  Future<String> _replaceVariables(
    String url, {
    Map<String, String>? variables,
    dynamic Function(String)? getString,
  }) async {
    if (!url.contains('{')) return url;

    final buffer = StringBuffer();
    int i = 0;
    
    while (i < url.length) {
      if (url[i] == '{') {
        // 检查是 {{js}} 还是 {key}
        if (i + 1 < url.length && url[i + 1] == '{') {
          // {{js}} 模式
          final endIdx = url.indexOf('}}', i + 2);
          if (endIdx != -1) {
            final jsExpr = url.substring(i + 2, endIdx);
            final jsResult = await _evalJsExpr(jsExpr, variables: variables, getString: getString);
            buffer.write(jsResult?.toString() ?? '');
            i = endIdx + 2;
            continue;
          }
        }
        
        // {key} 或 @get:{...} 模式
        final endIdx = url.indexOf('}', i + 1);
        if (endIdx != -1) {
          final key = url.substring(i + 1, endIdx);
          
          if (key.startsWith('@get:')) {
            // @get:{rule} 嵌套规则
            final ruleName = key.substring(5);
            if (getString != null) {
              final value = await getString(ruleName);
              buffer.write(value ?? '');
            } else {
              buffer.write('');
            }
          } else if (variables != null && variables.containsKey(key)) {
            // 从变量 map 获取
            buffer.write(variables[key]!);
          } else {
            // 保留原始文本
            buffer.write('{$key}');
          }
          
          i = endIdx + 1;
          continue;
        }
      }
      
      buffer.write(url[i]);
      i++;
    }

    return buffer.toString();
  }

  /// 执行 JS 表达式
  Future<dynamic> _evalJsExpr(
    String expr, {
    Map<String, String>? variables,
    dynamic Function(String)? getString,
  }) async {
    if (expr.isEmpty) return null;
    
    // 构建上下文
    final context = <String, dynamic>{};
    if (variables != null) {
      context.addAll(variables);
    }
    
    try {
      return await _jsEngine.eval(expr, context: context);
    } catch (_) {
      return null;
    }
  }

  /// 智能 URL 编码（只编码需要编码的部分）
  String _smartEncode(String url) {
    // 如果已经是完整 URL，不进行整体编码
    if (url.startsWith('http://') || url.startsWith('https://')) {
      // 只对查询参数中的特殊字符编码
      final uriParts = url.split('?');
      if (uriParts.length > 1) {
        final base = uriParts[0];
        final query = uriParts.sublist(1).join('?');
        
        // 对查询参数进行编码
        final encodedQuery = query.split('&').map((param) {
          final eqIdx = param.indexOf('=');
          if (eqIdx != -1) {
            final key = param.substring(0, eqIdx);
            var value = param.substring(eqIdx + 1);
            
            // 只对值部分中需要编码的字符编码
            value = Uri.encodeComponent(Uri.decodeComponent(value));
            return '$key=$value';
          }
          return param;
        }).join('&');
        
        return '$base?$encodedQuery';
      }
      
      return url;
    }
    
    // 非完整 URL，进行标准编码
    try {
      return Uri.encodeFull(url);
    } catch (_) {
      return url;
    }
  }

  /// 分析 URL 列表（支持多 URL）
  Future<List<String>> analyzeUrlList(
    String urlStr, {
    Map<String, String>? variables,
    dynamic Function(String)? getString,
  }) async {
    if (urlStr.isEmpty) return [];
    
    // 支持换行分隔的多 URL
    final urls = urlStr.split(RegExp(r'[\n\r]+')).where((s) => s.trim().isNotEmpty).toList();
    
    final results = <String>[];
    for (final url in urls) {
      final analyzed = await analyzeUrl(
        url.trim(),
        variables: variables,
        getString: getString,
      );
      if (analyzed.isNotEmpty) {
        results.add(analyzed);
      }
    }
    
    return results;
  }

  /// 构建 POST 请求体
  Future<Map<String, dynamic>> analyzePostBody(
    String body, {
    Map<String, String>? variables,
    dynamic Function(String)? getString,
  }) async {
    if (body.isEmpty) return {};
    
    // 尝试 JSON 格式
    if (body.trim().startsWith('{') || body.trim().startsWith('[')) {
      try {
        final processedBody = await _replaceVariables(body, 
          variables: variables, 
          getString: getString
        );
        return jsonDecode(processedBody) as Map<String, dynamic>;
      } catch (_) {}
    }
    
    // 表单格式
    final processedBody = await _replaceVariables(body, 
      variables: variables, 
      getString: getString
    );
    
    final params = <String, String>{};
    final pairs = processedBody.split('&');
    for (final pair in pairs) {
      final eqIdx = pair.indexOf('=');
      if (eqIdx != -1) {
        final key = pair.substring(0, eqIdx).trim();
        final value = pair.substring(eqIdx + 1).trim();
        if (key.isNotEmpty) {
          params[key] = value;
        }
      }
    }
    
    return params;
  }

  /// 解析请求头
  Future<Map<String, String>> analyzeHeaders(
    String headersStr, {
    Map<String, String>? variables,
    dynamic Function(String)? getString,
  }) async {
    if (headersStr.isEmpty) return {};
    
    final headers = <String, String>{};
    final lines = headersStr.split(RegExp(r'[\n\r]+'));
    
    for (final line in lines) {
      final colonIdx = line.indexOf(':');
      if (colonIdx != -1) {
        var key = line.substring(0, colonIdx).trim();
        var value = line.substring(colonIdx + 1).trim();
        
        // 替换变量
        key = await _replaceVariables(key, variables: variables, getString: getString);
        value = await _replaceVariables(value, variables: variables, getString: getString);
        
        if (key.isNotEmpty) {
          headers[key] = value;
        }
      }
    }
    
    return headers;
  }
}
