import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    // 延迟显示启动屏
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    // 请求权限
    await _requestPermissions();
    
    if (!mounted) return;
    
    // 跳转到主页面
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  Future<void> _requestPermissions() async {
    try {
      // 请求音频权限 (Android 13+)
      var audioStatus = await Permission.audio.status;
      if (audioStatus.isDenied) {
        audioStatus = await Permission.audio.request();
      }
      
      // 如果音频权限不可用，尝试存储权限 (Android 12 及以下)
      if (audioStatus.isDenied) {
        var storageStatus = await Permission.storage.status;
        if (storageStatus.isDenied) {
          await Permission.storage.request();
        }
      }
    } catch (e) {
      print('Permission request error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFF5B8DEF),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.music_note,
                size: 60,
                color: Color(0xFF5B8DEF),
              ),
            ),
            const SizedBox(height: 32),
            
            // App Name
            const Text(
              '悦音',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            
            // Subtitle
            const Text(
              '享受音乐的美好',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 48),
            
            // Loading indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
}
