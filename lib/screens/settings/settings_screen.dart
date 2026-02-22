import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/settings_provider.dart';
import '../../utils/constants.dart';
import '../../utils/logger.dart';
import '../../utils/theme_config.dart';
import '../../widgets/update/update_dialog.dart';
import '../../widgets/player/player_styles.dart';
import '../folder_picker/folder_picker_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    // 页面加载后自动检查更新（如果需要）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoCheckUpdate();
    });
  }

  Future<void> _autoCheckUpdate() async {
    // 静默检查更新
    await checkAndShowUpdate(context, manual: false);
  }

  Future<void> _manualCheckUpdate() async {
    // 手动检查更新
    await checkAndShowUpdate(context, manual: true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary.withOpacity(0.12),
                  theme.colorScheme.secondary.withOpacity(0.08),
                  theme.colorScheme.tertiary.withOpacity(0.04),
                ],
              ),
            ),
            child: ListView(
              children: [
              // 主题设置
              _buildSectionHeader(context, '外观'),
              Consumer<SettingsProvider>(
                builder: (context, settings, child) {
                  final themeConfig = settings.themeConfig;
                  
                  return ListTile(
                    leading: Icon(themeConfig.icon, color: theme.colorScheme.primary),
                    title: const Text('主题'),
                    subtitle: Text(themeConfig.name),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showThemeDialog(context),
                  );
                },
              ),

              // 播放器样式设置
              Consumer<SettingsProvider>(
                builder: (context, settings, child) {
                  return ListTile(
                    leading: Icon(Icons.music_video, color: theme.colorScheme.primary),
                    title: const Text('播放器样式'),
                    subtitle: Text(_getPlayerStyleName(settings.playerStyle)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showPlayerStyleDialog(context),
                  );
                },
              ),

              const Divider(),

              // 音乐库设置
              _buildSectionHeader(context, '音乐库扫描'),
              
              // 扫描方式选择
              Consumer<SettingsProvider>(
                builder: (context, settings, child) {
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: Colors.transparent,
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                settings.hasCustomScanPaths 
                                    ? Icons.folder 
                                    : Icons.library_music,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      settings.hasCustomScanPaths 
                                          ? '自定义目录' 
                                          : '扫描所有音乐',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      settings.hasCustomScanPaths
                                          ? '已选择 ${settings.scanPaths.length} 个目录'
                                          : '自动扫描设备中的所有音乐文件',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: theme.textTheme.bodySmall?.color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _showScanOptions(context),
                                  icon: const Icon(Icons.edit),
                                  label: Text(
                                    settings.hasCustomScanPaths 
                                        ? '修改目录' 
                                        : '选择目录'
                                  ),
                                ),
                              ),
                              if (settings.hasCustomScanPaths) ...[
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  onPressed: () => _resetToAllMusic(context),
                                  icon: const Icon(Icons.restore),
                                  label: const Text('恢复默认'),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // 过滤设置
              _buildSectionHeader(context, '过滤设置'),
              
              Consumer<SettingsProvider>(
                builder: (context, settings, child) => Column(
                  children: [
                    SwitchListTile(
                      secondary: Icon(Icons.timer, color: theme.colorScheme.primary),
                      title: const Text('过滤短音频'),
                      subtitle: Text('隐藏小于 ${settings.minDuration} 秒的音频（如铃声）'),
                      value: settings.skipShortAudio,
                      onChanged: (value) => settings.setSkipShortAudio(value),
                    ),
                    if (settings.skipShortAudio)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Text('${settings.minDuration}秒'),
                            Expanded(
                              child: Slider(
                                value: settings.minDuration.toDouble(),
                                min: 10,
                                max: 120,
                                divisions: 11,
                                label: '${settings.minDuration}秒',
                                onChanged: (value) => settings.setMinDuration(value.round()),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              const Divider(),

              // 功能设置
              _buildSectionHeader(context, '功能设置'),
              
              // 定时播放
              Consumer<SettingsProvider>(
                builder: (context, settings, child) => Column(
                  children: [
                    SwitchListTile(
                      secondary: Icon(Icons.timer, color: theme.colorScheme.primary),
                      title: const Text('定时播放'),
                      subtitle: Text(settings.sleepTimerEnabled 
                        ? '${settings.sleepTimerDuration} 分钟后自动停止'
                        : '自动停止播放'),
                      value: settings.sleepTimerEnabled,
                      onChanged: (value) {
                        settings.setSleepTimerEnabled(value);
                        if (value) {
                          _showSleepTimerDialog(context, settings);
                        }
                      },
                    ),
                    if (settings.sleepTimerEnabled)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            const Text('15分钟'),
                            Expanded(
                              child: Slider(
                                value: settings.sleepTimerDuration.toDouble(),
                                min: 15,
                                max: 120,
                                divisions: 7,
                                label: '${settings.sleepTimerDuration}分钟',
                                onChanged: (value) {
                                  settings.setSleepTimerDuration(value.round());
                                },
                              ),
                            ),
                            const Text('120分钟'),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              const Divider(),

              // 调试
              _buildSectionHeader(context, '调试'),
              ListTile(
                leading: Icon(Icons.bug_report, color: theme.colorScheme.primary),
                title: const Text('导出日志'),
                subtitle: const Text('分享日志文件用于排查问题'),
                trailing: const Icon(Icons.share),
                onTap: () => _exportLog(context),
              ),

              const Divider(),

              // 关于
              _buildSectionHeader(context, '关于'),
              ListTile(
                leading: Icon(Icons.info_outline, color: theme.colorScheme.primary),
                title: const Text('关于悦音'),
                subtitle: const Text(AppConstants.appDescription),
                onTap: () => _showAboutDialog(context),
              ),
              
              // 版本号（点击检查更新）
              ListTile(
                leading: Icon(
                  Icons.system_update_alt,
                  color: theme.colorScheme.primary,
                ),
                title: const Text('版本'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('v${AppConstants.appVersion}'),
                    const SizedBox(height: 2),
                    Text(
                      '点击检查更新',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                trailing: Icon(
                  Icons.touch_app,
                  size: 20,
                  color: theme.colorScheme.primary.withOpacity(0.5),
                ),
                onTap: _manualCheckUpdate,
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    ),
  );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  void _showThemeDialog(BuildContext context) {
    final settings = context.read<SettingsProvider>();
    
    // 主题列表
    final themes = [
      (AppTheme.light, AppThemes.light),
      (AppTheme.dark, AppThemes.dark),
      (AppTheme.system, null), // 特殊处理
      (AppTheme.sakuraPink, AppThemes.sakuraPink),
      (AppTheme.oceanBlue, AppThemes.oceanBlue),
      (AppTheme.forestGreen, AppThemes.forestGreen),
      (AppTheme.violetPurple, AppThemes.violetPurple),
      (AppTheme.sunsetOrange, AppThemes.sunsetOrange),
      (AppTheme.mintTeal, AppThemes.mintTeal),
      (AppTheme.darkRed, AppThemes.darkRed),
      (AppTheme.goldLuxury, AppThemes.goldLuxury),
      (AppTheme.skyBlue, AppThemes.skyBlue),
      (AppTheme.neonPurple, AppThemes.neonPurple),
    ];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择主题'),
        content: SizedBox(
          width: double.maxFinite,
          child: Consumer<SettingsProvider>(
            builder: (context, settings, child) {
              return GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: themes.length,
                itemBuilder: (context, index) {
                  final (theme, config) = themes[index];
                  final isSelected = settings.theme == theme;
                  
                  // 跟随系统特殊处理
                  if (theme == AppTheme.system) {
                    return _buildThemeOption(
                      context,
                      theme: theme,
                      name: '跟随系统',
                      icon: Icons.brightness_auto,
                      primaryColor: Colors.grey,
                      backgroundColor: Colors.grey[200]!,
                      isSelected: isSelected,
                      onTap: () {
                        settings.setTheme(theme);
                        Navigator.pop(context);
                      },
                    );
                  }
                  
                  return _buildThemeOption(
                    context,
                    theme: theme,
                    name: config!.name,
                    icon: config.icon,
                    primaryColor: config.primary,
                    backgroundColor: config.background,
                    isSelected: isSelected,
                    onTap: () {
                      settings.setTheme(theme);
                      Navigator.pop(context);
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context, {
    required AppTheme theme,
    required String name,
    required IconData icon,
    required Color primaryColor,
    required Color backgroundColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.transparent,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getPlayerStyleName(PlayerStyle style) {
    switch (style) {
      case PlayerStyle.vinyl:
        return '黑胶唱片';
      case PlayerStyle.waveform:
        return '波形可视';
      case PlayerStyle.rotatingDisc:
        return '旋转光盘';
      case PlayerStyle.minimal:
        return '简约封面';
      case PlayerStyle.retroCassette:
        return '复古磁带';
      case PlayerStyle.neonPulse:
        return '霓虹脉冲';
      case PlayerStyle.particleNebula:
        return '粒子星云';
      case PlayerStyle.spectrumWaterfall:
        return '频谱瀑布';
      case PlayerStyle.magicAura:
        return '魔法光环';
      case PlayerStyle.equalizer:
        return '均衡器';
      case PlayerStyle.ripple:
        return '水滴波纹';
      case PlayerStyle.cyberpunk:
        return '赛博朋克';
      case PlayerStyle.card3D:
        return '3D卡片';
      case PlayerStyle.cdCase:
        return '光盘盒';
    }
  }

  void _showPlayerStyleDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择播放器样式'),
        content: Consumer<SettingsProvider>(
          builder: (context, settings, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PlayerStyleSelector(
                  selectedStyle: settings.playerStyle,
                  onStyleSelected: (style) {
                    settings.setPlayerStyle(style);
                    Navigator.pop(context);
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showScanOptions(BuildContext context) {
    final settings = context.read<SettingsProvider>();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return SafeArea(
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const ListTile(
                  title: Text(
                    '选择扫描方式',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.folder_open,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        title: const Text('选择音乐目录'),
                        subtitle: const Text('手动选择要扫描的文件夹，更精准'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          Navigator.pop(context);
                          final result = await Navigator.push<List<String>>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FolderPickerScreen(
                                selectedPaths: settings.scanPaths,
                              ),
                            ),
                          );
                          if (result != null) {
                            await settings.clearScanPaths();
                            for (final path in result) {
                              await settings.addScanPath(path);
                            }
                          }
                        },
                      ),
                      const Divider(),
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.library_music,
                            color: Colors.green,
                          ),
                        ),
                        title: const Text('扫描所有音乐'),
                        subtitle: const Text('自动扫描设备中的所有音乐文件（智能过滤）'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          await settings.clearScanPaths();
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('将扫描所有音乐文件')),
                            );
                          }
                        },
                      ),
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          '说明：\n'
                          '• 选择目录：只扫描你选定的文件夹，更快速精准\n'
                          '• 扫描所有：自动扫描整个设备，会智能过滤系统音频（通话录音、铃声等）',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showSleepTimerDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('设置定时时长'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('播放多久后自动停止？'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [15, 30, 45, 60, 90, 120].map((minutes) {
                return ChoiceChip(
                  label: Text('$minutes分钟'),
                  selected: settings.sleepTimerDuration == minutes,
                  onSelected: (selected) {
                    if (selected) {
                      settings.setSleepTimerDuration(minutes);
                      Navigator.pop(context);
                    }
                  },
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportLog(BuildContext context) async {
    try {
      final logContent = await Logger().getLogContent();
      
      if (logContent.isNotEmpty) {
        // 复制到临时目录便于分享
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/melody_player_log.txt');
        await tempFile.writeAsString(logContent);
        
        await Share.shareXFiles(
          [XFile(tempFile.path)],
          subject: '悦音播放器日志',
          text: '请将此日志发送给开发者排查问题',
        );
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('暂无日志内容')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出日志失败: $e')),
        );
      }
    }
  }

  Future<void> _resetToAllMusic(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('恢复默认扫描'),
        content: const Text('确定要恢复为扫描所有音乐文件吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await context.read<SettingsProvider>().clearScanPaths();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已恢复为扫描所有音乐')),
        );
      }
    }
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: AppConstants.appName,
      applicationVersion: AppConstants.appVersion,
      applicationIcon: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF5B8DEF), Color(0xFFA8D8B9)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.music_note, color: Colors.white, size: 36),
      ),
      applicationLegalese: ' 2024 悦音. All rights reserved.',
      children: [
        const SizedBox(height: 16),
        const Text(
          '悦音是一款简洁清新的本地音乐播放器，专注于提供优质的音乐播放体验。',
          style: TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 8),
        const Text(
          '联系我们',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ListTile(
          leading: const Icon(Icons.email, size: 20),
          title: const Text('邮箱'),
          subtitle: const Text('hi@awen.me'),
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),
        ListTile(
          leading: const Icon(Icons.language, size: 20),
          title: const Text('博客'),
          subtitle: const Text('https://www.awen.me'),
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }
}
