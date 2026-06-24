import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/alert_model.dart';
import '../models/plant_model.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  static const _seenKey = 'notified_alert_ids';
  static const _weatherEnabledKey = 'weather_notifications_enabled';
  static const _wateringEnabledKey = 'watering_notifications_enabled';
  static const _wateringSeenKey = 'notified_watering_ids';

  static const _androidChannel = AndroidNotificationChannel(
    'urbanleaf_alerts',
    'UrbanLeaf Alerts',
    description: 'Peringatan cuaca dan kesehatan tanaman',
    importance: Importance.high,
  );

  static const _wateringChannel = AndroidNotificationChannel(
    'urbanleaf_watering',
    'UrbanLeaf Watering',
    description: 'Pengingat tanaman yang perlu disiram',
    importance: Importance.high,
  );

  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    }

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_androidChannel);
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_wateringChannel);
  }

  Future<void> showNewAlerts(List<AlertModel> alerts) async {
    if (alerts.isEmpty) return;

    final enabled = await weatherAlertsEnabled();
    if (!enabled) return;

    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getStringList(_seenKey) ?? [];
    final seenSet = seen.toSet();

    final newAlerts = alerts
        .where((a) => a.status == AlertStatus.active && !seenSet.contains(a.id))
        .toList();

    if (newAlerts.isEmpty) return;

    for (final alert in newAlerts) {
      await _plugin.show(
        alert.id.hashCode,
        _titleFor(alert),
        alert.description,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            importance: Importance.high,
            priority: _priorityFor(alert),
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    }

    // Tandai sebagai sudah dinotif
    final updatedSeen = (seenSet..addAll(newAlerts.map((a) => a.id))).toList();
    // Batasi ukuran list agar tidak tumbuh tak terbatas
    if (updatedSeen.length > 200) {
      updatedSeen.removeRange(0, updatedSeen.length - 200);
    }
    await prefs.setStringList(_seenKey, updatedSeen);
  }

  String _titleFor(AlertModel alert) {
    final emoji = switch (alert.type) {
      AlertType.heatStress => '🌡️',
      AlertType.fungusRisk => '🍄',
      AlertType.heavyRain => '🌧️',
      AlertType.windStorm => '💨',
      AlertType.uvHigh => '☀️',
      AlertType.drought => '🏜️',
      AlertType.coldStress => '❄️',
      AlertType.toleranceExceeded => '⚠️',
    };
    return '$emoji ${alert.title}';
  }

  Priority _priorityFor(AlertModel alert) =>
      alert.severity == AlertSeverity.critical
      ? Priority.high
      : Priority.defaultPriority;

  Future<void> clearSeenAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_seenKey);
  }

  Future<bool> weatherAlertsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_weatherEnabledKey) ?? true;
  }

  Future<void> setWeatherAlertsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_weatherEnabledKey, enabled);
  }

  Future<bool> wateringRemindersEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_wateringEnabledKey) ?? true;
  }

  Future<void> setWateringRemindersEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_wateringEnabledKey, enabled);
    if (enabled) {
      await prefs.remove(_wateringSeenKey);
    }
  }

  Future<void> showWateringReminders(List<PlantModel> plants) async {
    if (plants.isEmpty) return;

    final enabled = await wateringRemindersEnabled();
    if (!enabled) return;

    final duePlants = plants.where((plant) => plant.isWateringDue).toList();
    if (duePlants.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getStringList(_wateringSeenKey) ?? [];
    final seenSet = seen.toSet();

    final pendingPlants = duePlants
        .where((plant) => !seenSet.contains(_wateringReminderKey(plant)))
        .toList();

    if (pendingPlants.isEmpty) return;

    final names = pendingPlants.take(3).map((plant) => plant.name).join(', ');
    final moreCount = pendingPlants.length > 3 ? pendingPlants.length - 3 : 0;
    final suffix = moreCount > 0 ? ' +$moreCount lainnya' : '';
    final title = pendingPlants.length == 1
        ? '💧 ${pendingPlants.first.name} perlu disiram'
        : '💧 ${pendingPlants.length} tanaman perlu disiram';

    await _plugin.show(
      pendingPlants.map(_wateringReminderKey).join('|').hashCode,
      title,
      '$names$suffix sudah waktunya disiram hari ini.',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _wateringChannel.id,
          _wateringChannel.name,
          channelDescription: _wateringChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );

    final updatedSeen =
        (seenSet..addAll(pendingPlants.map(_wateringReminderKey))).toList();
    if (updatedSeen.length > 200) {
      updatedSeen.removeRange(0, updatedSeen.length - 200);
    }
    await prefs.setStringList(_wateringSeenKey, updatedSeen);
  }

  String _wateringReminderKey(PlantModel plant) {
    return '${plant.id}:${plant.nextWatering.millisecondsSinceEpoch}';
  }
}
