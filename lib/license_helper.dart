import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';

class LicenseHelper {
  static const String _secretKey = 'HOMA_OILSERVICE_2026_DEV_SECRET_KEY';
  
  static String generateLicense({
    required String deviceId,
    required Jalali expiryDate,
    required int planId,
  }) {
    final expiryStr = '${expiryDate.year}-${expiryDate.month.toString().padLeft(2, '0')}-${expiryDate.day.toString().padLeft(2, '0')}';
    final checksum = _generateChecksum(deviceId, expiryStr, planId);
    final payload = '$deviceId|$expiryStr|$planId|$checksum';
    return base64Encode(utf8.encode(payload));
  }
  
  static Map<String, dynamic>? validateLicense(String licenseCode, String currentDeviceId) {
    try {
      final payload = utf8.decode(base64Decode(licenseCode.trim()));
      final parts = payload.split('|');
      if (parts.length != 4) return null;
      
      final deviceId = parts[0];
      final expiryStr = parts[1];
      final planId = int.parse(parts[2]);
      final checksum = parts[3];
      
      if (deviceId != currentDeviceId) return {'error': 'device_mismatch'};
      
      final expectedChecksum = _generateChecksum(deviceId, expiryStr, planId);
      if (checksum != expectedChecksum) return {'error': 'invalid_checksum'};
      
      final expiryParts = expiryStr.split('-');
      final jalaliExpiry = Jalali(
        int.parse(expiryParts[0]),
        int.parse(expiryParts[1]),
        int.parse(expiryParts[2]),
      );
      final expiryDateTime = jalaliExpiry.toDateTime();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final expiryDay = DateTime(expiryDateTime.year, expiryDateTime.month, expiryDateTime.day);
      final daysRemaining = expiryDay.difference(today).inDays;
      
      if (daysRemaining < 0) return {'error': 'expired'};
      
      return {
        'deviceId': deviceId,
        'expiryJalali': jalaliExpiry,
        'planId': planId,
        'daysRemaining': daysRemaining,
      };
    } catch (e) {
      return {'error': 'invalid_format'};
    }
  }
  
  static String _generateChecksum(String deviceId, String expiryStr, int planId) {
    final input = '$deviceId|$expiryStr|$planId|$_secretKey';
    int hash = 0;
    for (int i = 0; i < input.length; i++) {
      hash = (hash * 31 + input.codeUnitAt(i)) & 0x7FFFFFFF;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }
  
  static Future<void> saveLicense(String licenseCode, int planId, Jalali expiryDate) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('license_code', licenseCode);
    await prefs.setInt('license_plan_id', planId);
    await prefs.setString('license_expiry_jalali', '${expiryDate.year}-${expiryDate.month.toString().padLeft(2, '0')}-${expiryDate.day.toString().padLeft(2, '0')}');
    await prefs.setString('license_activated_at', DateTime.now().toIso8601String());
  }
  
  static Future<Map<String, dynamic>?> getLicense() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('license_code');
    final planId = prefs.getInt('license_plan_id');
    final expiryStr = prefs.getString('license_expiry_jalali');
    if (code == null || planId == null || expiryStr == null) return null;
    
    try {
      final parts = expiryStr.split('-');
      final jalaliExpiry = Jalali(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      final expiryDateTime = jalaliExpiry.toDateTime();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final expiryDay = DateTime(expiryDateTime.year, expiryDateTime.month, expiryDateTime.day);
      final daysRemaining = expiryDay.difference(today).inDays;
      
      return {
        'code': code,
        'planId': planId,
        'expiryJalali': jalaliExpiry,
        'daysRemaining': daysRemaining,
        'isActive': daysRemaining >= 0,
      };
    } catch (e) {
      return null;
    }
  }
  
  static Future<void> clearLicense() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('license_code');
    await prefs.remove('license_plan_id');
    await prefs.remove('license_expiry_jalali');
    await prefs.remove('license_activated_at');
  }
}