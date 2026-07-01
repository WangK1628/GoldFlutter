import '../../core/constants.dart';
import 'api_client.dart';

class ExchangeResult {
  const ExchangeResult(this.rate);
  final double rate;
}

class ExchangeApi {
  ExchangeApi(this._client);
  final ApiClient _client;

  Future<ExchangeResult> fetchUsdCny() async {
    try {
      final text = await _client.getText(AppConstants.bocUrl);
      final rows = RegExp(r'<tr[^>]*>.*?</tr>', dotAll: true).allMatches(text);
      for (final row in rows) {
        if (!row.group(0)!.contains('美元')) continue;
        final nums = RegExp(r'<td>([\d]+\.[\d]+)</td>')
            .allMatches(row.group(0)!)
            .map((m) => m.group(1)!)
            .toList();
        if (nums.length >= 5) {
          return ExchangeResult(double.parse(nums[4]) / 100);
        }
      }
      throw Exception('中行页面未找到美元汇率');
    } catch (_) {
      final json = await _client.getJson(AppConstants.exchangeFallbackUrl);
      final rate = (json['rates'] as Map<String, dynamic>?)?['CNY'];
      if (rate == null) throw Exception('备用汇率获取失败');
      return ExchangeResult((rate as num).toDouble());
    }
  }
}
