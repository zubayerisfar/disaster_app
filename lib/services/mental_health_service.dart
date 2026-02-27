import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/mental_health_assessment.dart';

class MentalHealthResult {
  final String prediction;
  final double probability;
  final String riskLevel;

  MentalHealthResult({
    required this.prediction,
    required this.probability,
    required this.riskLevel,
  });

  factory MentalHealthResult.fromJson(Map<String, dynamic> json) {
    return MentalHealthResult(
      prediction: json['prediction'] ?? '',
      probability: (json['probability'] ?? 0).toDouble(),
      riskLevel: json['risk_level'] ?? 'Low',
    );
  }

  bool get isAtRisk => riskLevel == 'High' || riskLevel == 'Medium';
}

class MentalHealthService {
  // Update this URL with your server URL
  static const String baseUrl =
      'https://orthotropous-keisha-ungeodetically.ngrok-free.dev';

  /// Submit mental health assessment and get prediction
  static Future<MentalHealthResult> assessMentalHealth(
    MentalHealthAssessment assessment,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/predict/depression'),
            headers: {
              'Content-Type': 'application/json',
              'ngrok-skip-browser-warning': 'true',
              'User-Agent': 'DisasterApp/1.0',
            },
            body: json.encode(assessment.toJson()),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return MentalHealthResult.fromJson(jsonData);
      } else {
        throw Exception('সার্ভার থেকে তথ্য পাওয়া যায়নি।');
      }
    } catch (e) {
      throw Exception('মানসিক স্বাস্থ্য মূল্যায়ন পাঠাতে সমস্যা হয়েছে: $e');
    }
  }

  /// Check server health
  static Future<bool> checkServerHealth() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/health'),
            headers: {
              'ngrok-skip-browser-warning': 'true',
              'User-Agent': 'DisasterApp/1.0',
            },
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['depression_model_loaded'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
