import 'package:flutter/material.dart';
import '../utils/date_time_utils.dart';

Widget buildCurrentTemperatureCard(
    double? latestTemperature, String? lastUpdated) {
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
                      '${latestTemperature.toStringAsFixed(1)}°C',
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
          Text('最終更新: ${formatTimestamp(lastUpdated)}',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    ),
  );
}
