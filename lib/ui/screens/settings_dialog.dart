import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_design.dart';
import '../../models/app_config.dart';
import '../../providers/app_providers.dart';
import '../../services/autostart_service.dart';
import '../../services/window_layout.dart';
import '../../services/window_controller.dart';

class SettingsDialog extends ConsumerStatefulWidget {
  const SettingsDialog({super.key});

  @override
  ConsumerState<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends ConsumerState<SettingsDialog> {
  int _tab = 0;
  late AppConfig _draft;
  final _codesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _draft = _clone(ref.read(configProvider));
    _codesCtrl.text = _draft.stockCodes.join(',');
  }

  AppConfig _clone(AppConfig c) {
    return AppConfig(
      priceRefreshSeconds: c.priceRefreshSeconds,
      exchangeRefreshSeconds: c.exchangeRefreshSeconds,
      shopRefreshSeconds: c.shopRefreshSeconds,
      sentenceRefreshSeconds: c.sentenceRefreshSeconds,
      stockRefreshSeconds: c.stockRefreshSeconds,
      startInTray: c.startInTray,
      startMinimized: c.startMinimized,
      alwaysOnTop: c.alwaysOnTop,
      closeHides: c.closeHides,
      minimizeToTray: c.minimizeToTray,
      startOnBoot: c.startOnBoot,
      hideFromTaskbar: c.hideFromTaskbar,
      opacity: c.opacity,
      theme: c.theme,
      themePreset: c.themePreset,
      fontFamily: c.fontFamily,
      fontSize: c.fontSize,
      cornerRadius: c.cornerRadius,
      shadow: c.shadow,
      animation: c.animation,
      showInternational: c.showInternational,
      showDomestic: c.showDomestic,
      showExchange: c.showExchange,
      showSentence: c.showSentence,
      showChart: c.showChart,
      showBrand: c.showBrand,
      showBank: c.showBank,
      chartRange: c.chartRange,
      goldPrice: c.goldPrice,
      goldChart: c.goldChart,
      brandGold: c.brandGold,
      bankGold: c.bankGold,
      sentence: c.sentence,
      stockBoard: c.stockBoard,
      stockCodes: List.from(c.stockCodes),
      lastTab: c.lastTab,
      selectedCode: c.selectedCode,
      codeVisible: c.codeVisible,
      nameVisible: c.nameVisible,
      priceVisible: c.priceVisible,
      changeVisible: c.changeVisible,
      changePctVisible: c.changePctVisible,
      b1s1Visible: c.b1s1Visible,
      commiVisible: c.commiVisible,
      volVisible: c.volVisible,
      amountVisible: c.amountVisible,
      avgVisible: c.avgVisible,
      klineVisible: c.klineVisible,
      headerVisible: c.headerVisible,
      gridVisible: c.gridVisible,
      shortCode: c.shortCode,
      windowWidth: c.windowWidth,
      windowHeight: c.windowHeight,
      windowX: c.windowX,
      windowY: c.windowY,
      miniMode: c.miniMode,
      alerts: c.alerts.map((a) => AlertRule(
            price: a.price,
            direction: a.direction,
            sound: a.sound,
            notification: a.notification,
            popup: a.popup,
            note: a.note,
            triggered: a.triggered,
          )).toList(),
      networkTimeout: c.networkTimeout,
      cacheSeconds: c.cacheSeconds,
      logEnabled: c.logEnabled,
      debug: c.debug,
    );
  }

  @override
  void dispose() {
    _codesCtrl.dispose();
    super.dispose();
  }

  static const _sections = <(IconData, String)>[
    (FluentIcons.settings, '常规'),
    (FluentIcons.puzzle, '插件'),
    (FluentIcons.color, '显示'),
    (FluentIcons.database, '数据'),
    (FluentIcons.line_chart, '自选'),
    (FluentIcons.ringer, '提醒'),
    (FluentIcons.code, '高级'),
  ];

