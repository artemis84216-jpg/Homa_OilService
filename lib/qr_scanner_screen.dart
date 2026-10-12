import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';
import 'invitation_helper.dart';
import 'app_utils.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool _isScanned = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isScanned) return;
    for (final barcode in capture.barcodes) {
      if (barcode.rawValue != null) {
        setState(() => _isScanned = true);
        cameraController.stop();
        _processQRCode(barcode.rawValue!);
        break;
      }
    }
  }

  Future<void> _processQRCode(String qrData) async {
    final parsed = InvitationHelper.parseQRContent(qrData);
    if (parsed == null) {
      _showErrorDialog('این یک کد دعوت معتبر همـا تعویض روغنی نیست.');
      return;
    }
    final code = parsed['code'] as String;
    final apkUrl = parsed['apk'] as String;
    Clipboard.setData(ClipboardData(text: code));

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: AppTheme.cardBlack,
            title: const Row(children: [Icon(Icons.check_circle, color: Colors.green, size: 28), SizedBox(width: 8), Text('کد دعوت شناسایی شد!', style: TextStyle(color: Colors.green))]),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('کد دعوت شما در حافظه گوشی کپی شد:', style: TextStyle(color: AppTheme.textWhite)),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppTheme.gold.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.gold)),
                  child: Text(code, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.gold, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () { Navigator.pop(ctx); setState(() => _isScanned = false); cameraController.start(); }, child: const Text('اسکن مجدد', style: TextStyle(color: AppTheme.textGrey))),
              ElevatedButton.icon(
                onPressed: () async {
                  final uri = Uri.parse(apkUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.download),
                label: const Text('دانلود اپلیکیشن'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.gold, foregroundColor: Colors.black),
              ),
            ],
          ),
        ),
      );
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppTheme.cardBlack,
          title: const Row(children: [Icon(Icons.error, color: Colors.red, size: 28), SizedBox(width: 8), Text('خطا', style: TextStyle(color: Colors.red))]),
          content: Text(message, style: const TextStyle(color: AppTheme.textWhite)),
          actions: [TextButton(onPressed: () { Navigator.pop(ctx); setState(() => _isScanned = false); cameraController.start(); }, child: const Text('تلاش مجدد', style: TextStyle(color: AppTheme.gold)))],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('اسکن کد دعوت'), backgroundColor: Colors.black, foregroundColor: AppTheme.gold, centerTitle: true),
      body: Stack(
        children: [
          MobileScanner(controller: cameraController, onDetect: _onDetect),
          Center(child: Container(width: 250, height: 250, decoration: BoxDecoration(border: Border.all(color: AppTheme.gold, width: 3), borderRadius: BorderRadius.circular(12)))),
          Positioned(
            bottom: 40, left: 0, right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(20)),
                child: const Text('کد QR را در کادر قرار دهید', style: TextStyle(color: AppTheme.gold, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}