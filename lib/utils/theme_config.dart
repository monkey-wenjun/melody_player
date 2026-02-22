import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 主题配置类
class ThemeConfig {
  final String name;
  final Color primary;
  final Color secondary;
  final Color tertiary;
  final Brightness brightness;
  final Color background;
  final Color surface;
  final Color onSurface;
  final Color onBackground;
  final IconData icon;

  const ThemeConfig({
    required this.name,
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.brightness,
    required this.background,
    required this.surface,
    required this.onSurface,
    required this.onBackground,
    required this.icon,
  });
}

/// 所有主题配置
class AppThemes {
  // 基础主题
  static const ThemeConfig light = ThemeConfig(
    name: '浅色',
    primary: Color(0xFF5B8DEF),
    secondary: Color(0xFFA8D8B9),
    tertiary: Color(0xFFFFB74D),
    brightness: Brightness.light,
    background: Color(0xFFFAFAFA),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF2D3436),
    onBackground: Color(0xFF2D3436),
    icon: Icons.wb_sunny,
  );

  static const ThemeConfig dark = ThemeConfig(
    name: '深色',
    primary: Color(0xFF8BB4F7),
    secondary: Color(0xFFA8D8B9),
    tertiary: Color(0xFFFFB74D),
    brightness: Brightness.dark,
    background: Color(0xFF121212),
    surface: Color(0xFF1E1E1E),
    onSurface: Color(0xFFE8E8E8),
    onBackground: Color(0xFFE8E8E8),
    icon: Icons.nights_stay,
  );

  // 彩色主题（10种新主题）
  
  /// 1. 樱花粉 - 浪漫粉色系
  static const ThemeConfig sakuraPink = ThemeConfig(
    name: '樱花粉',
    primary: Color(0xFFF8BBD9),
    secondary: Color(0xFFFCE4EC),
    tertiary: Color(0xFFF48FB1),
    brightness: Brightness.light,
    background: Color(0xFFFDF2F8),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF880E4F),
    onBackground: Color(0xFF880E4F),
    icon: Icons.favorite,
  );

  /// 2. 深海蓝 - 深邃海洋系
  static const ThemeConfig oceanBlue = ThemeConfig(
    name: '深海蓝',
    primary: Color(0xFF0277BD),
    secondary: Color(0xFF4FC3F7),
    tertiary: Color(0xFF29B6F6),
    brightness: Brightness.dark,
    background: Color(0xFF0D1B2A),
    surface: Color(0xFF1B263B),
    onSurface: Color(0xFFE0F7FA),
    onBackground: Color(0xFFE0F7FA),
    icon: Icons.water,
  );

  /// 3. 森林绿 - 自然绿色系
  static const ThemeConfig forestGreen = ThemeConfig(
    name: '森林绿',
    primary: Color(0xFF2E7D32),
    secondary: Color(0xFF81C784),
    tertiary: Color(0xFF66BB6A),
    brightness: Brightness.light,
    background: Color(0xFFF1F8E9),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF1B5E20),
    onBackground: Color(0xFF1B5E20),
    icon: Icons.forest,
  );

  /// 4. 紫罗兰 - 优雅紫色系
  static const ThemeConfig violetPurple = ThemeConfig(
    name: '紫罗兰',
    primary: Color(0xFF7B1FA2),
    secondary: Color(0xFFBA68C8),
    tertiary: Color(0xFFAB47BC),
    brightness: Brightness.dark,
    background: Color(0xFF1A0033),
    surface: Color(0xFF2D004D),
    onSurface: Color(0xFFF3E5F5),
    onBackground: Color(0xFFF3E5F5),
    icon: Icons.spa,
  );

  /// 5. 日落橙 - 温暖橙黄色系
  static const ThemeConfig sunsetOrange = ThemeConfig(
    name: '日落橙',
    primary: Color(0xFFF57C00),
    secondary: Color(0xFFFFB74D),
    tertiary: Color(0xFFFF9800),
    brightness: Brightness.light,
    background: Color(0xFFFFF3E0),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFFE65100),
    onBackground: Color(0xFFE65100),
    icon: Icons.wb_twilight,
  );

  /// 6. 薄荷青 - 清新青绿色系
  static const ThemeConfig mintTeal = ThemeConfig(
    name: '薄荷青',
    primary: Color(0xFF00897B),
    secondary: Color(0xFF4DB6AC),
    tertiary: Color(0xFF26A69A),
    brightness: Brightness.light,
    background: Color(0xFFE0F2F1),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF004D40),
    onBackground: Color(0xFF004D40),
    icon: Icons.eco,
  );

  /// 7. 暗黑红 - 酷炫暗红系
  static const ThemeConfig darkRed = ThemeConfig(
    name: '暗黑红',
    primary: Color(0xFFD32F2F),
    secondary: Color(0xFFEF5350),
    tertiary: Color(0xFFE57373),
    brightness: Brightness.dark,
    background: Color(0xFF1A1A2E),
    surface: Color(0xFF16213E),
    onSurface: Color(0xFFFFEBEE),
    onBackground: Color(0xFFFFEBEE),
    icon: Icons.local_fire_department,
  );

  /// 8. 金色奢华 - 高端金棕色系
  static const ThemeConfig goldLuxury = ThemeConfig(
    name: '金色奢华',
    primary: Color(0xFFB8860B),
    secondary: Color(0xFFD4AF37),
    tertiary: Color(0xFFDAA520),
    brightness: Brightness.dark,
    background: Color(0xFF1C1C1C),
    surface: Color(0xFF2C2C2C),
    onSurface: Color(0xFFFFF8E1),
    onBackground: Color(0xFFFFF8E1),
    icon: Icons.diamond,
  );

  /// 9. 天空蓝 - 明亮天蓝系
  static const ThemeConfig skyBlue = ThemeConfig(
    name: '天空蓝',
    primary: Color(0xFF039BE5),
    secondary: Color(0xFF4FC3F7),
    tertiary: Color(0xFF29B6F6),
    brightness: Brightness.light,
    background: Color(0xFFE1F5FE),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF01579B),
    onBackground: Color(0xFF01579B),
    icon: Icons.cloud,
  );

  /// 10. 霓虹紫 - 赛博朋克霓虹系
  static const ThemeConfig neonPurple = ThemeConfig(
    name: '霓虹紫',
    primary: Color(0xFFE040FB),
    secondary: Color(0xFF18FFFF),
    tertiary: Color(0xFF64FFDA),
    brightness: Brightness.dark,
    background: Color(0xFF0A0A0A),
    surface: Color(0xFF121212),
    onSurface: Color(0xFFE0E0E0),
    onBackground: Color(0xFFE0E0E0),
    icon: Icons.lightbulb_circle,
  );

  /// 获取主题配置
  static ThemeConfig getConfig(int index) {
    switch (index) {
      case 0:
        return light;
      case 1:
        return dark;
      case 3:
        return sakuraPink;
      case 4:
        return oceanBlue;
      case 5:
        return forestGreen;
      case 6:
        return violetPurple;
      case 7:
        return sunsetOrange;
      case 8:
        return mintTeal;
      case 9:
        return darkRed;
      case 10:
        return goldLuxury;
      case 11:
        return skyBlue;
      case 12:
        return neonPurple;
      default:
        return light;
    }
  }
}

