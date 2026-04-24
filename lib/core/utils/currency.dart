import 'package:intl/intl.dart';

String formatMAD(int cents) {
  final f = NumberFormat.currency(locale: 'fr_MA', symbol: 'DH', decimalDigits: 0);
  return f.format(cents / 100.0);
}
