class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  Future<void> initialize() async {}
  Future<void> sendForecastNotifications(dynamic current, dynamic forecast) async {}
  Future<void> cancelAll() async {}
  Future<void> scheduleMorningForecast({required int hour, required int minute, required String message}) async {}
}
