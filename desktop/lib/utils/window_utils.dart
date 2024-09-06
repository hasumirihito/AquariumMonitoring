import 'package:flutter/material.dart';
import 'dart:io';

Future<Size> getScreenSize() async {
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

Future<void> setWindowPosition(double left, double top) async {
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
