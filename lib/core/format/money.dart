import 'package:intl/intl.dart' show NumberFormat;

final _money = NumberFormat.decimalPattern('en');

/// Format a money amount, always with thousands separator, no decimals if integer.
String formatMoney(double amount) {
  final abs = amount.abs();
  final str = abs == abs.roundToDouble()
      ? _money.format(abs.round())
      : _money.format(abs);
  return str;
}

String formatSigned(double amount) {
  if (amount == 0) return '0';
  final sign = amount < 0 ? '-' : '';
  return '$sign${formatMoney(amount)}';
}
