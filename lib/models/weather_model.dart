// Weather models parsed from the OpenWeatherMap One Call API response.
// Each [DayForecast] represents a single day in the 7-day forecast.

class DayForecast {
  final DateTime date;
  final double tempMin;
  final double tempMax;
  final double humidity;
  final double windSpeed; // km/h
  final String description;
  final String iconCode; // e.g. "10d"
  final double precipitation; // mm (pop * 100 as percentage, or rain volume)

  const DayForecast({
    required this.date,
    required this.tempMin,
    required this.tempMax,
    required this.humidity,
    required this.windSpeed,
    required this.description,
    required this.iconCode,
    required this.precipitation,
  });

  /// Parses a single daily entry from the OpenWeatherMap JSON.
  factory DayForecast.fromJson(Map<String, dynamic> json) {
    final temp = json['temp'] as Map<String, dynamic>;
    return DayForecast(
      date: DateTime.fromMillisecondsSinceEpoch((json['dt'] as int) * 1000),
      tempMin: (temp['min'] as num).toDouble(),
      tempMax: (temp['max'] as num).toDouble(),
      humidity: (json['humidity'] as num).toDouble(),
      // API returns m/s – convert to km/h
      windSpeed: ((json['wind_speed'] as num).toDouble() * 3.6),
      description: (json['weather'] as List).first['description'] as String,
      iconCode: (json['weather'] as List).first['icon'] as String,
      precipitation: json['rain'] != null
          ? (json['rain'] as num).toDouble()
          : 0.0,
    );
  }

  /// Full URL for the weather condition icon.
  String get iconUrl => 'https://openweathermap.org/img/wn/$iconCode@2x.png';
}

/// Holds the complete weather response including the current 7-day forecast.
class WeatherData {
  final double currentTemp;
  final double currentWindSpeed; // km/h
  final double currentHumidity;
  final String currentDescription;
  final String currentIconCode;
  final List<DayForecast> daily;

  const WeatherData({
    required this.currentTemp,
    required this.currentWindSpeed,
    required this.currentHumidity,
    required this.currentDescription,
    required this.currentIconCode,
    required this.daily,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final current = json['current'] as Map<String, dynamic>;
    final dailyList = (json['daily'] as List)
        .map((d) => DayForecast.fromJson(d as Map<String, dynamic>))
        .toList();
    return WeatherData(
      currentTemp: (current['temp'] as num).toDouble(),
      currentWindSpeed: ((current['wind_speed'] as num).toDouble() * 3.6),
      currentHumidity: (current['humidity'] as num).toDouble(),
      currentDescription:
          (current['weather'] as List).first['description'] as String,
      currentIconCode: (current['weather'] as List).first['icon'] as String,
      daily: dailyList,
    );
  }

  String get currentIconUrl =>
      'https://openweathermap.org/img/wn/$currentIconCode@2x.png';
}
