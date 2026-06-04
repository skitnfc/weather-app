class WeatherData {
  final double temp;
  final double feelsLike;
  final double tempMin;
  final double tempMax;
  final int humidity;
  final double windSpeed;
  final String description;
  final String icon;
  final String main; // Rain, Clear, Clouds, Snow, etc.
  final int pressure;
  final int visibility;
  final double? pop; // probability of precipitation (forecast only)
  final DateTime dateTime;
  final String cityName;

  WeatherData({
    required this.temp,
    required this.feelsLike,
    required this.tempMin,
    required this.tempMax,
    required this.humidity,
    required this.windSpeed,
    required this.description,
    required this.icon,
    required this.main,
    required this.pressure,
    required this.visibility,
    this.pop,
    required this.dateTime,
    required this.cityName,
  });

  factory WeatherData.fromCurrentJson(Map<String, dynamic> json) {
    return WeatherData(
      temp: (json['main']['temp'] as num).toDouble(),
      feelsLike: (json['main']['feels_like'] as num).toDouble(),
      tempMin: (json['main']['temp_min'] as num).toDouble(),
      tempMax: (json['main']['temp_max'] as num).toDouble(),
      humidity: json['main']['humidity'] as int,
      windSpeed: (json['wind']['speed'] as num).toDouble(),
      description: json['weather'][0]['description'] as String,
      icon: json['weather'][0]['icon'] as String,
      main: json['weather'][0]['main'] as String,
      pressure: json['main']['pressure'] as int,
      visibility: (json['visibility'] ?? 10000) as int,
      dateTime: DateTime.fromMillisecondsSinceEpoch(
          (json['dt'] as int) * 1000),
      cityName: json['name'] ?? '',
    );
  }

  factory WeatherData.fromForecastJson(
      Map<String, dynamic> json, String city) {
    return WeatherData(
      temp: (json['main']['temp'] as num).toDouble(),
      feelsLike: (json['main']['feels_like'] as num).toDouble(),
      tempMin: (json['main']['temp_min'] as num).toDouble(),
      tempMax: (json['main']['temp_max'] as num).toDouble(),
      humidity: json['main']['humidity'] as int,
      windSpeed: (json['wind']['speed'] as num).toDouble(),
      description: json['weather'][0]['description'] as String,
      icon: json['weather'][0]['icon'] as String,
      main: json['weather'][0]['main'] as String,
      pressure: json['main']['pressure'] as int,
      visibility: (json['visibility'] ?? 10000) as int,
      pop: (json['pop'] as num?)?.toDouble(),
      dateTime: DateTime.fromMillisecondsSinceEpoch(
          (json['dt'] as int) * 1000),
      cityName: city,
    );
  }

  String get iconUrl =>
      'https://openweathermap.org/img/wn/$icon@2x.png';

  bool get isRainy =>
      main == 'Rain' || main == 'Drizzle' || main == 'Thunderstorm';
  bool get isClear => main == 'Clear';
  bool get isCloudy => main == 'Clouds';
  bool get isSnowy => main == 'Snow';
  bool get isHot => temp >= 28;
  bool get isCold => temp <= 5;
  bool get isWindy => windSpeed >= 10;
  bool get isUVRisk => isClear && dateTime.hour >= 10 && dateTime.hour <= 16;
}

class DailyForecast {
  final DateTime date;
  final double tempMin;
  final double tempMax;
  final double tempAvg;
  final String main;
  final String description;
  final String icon;
  final double maxPop;
  final int humidity;
  final double windSpeed;
  final List<WeatherData> hourly;

  DailyForecast({
    required this.date,
    required this.tempMin,
    required this.tempMax,
    required this.tempAvg,
    required this.main,
    required this.description,
    required this.icon,
    required this.maxPop,
    required this.humidity,
    required this.windSpeed,
    required this.hourly,
  });

  // Score 0-100 for outdoor activity suitability
  int get activityScore {
    int score = 100;
    if (main == 'Rain' || main == 'Thunderstorm') score -= 50;
    if (main == 'Drizzle') score -= 25;
    if (main == 'Snow') score -= 30;
    if (tempAvg < 5) score -= 20;
    if (tempAvg > 32) score -= 20;
    if (windSpeed > 12) score -= 15;
    if (maxPop > 0.6) score -= 20;
    if (main == 'Clear') score += 10;
    return score.clamp(0, 100);
  }

  String get activityLabel {
    final s = activityScore;
    if (s >= 80) return 'Відмінно';
    if (s >= 60) return 'Добре';
    if (s >= 40) return 'Задовільно';
    return 'Погано';
  }
}
