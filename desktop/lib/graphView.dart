import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TemperatureDisplay extends StatefulWidget {
  @override
  _TemperatureDisplayState createState() => _TemperatureDisplayState();
}

class _TemperatureDisplayState extends State<TemperatureDisplay> {
  double? latestTemperature;
  String? lastUpdated;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    fetchLatestData();
    // 6分ごとにデータを更新
    timer = Timer.periodic(Duration(minutes: 6), (Timer t) => fetchLatestData());
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> fetchLatestData() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.10.19:5000/water_temperature?limit=1'));
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        if (jsonData.isNotEmpty) {
          final latestData = jsonData.first;
          setState(() {
            latestTemperature = latestData['temperature'] as double;
            lastUpdated = latestData['timestamp'];
          });
        }
      } else {
        throw Exception('Failed to load latest temperature data');
      }
    } catch (e) {
      print('Error fetching latest data: $e');
      // エラー時のUI更新やユーザーへの通知を行う
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Aquarium Temperature Monitor'),
      ),
      body: Center(
        child: latestTemperature == null
            ? CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '最新の水温',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  Text(
                    '${latestTemperature?.toStringAsFixed(1)}°C',
                    style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  Text(
                    '最終更新: $lastUpdated',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
      ),
    );
  }
}