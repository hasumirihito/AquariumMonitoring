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
    // 日付をYYYY-MM-DD HH:mm:ss形式にフォーマット
    final formattedStartDate = startDate.toString().split('.')[0];
    final formattedEndDate = endDate.toString().split('.')[0];

    final encodedStartDate = Uri.encodeComponent(formattedStartDate);
    final encodedEndDate = Uri.encodeComponent(formattedEndDate);

    final url =
        '${API_BASE_URL}/water_temperature?start_date=$encodedStartDate&end_date=$encodedEndDate';

    print('Fetching data from: $url'); // デバッグ用

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);
      print('Received ${jsonData.length} records'); // デバッグ用
      return List<Map<String, dynamic>>.from(jsonData);
    }
    throw Exception('Failed to load temperature history');
  }
}
