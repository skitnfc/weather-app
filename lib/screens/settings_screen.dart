import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_theme.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _cityController = TextEditingController();
  int _notifHour = 7;
  int _notifMinute = 30;
  bool _notifsEnabled = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _cityController.text = prefs.getString('city') ?? '';
      _notifHour = prefs.getInt('notif_hour') ?? 7;
      _notifMinute = prefs.getInt('notif_minute') ?? 30;
      _notifsEnabled = prefs.getBool('notifs_enabled') ?? true;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('city', _cityController.text.trim());
    await prefs.setInt('notif_hour', _notifHour);
    await prefs.setInt('notif_minute', _notifMinute);
    await prefs.setBool('notifs_enabled', _notifsEnabled);

    if (_notifsEnabled) {
      await NotificationService().scheduleMorningForecast(
        hour: _notifHour,
        minute: _notifMinute,
        message: 'Перевірте прогноз на сьогодні!',
      );
    } else {
      await NotificationService().cancelAll();
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Налаштування збережено'),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _notifHour, minute: _notifMinute),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.accentBlue,
            surface: AppTheme.cardColor,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _notifHour = picked.hour;
        _notifMinute = picked.minute;
      });
    }
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(title: const Text('Налаштування')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _sectionTitle('МІСТО'),
          const SizedBox(height: 8),
          TextField(
            controller: _cityController,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: const InputDecoration(
              hintText: 'Введіть назву міста (наприклад: Київ)',
              prefixIcon:
                  Icon(Icons.location_city, color: AppTheme.textMuted),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Залиште порожнім для автоматичного визначення через GPS',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 24),
          _sectionTitle('СПОВІЩЕННЯ'),
          const SizedBox(height: 8),
          _SettingsTile(
            title: 'Ранковий прогноз',
            subtitle: 'Отримувати погоду щоранку',
            trailing: Switch(
              value: _notifsEnabled,
              onChanged: (v) => setState(() => _notifsEnabled = v),
              activeColor: AppTheme.accentBlue,
            ),
          ),
          if (_notifsEnabled)
            _SettingsTile(
              title: 'Час сповіщення',
              subtitle:
                  '${_notifHour.toString().padLeft(2, '0')}:${_notifMinute.toString().padLeft(2, '0')}',
              trailing: const Icon(Icons.chevron_right,
                  color: AppTheme.textMuted),
              onTap: _pickTime,
            ),
          const SizedBox(height: 24),
          _sectionTitle('API КЛЮЧ'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppTheme.warning.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: AppTheme.warning, size: 16),
                    SizedBox(width: 8),
                    Text('Налаштування API',
                        style: TextStyle(
                            color: AppTheme.warning,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Відредагуйте файл lib/services/weather_service.dart '
                  'і замініть YOUR_API_KEY_HERE на ваш безкоштовний ключ '
                  'з openweathermap.org',
                  style: TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {},
                  child: const Text(
                    'openweathermap.org/api →',
                    style: TextStyle(
                        color: AppTheme.accentBlue, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentBlue,
              foregroundColor: AppTheme.primaryDark,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Зберегти налаштування',
                style: TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 15)),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 11,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w600),
      );
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;
  const _SettingsTile(
      {required this.title,
      required this.subtitle,
      required this.trailing,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: AppTheme.textPrimary, fontSize: 14)),
                  Text(subtitle,
                      style: const TextStyle(
                          color: AppTheme.textMuted, fontSize: 12)),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}