  static const _dialogW = WindowLayout.settingsDialogWidth;
  static const _dialogH = WindowLayout.settingsDialogHeight;
  static const _navW = 128.0;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);

    return ContentDialog(
      constraints: const BoxConstraints(
        maxWidth: _dialogW + 32,
        maxHeight: _dialogH + 120,
      ),
      content: SizedBox(
        width: _dialogW,
        height: _dialogH,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
              child: Row(
                children: [
                  Icon(FluentIcons.settings, size: 18, color: theme.accentColor),
                  const SizedBox(width: 8),
                  Text('设置', style: theme.typography.subtitle),
                  const Spacer(),
                  Tooltip(
                    message: '关闭',
                    child: IconButton(
                      icon: const Icon(FluentIcons.cancel, size: 14),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: _navW,
                    decoration: BoxDecoration(
                      color: theme.resources.cardStrokeColorDefault.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      itemCount: _sections.length,
                      itemBuilder: (_, i) => _navTile(context, i),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _scroll(_pageBody()),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Button(onPressed: () => Navigator.pop(context), child: const Text('取消')),
                const SizedBox(width: 8),
                FilledButton(onPressed: _save, child: const Text('保存并应用')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _navTile(BuildContext context, int index) {
    final (icon, label) = _sections[index];
    final selected = _tab == index;
    final theme = FluentTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Button(
        onPressed: () => setState(() => _tab = index),
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(
            selected ? theme.accentColor.withValues(alpha: 0.12) : Colors.transparent,
          ),
          padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: selected ? theme.accentColor : theme.inactiveColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  color: selected ? theme.accentColor : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pageBody() {
    switch (_tab) {
      case 0:
        return _generalTab();
      case 1:
        return _pluginsTab();
      case 2:
        return _displayTab();
      case 3:
        return _dataTab();
      case 4:
        return _stockTab();
      case 5:
        return _alertsTab();
      case 6:
        return _advancedTab();
      default:
        return _generalTab();
    }
  }

  Widget _scroll(Widget child) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
        child: child,
      );

  Widget _generalTab() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _slider('金价刷新(秒)', _draft.priceRefreshSeconds, 1, 60, (v) => _draft.priceRefreshSeconds = v.round()),
          _slider('汇率刷新(秒)', _draft.exchangeRefreshSeconds, 10, 600, (v) => _draft.exchangeRefreshSeconds = v.round()),
          _slider('品牌金刷新(秒)', _draft.shopRefreshSeconds, 30, 3600, (v) => _draft.shopRefreshSeconds = v.round()),
          _toggle('启动时仅在托盘', _draft.startInTray, (v) => _draft.startInTray = v),
          _toggle('启动时最小化到托盘', _draft.startMinimized, (v) => _draft.startMinimized = v),
          _toggle('开机自动启动', _draft.startOnBoot, (v) => _draft.startOnBoot = v),
          _toggle('最小化到托盘', _draft.minimizeToTray, (v) => _draft.minimizeToTray = v),
          _toggle('关闭隐藏到托盘', _draft.closeHides, (v) => _draft.closeHides = v),
          _toggle('智能浮层', _draft.alwaysOnTop, (v) => _draft.alwaysOnTop = v),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(
              '主界面保持在普通窗口之上；迷你模式默认开启。截屏、任务栏、托盘菜单、设置时自动让路。',
              style: TextStyle(fontSize: 11, color: FluentTheme.of(context).inactiveColor),
            ),
          ),
          _toggle('不在任务栏显示', _draft.hideFromTaskbar, (v) => _draft.hideFromTaskbar = v),
        ],
      );

  Widget _pluginsTab() => Column(
        children: [
          _toggle('金价面板', _draft.goldPrice, (v) => _draft.goldPrice = v),
          _toggle('走势图表', _draft.goldChart, (v) => _draft.goldChart = v),
          _toggle('品牌金价', _draft.brandGold, (v) => _draft.brandGold = v),
          _toggle('银行金条', _draft.bankGold, (v) => _draft.bankGold = v),
          _toggle('一句话', _draft.sentence, (v) => _draft.sentence = v),
          _toggle('自选股看板', _draft.stockBoard, (v) => _draft.stockBoard = v),
        ],
      );

  Widget _displayTab() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InfoLabel(label: '字号: ${_draft.fontSize}', child: Slider(value: _draft.fontSize.toDouble(), min: 8, max: 24, divisions: 16, onChanged: (v) => setState(() => _draft.fontSize = v.round()))),
          InfoLabel(label: '透明度: ${(_draft.opacity * 100).round()}%', child: Slider(value: _draft.opacity, min: 0.5, max: 1, divisions: 10, onChanged: (v) => setState(() => _draft.opacity = v))),
          const SizedBox(height: 8),
          const Text('主题风格'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppDesign.presets.entries.map((e) {
              final selected = _draft.themePreset == e.key;
              final preset = e.value;
              return Button(
                onPressed: () => setState(() {
                  _draft.themePreset = e.key;
                  _draft.theme = preset.isDark ? 'dark' : 'light';
                }),
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(selected ? preset.chipSelected : preset.chipBg),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: preset.gold,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: preset.cardBorder),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(preset.name, style: TextStyle(fontSize: 11, color: preset.textPrimary)),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          ComboBox<String>(
            value: _draft.theme,
            items: const [
              ComboBoxItem(value: 'light', child: Text('浅色模式')),
              ComboBoxItem(value: 'dark', child: Text('深色模式')),
            ],
            onChanged: (v) => setState(() => _draft.theme = v ?? 'light'),
          ),
          _toggle('卡片阴影', _draft.shadow, (v) => _draft.shadow = v),
          _toggle('启用动画', _draft.animation, (v) => _draft.animation = v),
        ],
      );

  Widget _dataTab() => Column(
        children: [
          _toggle('国际黄金', _draft.showInternational, (v) => _draft.showInternational = v),
          _toggle('人民币黄金', _draft.showDomestic, (v) => _draft.showDomestic = v),
          _toggle('美元汇率', _draft.showExchange, (v) => _draft.showExchange = v),
          _toggle('一句话', _draft.showSentence, (v) => _draft.showSentence = v),
          _toggle('走势图', _draft.showChart, (v) => _draft.showChart = v),
          _toggle('品牌金价', _draft.showBrand, (v) => _draft.showBrand = v),
          _toggle('银行金条', _draft.showBank, (v) => _draft.showBank = v),
          ComboBox<String>(
            value: _draft.chartRange,
            items: const [
              ComboBoxItem(value: '1H', child: Text('1H')),
              ComboBoxItem(value: '6H', child: Text('6H')),
              ComboBoxItem(value: '24H', child: Text('24H')),
            ],
            onChanged: (v) => setState(() => _draft.chartRange = v ?? '24H'),
          ),
        ],
      );

  Widget _stockTab() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _slider('刷新间隔(秒)', _draft.stockRefreshSeconds, 1, 60, (v) => _draft.stockRefreshSeconds = v.round()),
          InfoLabel(
            label: '监控代码（逗号分隔）',
            child: TextBox(controller: _codesCtrl, placeholder: 'sh000001,sh600519'),
          ),
          _toggle('代码列', _draft.codeVisible, (v) => _draft.codeVisible = v),
          _toggle('名称列', _draft.nameVisible, (v) => _draft.nameVisible = v),
          _toggle('现价列', _draft.priceVisible, (v) => _draft.priceVisible = v),
          _toggle('涨跌值列', _draft.changeVisible, (v) => _draft.changeVisible = v),
          _toggle('涨跌幅列', _draft.changePctVisible, (v) => _draft.changePctVisible = v),
          _toggle('买一/卖一列', _draft.b1s1Visible, (v) => _draft.b1s1Visible = v),
          _toggle('委比列', _draft.commiVisible, (v) => _draft.commiVisible = v),
          _toggle('成交量列', _draft.volVisible, (v) => _draft.volVisible = v),
          _toggle('成交额列', _draft.amountVisible, (v) => _draft.amountVisible = v),
          _toggle('均价列', _draft.avgVisible, (v) => _draft.avgVisible = v),
          _toggle('K线列', _draft.klineVisible, (v) => _draft.klineVisible = v),
          _toggle('显示表头', _draft.headerVisible, (v) => _draft.headerVisible = v),
          _toggle('显示网格', _draft.gridVisible, (v) => _draft.gridVisible = v),
          _toggle('简短代码', _draft.shortCode, (v) => _draft.shortCode = v),
        ],
      );

  Widget _alertsTab() => Column(
        children: [
          for (var i = 0; i < _draft.alerts.length; i++)
            _AlertEditor(
              key: ValueKey('alert_$i'),
              rule: _draft.alerts[i],
              onChanged: () => setState(() {}),
            ),
          Button(
            child: const Text('添加预警'),
            onPressed: () => setState(() => _draft.alerts.add(AlertRule(note: '新预警'))),
          ),
          if (_draft.alerts.isNotEmpty)
            Button(
              child: const Text('删除最后一条'),
              onPressed: () => setState(() => _draft.alerts.removeLast()),
            ),
        ],
      );

  Widget _advancedTab() => Column(
        children: [
          _slider('缓存时间(秒)', _draft.cacheSeconds, 30, 3600, (v) => _draft.cacheSeconds = v.round()),
          _slider('网络超时(秒)', _draft.networkTimeout.round(), 3, 60, (v) => _draft.networkTimeout = v),
          _toggle('启用日志', _draft.logEnabled, (v) => _draft.logEnabled = v),
          _toggle('调试模式', _draft.debug, (v) => _draft.debug = v),
        ],
      );

  static const _labelWidth = 148.0;

  Widget _slider(String label, num value, double min, double max, ValueChanged<double> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: _labelWidth,
            child: Text(label, style: const TextStyle(fontSize: 13)),
          ),
          Expanded(
            child: Slider(
              value: value.toDouble(),
              min: min,
              max: max,
              onChanged: (v) => setState(() => onChanged(v)),
            ),
          ),
          SizedBox(
            width: 36,
            child: Text(
              '$value',
              textAlign: TextAlign.end,
              style: TextStyle(fontSize: 12, color: FluentTheme.of(context).resources.textFillColorSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggle(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: _labelWidth,
            child: Text(label, style: const TextStyle(fontSize: 13)),
          ),
          ToggleSwitch(
            checked: value,
            onChanged: (v) => setState(() => onChanged(v)),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    _draft.stockCodes = _codesCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (_draft.stockCodes.isEmpty) _draft.stockCodes = ['sh000001'];
    ref.read(configProvider.notifier).update((_) => _draft);
    await ref.read(configProvider.notifier).save();
    if (_draft.startOnBoot) {
      await AutostartService.setEnabled(true);
    } else {
      await AutostartService.setEnabled(false);
    }
    ref.read(marketProvider.notifier).restartTimers();
    await ref.read(windowControllerProvider.notifier).applyWindowFlags(_draft);
    if (mounted) Navigator.pop(context);
  }
}

class _AlertEditor extends StatefulWidget {
  const _AlertEditor({super.key, required this.rule, required this.onChanged});

  final AlertRule rule;
  final VoidCallback onChanged;

  @override
  State<_AlertEditor> createState() => _AlertEditorState();
}

class _AlertEditorState extends State<_AlertEditor> {
  late final TextEditingController _noteCtrl;
  late final TextEditingController _priceCtrl;

  @override
  void initState() {
    super.initState();
    _noteCtrl = TextEditingController(text: widget.rule.note);
    _priceCtrl = TextEditingController(text: widget.rule.price.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rule = widget.rule;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InfoLabel(
                label: '备注',
                child: TextBox(
                  controller: _noteCtrl,
                  onChanged: (v) {
                    rule.note = v;
                    widget.onChanged();
                  },
                  placeholder: '预警说明',
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: InfoLabel(
                      label: '触发价格',
                      child: TextBox(
                        controller: _priceCtrl,
                        onChanged: (v) {
                          rule.price = double.tryParse(v) ?? rule.price;
                          widget.onChanged();
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InfoLabel(
                      label: '方向',
                      child: ComboBox<String>(
                        value: rule.direction,
                        items: const [
                          ComboBoxItem(value: 'above', child: Text('突破 ↑')),
                          ComboBoxItem(value: 'below', child: Text('跌破 ↓')),
                        ],
                        onChanged: (v) {
                          setState(() => rule.direction = v ?? 'below');
                          widget.onChanged();
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Checkbox(
                    checked: rule.sound,
                    onChanged: (v) {
                      setState(() => rule.sound = v ?? false);
                      widget.onChanged();
                    },
                    content: const Text('声音'),
                  ),
                  Checkbox(
                    checked: rule.notification,
                    onChanged: (v) {
                      setState(() => rule.notification = v ?? false);
                      widget.onChanged();
                    },
                    content: const Text('通知'),
                  ),
                  Checkbox(
                    checked: rule.popup,
                    onChanged: (v) {
                      setState(() => rule.popup = v ?? false);
                      widget.onChanged();
                    },
                    content: const Text('弹窗'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
