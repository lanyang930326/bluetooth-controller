import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:async';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '蓝牙控制器',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const ScanPage(),
    );
  }
}

// ─────────────────────────────────────────────
// 扫描页：搜索蓝牙设备
// ─────────────────────────────────────────────
class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final List<ScanResult> _devices = [];
  bool _isScanning = false;
  StreamSubscription? _scanSubscription;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  void _startScan() async {
    setState(() {
      _devices.clear();
      _isScanning = true;
    });

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      setState(() {
        for (final r in results) {
          if (!_devices.any((d) => d.device.remoteId == r.device.remoteId)) {
            _devices.add(r);
          }
        }
      });
    });

    FlutterBluePlus.isScanning.listen((scanning) {
      if (mounted) setState(() => _isScanning = scanning);
    });
  }

  void _connectToDevice(BluetoothDevice device) async {
    await FlutterBluePlus.stopScan();
    _scanSubscription?.cancel();

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConnectingPage(device: device),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          '蓝牙设备搜索',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 提示区域
          Container(
            width: double.infinity,
            color: const Color(0xFF1565C0),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              children: [
                const Icon(Icons.bluetooth_searching,
                    size: 64, color: Colors.white70),
                const SizedBox(height: 12),
                Text(
                  _isScanning ? '正在搜索附近蓝牙设备...' : '搜索完成',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                if (_isScanning)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.white30,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
          ),

          // 设备列表标题
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.devices, color: Color(0xFF1565C0)),
                const SizedBox(width: 8),
                Text(
                  '发现设备 (${_devices.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
              ],
            ),
          ),

          // 设备列表
          Expanded(
            child: _devices.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bluetooth_disabled,
                            size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          _isScanning ? '搜索中，请稍候...' : '未找到设备',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _devices.length,
                    itemBuilder: (ctx, i) {
                      final r = _devices[i];
                      final name = r.device.platformName.isNotEmpty
                          ? r.device.platformName
                          : '未知设备';
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor:
                                const Color(0xFF1565C0).withOpacity(0.1),
                            child: const Icon(Icons.bluetooth,
                                color: Color(0xFF1565C0)),
                          ),
                          title: Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            r.device.remoteId.toString(),
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[500]),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${r.rssi} dBm',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[500]),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.chevron_right,
                                  color: Color(0xFF1565C0)),
                            ],
                          ),
                          onTap: () => _connectToDevice(r.device),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isScanning ? null : _startScan,
        backgroundColor:
            _isScanning ? Colors.grey : const Color(0xFF1565C0),
        icon: _isScanning
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.refresh, color: Colors.white),
        label: Text(
          _isScanning ? '搜索中' : '重新搜索',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 连接中页面
// ─────────────────────────────────────────────
class ConnectingPage extends StatefulWidget {
  final BluetoothDevice device;
  const ConnectingPage({super.key, required this.device});

  @override
  State<ConnectingPage> createState() => _ConnectingPageState();
}

class _ConnectingPageState extends State<ConnectingPage> {
  @override
  void initState() {
    super.initState();
    _connect();
  }

  void _connect() async {
    try {
      await widget.device.connect(timeout: const Duration(seconds: 15));
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DeviceControlPage(device: widget.device),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('连接失败：$e'), backgroundColor: Colors.red),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              color: Color(0xFF1565C0),
              strokeWidth: 3,
            ),
            const SizedBox(height: 24),
            Text(
              '正在连接...',
              style: TextStyle(fontSize: 18, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              widget.device.platformName.isNotEmpty
                  ? widget.device.platformName
                  : widget.device.remoteId.toString(),
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1565C0)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 设备控制页面
// ─────────────────────────────────────────────
class DeviceControlPage extends StatefulWidget {
  final BluetoothDevice device;
  const DeviceControlPage({super.key, required this.device});

  @override
  State<DeviceControlPage> createState() => _DeviceControlPageState();
}

class _DeviceControlPageState extends State<DeviceControlPage> {
  BluetoothCharacteristic? _writeChar;
  String _deviceName = '';
  final TextEditingController _nameController = TextEditingController();
  String _statusMsg = '';
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    _deviceName = widget.device.platformName.isNotEmpty
        ? widget.device.platformName
        : '未知设备';
    _nameController.text = _deviceName;
    _discoverServices();

    widget.device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected && mounted) {
        setState(() => _isConnected = false);
        _showDisconnectedDialog();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    widget.device.disconnect();
    super.dispose();
  }

  void _discoverServices() async {
    try {
      final services = await widget.device.discoverServices();
      for (final s in services) {
        for (final c in s.characteristics) {
          if (c.properties.write || c.properties.writeWithoutResponse) {
            _writeChar = c;
            break;
          }
        }
        if (_writeChar != null) break;
      }
    } catch (e) {
      _setStatus('服务发现失败：$e');
    }
  }

  void _setStatus(String msg) {
    setState(() => _statusMsg = msg);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _statusMsg = '');
    });
  }

  Future<void> _sendData(List<int> data, String label) async {
    if (_writeChar == null) {
      _setStatus('未找到可写特征值，请确认设备支持');
      return;
    }
    try {
      await _writeChar!.write(data, withoutResponse: true);
      _setStatus('已发送：$label (0x${data[0].toRadixString(16).padLeft(2, "0").toUpperCase()})');
    } catch (e) {
      _setStatus('发送失败：$e');
    }
  }

  void _showDisconnectedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('连接断开'),
        content: const Text('设备已断开连接，请重新搜索并连接。'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).popUntil((r) => r.isFirst);
            },
            child: const Text('返回搜索'),
          ),
        ],
      ),
    );
  }

  void _renameDevice() {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) return;
    setState(() => _deviceName = newName);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('设备名称已更新为：$newName'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          '设备控制',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Icon(
              _isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
              color: _isConnected ? Colors.greenAccent : Colors.redAccent,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 设备名称卡片 ──
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.devices, color: Color(0xFF1565C0)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _deviceName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1565C0),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    const Text(
                      '修改设备名称',
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              hintText: '输入新名称',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: _renameDevice,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1565C0),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                          child: const Text('保存',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── 控制按钮区 ──
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                '设备控制',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
            ),

            // 上升按钮
            _ControlButton(
              label: '上升',
              icon: Icons.keyboard_arrow_up_rounded,
              color: const Color(0xFF1976D2),
              onPressed: () => _sendData([0x01], '上升'),
            ),
            const SizedBox(height: 14),

            // 停止按钮
            _ControlButton(
              label: '停止',
              icon: Icons.stop_rounded,
              color: const Color(0xFFE53935),
              onPressed: () => _sendData([0x02], '停止'),
            ),
            const SizedBox(height: 14),

            // 下降按钮
            _ControlButton(
              label: '下降',
              icon: Icons.keyboard_arrow_down_rounded,
              color: const Color(0xFF388E3C),
              onPressed: () => _sendData([0x03], '下降'),
            ),

            // 状态消息
            if (_statusMsg.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          color: Colors.white70, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _statusMsg,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 控制按钮组件（点动）
// ─────────────────────────────────────────────
class _ControlButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _ControlButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  State<_ControlButton> createState() => _ControlButtonState();
}

class _ControlButtonState extends State<_ControlButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _pressed = true);
        widget.onPressed();
      },
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: double.infinity,
        height: 64,
        decoration: BoxDecoration(
          color: _pressed
              ? widget.color.withOpacity(0.75)
              : widget.color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: _pressed
              ? []
              : [
                  BoxShadow(
                    color: widget.color.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.icon, color: Colors.white, size: 28),
            const SizedBox(width: 10),
            Text(
              widget.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
