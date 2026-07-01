class AppConfig {
  AppConfig({
    this.priceRefreshSeconds = 3,
    this.exchangeRefreshSeconds = 60,
    this.shopRefreshSeconds = 120,
    this.sentenceRefreshSeconds = 30,
    this.stockRefreshSeconds = 3,
    this.startInTray = false,
    this.startMinimized = false,
    this.alwaysOnTop = false,
    this.closeHides = true,
    this.minimizeToTray = true,
    this.startOnBoot = false,
    this.hideFromTaskbar = true,
    this.opacity = 0.96,
    this.theme = 'light',
    this.themePreset = 'gold_luxe',
    this.fontFamily = 'Microsoft YaHei',
    this.fontSize = 11,
    this.cornerRadius = 12,
    this.shadow = true,
    this.animation = true,
    this.showInternational = true,
    this.showDomestic = true,
    this.showExchange = true,
    this.showSentence = true,
    this.showChart = true,
    this.showBrand = true,
    this.showBank = true,
    this.chartRange = '24H',
    this.goldPrice = true,
    this.goldChart = true,
    this.brandGold = true,
    this.bankGold = true,
    this.sentence = true,
    this.stockBoard = true,
    this.stockCodes = const ['sh000001'],
    this.lastTab = 'gold',
    this.selectedCode = '',
    this.codeVisible = false,
    this.nameVisible = true,
    this.priceVisible = true,
    this.changeVisible = false,
    this.changePctVisible = true,
    this.b1s1Visible = false,
    this.commiVisible = false,
    this.volVisible = false,
    this.amountVisible = false,
    this.avgVisible = false,
    this.klineVisible = true,
    this.headerVisible = true,
    this.gridVisible = false,
    this.shortCode = false,
    this.windowWidth = 360,
    this.windowHeight = 420,
    this.windowX = -1,
    this.windowY = -1,
    this.miniMode = false,
    this.alerts = const [],
    this.networkTimeout = 10.0,
    this.cacheSeconds = 120,
    this.logEnabled = false,
    this.debug = false,
  });

  int priceRefreshSeconds;
  int exchangeRefreshSeconds;
  int shopRefreshSeconds;
  int sentenceRefreshSeconds;
  int stockRefreshSeconds;
  bool startInTray;
  bool startMinimized;
  bool alwaysOnTop;
  bool closeHides;
  bool minimizeToTray;
  bool startOnBoot;
  bool hideFromTaskbar;
  double opacity;
  String theme;
  String themePreset;
  String fontFamily;
  int fontSize;
  int cornerRadius;
  bool shadow;
  bool animation;
  bool showInternational;
  bool showDomestic;
  bool showExchange;
  bool showSentence;
  bool showChart;
  bool showBrand;
  bool showBank;
  String chartRange;
  bool goldPrice;
  bool goldChart;
  bool brandGold;
  bool bankGold;
  bool sentence;
  bool stockBoard;
  List<String> stockCodes;
  String lastTab;
  String selectedCode;
  bool codeVisible;
  bool nameVisible;
  bool priceVisible;
  bool changeVisible;
  bool changePctVisible;
  bool b1s1Visible;
  bool commiVisible;
  bool volVisible;
  bool amountVisible;
  bool avgVisible;
  bool klineVisible;
  bool headerVisible;
  bool gridVisible;
  bool shortCode;
  int windowWidth;
  int windowHeight;
  int windowX;
  int windowY;
  bool miniMode;
  List<AlertRule> alerts;
  double networkTimeout;
  int cacheSeconds;
  bool logEnabled;
  bool debug;

  List<String> visibleStockHeaders() {
    final map = {
      '代码': codeVisible,
      '名称': nameVisible,
      '现价': priceVisible,
      '涨跌值': changeVisible,
      '涨跌幅': changePctVisible,
      '买一': b1s1Visible,
      '卖一': b1s1Visible,
      '委比': commiVisible,
      '成交量': volVisible,
      '成交额': amountVisible,
      '均价': avgVisible,
      'K线': klineVisible,
    };
    return defaultHeaders.where((h) => map[h] == true).toList();
  }

  static const defaultHeaders = [
    '代码', '名称', '现价', '涨跌值', '涨跌幅', '买一', '卖一',
    '委比', '成交量', '成交额', '均价', 'K线',
  ];

  Map<String, dynamic> toJson() => {
        'general': {
          'price_refresh_seconds': priceRefreshSeconds,
          'exchange_refresh_seconds': exchangeRefreshSeconds,
          'shop_refresh_seconds': shopRefreshSeconds,
          'sentence_refresh_seconds': sentenceRefreshSeconds,
          'start_in_tray': startInTray,
          'start_minimized': startMinimized,
          'always_on_top': alwaysOnTop,
          'close_hides': closeHides,
          'minimize_to_tray': minimizeToTray,
          'start_on_boot': startOnBoot,
          'hide_from_taskbar': hideFromTaskbar,
        },
        'display': {
          'opacity': opacity,
          'theme': theme,
          'theme_preset': themePreset,
          'font_family': fontFamily,
          'font_size': fontSize,
          'corner_radius': cornerRadius,
          'shadow': shadow,
          'animation': animation,
          'show_international': showInternational,
          'show_domestic': showDomestic,
          'show_exchange': showExchange,
          'show_sentence': showSentence,
          'show_chart': showChart,
          'show_brand': showBrand,
          'show_bank': showBank,
          'chart_range': chartRange,
        },
        'plugins': {
          'gold_price': goldPrice,
          'gold_chart': goldChart,
          'brand_gold': brandGold,
          'bank_gold': bankGold,
          'sentence': sentence,
          'stock_board': stockBoard,
        },
        'stock': {
          'codes': stockCodes,
          'refresh_seconds': stockRefreshSeconds,
          'last_tab': lastTab,
          'selected_code': selectedCode,
          'code_visible': codeVisible,
          'name_visible': nameVisible,
          'price_visible': priceVisible,
          'change_visible': changeVisible,
          'change_pct_visible': changePctVisible,
          'b1s1_visible': b1s1Visible,
          'commi_visible': commiVisible,
          'vol_visible': volVisible,
          'amount_visible': amountVisible,
          'avg_visible': avgVisible,
          'kline_visible': klineVisible,
          'header_visible': headerVisible,
          'grid_visible': gridVisible,
          'short_code': shortCode,
        },
        'window': {
          'width': windowWidth,
          'height': windowHeight,
          'x': windowX,
          'y': windowY,
          'mini_mode': miniMode,
        },
        'alerts': alerts.map((a) => a.toJson()).toList(),
        'advanced': {
          'network_timeout': networkTimeout,
          'cache_seconds': cacheSeconds,
          'log_enabled': logEnabled,
          'debug': debug,
        },
      };

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    final g = json['general'] as Map<String, dynamic>? ?? {};
    final d = json['display'] as Map<String, dynamic>? ?? {};
    final p = json['plugins'] as Map<String, dynamic>? ?? {};
    final s = json['stock'] as Map<String, dynamic>? ?? {};
    final w = json['window'] as Map<String, dynamic>? ?? {};
    final adv = json['advanced'] as Map<String, dynamic>? ?? {};
    final alertsRaw = json['alerts'] as List<dynamic>? ?? [];

    return AppConfig(
      priceRefreshSeconds: g['price_refresh_seconds'] as int? ?? 3,
      exchangeRefreshSeconds: g['exchange_refresh_seconds'] as int? ?? 60,
      shopRefreshSeconds: g['shop_refresh_seconds'] as int? ?? 120,
      sentenceRefreshSeconds: g['sentence_refresh_seconds'] as int? ?? 30,
      stockRefreshSeconds: s['refresh_seconds'] as int? ?? 3,
      startInTray: g['start_in_tray'] as bool? ?? false,
      startMinimized: g['start_minimized'] as bool? ?? false,
      alwaysOnTop: g['always_on_top'] as bool? ?? false,
      closeHides: g['close_hides'] as bool? ?? true,
      minimizeToTray: g['minimize_to_tray'] as bool? ?? true,
      startOnBoot: g['start_on_boot'] as bool? ?? false,
      hideFromTaskbar: g['hide_from_taskbar'] as bool? ?? true,
      opacity: (d['opacity'] as num?)?.toDouble() ?? 0.96,
      theme: d['theme'] as String? ?? 'light',
      themePreset: d['theme_preset'] as String? ?? 'gold_luxe',
      fontFamily: d['font_family'] as String? ?? 'Microsoft YaHei',
      fontSize: d['font_size'] as int? ?? 11,
      cornerRadius: d['corner_radius'] as int? ?? 12,
      shadow: d['shadow'] as bool? ?? true,
      animation: d['animation'] as bool? ?? true,
      showInternational: d['show_international'] as bool? ?? true,
      showDomestic: d['show_domestic'] as bool? ?? true,
      showExchange: d['show_exchange'] as bool? ?? true,
      showSentence: d['show_sentence'] as bool? ?? true,
      showChart: d['show_chart'] as bool? ?? true,
      showBrand: d['show_brand'] as bool? ?? true,
      showBank: d['show_bank'] as bool? ?? true,
      chartRange: d['chart_range'] as String? ?? '24H',
      goldPrice: p['gold_price'] as bool? ?? true,
      goldChart: p['gold_chart'] as bool? ?? true,
      brandGold: p['brand_gold'] as bool? ?? true,
      bankGold: p['bank_gold'] as bool? ?? true,
      sentence: p['sentence'] as bool? ?? true,
      stockBoard: p['stock_board'] as bool? ?? true,
      stockCodes: (s['codes'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? ['sh000001'],
      lastTab: s['last_tab'] as String? ?? 'gold',
      selectedCode: s['selected_code'] as String? ?? '',
      codeVisible: s['code_visible'] as bool? ?? false,
      nameVisible: s['name_visible'] as bool? ?? true,
      priceVisible: s['price_visible'] as bool? ?? true,
      changeVisible: s['change_visible'] as bool? ?? false,
      changePctVisible: s['change_pct_visible'] as bool? ?? true,
      b1s1Visible: s['b1s1_visible'] as bool? ?? false,
      commiVisible: s['commi_visible'] as bool? ?? false,
      volVisible: s['vol_visible'] as bool? ?? false,
      amountVisible: s['amount_visible'] as bool? ?? false,
      avgVisible: s['avg_visible'] as bool? ?? false,
      klineVisible: s['kline_visible'] as bool? ?? true,
      headerVisible: s['header_visible'] as bool? ?? true,
      gridVisible: s['grid_visible'] as bool? ?? false,
      shortCode: s['short_code'] as bool? ?? false,
      windowWidth: w['width'] as int? ?? 360,
      windowHeight: w['height'] as int? ?? 420,
      windowX: w['x'] as int? ?? -1,
      windowY: w['y'] as int? ?? -1,
      miniMode: w['mini_mode'] as bool? ?? false,
      alerts: alertsRaw.map((e) => AlertRule.fromJson(e as Map<String, dynamic>)).toList(),
      networkTimeout: (adv['network_timeout'] as num?)?.toDouble() ?? 10.0,
      cacheSeconds: adv['cache_seconds'] as int? ?? 120,
      logEnabled: adv['log_enabled'] as bool? ?? false,
      debug: adv['debug'] as bool? ?? false,
    );
  }
}

class AlertRule {
  AlertRule({
    this.price = 800,
    this.direction = 'below',
    this.sound = true,
    this.notification = true,
    this.popup = true,
    this.note = '',
    this.triggered = false,
  });

  double price;
  String direction;
  bool sound;
  bool notification;
  bool popup;
  String note;
  bool triggered;

  Map<String, dynamic> toJson() => {
        'price': price,
        'direction': direction,
        'sound': sound,
        'notification': notification,
        'popup': popup,
        'note': note,
        'triggered': triggered,
      };

  factory AlertRule.fromJson(Map<String, dynamic> j) => AlertRule(
        price: (j['price'] as num?)?.toDouble() ?? 800,
        direction: j['direction'] as String? ?? 'below',
        sound: j['sound'] as bool? ?? true,
        notification: j['notification'] as bool? ?? true,
        popup: j['popup'] as bool? ?? true,
        note: j['note'] as String? ?? '',
        triggered: j['triggered'] as bool? ?? false,
      );
}
