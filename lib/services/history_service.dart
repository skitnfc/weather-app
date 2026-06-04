import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/weather_data.dart';

class HistoricalRecord {
  final DateTime date;
  final double temp;
  final double tempMin;
  final double tempMax;
  final String main;
  final int humidity;
  final double windSpeed;

  HistoricalRecord({
    required this.date,
    required this.temp,
    required this.tempMin,
    required this.tempMax,
    required this.main,
    required this.humidity,
    required this.windSpeed,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'temp': temp,
        'tempMin': tempMin,
        'tempMax': tempMax,
        'main': main,
        'humidity': humidity,
        'windSpeed': windSpeed,
      };

  factory HistoricalRecord.fromJson(Map<String, dynamic> json) =>
      HistoricalRecord(
        date: DateTime.parse(json['date'] as String),
        temp: (json['temp'] as num).toDouble(),
        tempMin: (json['tempMin'] as num).toDouble(),
        tempMax: (json['tempMax'] as num).toDouble(),
        main: json['main'] as String,
        humidity: json['humidity'] as int,
        windSpeed: (json['windSpeed'] as num).toDouble(),
      );
}

class HistoryService {
  static const String _key = 'weather_history';

  /// Зберегти запис поточної погоди
  Future<void> saveRecord(WeatherData w) async {
    final prefs = await SharedPreferences.getInstance();
    final records = await getRecords();
    final newRecord = HistoricalRecord(
      date: w.dateTime,
      temp: w.temp,
      tempMin: w.tempMin,
      tempMax: w.tempMax,
      main: w.main,
      humidity: w.humidity,
      windSpeed: w.windSpeed,
    );

    // Не дублювати за той самий день
    final today = DateTime(w.dateTime.year, w.dateTime.month, w.dateTime.day);
    records.removeWhere((r) {
      final d = DateTime(r.date.year, r.date.month, r.date.day);
      return d == today;
    });
    records.add(newRecord);

    // Зберігати максимум 400 записів (~13 місяців)
    if (records.length > 400) {
      records.removeRange(0, records.length - 400);
    }

    final encoded =
        jsonEncode(records.map((r) => r.toJson()).toList());
    await prefs.setString(_key, encoded);
  }

  /// Отримати всі збережені записи
  Future<List<HistoricalRecord>> getRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((item) =>
            HistoricalRecord.fromJson(item as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Знайти запис рівно рік тому (±7 днів)
  Future<HistoricalRecord?> getLastYearRecord(DateTime date) async {
    final records = await getRecords();
    final target = DateTime(date.year - 1, date.month, date.day);

    HistoricalRecord? closest;
    int minDiff = 999;
    for (final r in records) {
      final diff = (r.date.difference(target).inDays).abs();
      if (diff < minDiff && diff <= 7) {
        minDiff = diff;
        closest = r;
      }
    }
    return closest;
  }

  /// Порівняння: поточна vs торішня
  Future<WeatherComparison?> compareWithLastYear(WeatherData current) async {
    final lastYear = await getLastYearRecord(current.dateTime);
    if (lastYear == null) return null;
    return WeatherComparison(current: current, lastYear: lastYear);
  }

  /// Кліматичні норми (середнє за місяць для України)
  static const Map<int, _ClimateNorm> _norms = {
    1: _ClimateNorm(temp: -3.5, rain: 40),
    2: _ClimateNorm(temp: -2.5, rain: 38),
    3: _ClimateNorm(temp: 3.0, rain: 42),
    4: _ClimateNorm(temp: 10.5, rain: 45),
    5: _ClimateNorm(temp: 17.0, rain: 52),
    6: _ClimateNorm(temp: 20.5, rain: 68),
    7: _ClimateNorm(temp: 22.5, rain: 72),
    8: _ClimateNorm(temp: 21.5, rain: 60),
    9: _ClimateNorm(temp: 16.0, rain: 48),
    10: _ClimateNorm(temp: 9.0, rain: 44),
    11: _ClimateNorm(temp: 3.0, rain: 46),
    12: _ClimateNorm(temp: -1.5, rain: 42),
  };

  _ClimateNorm getNorm(int month) =>
      _norms[month] ?? const _ClimateNorm(temp: 10, rain: 50);

  /// Статистика за поточний місяць зі збережених записів
  Future<MonthlyStats?> getMonthlyStats(int year, int month) async {
    final records = await getRecords();
    final filtered = records
        .where((r) => r.date.year == year && r.date.month == month)
        .toList();
    if (filtered.isEmpty) return null;

    final temps = filtered.map((r) => r.temp).toList();
    return MonthlyStats(
      avgTemp: temps.reduce((a, b) => a + b) / temps.length,
      minTemp: temps.reduce((a, b) => a < b ? a : b),
      maxTemp: temps.reduce((a, b) => a > b ? a : b),
      rainyDays:
          filtered.where((r) => r.main == 'Rain' || r.main == 'Drizzle').length,
      totalDays: filtered.length,
      norm: getNorm(month),
    );
  }
}

class _ClimateNorm {
  final double temp;
  final double rain; // mm/місяць
  const _ClimateNorm({required this.temp, required this.rain});
}

class WeatherComparison {
  final WeatherData current;
  final HistoricalRecord lastYear;

  WeatherComparison({required this.current, required this.lastYear});

  double get tempDiff => current.temp - lastYear.temp;
  bool get isWarmerThanLastYear => tempDiff > 0;
  String get tempDiffText {
    final diff = tempDiff.abs().toStringAsFixed(1);
    return isWarmerThanLastYear ? '+$diff°C тепліше' : '-$diff°C холодніше';
  }
}

class MonthlyStats {
  final double avgTemp;
  final double minTemp;
  final double maxTemp;
  final int rainyDays;
  final int totalDays;
  final _ClimateNorm norm;

  MonthlyStats({
    required this.avgTemp,
    required this.minTemp,
    required this.maxTemp,
    required this.rainyDays,
    required this.totalDays,
    required this.norm,
  });

  double get tempVsNorm => avgTemp - norm.temp;
}
