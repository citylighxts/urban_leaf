import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import '../../models/weather_model.dart';

class WeatherResult {
  final WeatherModel current;
  final List<ForecastDayModel> forecast;

  const WeatherResult({required this.current, required this.forecast});
}

class WeatherService {
  static const _baseUrl = 'https://api.open-meteo.com/v1/forecast';
  static const _cacheTtl = Duration(minutes: 30);
  static const _cacheCollection = 'weather_cache';

  static WeatherResult? _memCache;
  static DateTime? _memCacheTime;

  /// Fetch current weather + 5-day forecast using device GPS.
  /// Returns in-memory result if still within TTL (avoids GPS on every call),
  /// then falls back to Firestore cache, then the live API.
  Future<WeatherResult> fetchWeather() async {
    if (_memCache != null &&
        _memCacheTime != null &&
        DateTime.now().difference(_memCacheTime!) < _cacheTtl) {
      return _memCache!;
    }
    final position = await _getPosition();
    final cached = await _readCache(position);
    if (cached != null) {
      _memCache = cached;
      _memCacheTime = DateTime.now();
      return cached;
    }
    final location = await _reverseGeocode(position);
    final result = await _fetchFromApi(position, location);
    _memCache = result;
    _memCacheTime = DateTime.now();
    _writeCache(position, result);
    return result;
  }

  // ─── Cache ────────────────────────────────────────────────────────────────

  // Round to 2 decimal places → ~1.1 km grid cell
  String _cacheKey(Position pos) =>
      '${pos.latitude.toStringAsFixed(2)}_${pos.longitude.toStringAsFixed(2)}';

  Future<WeatherResult?> _readCache(Position pos) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(_cacheCollection)
          .doc(_cacheKey(pos))
          .get();
      if (!doc.exists) return null;

      final data = doc.data()!;
      final cachedAt = DateTime.parse(data['cachedAt'] as String);
      if (DateTime.now().difference(cachedAt) > _cacheTtl) return null;

