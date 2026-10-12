import 'database_helper.dart';
import 'license_helper.dart';

class LicenseManager {
  static Future<Map<String, dynamic>?> getCurrentPlan() async {
    final license = await LicenseHelper.getLicense();
    if (license == null || license['isActive'] != true) return null;
    final plans = await DatabaseHelper.instance.getAllPlans();
    final plan = plans.firstWhere((p) => p['id'] == license['planId'], orElse: () => {});
    return plan.isNotEmpty ? plan : null;
  }

  static Future<Map<String, dynamic>> canAddEmployee() async {
    final plan = await getCurrentPlan();
    if (plan == null) return {'allowed': false, 'message': 'لایسنس فعال ندارید'};
    final maxEmployees = plan['max_employees'] ?? 0;
    if (maxEmployees == 0) return {'allowed': true, 'current': 0, 'max': -1, 'isUnlimited': true};
    final currentEmployees = await DatabaseHelper.instance.getAllEmployees();
    final activeEmployees = currentEmployees.where((e) => e['status'] == 'active').length;
    if (activeEmployees >= maxEmployees) {
      return {'allowed': false, 'current': activeEmployees, 'max': maxEmployees, 'isUnlimited': false, 'message': 'سقف کارمندان پلن شما پر شده است ($activeEmployees از $maxEmployees)'};
    }
    return {'allowed': true, 'current': activeEmployees, 'max': maxEmployees, 'isUnlimited': false};
  }

  static Future<Map<String, dynamic>> canAddVehicle() async {
    final plan = await getCurrentPlan();
    if (plan == null) return {'allowed': false, 'message': 'لایسنس فعال ندارید'};
    final maxVehicles = plan['max_vehicles'] ?? 0;
    if (maxVehicles == 0) return {'allowed': true, 'current': 0, 'max': -1, 'isUnlimited': true};
    final allVehicles = await DatabaseHelper.instance.getAllVehicles();
    final currentCount = allVehicles.length;
    if (currentCount >= maxVehicles) {
      return {'allowed': false, 'current': currentCount, 'max': maxVehicles, 'isUnlimited': false, 'message': 'سقف خودروهای پلن شما پر شده است ($currentCount از $maxVehicles)'};
    }
    return {'allowed': true, 'current': currentCount, 'max': maxVehicles, 'isUnlimited': false};
  }

  static Future<Map<String, dynamic>> getUsageStats() async {
    final plan = await getCurrentPlan();
    if (plan == null) {
      return {
        'hasLicense': false, 'planName': 'بدون لایسنس',
        'employees': {'current': 0, 'max': 0, 'isUnlimited': false},
        'vehicles': {'current': 0, 'max': 0, 'isUnlimited': false},
      };
    }
    final allEmployees = await DatabaseHelper.instance.getAllEmployees();
    final activeEmployees = allEmployees.where((e) => e['status'] == 'active').length;
    final maxEmployees = plan['max_employees'] ?? 0;
    final allVehicles = await DatabaseHelper.instance.getAllVehicles();
    final maxVehicles = plan['max_vehicles'] ?? 0;
    return {
      'hasLicense': true,
      'planName': plan['name'] ?? 'پلن نامشخص',
      'employees': {'current': activeEmployees, 'max': maxEmployees, 'isUnlimited': maxEmployees == 0},
      'vehicles': {'current': allVehicles.length, 'max': maxVehicles, 'isUnlimited': maxVehicles == 0},
    };
  }
}