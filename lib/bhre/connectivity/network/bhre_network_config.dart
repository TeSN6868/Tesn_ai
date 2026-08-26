class BhreNetworkConfig {
  final String baseUrl;
  final Duration connectTimeout;
  final Duration receiveTimeout;

  const BhreNetworkConfig({
    this.baseUrl = 'https://m8-messenger-api.coolalaga686.workers.dev',
    this.connectTimeout = const Duration(seconds: 10),
    this.receiveTimeout = const Duration(seconds: 20),
  });
}
