import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:http_parser/http_parser.dart';

class PlantDiseaseResult {
  final String predictedClass;
  final String predictedClassEnglish;
  final double confidence;

  PlantDiseaseResult({
    required this.predictedClass,
    required this.predictedClassEnglish,
    required this.confidence,
  });

  factory PlantDiseaseResult.fromJson(Map<String, dynamic> json) {
    return PlantDiseaseResult(
      predictedClass: json['predicted_class'] ?? '',
      predictedClassEnglish: json['predicted_class_english'] ?? '',
      confidence: (json['confidence'] ?? 0).toDouble(),
    );
  }
}

class PlantDiseaseService {
  // Update this URL with your ngrok URL
  static const String baseUrl =
      'https://orthotropous-keisha-ungeodetically.ngrok-free.dev';

  /// Upload image and get plant disease prediction
  static Future<PlantDiseaseResult> predictDisease(File imageFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/predict'),
      );

      // Add headers to bypass ngrok warning page
      request.headers.addAll({
        'ngrok-skip-browser-warning': 'true',
        'User-Agent': 'DisasterApp/1.0',
      });

      // Add the image file
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      // Send the request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return PlantDiseaseResult.fromJson(jsonData);
      } else {
        throw Exception('সার্ভার থেকে তথ্য পাওয়া যায়নি।');
      }
    } catch (e) {
      throw Exception('ছবি পাঠাতে সমস্যা হয়েছে');
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
        return data['model_loaded'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
