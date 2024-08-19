import 'package:intl/intl.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';

class TemperatureChart extends StatefulWidget {
  @override
  _TemperatureChartState createState() => _TemperatureChartState();
}

class _TemperatureChartState extends State<TemperatureChart> {
  List<FlSpot> temperatureData = [];
  Timer? timer;

  @override
  void initState() {
    super.initState();
    fetchInitialData();
    // 6分ごとにデータを更新
    timer = Timer.periodic(Duration(minutes: 6), (Timer t) => fetchLatestData());
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> fetchInitialData() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.10.19:5000/water_temperature'));
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        setState(() {
          temperatureData = jsonData.map((data) {
            final temperature = data['temperature'] as double;
            final timestamp = DateTime.parse(data['timestamp']);
            return FlSpot(timestamp.millisecondsSinceEpoch.toDouble(), temperature);
          }).toList();
          temperatureData.sort((a, b) => a.x.compareTo(b.x));
        });
      } else {
        throw Exception('Failed to load initial temperature data');
      }
    } catch (e) {
      print('Error fetching initial data: $e');
      // エラー時のUI更新やユーザーへの通知を行う
    }
  }

  Future<void> fetchLatestData() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.10.19:5000/water_temperature?limit=1'));
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        if (jsonData.isNotEmpty) {
          final latestData = jsonData.first;
          final temperature = latestData['temperature'] as double;
          final timestamp = DateTime.parse(latestData['timestamp']);
          setState(() {
            temperatureData.add(FlSpot(timestamp.millisecondsSinceEpoch.toDouble(), temperature));
            // 過去24時間分のデータのみを保持
            final twentyFourHoursAgo = DateTime.now().subtract(Duration(hours: 24));
            temperatureData.removeWhere((spot) => 
              DateTime.fromMillisecondsSinceEpoch(spot.x.toInt()).isBefore(twentyFourHoursAgo)
            );
            temperatureData.sort((a, b) => a.x.compareTo(b.x));
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: temperatureData.isEmpty
            ? Center(child: CircularProgressIndicator())
            : LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                          return Text(
                            DateFormat('HH:mm').format(date),
                            style: TextStyle(fontSize: 8),
                          );
                        },
                        reservedSize: 30,
                        interval: 3600000, // 1時間ごとに表示
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text('${value.toStringAsFixed(1)}°C');
                        },
                        reservedSize: 30,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  minX: temperatureData.first.x,
                  maxX: temperatureData.last.x,
                  minY: temperatureData.map((spot) => spot.y).reduce((a, b) => a < b ? a : b) - 1,
                  maxY: temperatureData.map((spot) => spot.y).reduce((a, b) => a > b ? a : b) + 1,
                  lineBarsData: [
                    LineChartBarData(
                      spots: temperatureData,
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}