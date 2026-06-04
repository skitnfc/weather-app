import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/weather_data.dart';
import 'recommendation_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
        android: androidSettings, iOS: iosSettings);

    await _plugin.initialize(settings,
        onDidReceiveNotificationResponse: (_) {});
    _initialized = true;
  }

  /// Запланувати щоранкове нагадування о вибраній годині
  Future<void> scheduleMorningForecast({
    required int hour,
    required int minute,
    required String message,
  }) async {
    await _plugin.cancelAll();
    final prefs = await SharedPreferences.getInstance();
    final tzName =
        prefs.getString('timezone') ?? 'Europe/Kiev';
    final location = tz.getLocation(tzName);
    final now = tz.TZDateTime.now(location);

    var scheduled = tz.TZDateTime(location, now.year, now.month, now.day,
        hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'morning_forecast',
      'Ранковий прогноз',
      channelDescription: 'Щоденний прогноз погоди вранці',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails();
    const details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _plugin.zonedSchedule(
      1,
      '🌤 Прогноз погоди',
      message,
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Нагадування взяти парасольку (якщо є дощ)
  Future<void> scheduleUmbrellaReminder(WeatherData forecast) async {
    if (!forecast.isRainy && (forecast.pop ?? 0) < 0.4) return;

    const androidDetails = AndroidNotificationDetails(
      'umbrella_reminder',
      'Нагадування парасольки',
      channelDescription: 'Нагадування коли очікується дощ',
      importance: Importance.defaultImportance,
    );
    const details =
        NotificationDetails(android: androidDetails);

    await _plugin.show(
      2,
      '☂️ Візьміть парасольку!',
      'Сьогодні очікується дощ. Не забудьте парасольку або дощовик.',
      details,
    );
  }

  /// Нагадування сонцезахисний крем
  Future<void> scheduleUVReminder() async {
    const androidDetails = AndroidNotificationDetails(
      'uv_reminder',
      'УФ нагадування',
      channelDescription: 'Нагадування про сонцезахисний крем',
      importance: Importance.defaultImportance,
    );
    const details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      3,
      '🧴 Не забудьте крем!',
      'Сьогодні висока УФ-активність. Нанесіть сонцезахисний крем SPF 30+.',
      details,
    );
  }

  /// Надіслати нотифікацію на основі прогнозу
  Future<void> sendForecastNotifications(
      WeatherData current, List<DailyForecast> forecast) async {
    final rec = RecommendationService();
    final message = rec.getMorningMessage(current, forecast);

    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt('notif_hour') ?? 7;
    final minute = prefs.getInt('notif_minute') ?? 30;

    await scheduleMorningForecast(
        hour: hour, minute: minute, message: message);

    if (current.isRainy || (current.pop ?? 0) > 0.4) {
      await scheduleUmbrellaReminder(current);
    }
    if (current.isUVRisk) {
      await scheduleUVReminder();
    }
  }

  Future<void> cancelAll() => _plugin.cancelAll();
}
