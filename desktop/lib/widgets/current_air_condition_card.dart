import 'package:flutter/material.dart';

Widget buildCurrentAirConditionCard(
    double? latestAirTemperature, double? latestHumidity) {
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
                          '${latestAirTemperature.toStringAsFixed(1)}°C',
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
                          '${latestHumidity.toStringAsFixed(1)}%',
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
