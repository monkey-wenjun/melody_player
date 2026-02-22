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
    primary: Color(0xFFE91E63),
    secondary: Color(0xFFF48FB1),
    tertiary: Color(0xFFF06292),
    brightness: Brightness.light,
    background: Color(0xFFFCE4EC),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF212121),
    onBackground: Color(0xFF212121),
    icon: Icons.favorite,
  );

  /// 2. 深海蓝 - 深邃海洋系
  static const ThemeConfig oceanBlue = ThemeConfig(
    name: '深海蓝',
    primary: Color(0xFF29B6F6),
    secondary: Color(0xFF4FC3F7),
    tertiary: Color(0xFF81D4FA),
    brightness: Brightness.dark,
    background: Color(0xFF0A1929),
    surface: Color(0xFF132F4C),
    onSurface: Color(0xFFFFFFFF),
    onBackground: Color(0xFFFFFFFF),
    icon: Icons.water,
  );

  /// 3. 森林绿 - 自然绿色系
  static const ThemeConfig forestGreen = ThemeConfig(
    name: '森林绿',
    primary: Color(0xFF388E3C),
    secondary: Color(0xFF81C784),
    tertiary: Color(0xFF66BB6A),
    brightness: Brightness.light,
    background: Color(0xFFF1F8E9),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF212121),
    onBackground: Color(0xFF212121),
    icon: Icons.forest,
  );

  /// 4. 紫罗兰 - 优雅紫色系
  static const ThemeConfig violetPurple = ThemeConfig(
    name: '紫罗兰',
    primary: Color(0xFFCE93D8),
    secondary: Color(0xFFBA68C8),
    tertiary: Color(0xFFAB47BC),
    brightness: Brightness.dark,
    background: Color(0xFF1A0033),
    surface: Color(0xFF2D004D),
    onSurface: Color(0xFFFFFFFF),
    onBackground: Color(0xFFFFFFFF),
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
    onSurface: Color(0xFF212121),
    onBackground: Color(0xFF212121),
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
    onSurface: Color(0xFF212121),
    onBackground: Color(0xFF212121),
    icon: Icons.eco,
  );

  /// 7. 暗黑红 - 酷炫暗红系
  static const ThemeConfig darkRed = ThemeConfig(
    name: '暗黑红',
    primary: Color(0xFFEF5350),
    secondary: Color(0xFFE57373),
    tertiary: Color(0xFFEF9A9A),
    brightness: Brightness.dark,
    background: Color(0xFF1A0A0A),
    surface: Color(0xFF2D1A1A),
    onSurface: Color(0xFFFFFFFF),
    onBackground: Color(0xFFFFFFFF),
    icon: Icons.local_fire_department,
  );

  /// 8. 金色奢华 - 高端金棕色系
  static const ThemeConfig goldLuxury = ThemeConfig(
    name: '金色奢华',
    primary: Color(0xFFFFD700),
    secondary: Color(0xFFFFE082),
    tertiary: Color(0xFFFFECB3),
    brightness: Brightness.dark,
    background: Color(0xFF1C1C1C),
    surface: Color(0xFF2C2C2C),
    onSurface: Color(0xFFFFFFFF),
    onBackground: Color(0xFFFFFFFF),
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
    onSurface: Color(0xFF212121),
    onBackground: Color(0xFF212121),
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
    onSurface: Color(0xFFFFFFFF),
    onBackground: Color(0xFFFFFFFF),
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
  
  // 核心：根据主题亮度确定文字颜色
  // 深色主题 -> 白色文字
  // 浅色主题 -> 黑色文字
  final textColor = isDark ? Colors.white : Colors.black;
  final secondaryTextColor = isDark ? Colors.white70 : Colors.black87;
  final tertiaryTextColor = isDark ? Colors.white54 : Colors.black54;
  
  // 计算 onPrimary 颜色（根据 primary 的亮度）
  final onPrimaryColor = _getContrastColor(primaryColor);
  
  return ThemeData(
    useMaterial3: true,
    brightness: config.brightness,
    colorScheme: ColorScheme(
      brightness: config.brightness,
      primary: primaryColor,
      onPrimary: onPrimaryColor,
      secondary: secondaryColor,
      onSecondary: _getContrastColor(secondaryColor),
      surface: config.surface,
      onSurface: textColor,
      background: config.background,
      onBackground: textColor,
      error: const Color(0xFFFF6B6B),
      onError: Colors.white,
      tertiary: config.tertiary,
      outline: textColor.withOpacity(0.2),
    ),
    scaffoldBackgroundColor: config.background,
    // 关键：设置默认文本样式
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: primaryColor,
      selectionColor: primaryColor.withOpacity(0.3),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: config.surface,
      foregroundColor: textColor,
      elevation: 0,
      centerTitle: true,
      systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      titleTextStyle: TextStyle(
        color: textColor,
        fontSize: 20,
        fontWeight: FontWeight.w500,
      ),
      iconTheme: IconThemeData(color: textColor),
      actionsIconTheme: IconThemeData(color: textColor),
    ),
    cardTheme: CardTheme(
      color: config.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: config.surface,
      selectedItemColor: primaryColor,
      unselectedItemColor: tertiaryTextColor,
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
    iconTheme: IconThemeData(color: secondaryTextColor),
    dividerTheme: DividerThemeData(
      color: textColor.withOpacity(0.1),
      thickness: 1,
    ),
    listTileTheme: ListTileThemeData(
      iconColor: primaryColor,
      textColor: textColor,
      titleTextStyle: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w500),
      subtitleTextStyle: TextStyle(color: secondaryTextColor, fontSize: 14),
      leadingAndTrailingTextStyle: TextStyle(color: textColor),
    ),
    // 按钮主题
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: onPrimaryColor,
        backgroundColor: primaryColor,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
      ),
    ),
    textTheme: TextTheme(
      displayLarge: TextStyle(color: textColor),
      displayMedium: TextStyle(color: textColor),
      displaySmall: TextStyle(color: textColor),
      headlineLarge: TextStyle(color: textColor),
      headlineMedium: TextStyle(color: textColor),
      headlineSmall: TextStyle(color: textColor),
      titleLarge: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.w500),
      titleMedium: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w500),
      titleSmall: TextStyle(color: secondaryTextColor, fontSize: 14),
      bodyLarge: TextStyle(color: textColor, fontSize: 16),
      bodyMedium: TextStyle(color: textColor, fontSize: 14),
      bodySmall: TextStyle(color: tertiaryTextColor, fontSize: 12),
      labelLarge: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w500),
      labelMedium: TextStyle(color: secondaryTextColor, fontSize: 12),
      labelSmall: TextStyle(color: tertiaryTextColor, fontSize: 11),
    ),
    tabBarTheme: TabBarTheme(
      labelColor: primaryColor,
      unselectedLabelColor: tertiaryTextColor,
      indicatorColor: primaryColor,
    ),
    dialogTheme: DialogTheme(
      backgroundColor: config.surface,
      titleTextStyle: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold),
      contentTextStyle: TextStyle(color: secondaryTextColor, fontSize: 16),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: config.surface,
      textStyle: TextStyle(color: textColor),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: isDark ? Colors.white : Colors.black87,
      contentTextStyle: TextStyle(color: isDark ? Colors.black : Colors.white),
    ),
  );
}

/// 根据颜色亮度返回对比色（黑或白）
Color _getContrastColor(Color color) {
  // 计算颜色的亮度 (0-1)
  final luminance = color.computeLuminance();
  // 如果颜色较亮，返回黑色；否则返回白色
  return luminance > 0.5 ? Colors.black : Colors.white;
}
