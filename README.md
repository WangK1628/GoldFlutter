# Gold Monitor (Flutter + Fluent UI)

Windows 桌面金价/自选股监控 — 自 PyQt6 版完整复刻，使用 **Fluent UI**（Windows 11 风格）。

## 技术栈

| 模块 | 方案 |
|------|------|
| UI | **fluent_ui** 4.x（Acrylic、TabView、ToggleSwitch） |
| 状态 | Riverpod |
| 图表 | fl_chart（带 X/Y 轴） |
| 托盘 | tray_manager |
| 窗口 | window_manager（无边框、迷你模式） |
| 自启 | launch_at_startup |
| 配置 | `%APPDATA%/GoldMonitor/gold_config.json`（与旧版兼容） |

## 功能清单

- **黄金 Tab**：国内/国际金价、涨跌、1H/6H/24H 走势、品牌/银行金价、一句话
- **自选 Tab**：左栏摘要/个股详情+分时，右栏可横纵滚动的表格
- **系统托盘**：显示/隐藏、迷你模式、刷新、设置、开机启动、退出
- **迷你浮窗**：黄金显示单价；自选显示最多 5 行；双击恢复
- **窗口模式**：NORMAL / MINI / HIDDEN（托盘）
- **设置 7 页**：常规、插件、显示、数据、自选、提醒、高级
- **价格预警**：突破/跌破、声音、通知、弹窗
- **关闭/最小化**：可隐藏到托盘

## 运行

```bash
cd FlutterP
flutter pub get
flutter run -d windows
```

## 构建（精简发布，含全部运行依赖 + 图标）

```powershell
cd FlutterP
flutter clean
powershell -ExecutionPolicy Bypass -File scripts\build_release.ps1
```

输出：
- `dist\GoldMonitor\gold_monitor.exe` — 带应用图标
- `dist\GoldMonitor.zip` — 压缩包
- `dist\GoldMonitor\install_runtime_and_run.bat` — 目标电脑首启推荐（自动安装 VC++ 运行库后启动）

目录内仅含运行所需：`gold_monitor.exe`、Flutter/插件 DLL、`data/`（含 `app_icon.ico` 托盘图标），无多余第三方库。
