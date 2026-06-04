import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_data.dart';

class WeatherService {
  // Замініть на ваш API ключ з openweathermap.org (безкоштовний план)
  static const String _apiKey = '7a20b4c02f3a0e95eaf4edb2e49fbeae';
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';
  static const String _lang = 'ua';
  static const String _units = 'metric';

  /// Поточна погода за координатами
  Future<WeatherData> getCurrentWeather(double lat, double lon) async {
    final url = Uri.parse(
      '$_baseUrl/weather?lat=$lat&lon=$lon&appid=$_apiKey'
      '&units=$_units&lang=$_lang',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return WeatherData.fromCurrentJson(json);
    }
    throw Exception('Помилка отримання погоди: ${response.statusCode}');
  }

  /// Поточна погода за назвою міста
  Future<WeatherData> getCurrentWeatherByCity(String city) async {
    final url = Uri.parse(
      '$_baseUrl/weather?q=${Uri.encodeComponent(city)}'
      '&appid=$_apiKey&units=$_units&lang=$_lang',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return WeatherData.fromCurrentJson(json);
    }
    throw Exception('Місто не знайдено');
  }

  /// Прогноз на 5 днів (кожні 3 години)
  Future<List<WeatherData>> getForecast(double lat, double lon) async {
    final url = Uri.parse(
      '$_baseUrl/forecast?lat=$lat&lon=$lon&appid=$_apiKey'
      '&units=$_units&lang=$_lang&cnt=40',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final city = json['city']['name'] as String;
      final list = json['list'] as List<dynamic>;
      return list
          .map((item) =>
              WeatherData.fromForecastJson(item as Map<String, dynamic>, city))
          .toList();
    }
    throw Exception('Помилка отримання прогнозу: ${response.statusCode}');
  }

  /// Прогноз за містом
  Future<List<WeatherData>> getForecastByCity(String city) async {
    final url = Uri.parse(
      '$_baseUrl/forecast?q=${Uri.encodeComponent(city)}'
      '&appid=$_apiKey&units=$_units&lang=$_lang&cnt=40',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final cityName = json['city']['name'] as String;
      final list = json['list'] as List<dynamic>;
      return list
          .map((item) => WeatherData.fromForecastJson(
              item as Map<String, dynamic>, cityName))
          .toList();
    }
    throw Exception('Помилка отримання прогнозу');
  }

  /// Групування прогнозу по днях
  List<DailyForecast> groupByDay(List<WeatherData> hourly) {
    final Map<String, List<WeatherData>> byDay = {};
    for (final w in hourly) {
      final key =
          '${w.dateTime.year}-${w.dateTime.month}-${w.dateTime.day}';
      byDay.putIfAbsent(key, () => []).add(w);
    }
    return byDay.entries.map((entry) {
      final items = entry.value;
      final temps = items.map((w) => w.temp).toList();
      final midday = items.firstWhere(
        (w) => w.dateTime.hour >= 12,
        orElse: () => items.first,
      );
      return DailyForecast(
        date: items.first.dateTime,
        tempMin: temps.reduce((a, b) => a < b ? a : b),
        tempMax: temps.reduce((a, b) => a > b ? a : b),
        tempAvg: temps.reduce((a, b) => a + b) / temps.length,
        main: midday.main,
        description: midday.description,
        icon: midday.icon,
        maxPop: items
            .map((w) => w.pop ?? 0)
            .reduce((a, b) => a > b ? a : b),
        humidity:
            (items.map((w) => w.humidity).reduce((a, b) => a + b) /
                    items.length)
                .round(),
        windSpeed: items
            .map((w) => w.windSpeed)
            .reduce((a, b) => a > b ? a : b),
        hourly: items,
      );
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Історична погода — імітація на основі поточного прогнозу
  /// (безкоштовний план OWM не надає historical API)
  /// Зберігаємо реальні дані локально і порівнюємо
  Map<String, double> simulateHistoricalComparison(
      WeatherData current, List<DailyForecast> forecast) {
    // Різниця порівняно з "кліматичною нормою" для місяця
    final month = current.dateTime.month;
    final climateNormsUkraine = {
      1: -3.0, 2: -2.0, 3: 3.0, 4: 10.0, 5: 17.0, 6: 21.0,
      7: 23.0, 8: 22.0, 9: 16.0, 10: 9.0, 11: 3.0, 12: -1.0,
    };
    final norm = climateNormsUkraine[month] ?? 10.0;
    return {
      'current_vs_norm': current.temp - norm,
      'norm': norm,
      'current': current.temp,
    };
  }
}
