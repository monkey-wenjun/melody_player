import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'app.dart';
import 'di/service_locator.dart';
import 'services/audio_handler.dart';
import 'services/audio_player_service.dart';
import 'utils/logger.dart';

// 全局 AudioHandler 实例
late final MyAudioHandler audioHandler;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化日志
  await Logger().init();
  logInfo('Main', 'App starting...');
  
  // 初始化依赖注入
  setupLocator();
  
  // 配置音频会话
  try {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    logInfo('Main', 'Audio session configured');
  } catch (e) {
    logInfo('Main', 'Audio session init error: $e');
  }
  
  // 初始化后台播放服务
  try {
    audioHandler = await AudioService.init(
      builder: () => MyAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.melody.channel.audio',
        androidNotificationChannelName: '悦音播放服务',
        androidNotificationOngoing: false,
        androidStopForegroundOnPause: false,  // 暂停时也不停止前台服务，确保后台播放
        androidNotificationClickStartsActivity: true,
      ),
    );
    // 设置全局 handler 供 AudioPlayerService 使用
    setGlobalAudioHandler(audioHandler);
    logInfo('Main', 'Background audio initialized');
  } catch (e) {
    logInfo('Main', 'Background audio init error: $e');
    // 降级方案：创建一个非后台的 handler
    audioHandler = MyAudioHandler();
    setGlobalAudioHandler(audioHandler);
  }
  
  runApp(const MelodyApp());
}
