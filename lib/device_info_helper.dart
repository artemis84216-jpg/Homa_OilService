import 'package:device_info_plus/device_info_plus.dart';

class DeviceInfoHelper {
  static final DeviceInfoHelper instance = DeviceInfoHelper._init();
  DeviceInfoHelper._init();

  String? _cachedDeviceId;

  Future<String> getDeviceId() async {
    if (_cachedDeviceId != null) return _cachedDeviceId!;
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    _cachedDeviceId = androidInfo.id;
    return _cachedDeviceId!;
  }

  Future<Map<String, String>> getFullDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    return {
      'deviceId': androidInfo.id,
      'brand': androidInfo.brand,
      'model': androidInfo.model,
      'androidVersion': androidInfo.version.release,
      'manufacturer': androidInfo.manufacturer,
    };
  }
}