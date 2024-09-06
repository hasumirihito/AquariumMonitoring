// lib/screens/temperature_dashboard.dart

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import '../widgets/status_card.dart';
import '../widgets/current_temperature_card.dart';
import '../widgets/current_air_condition_card.dart';
import '../widgets/temperature_history_card.dart';
import '../services/api_service.dart';
import '../utils/date_time_utils.dart';

class TemperatureDashboard extends StatefulWidget {
  @override
  _TemperatureDashboardState createState() => _TemperatureDashboardState();
}

class _TemperatureDashboardState extends State<TemperatureDashboard> {
  double? latestTemperature;
  double? latestAirTemperature;
  double? latestHumidity;
  String? lastUpdated;
  List<Map<String, dynamic>> temperatureHistory = [];
  Timer? timer;
  DateTime selectedDate = DateTime.now();
  bool isLoading = false;
  String lastFetchDuration = '';
  String lastHttpRequestDuration = '';

  @override
  void initState() {
    super.initState();
    fetchLatestData();
    fetchTemperatureHistory(selectedDate);
    _scheduleNextUpdate();
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

    timer?.cancel();
    timer = Timer(duration, () {
      fetchLatestData();
      fetchTemperatureHistory(selectedDate);
      _scheduleNextUpdate();
    });
  }

  Future<void> fetchLatestData() async {
    try {
      final data = await ApiService.fetchLatestData();
      setState(() {
        latestTemperature = data['water_temperature'];
        latestAirTemperature = data['air_temperature'];
        latestHumidity = data['humidity'];
        lastUpdated = data['water_temp_timestamp'];
      });
    } catch (e) {
      print('Error fetching latest data: $e');
    }
  }

  Future<void> fetchTemperatureHistory(DateTime selectedDate) async {
    setState(() {
      isLoading = true;
    });

    try {
      print("fetchTemperatureHistory selectedDate:$selectedDate");
      final startDate =
          DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
      final endDate = startDate.add(Duration(days: 1));
      print(
          'Fetching data for: ${startDate.toIso8601String()} to ${endDate.toIso8601String()}');

      final data = await ApiService.fetchTemperatureHistory(startDate, endDate);

      print('Received ${data.length} records');

      if (data.isEmpty) {
        print('No data received for the selected date');
      } else {
        print('First record: ${data.first}');
        print('Last record: ${data.last}');
      }

      setState(() {
        temperatureHistory = data;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching temperature history: $e');
      setState(() {
        temperatureHistory = [];
        isLoading = false;
      });
    }
  }

  Future<void> _manualUpdate() async {
    setState(() {
      isLoading = true;
    });

    try {
      await Future.wait([
        fetchLatestData(),
        fetchTemperatureHistory(selectedDate),
      ]);
    } catch (e) {
      print('Error during manual update: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
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
      await fetchTemperatureHistory(selectedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('水温ダッシュボード'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: buildStatusCard(isLoading, _manualUpdate)),
                  SizedBox(width: 16),
                  Expanded(
                      child: buildCurrentTemperatureCard(
                          latestTemperature, lastUpdated)),
                  SizedBox(width: 16),
                  Expanded(
                      child: buildCurrentAirConditionCard(
                          latestAirTemperature, latestHumidity)),
                ],
              ),
              SizedBox(height: 20),
              buildTemperatureHistoryCard(
                context,
                isLoading,
                selectedDate,
                temperatureHistory,
                _selectDate,
                fetchTemperatureHistory,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
