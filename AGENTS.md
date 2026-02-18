# AGENTS.md - 悦音播放器开发指南

## 用户偏好与工作规范

### 问题排查流程
当遇到应用运行问题时，**务必先向用户确认并索要日志文件**，再尝试修复。日志文件通常保存在：
- Android: `/sdcard/Android/data/com.melody.melody_player/files/logs/`
- 或通过应用内导出到 Download 目录

**不要仅凭猜测进行修复**，日志是定位问题的关键依据。

### 关键配置
- 包名: `com.melody.melody_player`
- 主 Activity: `MainActivity` (继承 `AudioServiceFragmentActivity`)
- 后台播放: 使用 `just_audio_background` + `audio_service`

### 开发注意事项
1. **后台播放**: MainActivity 必须继承 AudioServiceFragmentActivity，否则后台服务初始化失败
2. **content:// URI**: just_audio 可直接播放 content:// URI，无需额外转换
3. **版本号更新**: 每次发版需同步更新 `lib/utils/constants.dart` 和 `pubspec.yaml`