      final current = WeatherModel.fromJson(
          Map<String, dynamic>.from(data['current'] as Map));
      final forecast = (data['forecast'] as List)
          .map((e) => ForecastDayModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      return WeatherResult(current: current, forecast: forecast);
    } catch (_) {
      return null;
    }
  }

  void _writeCache(Position pos, WeatherResult result) {
    FirebaseFirestore.instance
        .collection(_cacheCollection)
        .doc(_cacheKey(pos))
        .set({
      'cachedAt': DateTime.now().toIso8601String(),
      'current': result.current.toJson(),
      'forecast': result.forecast.map((f) => f.toJson()).toList(),
    }).catchError((_) {});
  }

  // ─── GPS ──────────────────────────────────────────────────────────────────

  Future<Position> _getPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('Layanan GPS tidak aktif.');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Izin lokasi ditolak.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Izin lokasi diblokir permanen. Buka pengaturan HP.');
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
        ),
      ).timeout(const Duration(seconds: 10));
    } on TimeoutException {
      throw Exception('GPS timeout. Pastikan layanan lokasi aktif lalu coba lagi.');
    }
  }

  Future<String> _reverseGeocode(Position pos) async {
    try {
      final placemarks = await placemarkFromCoordinates(
              pos.latitude, pos.longitude)
          .timeout(const Duration(seconds: 5));
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = [p.subLocality, p.locality]
            .where((s) => s != null && s.isNotEmpty)
            .toList();
        return parts.isNotEmpty ? parts.join(', ') : 'Lokasiku';
      }
    } catch (_) {}
    return 'Lokasiku';
  }

  // ─── API Call ─────────────────────────────────────────────────────────────

  Future<WeatherResult> _fetchFromApi(Position pos, String location) async {
    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      'latitude': pos.latitude.toString(),
      'longitude': pos.longitude.toString(),
      'current': [
        'temperature_2m',
        'apparent_temperature',
        'relative_humidity_2m',
        'precipitation',
        'weathercode',
        'uv_index',
      ].join(','),
      'daily': [
        'temperature_2m_max',
        'temperature_2m_min',
        'precipitation_sum',
        'precipitation_probability_max',
        'weathercode',
        'uv_index_max',
      ].join(','),
      'timezone': 'auto',
      'forecast_days': '5',
    });

    final http.Response response;
    try {
      response = await http.get(uri).timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw Exception('Koneksi ke server cuaca timeout. Periksa internet lalu coba lagi.');
    }
    if (response.statusCode != 200) {
      throw Exception('Gagal mengambil data cuaca (${response.statusCode})');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final current = json['current'] as Map<String, dynamic>;
    final daily = json['daily'] as Map<String, dynamic>;

    // ── Current weather ──
    final weatherCode = (current['weathercode'] as num).toInt();
    final rainProb = (daily['precipitation_probability_max'] as List).isNotEmpty
        ? (daily['precipitation_probability_max'][0] as num).toDouble()
        : 0.0;

    final currentWeather = WeatherModel(
      temperature: (current['temperature_2m'] as num).toDouble(),
      feelsLike: (current['apparent_temperature'] as num).toDouble(),
      humidity: (current['relative_humidity_2m'] as num).toDouble(),
      uvIndex: (current['uv_index'] as num).toDouble(),
      precipitation: (current['precipitation'] as num).toDouble(),
      rainProbability: rainProb,
      condition: _conditionFromCode(weatherCode),
      conditionEmoji: _emojiFromCode(weatherCode),
      location: location,
      lastUpdated: DateTime.now(),
    );

    // ── Forecast ──
    final dates = daily['time'] as List;
    final maxTemps = daily['temperature_2m_max'] as List;
    final minTemps = daily['temperature_2m_min'] as List;
    final precipSums = daily['precipitation_sum'] as List;
    final precipProbs = daily['precipitation_probability_max'] as List;
    final weatherCodes = daily['weathercode'] as List;
    final uvIndices = daily['uv_index_max'] as List;

    final forecastList = List.generate(dates.length, (i) {
      final code = (weatherCodes[i] as num).toInt();
      return ForecastDayModel(
        date: DateTime.parse(dates[i] as String),
        maxTemp: (maxTemps[i] as num).toDouble(),
        minTemp: (minTemps[i] as num).toDouble(),
        precipitation: (precipSums[i] as num).toDouble(),
        rainProbability: (precipProbs[i] as num).toDouble(),
        condition: _conditionFromCode(code),
        conditionEmoji: _emojiFromCode(code),
        uvIndex: (uvIndices[i] as num).toDouble(),
      );
    });

    return WeatherResult(current: currentWeather, forecast: forecastList);
  }

  // ─── WMO Weather Code mapping ─────────────────────────────────────────────

  static String _conditionFromCode(int code) {
    if (code == 0) return 'Cerah';
    if (code == 1) return 'Sebagian Cerah';
    if (code == 2) return 'Berawan';
    if (code == 3) return 'Mendung';
    if (code <= 49) return 'Berkabut';
    if (code <= 59) return 'Gerimis';
    if (code <= 69) return 'Hujan';
    if (code <= 79) return 'Salju';
    if (code <= 82) return 'Hujan Lebat';
    if (code <= 84) return 'Hujan Es';
    if (code <= 99) return 'Badai Petir';
    return 'Tidak Diketahui';
  }

  static String _emojiFromCode(int code) {
    if (code == 0) return '☀️';
    if (code == 1) return '🌤️';
    if (code == 2) return '⛅';
    if (code == 3) return '☁️';
    if (code <= 49) return '🌫️';
    if (code <= 59) return '🌦️';
    if (code <= 69) return '🌧️';
    if (code <= 79) return '🌨️';
    if (code <= 82) return '🌧️';
    if (code <= 84) return '🌨️';
    if (code <= 99) return '⛈️';
    return '🌡️';
  }
}
