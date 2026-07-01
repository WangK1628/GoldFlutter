class AppConstants {
  static const appName = 'Gold Monitor';
  static const appVersion = '3.0.0';
  static const ozToGram = 31.1035;

  static const sinaGoldUrl = 'https://hq.sinajs.cn/list=hf_XAU';
  static const sinaReferer = 'https://finance.sina.com.cn/';
  static const shopGoldUrl = 'https://v2.xxapi.cn/api/goldprice';
  static const hitokotoUrl = 'https://v1.hitokoto.cn/?encode=text';
  static const bocUrl = 'https://www.boc.cn/sourcedb/whpj/';
  static const exchangeFallbackUrl = 'https://api.exchangerate-api.com/v4/latest/USD';

  static const userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

  static const defaultPriceInterval = 3;
  static const defaultExchangeInterval = 60;
  static const defaultShopInterval = 120;
  static const defaultSentenceInterval = 30;
  static const defaultStockInterval = 3;
  static const networkTimeout = 10.0;

  static const colorRise = 0xFFE53935;
  static const colorFall = 0xFF43A047;
  static const colorPrimary = 0xFF0078D4;
  static const colorTextDim = 0xFF6B7280;

  static const chartRanges = ['1H', '6H', '24H'];
  static const chartRangeSeconds = {'1H': 3600, '6H': 21600, '24H': 86400};

  static const allStockHeaders = [
    '代码', '名称', '现价', '涨跌值', '涨跌幅', '买一', '卖一',
    '委比', '成交量', '成交额', '均价', 'K线',
  ];
}
