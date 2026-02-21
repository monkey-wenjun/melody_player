import 'package:flutter/material.dart';
import '../../services/cast_service.dart';

/// Google Cast 投屏按钮
class CastButton extends StatefulWidget {
  const CastButton({super.key});

  @override
  State<CastButton> createState() => _CastButtonState();
}

class _CastButtonState extends State<CastButton> {
  final CastService _castService = CastService();
  List<CastDevice> _devices = [];
  bool _isConnected = false;
  CastDevice? _currentDevice;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _castService.init();
    await _castService.startDiscovery();
    
    // 监听设备列表
    _castService.devicesStream.listen((devices) {
      setState(() => _devices = devices);
    });
    
    // 监听连接状态
    _castService.connectionStream.listen((connected) {
      setState(() => _isConnected = connected);
    });
  }

  @override
  void dispose() {
    _castService.stopDiscovery();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        _isConnected ? Icons.cast_connected : Icons.cast,
        color: _isConnected ? Theme.of(context).colorScheme.primary : null,
      ),
      onPressed: _showDevicePicker,
    );
  }

  void _showDevicePicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text(
                '选择投屏设备',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              trailing: _isConnected
                  ? TextButton(
                      onPressed: () {
                        _castService.disconnect();
                        Navigator.pop(context);
                      },
                      child: const Text('断开连接'),
                    )
                  : null,
            ),
            const Divider(),
            if (_devices.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  '未找到可用设备\n请确保设备与手机在同一 WiFi 网络',
                  textAlign: TextAlign.center,
                ),
              )
            else
              ..._devices.map((device) => ListTile(
                    leading: Icon(
                      Icons.speaker,
                      color: _currentDevice?.id == device.id
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    title: Text(device.name),
                    subtitle: Text(device.model ?? '未知设备'),
                    trailing: _currentDevice?.id == device.id
                        ? Icon(Icons.check,
                            color: Theme.of(context).colorScheme.primary)
                        : null,
                    onTap: () async {
                      Navigator.pop(context);
                      final success =
                          await _castService.connectToDevice(device);
                      if (success) {
                        setState(() => _currentDevice = device);
                        _showConnectedSnackBar(device.name);
                      }
                    },
                  )),
          ],
        ),
      ),
    );
  }

  void _showConnectedSnackBar(String deviceName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已连接到 $deviceName'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
