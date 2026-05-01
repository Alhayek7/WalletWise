import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  static SupabaseClient get client => _client;

  // تهيئة
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: 'https://sxmchctkfrxnydqeohqu.supabase.co',
      anonKey: 'sb_publishable_3kzSF5VByximYj_Sck3QPQ_goHtvOsR',
    );
  }

  // ⭐ المستخدم الحالي
  static User? get currentUser => _client.auth.currentUser;

  // ⭐ معرف المستخدم
  static String? get currentUserId => _client.auth.currentUser?.id;

  // === المصادقة ===
  static Future<bool> login(String email, String password) async {
    try {
      await _client.auth
          .signInWithPassword(email: email, password: password)
          .timeout(const Duration(seconds: 5));
      return true;
    } catch (e) {
      // print('🔴 Supabase Login Error: $e');
      return false;
    }
  }

  static Future<bool> register(
    String email,
    String password,
    String name,
  ) async {
    try {
      final result = await _client.auth.signUp(
        email: email,
        password: password,
      );
      if (result.user != null) {
        await _client.from('users').upsert({
          'id': result.user!.id,
          'name': name,
          'email': email,
          'monthly_income': 6500,
          'monthly_budget': 4800,
          'currency': 'ILS',
        });
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<void> logout() async {
    await _client.auth.signOut();
  }

  // === بيانات المستخدم ===
  static Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final data = await _client
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();
      return data;
    } catch (e) {
      return null;
    }
  }

  static Future<void> updateUserData(
    String userId,
    Map<String, dynamic> data,
  ) async {
    await _client.from('users').upsert({'id': userId, ...data});
  }

  // === المعاملات ===
  static Future<void> addTransaction({
    required String userId,
    required double amount,
    required String category,
    required String note,
    required String method,
  }) async {
    await _client.from('transactions').insert({
      'user_id': userId,
      'amount': amount,
      'category': category,
      'note': note,
      'method': method,
      'date': DateTime.now().toIso8601String(),
    });
  }

  static Future<List<Map<String, dynamic>>> getTransactions(
    String userId,
  ) async {
    try {
      final data = await _client
          .from('transactions')
          .select()
          .eq('user_id', userId)
          .order('date', ascending: false);
      return data;
    } catch (e) {
      return [];
    }
  }

  // === الأهداف ===
  static Future<void> addGoal({
    required String userId,
    required String title,
    required double targetAmount,
    required String deadline,
    required String emoji,
  }) async {
    await _client.from('goals').insert({
      'user_id': userId,
      'title': title,
      'target_amount': targetAmount,
      'saved_amount': 0,
      'deadline': deadline,
      'emoji': emoji,
    });
  }

  static Future<List<Map<String, dynamic>>> getGoals(String userId) async {
    try {
      final data = await _client.from('goals').select().eq('user_id', userId);
      return data;
    } catch (e) {
      return [];
    }
  }

  // === الميزانية ===
  static Future<void> setCategoryBudget({
    required String userId,
    required String category,
    required double limit,
  }) async {
    await _client.from('category_budgets').upsert({
      'user_id': userId,
      'category': category,
      'budget_limit': limit,
    });
  }

  static Future<List<Map<String, dynamic>>> getCategoryBudgets(
    String userId,
  ) async {
    try {
      final data = await _client
          .from('category_budgets')
          .select()
          .eq('user_id', userId);
      return data;
    } catch (e) {
      return [];
    }
  }
}
