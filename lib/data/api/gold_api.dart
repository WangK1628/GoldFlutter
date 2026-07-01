import '../../core/constants.dart';
import 'api_client.dart';

class GoldApi {
  GoldApi(this._client);
  final ApiClient _client;

  Future<double> fetchUsdPrice() async {
    final text = await _client.getText(
      AppConstants.sinaGoldUrl,
      headers: {'Referer': AppConstants.sinaReferer},
    );
    final match = RegExp(r'hq_str_hf_XAU="([^"]+)"').firstMatch(text);
    if (match == null) throw Exception('无法解析新浪金价');
    final parts = match.group(1)!.split(',');
    return double.parse(parts[0]);
  }
}
