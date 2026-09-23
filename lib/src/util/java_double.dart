String javaDouble(double value) {
  if (value.isNaN) return 'NaN';
  if (value.isInfinite) return value > 0 ? 'Infinity' : '-Infinity';
  if (value == 0) return value.isNegative ? '-0.0' : '0.0';
  final sign = value < 0 ? '-' : '';
  final magnitude = value.abs();
  var parts = magnitude.toStringAsExponential().split('e');
  if (parts[0].length == 1) parts = magnitude.toStringAsExponential(1).split('e');
  final digits = parts[0].replaceAll('.', '');
  final exponent = int.parse(parts[1]);
  if (magnitude >= 1e-3 && magnitude < 1e7) {
    if (exponent < 0) return '${sign}0.${'0' * (-exponent - 1)}${_trimmed(digits)}';
    final whole = exponent + 1;
    if (digits.length <= whole) return '$sign${digits.padRight(whole, '0')}.0';
    final fraction = _trimmed(digits.substring(whole));
    return '$sign${digits.substring(0, whole)}.${fraction.isEmpty ? '0' : fraction}';
  }
  return '$sign${digits[0]}.${digits.substring(1)}E$exponent';
}

String _trimmed(String digits) {
  var end = digits.length;
  while (end > 0 && digits[end - 1] == '0') {
    end--;
  }
  return digits.substring(0, end);
}
