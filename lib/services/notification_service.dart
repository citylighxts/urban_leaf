import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/alert_model.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  static const _seenKey = 'notified_alert_ids';

  static const _androidChannel = AndroidNotificationChannel(
    'urbanleaf_alerts',
    'UrbanLeaf Alerts',
    description: 'Peringatan cuaca dan kesehatan tanaman',
    importance: Importance.high,
  );

  Future<void> init() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);
  }

  Future<void> showNewAlerts(List<AlertModel> alerts) async {
    if (alerts.isEmpty) return;

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
      alert.severity == AlertSeverity.critical ? Priority.high : Priority.defaultPriority;

  Future<void> clearSeenAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_seenKey);
  }
}
