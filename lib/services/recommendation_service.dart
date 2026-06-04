import '../models/weather_data.dart';

class Recommendation {
  final String emoji;
  final String title;
  final String body;
  final RecommendationType type;

  const Recommendation({
    required this.emoji,
    required this.title,
    required this.body,
    required this.type,
  });
}

enum RecommendationType { clothing, alert, activity, uv }

class RecommendationService {
  /// Повний набір рекомендацій для поточної погоди
  List<Recommendation> getRecommendations(WeatherData w) {
    final list = <Recommendation>[];
    list.addAll(_clothingRecommendations(w));
    list.addAll(_alertRecommendations(w));
    list.addAll(_activityRecommendations(w));
    return list;
  }

  List<Recommendation> _clothingRecommendations(WeatherData w) {
    final recs = <Recommendation>[];
    final temp = w.temp;

    if (temp >= 28) {
      recs.add(const Recommendation(
        emoji: '👕',
        title: 'Легкий одяг',
        body: 'Спекотно! Одягайте легкий, світлий одяг з натуральних тканин.',
        type: RecommendationType.clothing,
      ));
    } else if (temp >= 20) {
      recs.add(const Recommendation(
        emoji: '👔',
        title: 'Літній одяг',
        body: 'Тепла погода — футболка або сорочка, легкі штани чи спідниця.',
        type: RecommendationType.clothing,
      ));
    } else if (temp >= 12) {
      recs.add(const Recommendation(
        emoji: '🧥',
        title: 'Легка куртка',
        body: 'Прохолодно. Потрібна легка куртка або кардиган.',
        type: RecommendationType.clothing,
      ));
    } else if (temp >= 5) {
      recs.add(const Recommendation(
        emoji: '🧣',
        title: 'Тепло одягтися',
        body: 'Холодно. Потрібні тепла куртка, шарф і шапка.',
        type: RecommendationType.clothing,
      ));
    } else {
      recs.add(const Recommendation(
        emoji: '🧤',
        title: 'Зимовий одяг',
        body: 'Мороз! Зимова куртка, шапка, шарф, рукавички — обов\'язково.',
        type: RecommendationType.clothing,
      ));
    }

    if (w.isRainy) {
      recs.add(const Recommendation(
        emoji: '🌂',
        title: 'Візьміть парасольку',
        body: 'Очікується дощ. Не забудьте парасольку або дощовик.',
        type: RecommendationType.alert,
      ));
    } else if ((w.pop ?? 0) > 0.4) {
      recs.add(const Recommendation(
        emoji: '☂️',
        title: 'Парасолька про запас',
        body: 'Є вірогідність опадів. Краще взяти складну парасольку.',
        type: RecommendationType.alert,
      ));
    }

    if (w.isSnowy) {
      recs.add(const Recommendation(
        emoji: '🥾',
        title: 'Зимове взуття',
        body: 'Сніг! Надягайте чоботи або черевики з нековзкою підошвою.',
        type: RecommendationType.clothing,
      ));
    }

    return recs;
  }

  List<Recommendation> _alertRecommendations(WeatherData w) {
    final recs = <Recommendation>[];

    if (w.isUVRisk) {
      recs.add(const Recommendation(
        emoji: '🧴',
        title: 'Сонцезахисний крем',
        body: 'Ясна погода в пік УФ-активності. Нанесіть SPF 30+ перед виходом.',
        type: RecommendationType.uv,
      ));
    }

    if (w.isWindy) {
      recs.add(Recommendation(
        emoji: '💨',
        title: 'Вітряна погода',
        body:
            'Вітер ${w.windSpeed.round()} м/с. Закріпіть легкі предмети, одягніть вітровку.',
        type: RecommendationType.alert,
      ));
    }

    if (w.humidity > 80) {
      recs.add(const Recommendation(
        emoji: '💧',
        title: 'Висока вологість',
        body: 'Задушливо. Пийте більше води і уникайте фізичних навантажень.',
        type: RecommendationType.alert,
      ));
    }

    if (w.temp > 33) {
      recs.add(const Recommendation(
        emoji: '🌡️',
        title: 'Спека! Обережно',
        body: 'Температура вище 33°C. Уникайте прямого сонця з 11 до 16 год.',
        type: RecommendationType.alert,
      ));
    }

    if (w.main == 'Thunderstorm') {
      recs.add(const Recommendation(
        emoji: '⛈️',
        title: 'Гроза',
        body: 'Очікується гроза. Уникайте відкритих місць і дерев.',
        type: RecommendationType.alert,
      ));
    }

    return recs;
  }

  List<Recommendation> _activityRecommendations(WeatherData w) {
    final recs = <Recommendation>[];
    final hour = w.dateTime.hour;

    if (w.isClear && w.temp >= 15 && w.temp <= 28 && !w.isWindy) {
      recs.add(const Recommendation(
        emoji: '🚴',
        title: 'Відмінно для прогулянки',
        body: 'Ідеальні умови для велосипеду, бігу або пікніка на свіжому повітрі.',
        type: RecommendationType.activity,
      ));
    }

    if (w.isRainy && (hour < 9 || hour > 18)) {
      recs.add(const Recommendation(
        emoji: '🏠',
        title: 'Домашній день',
        body: 'Дощ надвечір — чудовий привід для книги або фільму вдома.',
        type: RecommendationType.activity,
      ));
    }

    return recs;
  }

  /// Щоранкове повідомлення (для нотифікації)
  String getMorningMessage(WeatherData w, List<DailyForecast> forecast) {
    final buf = StringBuffer();
    buf.write('Доброго ранку! Сьогодні ${w.description}, '
        '${w.temp.round()}°C. ');

    if (w.isRainy || (w.pop ?? 0) > 0.5) {
      buf.write('Не забудьте парасольку. ');
    }
    if (w.isUVRisk) {
      buf.write('Нанесіть сонцезахисний крем. ');
    }

    if (forecast.isNotEmpty) {
      final best = forecast
          .skip(1)
          .take(4)
          .reduce((a, b) => a.activityScore > b.activityScore ? a : b);
      final days = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Нд'];
      final dayName = days[best.date.weekday - 1];
      if (best.activityScore >= 70) {
        buf.write('Найкращий день для прогулянки — $dayName.');
      }
    }

    return buf.toString();
  }
}
