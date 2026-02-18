import 'dart:io';
import '../models/song.dart';

/// 音频转码服务 - 当前版本禁用转码，直接返回原文件
/// 后续版本可重新启用 FFmpeg 转码
class AudioTranscodeService {
  static final AudioTranscodeService _instance = AudioTranscodeService._internal();
  factory AudioTranscodeService() => _instance;
  AudioTranscodeService._internal();

  // 需要转码的格式
  final List<String> _transcodableFormats = ['wma', 'ape'];

  /// 初始化 - 当前版本无需初始化
  Future<void> init() async {
    // 禁用转码，无需初始化
  }

  /// 检查是否需要转码
  bool needsTranscode(String fileExtension) {
    return _transcodableFormats.contains(fileExtension.toLowerCase());
  }

  /// 获取转码后的文件路径 - 当前版本直接返回 null
  /// 表示该格式不支持播放
  Future<String?> getTranscodedPath(Song song) async {
    // 当前版本禁用转码，返回 null
    return null;
  }
}
