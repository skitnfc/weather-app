import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/history_service.dart';
import '../models/app_theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _historyService = HistoryService();
  List<HistoricalRecord> _records = [];
  MonthlyStats? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final now = DateTime.now();
    final records = await _historyService.getRecords();
    final stats = await _historyService.getMonthlyStats(now.year, now.month);
    setState(() {
      _records = records.reversed.take(30).toList();
      _stats = stats;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(title: const Text('Історія та порівняння')),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accentBlue))
          : _records.isEmpty
              ? _buildEmpty()
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildStatsCard(),
                    const SizedBox(height: 16),
                    _buildNormComparison(),
                    const SizedBox(height: 16),
                    if (_records.length >= 5) ...[
                      _buildHistoryChart(),
                      const SizedBox(height: 16),
                    ],
                    _buildRecordsList(),
                  ],
                ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history, color: AppTheme.textMuted, size: 64),
          SizedBox(height: 16),
          Text(
            'Ще немає збережених даних.\nВідкривайте додаток щодня\nщоб накопичити статистику.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    if (_stats == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text(
          'Накопичується статистика поточного місяця...',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }
    final s = _stats!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Статистика за ${DateFormat('MMMM yyyy', 'uk').format(DateTime.now())}',
            style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 15),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatChip(
                  label: 'Середня t°',
                  value: '${s.avgTemp.toStringAsFixed(1)}°C',
                  color: AppTheme.accentBlue),
              _StatChip(
                  label: 'Мінімум',
                  value: '${s.minTemp.round()}°C',
                  color: AppTheme.accentTeal),
              _StatChip(
                  label: 'Максимум',
                  value: '${s.maxTemp.round()}°C',
                  color: AppTheme.accentOrange),
              _StatChip(
                  label: 'Дощових днів',
                  value: '${s.rainyDays}',
                  color: AppTheme.textSecondary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNormComparison() {
    if (_stats == null) return const SizedBox.shrink();
    final s = _stats!;
    final diff = s.tempVsNorm;
    final isAbove = diff > 0;
    final color = isAbove ? AppTheme.accentOrange : AppTheme.accentBlue;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Порівняння з кліматичною нормою',
            style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 15),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Норма: ${s.norm.temp.round()}°C',
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 13)),
                    Text(
                        'Фактично: ${s.avgTemp.toStringAsFixed(1)}°C',
                        style: const TextStyle(
                            color: AppTheme.textPrimary, fontSize: 13)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${isAbove ? "+" : ""}${diff.toStringAsFixed(1)}°C',
                  style: TextStyle(
                      color: color,
                      fontSize: 20,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isAbove
                ? 'Місяць теплішає за норму на ${diff.toStringAsFixed(1)}°C.'
                : 'Місяць холодніший за норму на ${diff.abs().toStringAsFixed(1)}°C.',
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryChart() {
    final data = _records.reversed.take(14).toList().reversed.toList();
    final minY =
        data.map((r) => r.temp).reduce((a, b) => a < b ? a : b) - 3;
    final maxY =
        data.map((r) => r.temp).reduce((a, b) => a > b ? a : b) + 3;

    return Container(
      height: 180,
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
            child: Text('Температура за 14 днів',
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
                      getTitlesWidget: (v, _) => Text('${v.round()}°',
                          style: const TextStyle(
                              color: AppTheme.textMuted, fontSize: 10)),
                      reservedSize: 30,
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final i = v.round();
                        if (i < 0 || i >= data.length) {
                          return const SizedBox.shrink();
                        }
                        if (i % 3 != 0) return const SizedBox.shrink();
                        return Text(
                          DateFormat('d.MM').format(data[i].date),
                          style: const TextStyle(
                              color: AppTheme.textMuted, fontSize: 9),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      data.length,
                      (i) => FlSpot(i.toDouble(), data[i].temp),
                    ),
                    isCurved: true,
                    color: AppTheme.accentBlue,
                    barWidth: 2.5,
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.accentBlue.withOpacity(0.1),
                    ),
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (_, __, ___, ____) =>
                          FlDotCirclePainter(
                              radius: 3,
                              color: AppTheme.accentBlue,
                              strokeWidth: 0),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ОСТАННІ ЗАПИСИ',
          style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 11,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        ...List.generate(_records.length, (i) {
          final r = _records[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 72,
                  child: Text(
                    DateFormat('d MMM', 'uk').format(r.date),
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13),
                  ),
                ),
                Expanded(
                  child: Text(r.main,
                      style: const TextStyle(
                          color: AppTheme.textMuted, fontSize: 12)),
                ),
                Text(
                  '${r.tempMin.round()}° / ${r.tempMax.round()}°',
                  style: const TextStyle(
                      color: AppTheme.textPrimary, fontSize: 13),
                ),
                const SizedBox(width: 8),
                Text(
                  '${r.temp.round()}°C',
                  style: const TextStyle(
                      color: AppTheme.accentBlue,
                      fontWeight: FontWeight.w600,
                      fontSize: 14),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 16)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                color: AppTheme.textMuted, fontSize: 10),
            textAlign: TextAlign.center),
      ],
    );
  }
}
