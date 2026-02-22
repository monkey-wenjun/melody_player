import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/player_provider.dart';
import 'providers/library_provider.dart';
import 'providers/playlist_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/splash/splash_screen.dart';
import 'utils/theme.dart';
import 'utils/theme_config.dart';
import 'widgets/update/update_dialog.dart';

class MelodyApp extends StatelessWidget {
  const MelodyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => PlaylistProvider()),
        ChangeNotifierProvider(create: (_) => LibraryProvider()),
        ChangeNotifierProxyProvider<PlaylistProvider, PlayerProvider>(
          create: (_) => PlayerProvider(),
          update: (_, playlistProvider, playerProvider) {
            playerProvider?.setPlaylistProvider(playlistProvider);
            return playerProvider!;
          },
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          // 使用自定义主题或默认主题
          final isCustomTheme = settings.isCustomTheme;
          
          return MaterialApp(
            title: '悦音',
            debugShowCheckedModeBanner: false,
            theme: isCustomTheme ? settings.themeData : AppThemeData.lightTheme,
            darkTheme: isCustomTheme ? settings.themeData : AppThemeData.darkTheme,
            themeMode: isCustomTheme ? ThemeMode.light : settings.themeMode,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}

/// 在主页显示后自动检查更新
class AutoUpdateChecker extends StatefulWidget {
  final Widget child;
  
  const AutoUpdateChecker({Key? key, required this.child}) : super(key: key);

  @override
  State<AutoUpdateChecker> createState() => _AutoUpdateCheckerState();
}

class _AutoUpdateCheckerState extends State<AutoUpdateChecker> {
  bool _hasChecked = false;

  @override
  void initState() {
    super.initState();
    // 延迟5秒后自动检查更新（避免启动时卡顿）
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && !_hasChecked) {
        _hasChecked = true;
        checkAndShowUpdate(context, manual: false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
