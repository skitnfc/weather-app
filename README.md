# 🌤 Погодний помічник — Flutter App

Мобільний додаток для Android/iOS з персональними погодними рекомендаціями.

## Функціональність

- **Поточна погода** — температура, вологість, вітер, відчуття
- **Рекомендації** — що одягти, чи брати парасольку, сонцезахисний крем
- **Прогноз на 5 днів** з графіком температур
- **Аналіз активності** — рейтинг кожного дня для прогулянок/спорту
- **Щоранкові сповіщення** — прогноз о вибраний час
- **Порівняння з нормою** — температура vs кліматична норма місяця
- **Історія** — збереження і графік за 30 днів

## Налаштування

### 1. Отримати API ключ

1. Зареєструватись на [openweathermap.org](https://openweathermap.org/api)
2. Перейти в My API Keys
3. Скопіювати безкоштовний ключ (план Free — 1000 запитів/день)

### 2. Вставити ключ

Відкрити `lib/services/weather_service.dart`:
```dart
static const String _apiKey = 'YOUR_API_KEY_HERE'; // ← замінити
```

### 3. Запустити (варіант A — zapp.run)

1. Відкрити [zapp.run](https://zapp.run)
2. Завантажити весь проєкт як ZIP
3. Запуститься прямо в браузері

### 3. Запустити (варіант B — Expo/локально)

```bash
flutter pub get
flutter run
```

## Структура проєкту

```
lib/
├── main.dart                    # Точка входу + навігація
├── models/
│   ├── weather_data.dart        # Моделі даних погоди
│   └── app_theme.dart           # Тема і константи
├── services/
│   ├── weather_service.dart     # OpenWeatherMap API
│   ├── recommendation_service.dart  # Поради що одягти
│   ├── history_service.dart     # Локальна історія
│   └── notification_service.dart    # Сповіщення
├── screens/
│   ├── home_screen.dart         # Головний екран
│   ├── forecast_screen.dart     # Прогноз + активність
│   ├── history_screen.dart      # Порівняння з нормою
│   └── settings_screen.dart     # Налаштування
└── widgets/
    └── weather_widgets.dart     # Компоненти UI
```

## Технології

| Технологія | Версія | Призначення |
|-----------|--------|-------------|
| Flutter | 3.10+ | Фреймворк |
| Dart | 3.0+ | Мова програмування |
| OpenWeatherMap API | 2.5 | Погодні дані |
| http | 1.2.0 | HTTP-запити |
| geolocator | 11.0.0 | GPS |
| shared_preferences | 2.2.2 | Локальне сховище |
| flutter_local_notifications | 17.0.0 | Push-сповіщення |
| fl_chart | 0.68.0 | Графіки |
| intl | 0.19.0 | Форматування дат (uk) |
