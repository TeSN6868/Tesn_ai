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
    final uri = _buildUri(url);

    final response = await http
        .get(uri, headers: headers)
        .timeout(config.receiveTimeout);

    return BhreHttpResponse(
      statusCode: response.statusCode,
      body: response.body,
    );
  }

  Uri _buildUri(String url) {
    final value = url.trim();

    if (value.startsWith('http://') || value.startsWith('https://')) {
      return Uri.parse(value);
    }

    final base = config.baseUrl.endsWith('/')
        ? config.baseUrl.substring(0, config.baseUrl.length - 1)
        : config.baseUrl;

    final path = value.startsWith('/') ? value : '/$value';

    return Uri.parse('$base$path');
  }
}
