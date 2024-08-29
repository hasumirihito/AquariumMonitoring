import 'dart:async';
import 'dart:io';
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
    await DesktopWindow.setMinWindowSize(const Size(1280, 900));
    Size windowSize = Size(1280, 1000);
    await DesktopWindow.setWindowSize(windowSize);

    Size screenSize = await _getScreenSize();
    if (screenSize != Size.zero) {
      double left = (screenSize.width - windowSize.width) / 2;
      double top = (screenSize.height - windowSize.height) / 2;
      await _setWindowPosition(left, top);
    }
  }
  runApp(MyApp());
}

Future<Size> _getScreenSize() async {
  if (Platform.isWindows) {
    try {
      var result = await Process.run(
          'wmic', ['desktopmonitor', 'get', 'ScreenHeight,ScreenWidth']);
      if (result.exitCode == 0) {
        var lines = result.stdout.toString().split('\n');
        if (lines.length > 1) {
          var parts = lines[1].trim().split(RegExp(r'\s+'));
          if (parts.length == 2) {
            return Size(double.parse(parts[1]), double.parse(parts[0]));
          }
        }
      }
    } catch (e) {
      print('Error getting screen size: $e');
    }
  }
  return Size.zero;
}

Future<void> _setWindowPosition(double left, double top) async {
  if (Platform.isWindows) {
    try {
      await Process.run('powershell', [
        '-command',
        '\$window = New-Object -ComObject Shell.Application; \$window.MinimizeAll(); Start-Sleep -Milliseconds 100; [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point(${left.round()}, ${top.round()}); [System.Windows.Forms.SendKeys]::SendWait("%{UP}")'
      ]);
    } catch (e) {
      print('Error setting window position: $e');
    }
  }
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
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    fetchLatestData();
    fetchTemperatureHistory(); // 引数を削除
    timer = Timer.periodic(Duration(minutes: 6), (Timer t) {
      fetchLatestData();
      fetchTemperatureHistory(); // 引数を削除
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
      final startDate =
          DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
      final endDate = startDate.add(Duration(days: 1));
      final formattedStartDate =
          DateFormat('yyyy-MM-dd HH:mm:ss').format(startDate);
      final formattedEndDate =
          DateFormat('yyyy-MM-dd HH:mm:ss').format(endDate);

      final response = await http.get(
        Uri.parse(
            'http://192.168.10.19:5000/water_temperature?start_date=$formattedStartDate&end_date=$formattedEndDate'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        setState(() {
          temperatureHistory = List<Map<String, dynamic>>.from(jsonData);
        });
      } else {
        throw Exception('Failed to load temperature history');
      }
    } catch (e) {
      print('Error fetching temperature history: $e');
    }
  }

  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
      fetchTemperatureHistory(); // 引数を削除
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
              onPressed: () => _setWindowSize(Size(1280, 1000)),
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
              Row(
                children: [
                  Expanded(child: _buildStatusCard()),
                  SizedBox(width: 16),
                  Expanded(child: _buildCurrentTemperatureCard()),
                ],
              ),
              SizedBox(height: 20),
              _buildTemperatureHistoryCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        height: 150,
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('システム状態',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 48, color: Colors.green),
                SizedBox(width: 10),
                Text('正常に稼働中',
                    style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ],
            ),
            Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentTemperatureCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        height: 150,
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('現在の水温',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                latestTemperature == null
                    ? CircularProgressIndicator()
                    : Text(
                        '${latestTemperature?.toStringAsFixed(1)}°C',
                        style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue),
                      ),
                SizedBox(width: 10),
                Icon(Icons.water_drop, size: 36, color: Colors.blue),
              ],
            ),
            Spacer(),
            Text('最終更新: ${_formatTimestamp(lastUpdated)}',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('24時間の温度推移',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back),
                      onPressed: () {
                        setState(() {
                          selectedDate =
                              selectedDate.subtract(Duration(days: 1));
                        });
                        fetchTemperatureHistory();
                      },
                    ),
                    TextButton(
                      child:
                          Text(DateFormat('yyyy/MM/dd').format(selectedDate)),
                      onPressed: () => _selectDate(context),
                    ),
                    IconButton(
                      icon: Icon(Icons.arrow_forward),
                      onPressed: selectedDate.day == DateTime.now().day
                          ? null
                          : () {
                              setState(() {
                                selectedDate =
                                    selectedDate.add(Duration(days: 1));
                              });
                              fetchTemperatureHistory();
                            },
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 10),
            Container(
              height: 450,
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
    DateTime? startDate;

    final last24Hours = temperatureHistory.length > 144
        ? temperatureHistory.sublist(temperatureHistory.length - 144)
        : temperatureHistory;

    for (var i = 0; i < last24Hours.length; i++) {
      final data = last24Hours[i];
      final temperature = data['temperature'] as double;
      spots.add(FlSpot(i.toDouble(), temperature));
      if (temperature < minY) minY = temperature;
      if (temperature > maxY) maxY = temperature;

      if (startDate == null) {
        startDate = DateTime.parse(data['timestamp']);
      }
    }

    return Column(
      children: [
        SizedBox(
          height: 350, // グラフの高さを少し減らす
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: true),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: 6,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < last24Hours.length && index % 6 == 0) {
                        final data = last24Hours[index];
                        final dateTime = DateTime.parse(data['timestamp']);
                        return Text(
                          DateFormat('HH:mm').format(dateTime),
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
                topTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: true),
              minX: 0,
              maxX: last24Hours.length.toDouble() - 1,
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
              lineTouchData: LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                    return touchedBarSpots.map((barSpot) {
                      final flSpot = barSpot;
                      if (flSpot.x.toInt() < last24Hours.length) {
                        final data = last24Hours[flSpot.x.toInt()];
                        final time = _formatTimestamp(data['timestamp']);
                        return LineTooltipItem(
                          '${flSpot.y.toStringAsFixed(1)}°C\n$time',
                          const TextStyle(color: Colors.white),
                        );
                      }
                      return null;
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ),
        if (startDate != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Date: ${DateFormat('yyyy/MM/dd').format(startDate)}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
          ),
      ],
    );
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return 'N/A';
    final dateTime = DateTime.parse(timestamp);
    return DateFormat('yyyy/MM/dd HH:mm').format(dateTime);
  }
}
