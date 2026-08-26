import 'package:http/http.dart' as http;

import 'bhre_http_client.dart';
import 'bhre_network_config.dart';

class BhreHttpClientImpl implements BhreHttpClient {
  final BhreNetworkConfig config;

  BhreHttpClientImpl({BhreNetworkConfig? config})
    : config = config ?? const BhreNetworkConfig();

  @override
  Future<BhreHttpResponse> get(
    String url, {
    Map<String, String>? headers,
  }) async {
    final response = await http
        .get(Uri.parse(url), headers: headers)
        .timeout(config.receiveTimeout);

    return BhreHttpResponse(
      statusCode: response.statusCode,
      body: response.body,
    );
  }
}
