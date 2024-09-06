import 'package:flutter/material.dart';
import 'package:desktop_window/desktop_window.dart';
import 'dart:io' show Platform;
import 'screens/temperature_dashboard.dart';
import 'utils/window_utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await DesktopWindow.setMinWindowSize(const Size(1280, 900));
    Size windowSize = Size(1280, 1000);
    await DesktopWindow.setWindowSize(windowSize);

    Size screenSize = await getScreenSize();
    if (screenSize != Size.zero) {
      double left = (screenSize.width - windowSize.width) / 2;
      double top = (screenSize.height - windowSize.height) / 2;
      await setWindowPosition(left, top);
    }
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
