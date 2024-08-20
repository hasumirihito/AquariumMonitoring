import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
   runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '水温モニター',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: TemperatureDisplay(),
    );
  }
}

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
    }
  }

  @override
  Widget build(BuildContext context) {
    // 画面サイズを取得
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: Text('水温モニター'),
      ),
      body: Container(
        width: screenSize.width,
        height: screenSize.height,
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: screenSize.width * 0.8,  // 画面幅の30%
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text(
                    '最新の水温',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 30),
                  latestTemperature == null
                      ? CircularProgressIndicator()
                      : Text(
                          '${latestTemperature?.toStringAsFixed(1)}°C',
                          style: TextStyle(fontSize: 72, fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                  SizedBox(height: 30),
                  Text(
                    '最終更新: $lastUpdated',
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}