import 'package:flutter/material.dart';
import '../models/weather_data.dart';
import '../models/app_theme.dart';
import '../services/recommendation_service.dart';

/// Велика картка поточної погоди
class CurrentWeatherCard extends StatelessWidget {
  final WeatherData weather;
  const CurrentWeatherCard({super.key, required this.weather});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.weatherGradientStart(weather.main),
            AppTheme.weatherGradientEnd(weather.main),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    weather.cityName,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${weather.temp.round()}°',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 72,
                      fontWeight: FontWeight.w200,
                      height: 1,
                    ),
                  ),
                ],
              ),
              Image.network(
                weather.iconUrl,
                width: 80,
                height: 80,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.wb_sunny, size: 64,
                        color: AppTheme.accentAmber),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _capitalize(weather.description),
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Відчувається як ${weather.feelsLike.round()}°  •  '
            '${weather.tempMin.round()}° / ${weather.tempMax.round()}°',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _WeatherStat(
                icon: Icons.water_drop_outlined,
                value: '${weather.humidity}%',
                label: 'Вологість',
              ),
              _WeatherStat(
                icon: Icons.air,
                value: '${weather.windSpeed.round()} м/с',
                label: 'Вітер',
              ),
              _WeatherStat(
                icon: Icons.compress,
                value: '${weather.pressure} гПа',
                label: 'Тиск',
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _WeatherStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _WeatherStat(
      {required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.accentBlue, size: 18),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        Text(label,
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 11)),
      ],
    );
  }
}

/// Картка рекомендації
class RecommendationCard extends StatelessWidget {
  final Recommendation rec;
  const RecommendationCard({super.key, required this.rec});

  @override
  Widget build(BuildContext context) {
    final color = rec.type == RecommendationType.alert
        ? AppTheme.warning
        : rec.type == RecommendationType.uv
            ? AppTheme.accentAmber
            : AppTheme.accentBlue;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(rec.emoji, style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rec.title,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                const SizedBox(height: 2),
                Text(rec.body,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Картка одного дня прогнозу
class DayForecastCard extends StatelessWidget {
  final DailyForecast day;
  final bool isToday;
  final bool showActivityScore;
  const DayForecastCard({
    super.key,
    required this.day,
    this.isToday = false,
    this.showActivityScore = false,
  });

  @override
  Widget build(BuildContext context) {
    final days = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Нд'];
    final dayName = isToday ? 'Сьогодні' : days[day.date.weekday - 1];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isToday
            ? AppTheme.accentBlue.withOpacity(0.1)
            : AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: isToday
            ? Border.all(color: AppTheme.accentBlue.withOpacity(0.3))
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(dayName,
                style: TextStyle(
                    color: isToday
                        ? AppTheme.accentBlue
                        : AppTheme.textPrimary,
                    fontWeight:
                        isToday ? FontWeight.w700 : FontWeight.normal,
                    fontSize: 14)),
          ),
          Image.network(day.iconUrl ?? '', width: 32, height: 32,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.wb_cloudy, color: AppTheme.textMuted, size: 28)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${(day.maxPop * 100).round()}%',
              style: TextStyle(
                color: day.maxPop > 0.4
                    ? AppTheme.accentBlue
                    : AppTheme.textMuted,
                fontSize: 13,
              ),
            ),
          ),
          if (showActivityScore) ...[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.activityScoreColor(day.activityScore)
                    .withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                day.activityLabel,
                style: TextStyle(
                  color: AppTheme.activityScoreColor(day.activityScore),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            '${day.tempMin.round()}°',
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 14),
          ),
          const SizedBox(width: 4),
          Text('/',
              style: const TextStyle(
                  color: AppTheme.textMuted, fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            '${day.tempMax.round()}°',
            style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

extension _DailyForecastExt on DailyForecast {
  String? get iconUrl =>
      'https://openweathermap.org/img/wn/$icon@2x.png';
}

/// Горизонтальний скролл погодинного прогнозу
class HourlyForecastRow extends StatelessWidget {
  final List<WeatherData> hours;
  const HourlyForecastRow({super.key, required this.hours});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: hours.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final w = hours[i];
          return Container(
            width: 60,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${w.dateTime.hour.toString().padLeft(2, '0')}:00',
                  style: const TextStyle(
                      color: AppTheme.textMuted, fontSize: 11),
                ),
                Image.network(w.iconUrl,
                    width: 28, height: 28,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.wb_sunny,
                            size: 24, color: AppTheme.accentAmber)),
                Text(
                  '${w.temp.round()}°',
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
