import 'package:intl/intl.dart';

/// Presentation-only formatting for the Egyptian Arabic storefront.
/// Monetary values remain numeric throughout the domain and data layers.
abstract final class EgyptianFormatters {
  static final NumberFormat _money = NumberFormat('#,##0.##', 'ar_EG');

  static String money(num value) => '${_money.format(value)} ج.م';

  /// Returns a canonical Egyptian mobile number (`01XXXXXXXXX`) or null.
  static String? normalizeMobile(String input) {
    final digits = input.replaceAll(RegExp(r'\D'), '');
    final local = digits.startsWith('0020')
        ? digits.substring(4)
        : digits.startsWith('20')
            ? digits.substring(2)
            : digits;
    return RegExp(r'^01[0125]\d{8}$').hasMatch(local) ? local : null;
  }

  static String? whatsappNumber(String input) {
    final local = normalizeMobile(input);
    return local == null ? null : '20${local.substring(1)}';
  }
}
