class BhreHttpResponse {
  final int statusCode;
  final String body;

  const BhreHttpResponse({
    required this.statusCode,
    required this.body,
  });

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
}

abstract class BhreHttpClient {
  Future<BhreHttpResponse> get(
    String url, {
    Map<String, String>? headers,
  });
}
