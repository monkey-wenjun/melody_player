# 🎵 悦音播放器 (Melody Player)

<p align="center">
  <img src="assets/images/default_album_art.png" alt="悦音播放器 Logo" width="120">
</p>

<p align="center">
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-3.24+-02569B?style=flat-square&logo=flutter" alt="Flutter"></a>
  <a href="https://dart.dev"><img src="https://img.shields.io/badge/Dart-3.5+-0175C2?style=flat-square&logo=dart" alt="Dart"></a>
  <a href="https://www.android.com"><img src="https://img.shields.io/badge/Android-5.0+-3DDC84?style=flat-square&logo=android" alt="Android"></a>
  <img src="https://img.shields.io/badge/Version-1.9.0-FF6B6B?style=flat-square" alt="Version">
</p>

<p align="center">一款简洁、清新、轻量的本地音乐播放器</p>

---

## ✨ 功能特性

### 🎶 核心播放功能
- **高品质音频播放** - 基于 just_audio 引擎，支持多种音频格式
- **后台播放** - 支持后台播放和通知栏控制，锁屏也能控制音乐
- **播放模式** - 顺序播放、随机播放、单曲循环、列表循环四种模式
- **歌词显示** - 支持歌词同步显示（开发中）

### 📱 本地音乐管理
- **智能扫描** - 自动扫描设备中的音乐文件，智能过滤录音、铃声等非音乐文件
- **多维度浏览** - 按歌曲、歌手、专辑分类浏览
- **播放列表** - 创建自定义播放列表，管理你的音乐收藏
- **最近播放** - 自动记录最近播放的 50 首歌曲

### 🎨 界面与体验
- **精美界面** - 简洁清新的 Material Design 设计风格
- **深色模式** - 支持浅色/深色主题切换，适配系统主题
- **流畅动画** - 精心设计的转场动画和交互反馈
- **迷你播放器** - 底部常驻迷你播放条，随时控制播放

### 🔄 其他功能
- **自动更新** - 自动检测新版本并提示更新
- **音频格式支持** - MP3、AAC、M4A、FLAC、WAV、OGG、OPUS、APE、DSD、WMA
- **文件夹选择** - 自定义扫描特定文件夹，避免扫描无关音频

---

## 📥 下载安装

### 直接下载
| 版本 | 下载链接 | 文件大小 |
|:---:|:---:|:---:|
| 最新版 (v1.9.0) | [点击下载](https://file.awen.me/music/melody_player_v1.9.0.apk) | ~125 MB |

### 系统要求
- **Android 版本**: Android 5.0 (API 21) 及以上
- **存储空间**: 至少 150 MB 可用空间
- **权限**: 存储权限（用于读取音乐文件）

---

## 🛠️ 技术架构

### 技术栈
| 层级 | 技术选型 |
|:---:|:---|
| **框架** | Flutter 3.24+ |
| **语言** | Dart 3.5+ |
| **状态管理** | Provider |
| **本地存储** | SQFlite + SharedPreferences |
| **音频播放** | just_audio + audio_service |
| **权限处理** | permission_handler |
| **媒体扫描** | on_audio_query |

### 项目结构
```
lib/
├── models/              # 数据模型
│   ├── song.dart        # 歌曲模型
│   ├── album.dart       # 专辑模型
│   ├── artist.dart      # 歌手模型
│   └── playlist.dart    # 播放列表模型
├── services/            # 业务服务
│   ├── audio_player_service.dart   # 音频播放服务
│   ├── audio_handler.dart          # 后台播放处理
│   ├── media_scanner_service.dart  # 媒体扫描服务
│   ├── playlist_service.dart       # 播放列表服务
│   ├── update_service.dart         # 更新检查服务
│   └── audio_transcode_service.dart # 音频转码服务
├── providers/           # 状态管理
│   ├── player_provider.dart        # 播放器状态
│   ├── library_provider.dart       # 音乐库状态
│   ├── playlist_provider.dart      # 播放列表状态
│   └── settings_provider.dart      # 设置状态
├── screens/             # 页面
│   ├── splash/          # 启动页
│   ├── home/            # 主页
│   ├── library/         # 音乐库
│   ├── player/          # 播放页
│   ├── playlist/        # 播放列表
│   ├── settings/        # 设置页
│   └── folder_picker/   # 文件夹选择
├── widgets/             # 组件
│   ├── player/          # 播放器相关组件
│   ├── common/          # 通用组件
│   └── update/          # 更新弹窗
├── utils/               # 工具类
│   ├── constants.dart   # 常量定义
│   ├── theme.dart       # 主题配置
│   └── logger.dart      # 日志工具
├── di/                  # 依赖注入
│   └── service_locator.dart
├── app.dart             # 应用入口
└── main.dart            # 程序入口
```

---

## 🔧 编译构建

### 环境要求
- Flutter SDK 3.24 或更高版本
- Android SDK (API 21+)
- Java JDK 11 或更高版本
- Git

### 编译步骤

1. **克隆仓库**
```bash
git clone https://github.com/yourusername/melody_player.git
cd melody_player
```

2. **安装依赖**
```bash
flutter pub get
```

3. **编译 APK**
```bash
# 使用快捷脚本
./build.sh

# 或手动编译
flutter clean
flutter pub get
flutter build apk --release
```

4. **输出文件**
编译完成后，APK 文件位于：
```
build/app/outputs/flutter-apk/app-release.apk
```

### 编译并上传到 OSS（内部使用）
```bash
./build.sh "更新说明"
```

---

## 📋 权限说明

悦音播放器需要以下权限来提供完整功能：

| 权限 | 用途 | 是否必需 |
|:---|:---|:---:|
| `READ_MEDIA_AUDIO` | 读取音乐文件（Android 13+） | ✅ |
| `READ_EXTERNAL_STORAGE` | 读取存储（Android 12 及以下） | ✅ |
| `MANAGE_EXTERNAL_STORAGE` | 管理所有文件（用于自定义文件夹选择） | ❌ |
| `FOREGROUND_SERVICE` | 后台播放服务 | ✅ |
| `FOREGROUND_SERVICE_MEDIA_PLAYBACK` | 媒体播放前台服务 | ✅ |
| `INTERNET` | 检查更新 | ❌ |
| `REQUEST_INSTALL_PACKAGES` | 自动安装更新 | ❌ |

---

## 🚀 更新日志

### v1.9.0 (2026-02-18)
- ✨ 新增自动更新检查功能
- 🎨 优化播放界面 UI
- 🔧 修复后台播放稳定性问题
- 📁 新增自定义文件夹选择功能

### v1.8.0 (早期版本)
- ✨ 支持更多音频格式（WMA 等）
- 🎨 深色模式优化
- 🔧 修复若干已知问题

---

## 🤝 参与贡献

欢迎提交 Issue 和 Pull Request！

1. Fork 本仓库
2. 创建你的特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 打开一个 Pull Request

---

## 📄 开源协议

本项目基于 [MIT](LICENSE) 协议开源。

---

## 🙏 致谢

- [just_audio](https://pub.dev/packages/just_audio) - 优秀的音频播放库
- [audio_service](https://pub.dev/packages/audio_service) - 后台音频播放支持
- [Flutter](https://flutter.dev) - 跨平台 UI 框架
- [Material Design](https://m3.material.io/) - 设计语言

---

## 📮 联系我们

如有问题或建议，欢迎通过以下方式联系：

- 📧 邮箱: your.email@example.com
- 🐛 Issues: [GitHub Issues](https://github.com/yourusername/melody_player/issues)

---

<p align="center">
  Made with ❤️ by 悦音团队
</p>