/// 创建 ThemeData
ThemeData createThemeData(ThemeConfig config) {
  final isDark = config.brightness == Brightness.dark;
  final primaryColor = config.primary;
  final secondaryColor = config.secondary;
  
  return ThemeData(
    useMaterial3: true,
    brightness: config.brightness,
    colorScheme: ColorScheme(
      brightness: config.brightness,
      primary: primaryColor,
      onPrimary: isDark ? Colors.white : Colors.white,
      secondary: secondaryColor,
      onSecondary: isDark ? Colors.black : Colors.white,
      surface: config.surface,
      onSurface: config.onSurface,
      background: config.background,
      onBackground: config.onBackground,
      error: const Color(0xFFFF6B6B),
      onError: Colors.white,
      tertiary: config.tertiary,
      outline: config.onSurface.withOpacity(0.2),
    ),
    scaffoldBackgroundColor: config.background,
    appBarTheme: AppBarTheme(
      backgroundColor: config.surface,
      foregroundColor: config.onSurface,
      elevation: 0,
      centerTitle: true,
      systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
    ),
    cardTheme: CardTheme(
      color: config.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: config.surface,
      selectedItemColor: primaryColor,
      unselectedItemColor: config.onSurface.withOpacity(0.5),
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: primaryColor,
      inactiveTrackColor: primaryColor.withOpacity(0.2),
      thumbColor: primaryColor,
      trackHeight: 4,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
    ),
    iconTheme: IconThemeData(color: config.onSurface.withOpacity(0.7)),
    dividerTheme: DividerThemeData(
      color: config.onSurface.withOpacity(0.1),
      thickness: 1,
    ),
    listTileTheme: ListTileThemeData(
      iconColor: primaryColor,
      textColor: config.onSurface,
    ),
  );
}
