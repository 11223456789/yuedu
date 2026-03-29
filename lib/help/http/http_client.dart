import 'dart:async';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';

/// 全局 HTTP 客户端，支持 Cookie、重试、并发限速
class AppHttpClient {
  static final AppHttpClient _instance = AppHttpClient._();
  factory AppHttpClient() => _instance;
  AppHttpClient._() {
    _init();
  }

  late final Dio _dio;
  final CookieJar _cookieJar = CookieJar();

  // 并发限速：每个书源最多同时 N 个请求
  final Map<String, Semaphore> _semaphores = {};

  void _init() {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 15),
      followRedirects: true,
      maxRedirects: 5,
    ));
    _dio.interceptors.add(CookieManager(_cookieJar));
    _dio.interceptors.add(_RetryInterceptor(maxRetries: 3));
  }

  Dio get dio => _dio;

  /// 发起 GET 请求
  Future<Response<String>> get(
    String url, {
    Map<String, dynamic>? headers,
    Map<String, dynamic>? queryParameters,
    String? concurrentRate,
    CancelToken? cancelToken,
  }) async {
    final semaphore = _getSemaphore(url, concurrentRate);
    await semaphore.acquire();
    try {
      return await _dio.get<String>(
        url,
        queryParameters: queryParameters,
        options: Options(
          headers: headers,
          responseType: ResponseType.plain,
        ),
        cancelToken: cancelToken,
      );
    } finally {
      semaphore.release();
    }
  }

  /// 发起 POST 请求
  Future<Response<String>> post(
    String url, {
    dynamic data,
    Map<String, dynamic>? headers,
    String? concurrentRate,
    CancelToken? cancelToken,
  }) async {
    final semaphore = _getSemaphore(url, concurrentRate);
    await semaphore.acquire();
    try {
      return await _dio.post<String>(
        url,
        data: data,
        options: Options(
          headers: headers,
          responseType: ResponseType.plain,
        ),
        cancelToken: cancelToken,
      );
    } finally {
      semaphore.release();
    }
  }

  /// 下载字节流（用于音频/图片）
  Future<Response<List<int>>> getBytes(
    String url, {
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
  }) {
    return _dio.get<List<int>>(
      url,
      options: Options(
        headers: headers,
        responseType: ResponseType.bytes,
      ),
      cancelToken: cancelToken,
    );
  }

  Semaphore _getSemaphore(String url, String? concurrentRate) {
    final host = Uri.tryParse(url)?.host ?? url;
    final maxConcurrent = _parseConcurrentRate(concurrentRate);
    return _semaphores.putIfAbsent(host, () => Semaphore(maxConcurrent));
  }

  int _parseConcurrentRate(String? rate) {
    if (rate == null || rate.isEmpty) return 5;
    // 格式：数字 或 数字/秒
    final n = int.tryParse(rate.split('/').first.trim());
    return (n != null && n > 0) ? n.clamp(1, 20) : 5;
  }

  /// 清除指定域名的 Cookie
  Future<void> clearCookies(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      await _cookieJar.delete(uri);
    }
  }

  /// 获取指定域名的 Cookie 字符串
  Future<String> getCookieString(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return '';
    final cookies = await _cookieJar.loadForRequest(uri);
    return cookies.map((c) => '${c.name}=${c.value}').join('; ');
  }
}

/// 简单信号量，用于并发限速
class Semaphore {
  final int maxCount;
  int _count = 0;
  final List<Completer<void>> _waiters = [];

  Semaphore(this.maxCount);

  Future<void> acquire() async {
    if (_count < maxCount) {
      _count++;
      return;
    }
    final completer = Completer<void>();
    _waiters.add(completer);
    await completer.future;
  }

  void release() {
    if (_waiters.isNotEmpty) {
      final next = _waiters.removeAt(0);
      next.complete();
    } else {
      _count--;
    }
  }
}

/// 自动重试拦截器
class _RetryInterceptor extends Interceptor {
  final int maxRetries;
  _RetryInterceptor({this.maxRetries = 3});

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final extra = err.requestOptions.extra;
    final retryCount = (extra['retryCount'] as int?) ?? 0;

    if (retryCount < maxRetries && _shouldRetry(err)) {
      err.requestOptions.extra['retryCount'] = retryCount + 1;
      await Future.delayed(Duration(milliseconds: 500 * (retryCount + 1)));
      try {
        final response = await AppHttpClient()._dio.fetch(err.requestOptions);
        handler.resolve(response);
        return;
      } catch (e) {
        // 继续传递错误
      }
    }
    handler.next(err);
  }

  bool _shouldRetry(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError;
  }
}
