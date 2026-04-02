import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

/// 日志级别
enum LogLevel {
  debug,
  info,
  warning,
  error,
  fatal,
}

/// 日志条目
class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final String? tag;
  final StackTrace? stackTrace;
  final dynamic error;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.tag,
    this.stackTrace,
    this.error,
  });

  String toFormattedString() {
    final timeStr = DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(timestamp);
    final levelStr = level.name.toUpperCase().padRight(7);
    final tagStr = tag != null ? '[$tag] ' : '';
    var result = '$timeStr $levelStr $tagStr$message';
    
    if (error != null) {
      result += '\nError: $error';
    }
    if (stackTrace != null) {
      result += '\nStackTrace:\n$stackTrace';
    }
    
    return result;
  }
}

/// 日志服务
class LoggerService {
  static final LoggerService _instance = LoggerService._internal();
  factory LoggerService() => _instance;
  LoggerService._internal();

  static LoggerService get instance => _instance;

  // 配置
  LogLevel _minLevel = kDebugMode ? LogLevel.debug : LogLevel.info;
  bool _writeToFile = !kDebugMode;
  int _maxLogFiles = 7; // 保留7天日志
  int _maxFileSize = 10 * 1024 * 1024; // 10MB

  // 日志文件
  File? _logFile;
  IOSink? _logSink;
  final List<LogEntry> _recentLogs = [];
  static const int _maxRecentLogs = 100;

  /// 初始化日志服务
  Future<void> init() async {
    if (!_writeToFile) return;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final logDir = Directory('${directory.path}/logs');
      
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }

      // 清理旧日志
      await _cleanOldLogs(logDir);

      // 创建新日志文件
      final dateStr = DateFormat('yyyyMMdd').format(DateTime.now());
      _logFile = File('${logDir.path}/app_$dateStr.log');
      _logSink = _logFile!.openWrite(mode: FileMode.append);

      info('LoggerService', '日志服务初始化完成');
    } catch (e) {
      debugPrint('日志服务初始化失败: $e');
    }
  }

  /// 清理旧日志文件
  Future<void> _cleanOldLogs(Directory logDir) async {
    try {
      final files = await logDir.list().toList();
      final now = DateTime.now();
      
      for (final file in files) {
        if (file is File) {
          final stat = await file.stat();
          final age = now.difference(stat.modified);
          
          // 删除超过7天的日志
          if (age.inDays > _maxLogFiles) {
            await file.delete();
          }
          // 删除超过10MB的日志
          else if (stat.size > _maxFileSize) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      debugPrint('清理旧日志失败: $e');
    }
  }

  /// 关闭日志服务
  Future<void> dispose() async {
    await _logSink?.close();
    _logSink = null;
    _logFile = null;
  }

  /// 设置最小日志级别
  void setMinLevel(LogLevel level) {
    _minLevel = level;
  }

  /// 记录日志
  void _log(
    LogLevel level,
    String tag,
    String message, {
    dynamic error,
    StackTrace? stackTrace,
  }) {
    // 检查日志级别
    if (level.index < _minLevel.index) return;

    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      message: message,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
    );

    // 添加到最近日志
    _recentLogs.add(entry);
    if (_recentLogs.length > _maxRecentLogs) {
      _recentLogs.removeAt(0);
    }

    // 输出到控制台
    _outputToConsole(entry);

    // 写入文件
    if (_writeToFile && _logSink != null) {
      _logSink!.writeln(entry.toFormattedString());
    }
  }

  /// 输出到控制台
  void _outputToConsole(LogEntry entry) {
    final emoji = _getLevelEmoji(entry.level);
    final output = '$emoji [${entry.tag}] ${entry.message}';

    switch (entry.level) {
      case LogLevel.debug:
        debugPrint('\x1B[36m$output\x1B[0m'); // 青色
        break;
      case LogLevel.info:
        debugPrint('\x1B[32m$output\x1B[0m'); // 绿色
        break;
      case LogLevel.warning:
        debugPrint('\x1B[33m$output\x1B[0m'); // 黄色
        break;
      case LogLevel.error:
        debugPrint('\x1B[31m$output\x1B[0m'); // 红色
        if (entry.error != null) {
          debugPrint('\x1B[31mError: ${entry.error}\x1B[0m');
        }
        break;
      case LogLevel.fatal:
        debugPrint('\x1B[35m$output\x1B[0m'); // 紫色
        if (entry.error != null) {
          debugPrint('\x1B[35mError: ${entry.error}\x1B[0m');
        }
        if (entry.stackTrace != null) {
          debugPrint('\x1B[35mStackTrace:\n${entry.stackTrace}\x1B[0m');
        }
        break;
    }
  }

  String _getLevelEmoji(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '🐛';
      case LogLevel.info:
        return 'ℹ️';
      case LogLevel.warning:
        return '⚠️';
      case LogLevel.error:
        return '❌';
      case LogLevel.fatal:
        return '💥';
    }
  }

  // 便捷方法
  void debug(String tag, String message) => _log(LogLevel.debug, tag, message);
  void info(String tag, String message) => _log(LogLevel.info, tag, message);
  void warning(String tag, String message) => _log(LogLevel.warning, tag, message);
  
  void error(
    String tag,
    String message, {
    dynamic error,
    StackTrace? stackTrace,
  }) => _log(LogLevel.error, tag, message, error: error, stackTrace: stackTrace);
  
  void fatal(
    String tag,
    String message, {
    dynamic error,
    StackTrace? stackTrace,
  }) => _log(LogLevel.fatal, tag, message, error: error, stackTrace: stackTrace);

  /// 获取最近日志
  List<LogEntry> getRecentLogs({int count = 50}) {
    if (count >= _recentLogs.length) {
      return List.unmodifiable(_recentLogs);
    }
    return List.unmodifiable(_recentLogs.sublist(_recentLogs.length - count));
  }

  /// 获取日志文件路径
  String? get logFilePath => _logFile?.path;

  /// 导出日志
  Future<String?> exportLogs() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final exportDir = Directory('${directory.path}/exports');
      
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final exportFile = File('${exportDir.path}/logs_$timestamp.txt');

      final buffer = StringBuffer();
      buffer.writeln('===== 佩宇书屋日志导出 =====');
      buffer.writeln('导出时间: ${DateTime.now()}');
      buffer.writeln('==========================\n');

      for (final entry in _recentLogs) {
        buffer.writeln(entry.toFormattedString());
        buffer.writeln();
      }

      await exportFile.writeAsString(buffer.toString());
      return exportFile.path;
    } catch (e) {
      error('LoggerService', '导出日志失败', error: e);
      return null;
    }
  }
}

/// 全局日志便捷函数
void logDebug(String tag, String message) => LoggerService.instance.debug(tag, message);
void logInfo(String tag, String message) => LoggerService.instance.info(tag, message);
void logWarning(String tag, String message) => LoggerService.instance.warning(tag, message);
void logError(
  String tag,
  String message, {
  dynamic error,
  StackTrace? stackTrace,
}) => LoggerService.instance.error(tag, message, error: error, stackTrace: stackTrace);
