import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_utils.dart';

class LicenseManager {
  static const String _secretKey = 'HomaSecret2026';
  static const String _prefsKey = 'homa_license_data';

  static Future<String> getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    if (await deviceInfo.androidInfo.then((_) => true).catchError((_) => false)) {
      final info = await deviceInfo.androidInfo;
      return info.id; // Android ID
    }
    final info = await deviceInfo.iosInfo;
    return info.identifierForVendor ?? 'unknown';
  }

  static String generateLicense(String deviceId, String expiryDate, String planId) {
    final payload = '$deviceId|$expiryDate|$planId';
    final hmac = Hmac(sha256, utf8.encode(_secretKey));
    final checksum = hmac.convert(utf8.encode(payload)).toString();
    return base64Encode(utf8.encode('$payload|$checksum'));
  }

  static Future<Map<String, dynamic>> validateLicense(String licenseCode) async {
    try {
      final decoded = utf8.decode(base64Decode(licenseCode));
      final parts = decoded.split('|');
      if (parts.length != 4) return {'valid': false, 'error': 'فرمت نامعتبر'};

      final [deviceId, expiryDate, planId, checksum] = parts;
      final currentDeviceId = await getDeviceId();
      
      if (deviceId != currentDeviceId) return {'valid': false, 'error': 'عدم تطابق دستگاه'};

      final payload = '$deviceId|$expiryDate|$planId';
      final hmac = Hmac(sha256, utf8.encode(_secretKey));
      final expectedChecksum = hmac.convert(utf8.encode(payload)).toString();

      if (checksum != expectedChecksum) return {'valid': false, 'error': 'لایسنس جعلی'};

      // بررسی تاریخ (ساده‌شده برای آفلاین)
      // در نسخه نهایی می‌توان تاریخ شمسی را به میلادی تبدیل و مقایسه کرد
      return {'valid': true, 'planId': planId, 'expiryDate': expiryDate};
    } catch (e) {
      return {'valid': false, 'error': 'خطا در خواندن لایسنس'};
    }
  }
}