import 'package:flutter/material.dart';

Widget buildStatusCard(bool isLoading, Function manualUpdate) {
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
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      icon: Icon(Icons.refresh),
                      onPressed: () => manualUpdate(),
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
