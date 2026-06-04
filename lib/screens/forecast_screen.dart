import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/weather_service.dart';
import '../models/weather_data.dart';
import '../models/app_theme.dart';
import '../widgets/weather_widgets.dart';

class ForecastScreen extends StatefulWidget {
  const ForecastScreen({super.key});

  @override
  State<ForecastScreen> createState() => _ForecastScreenState();
}

class _ForecastScreenState extends State<ForecastScreen>
    with SingleTickerProviderStateMixin {
  final _weatherService = WeatherService();
  List<DailyForecast> _days = [];
  bool _loading = true;
  String? _error;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final city = prefs.getString('city') ?? 'Київ';
      final forecast = await _weatherService.getForecastByCity(city);
      setState(() {
        _days = _weatherService.groupByDay(forecast);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: const Text('Прогноз'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accentBlue,
          labelColor: AppTheme.accentBlue,
          unselectedLabelColor: AppTheme.textMuted,
          tabs: const [
            Tab(text: '5 днів'),
            Tab(text: 'Аналіз активності'),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accentBlue))
          : _error != null
              ? Center(
                  child: Text(_error!,
                      style: const TextStyle(color: AppTheme.textSecondary)))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildForecastTab(),
                    _buildActivityTab(),
                  ],
                ),
    );
  }

  Widget _buildForecastTab() {
    return RefreshIndicator(
      onRefresh: _load,
      color: AppTheme.accentBlue,
      child: ListView(
        padding: const EdgeInsets.all(AppConstants.screenPadding),
        children: [
          _buildTempChart(),
          const SizedBox(height: 16),
          const Text(
            'ЩОДЕННИЙ ПРОГНОЗ',
            style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 11,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ...List.generate(_days.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: DayForecastCard(
                day: _days[i],
                isToday: i == 0,
                showActivityScore: false,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTempChart() {
    if (_days.isEmpty) return const SizedBox.shrink();

    final minY = _days
            .map((d) => d.tempMin)
            .reduce((a, b) => a < b ? a : b) -
        3;
    final maxY = _days
            .map((d) => d.tempMax)
            .reduce((a, b) => a > b ? a : b) +
        3;

    final days = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Нд'];

    return Container(
      height: 200,
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 8, bottom: 8),
            child: Text('Температура °C',
                style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => const FlLine(
                    color: AppTheme.textMuted,
                    strokeWidth: 0.3,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) => Text(
                        '${v.round()}°',
                        style: const TextStyle(
                            color: AppTheme.textMuted, fontSize: 10),
                      ),
                      reservedSize: 32,
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final i = v.round();
                        if (i < 0 || i >= _days.length) {
                          return const SizedBox.shrink();
                        }
                        final label = i == 0
                            ? 'Сьог.'
                            : days[_days[i].date.weekday - 1];
                        return Text(label,
                            style: const TextStyle(
                                color: AppTheme.textMuted, fontSize: 10));
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: [
                  // Max temp line
                  LineChartBarData(
                    spots: List.generate(
                      _days.length,
                      (i) => FlSpot(i.toDouble(), _days[i].tempMax),
                    ),
                    isCurved: true,
                    color: AppTheme.accentOrange,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.accentOrange.withOpacity(0.05),
                    ),
                  ),
                  // Min temp line
                  LineChartBarData(
                    spots: List.generate(
                      _days.length,
                      (i) => FlSpot(i.toDouble(), _days[i].tempMin),
                    ),
                    isCurved: true,
                    color: AppTheme.accentBlue,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTab() {
    return ListView(
      padding: const EdgeInsets.all(AppConstants.screenPadding),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Найкращі дні для активностей',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              const Text(
                'Рейтинг враховує температуру, опади, вітер та хмарність',
                style: TextStyle(
                    color: AppTheme.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 16),
              _buildActivityBars(),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'ДЕТАЛІ ПО ДНЯХ',
          style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 11,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        ...List.generate(_days.length, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: DayForecastCard(
              day: _days[i],
              isToday: i == 0,
              showActivityScore: true,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildActivityBars() {
    final days = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Нд'];
    return Column(
      children: List.generate(_days.length, (i) {
        final d = _days[i];
        final score = d.activityScore;
        final label = i == 0 ? 'Сьогодні' : days[d.date.weekday - 1];
        final color = AppTheme.activityScoreColor(score);
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              SizedBox(
                width: 60,
                child: Text(label,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13)),
              ),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryMid,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: score / 100,
                      child: Container(
                        height: 28,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: color.withOpacity(0.5), width: 1),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(d.description,
                                style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 11)),
                            Text('$score%',
                                style: TextStyle(
                                    color: color,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
