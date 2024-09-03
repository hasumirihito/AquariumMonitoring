import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

List<FlSpot> prepareChartData(List<Map<String, dynamic>> data, String key) {
  return data
      .map((item) {
        final timestamp = DateTime.parse(item['water_temp_timestamp']);
        final value = item[key] as double?;
        if (value != null) {
          final minutes = timestamp.hour * 60 + timestamp.minute;
          return FlSpot(minutes.toDouble(), value);
        }
        return FlSpot.nullSpot;
      })
      .where((spot) => spot != FlSpot.nullSpot)
      .toList();
}

FlTitlesData getChartTitles() {
  return FlTitlesData(
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 30,
        interval: 120,
        getTitlesWidget: (value, meta) {
          final hour = (value ~/ 60).toInt();
          if (hour % 2 == 0) {
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

LineTouchData getLineTouchData() {
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
