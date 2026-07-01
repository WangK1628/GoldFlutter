import '../../core/constants.dart';
import '../../models/market_models.dart';
import 'api_client.dart';

class ShopApi {
  ShopApi(this._client);
  final ApiClient _client;

  Future<List<ShopGoldItem>> fetchBrands() async {
    final data = await _fetch();
    return data.brands;
  }

  Future<List<ShopGoldItem>> fetchBanks() async {
    final data = await _fetch();
    return data.banks;
  }

  Future<({List<ShopGoldItem> brands, List<ShopGoldItem> banks})> _fetch() async {
    final json = await _client.getJson(AppConstants.shopGoldUrl);
    if (json['code'] != 200) {
      throw Exception(json['msg'] ?? '金价接口异常');
    }
    final payload = json['data'] as Map<String, dynamic>;
    final brands = (payload['precious_metal_price'] as List<dynamic>)
        .map((i) => ShopGoldItem(
              name: (i['brand'] as String).trim(),
              price: '${i['gold_price']} 元/克',
            ))
        .toList();
    final banks = (payload['bank_gold_bar_price'] as List<dynamic>)
        .map((i) => ShopGoldItem(
              name: (i['bank'] as String).trim(),
              price: '${i['price']} 元/克',
            ))
        .toList();
    return (brands: brands, banks: banks);
  }
}
