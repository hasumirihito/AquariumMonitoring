import 'package:intl/intl.dart';

String formatTimestamp(String? timestamp) {
  if (timestamp == null) return 'N/A';
  final dateTime = DateTime.parse(timestamp);
  return DateFormat('yyyy/MM/dd HH:mm').format(dateTime);
}
