# 蓝牙控制器 APP

一款基于 Flutter 的蓝牙设备控制应用，用于搜索、连接蓝牙设备并发送控制指令。

---

## 功能说明

### 页面一：蓝牙扫描页
- 打开 APP 自动开始搜索附近蓝牙设备
- 显示设备名称、MAC 地址、信号强度（RSSI）
- 点击设备卡片进行连接
- 支持手动"重新搜索"

### 页面二：设备控制页
- **顶部**：显示设备名称 + 连接状态
- **名称修改**：文本框输入新名称，点击"保存"即时更新
- **控制按钮（点动）**：
  | 按钮 | 发送数据 |
  |------|---------|
  | 上升 | `0x01`  |
  | 停止 | `0x02`  |
  | 下降 | `0x03`  |

---

## 项目结构

```
bluetooth_app/
├── lib/
│   └── main.dart              # 全部业务逻辑（扫描/连接/控制）
├── android/
│   └── app/src/main/
│       └── AndroidManifest.xml  # 蓝牙权限声明
└── pubspec.yaml               # Flutter 依赖配置
```

---

## 依赖包

| 包名 | 版本 | 用途 |
|------|------|------|
| `flutter_blue_plus` | ^1.31.12 | BLE 蓝牙通信核心 |
| `permission_handler` | ^11.3.1 | 运行时权限请求 |

---

## 编译运行步骤

### 前置条件
- 安装 [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.x
- Android Studio 或 VS Code
- Android 真机（蓝牙功能无法在模拟器中完整测试）

### 步骤

```bash
# 1. 进入项目目录
cd bluetooth_app

# 2. 安装依赖
flutter pub get

# 3. 连接 Android 手机（开启开发者模式+USB调试）
# 4. 运行
flutter run
```

### 打包 APK

```bash
flutter build apk --release
# 输出：build/app/outputs/flutter-apk/app-release.apk
```

---

## Android 权限说明

| 权限 | 用途 |
|------|------|
| `BLUETOOTH_SCAN` | 扫描附近设备（Android 12+）|
| `BLUETOOTH_CONNECT` | 连接设备（Android 12+）|
| `BLUETOOTH` + `BLUETOOTH_ADMIN` | 蓝牙基础（Android ≤ 11）|
| `ACCESS_FINE_LOCATION` | BLE 扫描定位需求（Android ≤ 11）|

---

## 蓝牙数据协议

> 所有指令均发送到设备的**第一个可写 BLE 特征值（Characteristic）**

| 操作 | 十六进制 | 字节数组 |
|------|---------|---------|
| 上升 | `0x01` | `[1]` |
| 停止 | `0x02` | `[2]` |
| 下降 | `0x03` | `[3]` |

如需指定特定的 Service UUID / Characteristic UUID，修改 `_discoverServices()` 方法中的筛选逻辑即可。

---

## 预览

打开 `bluetooth_app_preview.html` 在浏览器中体验完整交互效果。
