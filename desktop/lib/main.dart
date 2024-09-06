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
  static const String API_BASE_URL = 'http://192.168.10.19:5000';
  double? latestTemperature;
  double? latestAirTemperature;
  double? latestHumidity;
  String? lastUpdated;
  List<Map<String, dynamic>> temperatureHistory = [];
  Timer? timer;
  Size? windowSize;
  DateTime selectedDate = DateTime.now();
  bool isLoading = false;
  String lastFetchDuration = '';
  String lastHttpRequestDuration = '';

  @override
  void initState() {
    super.initState();
    fetchLatestData().then((_) {
      if (mounted) {
        setState(() {}); // 状態を更新してUIを再描画
      }
    });
    fetchTemperatureHistory();
    _scheduleNextUpdate();
    _getWindowSize();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void _scheduleNextUpdate() {
    final now = DateTime.now();
    final minutesToNextUpdate = 5 - (now.minute % 5) + 1;
    final duration =
        Duration(minutes: minutesToNextUpdate, seconds: 60 - now.second);

    timer?.cancel(); // 既存のタイマーをキャンセル
    timer = Timer(duration, () {
      print("TIMER START");
      fetchLatestData();
      fetchTemperatureHistory();
      _scheduleNextUpdate(); // 次の更新をスケジュール
    });
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
      print("fetchLatestData START");
      final response =
          await http.get(Uri.parse('$API_BASE_URL/water_temperature?limit=1'));
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        print("Received data: $jsonData"); // デバッグ出力を追加
        if (jsonData.isNotEmpty) {
          final latestData = jsonData.first;
          print("Latest data: $latestData"); // デバッグ出力を追加
          setState(() {
            latestTemperature = latestData['water_temperature'] as double?;
            latestAirTemperature = latestData['air_temperature'] as double?;
            latestHumidity = latestData['humidity'] as double?;
            lastUpdated = latestData['water_temp_timestamp'];
          });
          print(
              "Updated state: water_temp=$latestTemperature, air_temp=$latestAirTemperature, humidity=$latestHumidity"); // デバッグ出力を追加
        }
      } else {
        print("HTTP Error: ${response.statusCode}"); // エラー情報を出力
        throw Exception('Failed to load latest temperature data');
      }
    } catch (e) {
      print('Error fetching latest data: $e');
    }
  }

  Future<void> fetchTemperatureHistory() async {
    final totalStopwatch = Stopwatch()..start();
    setState(() {
      isLoading = true;
    });

    try {
      final startDate =
          DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
      final endDate = startDate.add(Duration(days: 1));
      final formattedStartDate =
          DateFormat('yyyy-MM-dd HH:mm:ss').format(startDate);
      final formattedEndDate =
          DateFormat('yyyy-MM-dd HH:mm:ss').format(endDate);

      print(
          'Fetching data for date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}');
      final url =
          '$API_BASE_URL/water_temperature?start_date=$formattedStartDate&end_date=$formattedEndDate';
      print('URL: $url');

      final httpStopwatch = Stopwatch()..start();
      final response = await http.get(Uri.parse(url));
      httpStopwatch.stop();
      lastHttpRequestDuration = '${httpStopwatch.elapsedMilliseconds}ms';
      print('HTTP request duration: $lastHttpRequestDuration');

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        print('Fetched ${jsonData.length} records');
        setState(() {
          temperatureHistory = List<Map<String, dynamic>>.from(jsonData);
          isLoading = false;
          lastFetchDuration = '${totalStopwatch.elapsedMilliseconds}ms';
        });
        print(
            'Updated temperatureHistory with ${temperatureHistory.length} records');
        print('Total fetch duration: $lastFetchDuration');
      } else {
        print('Failed to load data. Status code: ${response.statusCode}');
        setState(() {
          isLoading = false;
          lastFetchDuration = 'Error';
          lastHttpRequestDuration = 'Error';
        });
        throw Exception('Failed to load temperature history');
      }
    } catch (e) {
      print('Error fetching temperature history: $e');
      setState(() {
        temperatureHistory = [];
        isLoading = false;
        lastFetchDuration = 'Error';
        lastHttpRequestDuration = 'Error';
      });
    }
    totalStopwatch.stop();
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
      await fetchTemperatureHistory(); // awaitを使用
      setState(() {}); // データ取得後に再描画を強制
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
                  SizedBox(width: 16),
                  Expanded(child: _buildCurrentAirConditionCard()),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('システム状態',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                isLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        icon: Icon(Icons.refresh),
                        onPressed: _manualUpdate,
                        tooltip: '手動更新',
                      ),
              ],
            ),
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

  Future<void> _manualUpdate() async {
    setState(() {
      isLoading = true;
    });

    try {
      await Future.wait([
        fetchLatestData(),
        fetchTemperatureHistory(),
      ]);
    } catch (e) {
      print('Error during manual update: $e');
      // エラー処理を追加することもできます（例：スナックバーでユーザーに通知）
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _buildCurrentTemperatureCard() {
    Color getTemperatureColor(double? temperature) {
      if (temperature == null) return Colors.black;
      if (temperature >= 25) return Colors.red;
      if (temperature <= 20) return Colors.blue;
      return Colors.green;
    }

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
                            color: getTemperatureColor(latestTemperature)),
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
    print("lastFetchDuration : $lastFetchDuration");
    print("lastHttpRequestDuration : $lastHttpRequestDuration");

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
                Text('24時間の推移',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back),
                      onPressed: isLoading
                          ? null
                          : () async {
                              setState(() {
                                selectedDate =
                                    selectedDate.subtract(Duration(days: 1));
                              });
                              await fetchTemperatureHistory();
                            },
                    ),
                    TextButton(
                      child:
                          Text(DateFormat('yyyy/MM/dd').format(selectedDate)),
                      onPressed: isLoading ? null : () => _selectDate(context),
                    ),
                    IconButton(
                      icon: Icon(Icons.arrow_forward),
                      onPressed:
                          (isLoading || selectedDate.day == DateTime.now().day)
                              ? null
                              : () async {
                                  setState(() {
                                    selectedDate =
                                        selectedDate.add(Duration(days: 1));
                                  });
                                  await fetchTemperatureHistory();
                                },
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 10),
            if (isLoading)
              Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 10),
                    Text('データを読み込んでいます...'),
                  ],
                ),
              )
            else if (temperatureHistory.isEmpty)
              Center(child: Text('データがありません'))
            else
              Column(
                children: [
                  Container(
                    height: 300,
                    child: _buildTemperatureChart(),
                  ),
                  SizedBox(height: 20),
                  Container(
                    height: 300,
                    child: _buildHumidityChart(),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _prepareChartData(String key) {
    List<FlSpot> spots = [];
    for (var data in temperatureHistory) {
      final timestamp = DateTime.parse(data['water_temp_timestamp']);
      final value = data[key] as double?;
      if (value != null) {
        final minutes = timestamp.hour * 60 + timestamp.minute;
        spots.add(FlSpot(minutes.toDouble(), value));
      }
    }
    print('Prepared ${spots.length} spots for $key'); // デバッグプリント追加
    return spots;
  }

  Widget _buildTemperatureChart() {
    final waterTempSpots = _prepareChartData('water_temperature');
    final airTempSpots = _prepareChartData('air_temperature');

    // Y軸の範囲を計算
    final allTemps =
        [...waterTempSpots, ...airTempSpots].map((spot) => spot.y).toList();
    final minY = allTemps.reduce((a, b) => a < b ? a : b);
    final maxY = allTemps.reduce((a, b) => a > b ? a : b);

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        titlesData: _getChartTitles(),
        borderData: FlBorderData(show: true),
        minX: 0,
        maxX: 24 * 60 - 1,
        minY: minY - 1, // 下限を調整
        maxY: maxY + 1, // 上限を調整
        lineBarsData: [
          LineChartBarData(
            spots: waterTempSpots,
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
          LineChartBarData(
            spots: airTempSpots,
            isCurved: true,
            color: Colors.red,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        ],
        lineTouchData: _getLineTouchData(),
      ),
    );
  }

  Widget _buildHumidityChart() {
    final humiditySpots = _prepareChartData('humidity');

    // Y軸の範囲を計算
    final minY =
        humiditySpots.map((spot) => spot.y).reduce((a, b) => a < b ? a : b);
    final maxY =
        humiditySpots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);

    return Column(
      children: [
        Expanded(
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: true),
              titlesData: _getChartTitles(),
              borderData: FlBorderData(show: true),
              minX: 0,
              maxX: 24 * 60 - 1,
              minY: minY - 1,
              maxY: maxY + 1,
              lineBarsData: [
                LineChartBarData(
                  spots: humiditySpots,
                  isCurved: true,
                  color: Colors.green,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(show: false),
                ),
              ],
              lineTouchData: _getLineTouchData(),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _legendItem('湿度', Colors.green),
          ],
        ),
      ],
    );
  }

  Widget _buildCurrentAirConditionCard() {
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
            Text('現在の気温・湿度',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    Icon(Icons.thermostat, size: 24, color: Colors.orange),
                    SizedBox(height: 4),
                    latestAirTemperature == null
                        ? Text('--°C',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ))
                        : Text(
                            '${latestAirTemperature?.toStringAsFixed(1)}°C',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                  ],
                ),
                SizedBox(width: 20),
                Column(
                  children: [
                    Icon(Icons.water_drop, size: 24, color: Colors.blue),
                    SizedBox(height: 4),
                    latestHumidity == null
                        ? Text('--%',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ))
                        : Text(
                            '${latestHumidity?.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                  ],
                ),
              ],
            ),
            Spacer(),
          ],
        ),
      ),
    );
  }

  FlTitlesData _getChartTitles() {
    return FlTitlesData(
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          interval: 120, // 2時間ごとに表示
          getTitlesWidget: (value, meta) {
            final hour = (value ~/ 60).toInt();
            if (hour % 2 == 0) {
              // 偶数時のみ表示
              return Text(
                '${hour.toString().padLeft(2, '0')}:00',
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
              '${value.toInt()}°C',
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
    );
  }

  LineTouchData _getLineTouchData() {
    return LineTouchData(
      enabled: true,
      touchTooltipData: LineTouchTooltipData(
        getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
          return touchedBarSpots.map((barSpot) {
            final flSpot = barSpot;
            final hour = (flSpot.x ~/ 60).toInt();
            final minute = (flSpot.x % 60).toInt();
            final time = '$hour:${minute.toString().padLeft(2, '0')}';
            String tooltipText = '';
            if (barSpot.barIndex == 0) {
              tooltipText = '水温: ${flSpot.y.toStringAsFixed(1)}°C\n$time';
            } else {
              tooltipText = '気温: ${flSpot.y.toStringAsFixed(1)}°C\n$time';
            }
            return LineTooltipItem(
              tooltipText,
              const TextStyle(color: Colors.white),
            );
          }).toList();
        },
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          color: color,
        ),
        SizedBox(width: 4),
        Text(label),
      ],
    );
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return 'N/A';
    final dateTime = DateTime.parse(timestamp);
    return DateFormat('yyyy/MM/dd HH:mm').format(dateTime);
  }
}
