import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants.dart';

class ApiService {
  static Future<Map<String, dynamic>> fetchLatestData() async {
    final response =
        await http.get(Uri.parse('${API_BASE_URL}/water_temperature?limit=1'));
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);
      if (jsonData.isNotEmpty) {
        return jsonData.first;
      }
    }
    throw Exception('Failed to load latest temperature data');
  }

  static Future<List<Map<String, dynamic>>> fetchTemperatureHistory(
      DateTime startDate, DateTime endDate) async {
    final formattedStartDate = startDate.toIso8601String();
    final formattedEndDate = endDate.toIso8601String();
    final url =
        '${API_BASE_URL}/water_temperature?start_date=$formattedStartDate&end_date=$formattedEndDate';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);
      return List<Map<String, dynamic>>.from(jsonData);
    }
    throw Exception('Failed to load temperature history');
  }
}
