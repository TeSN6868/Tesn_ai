class BhreAlarmService {
  Future<void> schedule({
    required DateTime time,
    required String message,
  }) async {
    // Android alarm integration akan dipasang pada tahap platform service.
    // Untuk sekarang, service ini menjadi kontrak runtime Bree.
  }

  Future<void> cancel(String id) async {
    // Cancellation akan dihubungkan ke Android alarm service.
  }
}
