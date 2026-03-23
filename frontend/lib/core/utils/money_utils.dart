class MoneyUtils {
  static double normalize(dynamic value) {
    final amount = value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
    return double.parse(amount.toStringAsFixed(2));
  }

  static String format(dynamic value, {bool withSymbol = true}) {
    final amount = normalize(value);
    final decimals = amount == amount.roundToDouble() ? 0 : 2;
    final formatted = amount.toStringAsFixed(decimals);
    return withSymbol ? 'Rs $formatted' : formatted;
  }
}
