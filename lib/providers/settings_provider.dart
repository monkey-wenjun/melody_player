import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppTheme { light, dark, system }
enum PlayerStyle { 
  vinyl, waveform, rotatingDisc, minimal,
  retroCassette, neonPulse, particleNebula, spectrumWaterfall,
  magicAura, equalizer, ripple, cyberpunk, card3D, cdCase
}

class SettingsProvider extends ChangeNotifier {
  static const String _themeKey = 'app_theme';
  static const String _scanPathsKey = 'scan_paths';
  static const String _autoScanKey = 'auto_scan';
  static const String _skipShortAudioKey = 'skip_short_audio';
  static const String _minDurationKey = 'min_duration';
  static const String _sleepTimerEnabledKey = 'sleep_timer_enabled';
  static const String _sleepTimerDurationKey = 'sleep_timer_duration';
  static const String _playerStyleKey = 'player_style';

  SharedPreferences? _prefs;
  
  // 设置项
  AppTheme _theme = AppTheme.system;
  List<String> _scanPaths = [];
  bool _autoScan = true;
  bool _skipShortAudio = true;
  int _minDuration = 30; // 秒
  bool _sleepTimerEnabled = false;
  int _sleepTimerDuration = 30; // 分钟
  PlayerStyle _playerStyle = PlayerStyle.vinyl;

  // Getters
  AppTheme get theme => _theme;
  List<String> get scanPaths => _scanPaths;
  bool get autoScan => _autoScan;
  bool get skipShortAudio => _skipShortAudio;
  int get minDuration => _minDuration;
  bool get sleepTimerEnabled => _sleepTimerEnabled;
  int get sleepTimerDuration => _sleepTimerDuration;
  PlayerStyle get playerStyle => _playerStyle;

  bool get hasCustomScanPaths => _scanPaths.isNotEmpty;

  ThemeMode get themeMode {
    switch (_theme) {
      case AppTheme.light:
        return ThemeMode.light;
      case AppTheme.dark:
        return ThemeMode.dark;
      case AppTheme.system:
        return ThemeMode.system;
    }
  }

  bool get isDarkMode => _theme == AppTheme.dark;
  bool get isLightMode => _theme == AppTheme.light;

  SettingsProvider() {
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadSettings();
  }

  void _loadSettings() {
    // 主题
    final themeIndex = _prefs?.getInt(_themeKey) ?? 2;
    _theme = AppTheme.values[themeIndex.clamp(0, AppTheme.values.length - 1)];
    
    // 扫描路径
    _scanPaths = _prefs?.getStringList(_scanPathsKey) ?? [];
    
    // 自动扫描
    _autoScan = _prefs?.getBool(_autoScanKey) ?? true;
    
    // 跳过低质量音频
    _skipShortAudio = _prefs?.getBool(_skipShortAudioKey) ?? true;
    
    // 最小时长
    _minDuration = _prefs?.getInt(_minDurationKey) ?? 30;
    
    // 定时播放
    _sleepTimerEnabled = _prefs?.getBool(_sleepTimerEnabledKey) ?? false;
    _sleepTimerDuration = _prefs?.getInt(_sleepTimerDurationKey) ?? 30;
    
    // 播放器样式
    final playerStyleIndex = _prefs?.getInt(_playerStyleKey) ?? 0;
    _playerStyle = PlayerStyle.values[playerStyleIndex.clamp(0, PlayerStyle.values.length - 1)];
    
    notifyListeners();
  }

  // 主题设置
  Future<void> setTheme(AppTheme theme) async {
    _theme = theme;
    await _prefs?.setInt(_themeKey, theme.index);
    notifyListeners();
  }

  void cycleTheme() {
    final nextIndex = (_theme.index + 1) % AppTheme.values.length;
    setTheme(AppTheme.values[nextIndex]);
  }

  // 扫描路径设置
  Future<void> addScanPath(String path) async {
    if (!_scanPaths.contains(path)) {
      _scanPaths.add(path);
      await _prefs?.setStringList(_scanPathsKey, _scanPaths);
      notifyListeners();
    }
  }

  Future<void> removeScanPath(String path) async {
    _scanPaths.remove(path);
    await _prefs?.setStringList(_scanPathsKey, _scanPaths);
    notifyListeners();
  }

  Future<void> clearScanPaths() async {
    _scanPaths.clear();
    await _prefs?.remove(_scanPathsKey);
    notifyListeners();
  }

  // 自动扫描设置
  Future<void> setAutoScan(bool value) async {
    _autoScan = value;
    await _prefs?.setBool(_autoScanKey, value);
    notifyListeners();
  }

  // 跳过短音频设置
  Future<void> setSkipShortAudio(bool value) async {
    _skipShortAudio = value;
    await _prefs?.setBool(_skipShortAudioKey, value);
    notifyListeners();
  }

  // 最小时长设置
  Future<void> setMinDuration(int seconds) async {
    _minDuration = seconds;
    await _prefs?.setInt(_minDurationKey, seconds);
    notifyListeners();
  }

  // 定时播放开关
  Future<void> setSleepTimerEnabled(bool value) async {
    _sleepTimerEnabled = value;
    await _prefs?.setBool(_sleepTimerEnabledKey, value);
    notifyListeners();
  }

  // 定时播放时长
  Future<void> setSleepTimerDuration(int minutes) async {
    _sleepTimerDuration = minutes;
    await _prefs?.setInt(_sleepTimerDurationKey, minutes);
    notifyListeners();
  }

  // 播放器样式设置
  Future<void> setPlayerStyle(PlayerStyle style) async {
    _playerStyle = style;
    await _prefs?.setInt(_playerStyleKey, style.index);
    notifyListeners();
  }

  // 重置设置
  Future<void> resetSettings() async {
    _theme = AppTheme.system;
    _scanPaths = [];
    _autoScan = true;
    _skipShortAudio = true;
    _minDuration = 30;
    _sleepTimerEnabled = false;
    _sleepTimerDuration = 30;
    _playerStyle = PlayerStyle.vinyl;
    
    await _prefs?.setInt(_themeKey, _theme.index);
    await _prefs?.remove(_scanPathsKey);
    await _prefs?.setBool(_autoScanKey, _autoScan);
    await _prefs?.setBool(_skipShortAudioKey, _skipShortAudio);
    await _prefs?.setInt(_minDurationKey, _minDuration);
    await _prefs?.setBool(_sleepTimerEnabledKey, _sleepTimerEnabled);
    await _prefs?.setInt(_sleepTimerDurationKey, _sleepTimerDuration);
    await _prefs?.setInt(_playerStyleKey, _playerStyle.index);
    
    notifyListeners();
  }
}
