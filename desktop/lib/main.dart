import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:desktop_window/desktop_window.dart';
import 'dart:io' show Platform;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await DesktopWindow.setMinWindowSize(const Size(600, 800));
    await DesktopWindow.setWindowSize(const Size(900, 1000));
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '水温ダッシュボード',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: TemperatureDashboard(),
    );
  }
}

class TemperatureDashboard extends StatefulWidget {
  @override
  _TemperatureDashboardState createState() => _TemperatureDashboardState();
}

class _TemperatureDashboardState extends State<TemperatureDashboard> {
  double? latestTemperature;
  String? lastUpdated;
  List<Map<String, dynamic>> temperatureHistory = [];
  Timer? timer;
  Size? windowSize;

  @override
  void initState() {
    super.initState();
    fetchLatestData();
    fetchTemperatureHistory();
    timer = Timer.periodic(Duration(minutes: 6), (Timer t) {
      fetchLatestData();
      fetchTemperatureHistory();
    });
    _getWindowSize();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> _getWindowSize() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      try {
        windowSize = await DesktopWindow.getWindowSize();
        setState(() {});
      } catch (e) {
        print('ウィンドウサイズの取得に失敗しました: $e');
      }
    }
  }

  Future<void> _setWindowSize(Size size) async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      try {
        await DesktopWindow.setWindowSize(size);
        await _getWindowSize();
      } catch (e) {
        print('ウィンドウサイズの設定に失敗しました: $e');
      }
    }
  }

  Future<void> fetchLatestData() async {
    try {
      final response = await http.get(
          Uri.parse('http://192.168.10.19:5000/water_temperature?limit=1'));
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

  Future<void> fetchTemperatureHistory() async {
    try {
      final response = await http.get(
          Uri.parse('http://192.168.10.19:5000/water_temperature?limit=144'));
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        setState(() {
          temperatureHistory =
              List<Map<String, dynamic>>.from(jsonData.reversed);
        });
      } else {
        throw Exception('Failed to load temperature history');
      }
    } catch (e) {
      print('Error fetching temperature history: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('水温ダッシュボード'),
        elevation: 0,
        actions: [
          if (Platform.isWindows || Platform.isLinux || Platform.isMacOS)
            IconButton(
              icon: Icon(Icons.aspect_ratio),
              onPressed: () => _setWindowSize(Size(1200, 1000)),
              tooltip: 'ウィンドウを拡大',
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (windowSize != null)
                Text(
                    '現在のウィンドウサイズ: ${windowSize!.width.toInt()} x ${windowSize!.height.toInt()}'),
              SizedBox(height: 10),
              _buildCurrentTemperatureCard(),
              SizedBox(height: 20),
              _buildTemperatureHistoryCard(),
              SizedBox(height: 20),
              _buildStatusCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentTemperatureCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('現在の水温',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                latestTemperature == null
                    ? CircularProgressIndicator()
                    : Text(
                        '${latestTemperature?.toStringAsFixed(1)}°C',
                        style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue),
                      ),
                Icon(Icons.water_drop, size: 48, color: Colors.blue),
              ],
            ),
            SizedBox(height: 10),
            Text('最終更新: ${_formatTimestamp(lastUpdated)}',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildTemperatureHistoryCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('24時間の温度推移',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Container(
              height: windowSize != null ? windowSize!.height * 0.5 : 500,
              child: temperatureHistory.isEmpty
                  ? Center(child: CircularProgressIndicator())
                  : _buildLineChart(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart() {
    List<FlSpot> spots = [];
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (var i = 0; i < temperatureHistory.length; i++) {
      final data = temperatureHistory[i];
      final temperature = data['temperature'] as double;
      spots.add(FlSpot(i.toDouble(), temperature));
      if (temperature < minY) minY = temperature;
      if (temperature > maxY) maxY = temperature;
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: 24,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < temperatureHistory.length) {
                  final data = temperatureHistory[index];
                  return Text(
                    _formatTime(data['timestamp']),
                    style: const TextStyle(
                      color: Color(0xff68737d),
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toStringAsFixed(1)}°C',
                  style: const TextStyle(
                    color: Color(0xff67727d),
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                );
              },
              reservedSize: 28,
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        minX: 0,
        maxX: temperatureHistory.length.toDouble() - 1,
        minY: minY - 1,
        maxY: maxY + 1,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('システム状態',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                Text('正常に稼働中',
                    style: TextStyle(
                        color: Colors.green, fontWeight: FontWeight.bold)),
              ],
            ),
            Icon(Icons.check_circle, size: 48, color: Colors.green),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return 'N/A';
    final dateTime = DateTime.parse(timestamp);
    return DateFormat('yyyy/MM/dd HH:mm').format(dateTime);
  }

  String _formatTime(String timestamp) {
    final dateTime = DateTime.parse(timestamp);
    return DateFormat('HH:mm').format(dateTime);
  }
}
