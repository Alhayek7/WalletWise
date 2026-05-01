import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LocalService {
  static const String _userId = 'gfvok5I7d6QLkLaXKdW6ltDxcmh1';
  
  static String get currentUserId => _userId;

  // ========== بيانات المستخدم ==========
  static Future<Map<String, dynamic>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('user_data');
    if (stored != null) return json.decode(stored);
    return {
      'name': 'أحمد',
      'monthly_income': 6500,
      'monthly_budget': 4800,
      'currency': 'ILS',
    };
  }

  static Future<void> saveUserData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', json.encode(data));
  }

  // ========== المعاملات ==========
  static Future<List<Map<String, dynamic>>> getTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('transactions');
    if (stored != null) {
      return List<Map<String, dynamic>>.from(json.decode(stored));
    }
    return [];
  }

  static Future<void> addTransaction(Map<String, dynamic> tx) async {
    final transactions = await getTransactions();
    transactions.insert(0, {
      ...tx,
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'date': DateTime.now().toIso8601String(),
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('transactions', json.encode(transactions));
  }

  // ========== المصادقة ==========
  static Future<void> saveUserCredentials(String email, String password, String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_email', email);
    await prefs.setString('user_password', password);
    await saveUserData({
      'name': name,
      'email': email,
      'monthly_income': 6500,
      'monthly_budget': 4800,
      'currency': 'ILS',
    });
  }

  static Future<bool> verifyLogin(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('user_email');
    final savedPassword = prefs.getString('user_password');
    return savedEmail == email && savedPassword == password;
  }

  static Future<String?> getSavedPassword(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('user_email');
    if (savedEmail == email) {
      return prefs.getString('user_password');
    }
    return null;
  }

  static Future<void> updatePassword(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('user_email');
    if (savedEmail == email) {
      await prefs.setString('user_password', password);
    }
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_email') != null;
  }

  // ========== بيانات العائلة ==========
  static Future<void> saveFamilyMembers(List<Map<String, dynamic>> members) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('family_members', json.encode(members));
  }

  static Future<List<Map<String, dynamic>>> getFamilyMembers() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('family_members');
    if (stored != null) {
      return List<Map<String, dynamic>>.from(json.decode(stored));
    }
    return [
      {'id': 'user_1', 'name': 'أحمد (أنت)', 'role': 'admin', 'avatar': '👨', 'status': 'نشط', 'budget': 4000, 'color': 0xFF0F4C3A},
      {'id': 'user_2', 'name': 'سارة', 'role': 'viewer', 'avatar': '👩', 'status': 'نشط', 'budget': 3500, 'color': 0xFFD4AF37},
      {'id': 'user_3', 'name': 'خالد', 'role': 'custom', 'avatar': '👦', 'status': 'نشط', 'budget': 2500, 'color': 0xFF8B5CF6},
    ];
  }

  static Future<void> saveFamilyGoals(List<Map<String, dynamic>> goals) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('family_goals', json.encode(goals));
  }

  static Future<List<Map<String, dynamic>>> getFamilyGoals() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('family_goals');
    if (stored != null) {
      return List<Map<String, dynamic>>.from(json.decode(stored));
    }
    return [
      {'id': 'g1', 'name': 'رحلة صيفية', 'target': 15000, 'saved': 7500, 'emoji': '✈️', 'deadline': 'يوليو 2026'},
      {'id': 'g2', 'name': 'تجديد الأثاث', 'target': 8000, 'saved': 3200, 'emoji': '🛋️', 'deadline': 'ديسمبر 2026'},
    ];
  }

  static Future<void> saveFamilyCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('family_code', code);
  }

  static Future<String> getFamilyCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('family_code') ?? 'WW-2026-X7K9';
  }

  static Future<void> saveFamilyName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('family_name', name);
  }

  static Future<String> getFamilyName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('family_name') ?? 'عائلة الراشدي';
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // حفظ حالة قراءة إشعار واحد
static Future<void> markNotificationRead(String id) async {
  final prefs = await SharedPreferences.getInstance();
  final stored = prefs.getString('notif_read');
  Map<String, dynamic> readMap = stored != null ? Map<String, dynamic>.from(json.decode(stored)) : {};
  readMap[id] = true;
  await prefs.setString('notif_read', json.encode(readMap));
}

// حفظ حالة قراءة عدة إشعارات
static Future<void> markNotificationsRead(List<String> ids) async {
  final prefs = await SharedPreferences.getInstance();
  final stored = prefs.getString('notif_read');
  Map<String, dynamic> readMap = stored != null ? Map<String, dynamic>.from(json.decode(stored)) : {};
  for (var id in ids) {
    readMap[id] = true;
  }
  await prefs.setString('notif_read', json.encode(readMap));
}

// تحميل حالة قراءة الإشعارات
static Future<Map<String, dynamic>> getNotificationReadStatus() async {
  final prefs = await SharedPreferences.getInstance();
  final stored = prefs.getString('notif_read');
  return stored != null ? Map<String, dynamic>.from(json.decode(stored)) : {};
}

// حفظ الأهداف
static Future<void> saveGoals(List<Map<String, dynamic>> goals) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('goals', jsonEncode(goals));
}

// تحميل الأهداف
static Future<List<Map<String, dynamic>>> getGoals() async {
  final prefs = await SharedPreferences.getInstance();
  final stored = prefs.getString('goals');
  if (stored != null) {
    return List<Map<String, dynamic>>.from(jsonDecode(stored));
  }
  return [];
}

}