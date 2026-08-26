class BhreNetworkConfig {
  final Duration connectTimeout;
  final Duration receiveTimeout;

  const BhreNetworkConfig({
    this.connectTimeout = const Duration(seconds: 10),
    this.receiveTimeout = const Duration(seconds: 20),
  });
}
