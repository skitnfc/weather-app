import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/weather_service.dart';
import '../services/recommendation_service.dart';
import '../services/notification_service.dart';
import '../services/history_service.dart';
import '../models/weather_data.dart';
import '../models/app_theme.dart';
import '../widgets/weather_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _weatherService = WeatherService();
  final _recService = RecommendationService();
  final _historyService = HistoryService();
  final _notifService = NotificationService();

  WeatherData? _current;
  List<WeatherData> _forecast = [];
  bool _loading = true;
  String? _error;
  String _cityInput = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCity = prefs.getString('city');

      WeatherData current;
      List<WeatherData> forecast;

      if (savedCity != null && savedCity.isNotEmpty) {
        current = await _weatherService.getCurrentWeatherByCity(savedCity);
        forecast = await _weatherService.getForecastByCity(savedCity);
      } else {
        final pos = await _getPosition();
        current = await _weatherService.getCurrentWeather(
            pos.latitude, pos.longitude);
        forecast = await _weatherService.getForecast(
            pos.latitude, pos.longitude);
      }

      // Зберегти для порівняння
      await _historyService.saveRecord(current);

      // Запланувати нотифікації
      final daily = _weatherService.groupByDay(forecast);
      await _notifService.sendForecastNotifications(current, daily);

      setState(() {
        _current = current;
        _forecast = forecast;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<Position> _getPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('GPS вимкнено');

    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) {
        throw Exception('Доступ до геолокації відхилено');
      }
    }
    return Geolocator.getCurrentPosition();
  }

  Future<void> _searchCity(String city) async {
    if (city.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('city', city.trim());
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          color: AppTheme.accentBlue,
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                floating: true,
                backgroundColor: AppTheme.primaryDark,
                title: _buildSearchBar(),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh, color: AppTheme.textSecondary),
                    onPressed: _load,
                  ),
                ],
              ),
              if (_loading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppTheme.accentBlue),
                  ),
                )
              else if (_error != null)
                SliverFillRemaining(child: _buildError())
              else
                SliverPadding(
                  padding: const EdgeInsets.all(AppConstants.screenPadding),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      CurrentWeatherCard(weather: _current!),
                      const SizedBox(height: 16),
                      _buildHourlySection(),
                      const SizedBox(height: 16),
                      _buildRecommendationsSection(),
                      const SizedBox(height: 16),
                      _buildComparisonSection(),
                      const SizedBox(height: 24),
                    ]),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        hintText: 'Пошук міста...',
        hintStyle: const TextStyle(color: AppTheme.textMuted),
        prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted),
        filled: true,
        fillColor: AppTheme.cardColor,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      onChanged: (v) => _cityInput = v,
      onSubmitted: _searchCity,
    );
  }

  Widget _buildHourlySection() {
    final next24h = _forecast
        .where((w) => w.dateTime.isBefore(
            DateTime.now().add(const Duration(hours: 25))))
        .toList();
    if (next24h.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Погодинний прогноз',
            style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5)),
        const SizedBox(height: 8),
        HourlyForecastRow(hours: next24h),
      ],
    );
  }

  Widget _buildRecommendationsSection() {
    if (_current == null) return const SizedBox.shrink();
    final recs = _recService.getRecommendations(_current!);
    if (recs.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Рекомендації',
            style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5)),
        const SizedBox(height: 8),
        ...recs.map((r) => RecommendationCard(rec: r)),
      ],
    );
  }

  Widget _buildComparisonSection() {
    final current = _current;
    if (current == null) return const SizedBox.shrink();

    final hist = _historyService;
    final norm = hist.getNorm(current.dateTime.month);
    final diff = current.temp - norm.temp;
    final absDiff = diff.abs().toStringAsFixed(1);
    final isAbove = diff > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Порівняння з нормою',
              style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ComparisonStat(
                  label: 'Зараз',
                  value: '${current.temp.round()}°C',
                  color: AppTheme.accentBlue,
                ),
              ),
              Expanded(
                child: _ComparisonStat(
                  label: 'Норма місяця',
                  value: '${norm.temp.round()}°C',
                  color: AppTheme.textSecondary,
                ),
              ),
              Expanded(
                child: _ComparisonStat(
                  label: 'Різниця',
                  value: '${isAbove ? "+" : "-"}$absDiff°C',
                  color:
                      isAbove ? AppTheme.accentOrange : AppTheme.accentBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isAbove
                ? 'Сьогодні на $absDiff°C тепліше за кліматичну норму для цього місяця.'
                : 'Сьогодні на $absDiff°C холодніше за кліматичну норму для цього місяця.',
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, color: AppTheme.textMuted, size: 64),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Помилка',
              style: const TextStyle(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Спробувати знову'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentBlue,
                foregroundColor: AppTheme.primaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComparisonStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _ComparisonStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                color: AppTheme.textMuted, fontSize: 11)),
      ],
    );
  }
}
