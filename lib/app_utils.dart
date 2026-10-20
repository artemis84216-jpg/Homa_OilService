import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'database_helper.dart';

class AppTheme {
  static const Color backgroundBlack = Color(0xFF121212);
  static const Color cardBlack = Color(0xFF1E1E1E);
  static const Color gold = Color(0xFFFFD700);
  static const Color goldDark = Color(0xFFFFA000);
  static const Color textWhite = Colors.white;
  static const Color textYellow = Color(0xFFFFEB3B);
  static const Color textGrey = Color(0xFFB0B0B0);
  static const Color oilBlue = Color(0xFF1E88E5);
  
  static ThemeData get darkGoldTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: gold,
      scaffoldBackgroundColor: backgroundBlack,
      colorScheme: const ColorScheme.dark(primary: gold, secondary: goldDark, surface: cardBlack, onPrimary: Colors.black, onSurface: textWhite),
      appBarTheme: const AppBarTheme(backgroundColor: Colors.black, foregroundColor: gold, elevation: 0, centerTitle: true, titleTextStyle: TextStyle(color: gold, fontSize: 20, fontWeight: FontWeight.bold)),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: const Color(0xFF2A2A2A),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: gold, width: 1)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF444444), width: 1)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: gold, width: 2)),
        labelStyle: const TextStyle(color: textGrey), hintStyle: const TextStyle(color: Color(0xFF666666)),
      ),
    );
  }
}

String toPersianDigits(String input) {
  return input.replaceAll('0', '۰').replaceAll('1', '۱').replaceAll('2', '۲').replaceAll('3', '۳').replaceAll('4', '۴').replaceAll('5', '۵').replaceAll('6', '۶').replaceAll('7', '۷').replaceAll('8', '۸').replaceAll('9', '۹');
}

String toEnglishDigits(String input) {
  const persian = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
  const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  for (int i = 0; i < 10; i++) {
    input = input.replaceAll(persian[i], i.toString()).replaceAll(arabic[i], i.toString());
  }
  return input;
}

String formatPrice(dynamic price) {
  if (price == null) return '۰';
  final num priceNum = price is int ? price : (price is double ? price.toInt() : 0);
  String formatted = priceNum.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  return toPersianDigits(formatted);
}

String formatNumber(num number) => toPersianDigits(number.toString());

// فرمت‌کننده کاما که حین تایپ هم کار می‌کند (مورد ۹)
class CommaSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    String cleanText = toEnglishDigits(newValue.text.replaceAll(',', ''));
    if (cleanText.isEmpty) return newValue;
    final intVal = int.tryParse(cleanText);
    if (intVal == null) return oldValue;
    final formatted = intVal.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
    return TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
  }
}

// تولید شماره فاکتور روزانه متوالی (مورد ۱۳)
Future<String> generateDailyInvoiceNumber() async {
  final today = Jalali.now();
  final dateStr = '${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}';
  
  final allInvoices = await DatabaseHelper.instance.getAllInvoices();
  final todayInvoices = allInvoices.where((inv) => (inv['invoice_number'] ?? '').toString().startsWith('HOMA-$dateStr')).toList();
  
  final nextSeq = todayInvoices.length + 1;
  final seqStr = nextSeq.toString().padLeft(4, '0');
  
  return 'HOMA-$dateStr-$seqStr';
}

const List<String> productCategories = ['روغن موتور', 'روغن گیربکس', 'فیلتر روغن', 'فیلتر هوا', 'فیلتر کابین', 'فیلتر سوخت', 'مایع خنک‌کننده', 'مایع شستشو', 'روغن ترمز', 'شمع موتور', 'تسمه', 'سایر'];
const List<String> oilViscosities = ['5W-30', '5W-40', '10W-30', '10W-40', '10W-50', '15W-40', '20W-50', '0W-20', '0W-30', '20W-40'];
const List<String> oilBrands = ['بهران', 'پارس', 'ایرانول', 'سپاهان', 'شل', 'موبیل', 'توتال', 'کاسترول', 'والولاین', 'لیکومولی', 'سایر'];