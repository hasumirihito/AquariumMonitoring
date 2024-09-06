import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/chart_utils.dart';

Widget buildTemperatureHistoryCard(
  BuildContext context,
  bool isLoading,
  DateTime selectedDate,
  List<Map<String, dynamic>> temperatureHistory,
  Function(BuildContext) selectDate,
  Function(DateTime) fetchTemperatureHistory,
) {
  return StatefulBuilder(
    builder: (BuildContext context, StateSetter setState) {
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
                                final newDate =
                                    selectedDate.subtract(Duration(days: 1));
                                await fetchTemperatureHistory(newDate);
                                setState(() {
                                  selectedDate = newDate;
                                });
                              },
                      ),
                      TextButton(
                        child:
                            Text(DateFormat('yyyy/MM/dd').format(selectedDate)),
                        onPressed: isLoading
                            ? null
                            : () async {
                                final DateTime? picked =
                                    await selectDate(context);
                                if (picked != null && picked != selectedDate) {
                                  await fetchTemperatureHistory(picked);
                                  setState(() {
                                    selectedDate = picked;
                                  });
                                }
                              },
                      ),
                      IconButton(
                        icon: Icon(Icons.arrow_forward),
                        onPressed: (isLoading ||
                                selectedDate.day == DateTime.now().day)
                            ? null
                            : () async {
                                final newDate =
                                    selectedDate.add(Duration(days: 1));
                                await fetchTemperatureHistory(newDate);
                                setState(() {
                                  selectedDate = newDate;
                                });
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
                      child: buildTemperatureChart(temperatureHistory),
                    ),
                    SizedBox(height: 20),
                    Container(
                      height: 300,
                      child: buildHumidityChart(temperatureHistory),
                    ),
                  ],
                ),
            ],
          ),
        ),
      );
    },
  );
}

Widget buildTemperatureChart(List<Map<String, dynamic>> temperatureHistory) {
  final waterTempSpots =
      prepareChartData(temperatureHistory, 'water_temperature');
  final airTempSpots = prepareChartData(temperatureHistory, 'air_temperature');

  final allTemps =
      [...waterTempSpots, ...airTempSpots].map((spot) => spot.y).toList();
  final minY = allTemps.reduce((a, b) => a < b ? a : b);
  final maxY = allTemps.reduce((a, b) => a > b ? a : b);

  return LineChart(
    LineChartData(
      gridData: FlGridData(show: true),
      titlesData: getChartTitles(),
      borderData: FlBorderData(show: true),
      minX: 0,
      maxX: 24 * 60 - 1,
      minY: minY - 1,
      maxY: maxY + 1,
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
      lineTouchData: getLineTouchData(),
    ),
  );
}

Widget buildHumidityChart(List<Map<String, dynamic>> temperatureHistory) {
  final humiditySpots = prepareChartData(temperatureHistory, 'humidity');

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
            titlesData: getChartTitles(),
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
            lineTouchData: getLineTouchData(),
          ),
        ),
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          legendItem('湿度', Colors.green),
        ],
      ),
    ],
  );
}

Widget legendItem(String label, Color color) {
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
