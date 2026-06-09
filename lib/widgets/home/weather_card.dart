import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/weather_model.dart';

class WeatherCard extends StatelessWidget {
  final WeatherModel weather;
  final List<ForecastDayModel> forecast;

  const WeatherCard({
    super.key,
    required this.weather,
    required this.forecast,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.weatherGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -30,
            right: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            left: -20,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                _buildMainTemp(),
                const SizedBox(height: 20),
                _buildWeatherStats(),
                const SizedBox(height: 16),
                const Divider(color: Colors.white24, thickness: 1),
                const SizedBox(height: 12),
                _buildForecastRow(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.location_on_rounded, color: Colors.white70, size: 14),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            weather.location,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            weather.lastUpdatedLabel,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainTemp() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          weather.conditionEmoji,
          style: const TextStyle(fontSize: 52),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  weather.temperature.toStringAsFixed(0),
                  style: AppTextStyles.tempLarge,
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text('°C', style: AppTextStyles.tempUnit),
                ),
              ],
            ),
            Text(
              weather.condition,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Terasa seperti ${weather.feelsLike.toStringAsFixed(0)}°C',
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeatherStats() {
    return Row(
      children: [
        _StatItem(
          icon: Icons.water_drop_rounded,
          label: 'Kelembapan',
          value: '${weather.humidity.toStringAsFixed(0)}%',
        ),
        const SizedBox(width: 8),
        _StatItem(
          icon: Icons.wb_sunny_rounded,
          label: 'UV Index',
          value: '${weather.uvIndex.toStringAsFixed(1)} (${weather.uvLabel})',
        ),
        const SizedBox(width: 8),
        _StatItem(
          icon: Icons.umbrella_rounded,
          label: 'Hujan',
          value: '${weather.rainProbability.toStringAsFixed(0)}%',
        ),
      ],
    );
  }

  Widget _buildForecastRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: forecast
          .take(5)
          .map((f) => _ForecastItem(forecast: f))
          .toList(),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white70, size: 14),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 10,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _ForecastItem extends StatelessWidget {
  final ForecastDayModel forecast;

  const _ForecastItem({required this.forecast});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          forecast.dayLabel,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(forecast.conditionEmoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 4),
        Text(
          '${forecast.maxTemp.toStringAsFixed(0)}°',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          '${forecast.minTemp.toStringAsFixed(0)}°',
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
