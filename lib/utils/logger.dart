import 'dart:io';
import 'package:path_provider/path_provider.dart';

class Logger {
  static final Logger _instance = Logger._internal();
  factory Logger() => _instance;
  Logger._internal();

  File? _logFile;
  final List<String> _logBuffer = [];
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    
    try {
      final dir = await getApplicationDocumentsDirectory();
      _logFile = File('${dir.path}/app.log');
      
      // 写入启动标记
      await _writeLog('=== App Started at ${DateTime.now()} ===\n');
      _initialized = true;
    } catch (e) {
      print('Logger init error: $e');
    }
  }

  void log(String tag, String message) {
    final line = '[${DateTime.now()}] [$tag] $message';
    _logBuffer.add(line);
    print(line);
    
    // 实时写入文件
    _writeLog('$line\n');
  }

  Future<void> _writeLog(String text) async {
    try {
      if (_logFile != null) {
        await _logFile!.writeAsString(text, mode: FileMode.append);
      }
    } catch (e) {
      print('Write log error: $e');
    }
  }

  Future<String> getLogPath() async {
    if (_logFile != null) {
      return _logFile!.path;
    }
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/app.log';
  }

  Future<String> getLogContent() async {
    try {
      if (_logFile != null && await _logFile!.exists()) {
        return await _logFile!.readAsString();
      }
    } catch (e) {
      return 'Error reading log: $e';
    }
    return '';
  }

  void clear() {
    _logBuffer.clear();
    try {
      _logFile?.writeAsStringSync('=== Log Cleared at ${DateTime.now()} ===\n');
    } catch (e) {
      print('Clear log error: $e');
    }
  }
}

// 全局日志函数
void logInfo(String tag, String message) {
  Logger().log(tag, message);
}

void logError(String tag, String message) {
  Logger().log(tag, 'ERROR: $message');
}
