import 'package:shared_preferences/shared_preferences.dart';

class AppUtils {
  static const String englishDigits = '0123456789';
  static const String persianDigits = '۰۱۲۳۴۵۶۷۸۹';

  static String toPersianDigits(String text) {
    return text.splitMapJoin(
      RegExp(r'[0-9]'),
      onMatch: (m) => persianDigits[int.parse(m.group(0)!)],
      onNonMatch: (n) => n,
    );
  }

  static String toEnglishDigits(String text) {
    return text.splitMapJoin(
      RegExp(r'[۰-۹]'),
      onMatch: (m) => englishDigits[persianDigits.indexOf(m.group(0)!)],
      onNonMatch: (n) => n,
    );
  }

  static String formatPrice(dynamic price) {
    if (price == null) return '۰';
    String cleanPrice = toEnglishDigits(price.toString()).replaceAll(RegExp(r'[^0-9]'), '');
    String formatted = cleanPrice.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    return '${toPersianDigits(formatted)} تومان';
  }

  // بررسی حالت مدیریت تک‌نفره (Master Mode)
  static Future<bool> isMasterMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_master_mode') ?? false;
  }

  static Future<void> toggleMasterMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_master_mode', value);
  }
}