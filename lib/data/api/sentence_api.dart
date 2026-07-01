import '../../core/constants.dart';
import 'api_client.dart';

class SentenceApi {
  SentenceApi(this._client);
  final ApiClient _client;

  Future<String> fetch() async {
    final text = await _client.getText(AppConstants.hitokotoUrl);
    return text.trim();
  }
}
