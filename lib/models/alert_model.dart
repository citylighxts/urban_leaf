enum AlertType { heatStress, coldStress, fungusRisk, drought, heavyRain, uvHigh, windStorm, toleranceExceeded }
enum AlertStatus { active, handled, dismissed }
enum AlertSeverity { low, medium, high, critical }

class AlertModel {
  final String id;
  final AlertType type;
  final AlertSeverity severity;
  final String title;
  final String description;
  final String plantName;
  final String plantEmoji;
  final AlertStatus status;
  final DateTime createdAt;
  final String actionRequired;

  const AlertModel({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.description,
    required this.plantName,
    required this.plantEmoji,
    required this.status,
    required this.createdAt,
    required this.actionRequired,
  });

  String get typeEmoji {
    switch (type) {
      case AlertType.heatStress:
        return '🌡️';
      case AlertType.coldStress:
        return '❄️';
      case AlertType.fungusRisk:
        return '🍄';
      case AlertType.drought:
        return '🏜️';
      case AlertType.heavyRain:
        return '🌧️';
      case AlertType.uvHigh:
        return '☀️';
      case AlertType.windStorm:
        return '💨';
      case AlertType.toleranceExceeded:
        return '⚠️';
    }
  }

  String get statusLabel {
    switch (status) {
      case AlertStatus.active:
        return 'Aktif';
      case AlertStatus.handled:
        return 'Ditangani';
      case AlertStatus.dismissed:
        return 'Diabaikan';
    }
  }

  String get severityLabel {
    switch (severity) {
      case AlertSeverity.low:
        return 'Ringan';
      case AlertSeverity.medium:
        return 'Sedang';
      case AlertSeverity.high:
        return 'Tinggi';
      case AlertSeverity.critical:
        return 'Kritis';
    }
  }

  AlertModel copyWith({AlertStatus? status}) {
    return AlertModel(
      id: id,
      type: type,
      severity: severity,
      title: title,
      description: description,
      plantName: plantName,
      plantEmoji: plantEmoji,
      status: status ?? this.status,
      createdAt: createdAt,
      actionRequired: actionRequired,
    );
  }
}
