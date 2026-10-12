import 'dart:convert';
import 'dart:math';

class InvitationHelper {
  static String generateInvitationCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    return String.fromCharCodes(Iterable.generate(8, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  }

  static String generateQRContent({required String invitationCode, required String apkDownloadUrl}) {
    final data = {'app': 'Homa_OilService', 'version': '1.0.0', 'code': invitationCode, 'apk': apkDownloadUrl};
    return base64Encode(utf8.encode(jsonEncode(data)));
  }

  static Map<String, dynamic>? parseQRContent(String qrContent) {
    try {
      final decoded = utf8.decode(base64Decode(qrContent.trim()));
      final data = jsonDecode(decoded);
      if (data['app'] != 'Homa_OilService') return null;
      return {'code': data['code'], 'apk': data['apk']};
    } catch (e) {
      return null;
    }
  }
}