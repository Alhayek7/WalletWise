import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ⭐ تخزين UID محلياً للاستخدام عند فشل auth
  static String? _currentUserId;

  static User? get currentUser => _auth.currentUser;
  
  // ⭐ هذا ما ستستخدمه Dashboard وغيرها
  static String? get currentUserId => 
      _auth.currentUser?.uid ?? _currentUserId ?? 'gfvok5I7d6QLkLaXKdW6ltDxcmh1';

  // تهيئة Firebase
  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyDZv29D2jGLCYDac_osy6QoKYUpEUlJ8nk',
        appId: '1:651404894521:web:b57497e38d1a2e12fe48e8',
        messagingSenderId: '651404894521',
        projectId: 'walletwise-e01da',
        storageBucket: 'walletwise-e01da.firebasestorage.app',
      ),
    );
  }

  // === المصادقة ===
  static Future<bool> login(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _currentUserId = result.user?.uid;
      return true;
    } catch (e) {
      _currentUserId = 'gfvok5I7d6QLkLaXKdW6ltDxcmh1';
      return false;
    }
  }

  static Future<bool> register(String email, String password, String name) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      _currentUserId = result.user?.uid;
      await _firestore.collection('users').doc(result.user!.uid).set({
        'name': name,
        'email': email,
        'currency': 'ILS',
        'monthlyIncome': 6500,
        'monthlyBudget': 4800,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<void> logout() async {
    _currentUserId = null;
    await _auth.signOut();
  }

  // === بيانات المستخدم ===
  static Future<Map<String, dynamic>?> getUserData(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    return doc.data();
  }

  static Future<void> updateUserData(String userId, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(userId).update(data);
  }

  // === المعاملات ===
  static Future<void> addTransaction({
    required String userId,
    required double amount,
    required String category,
    required String note,
    required String method,
  }) async {
    await _firestore.collection('transactions').add({
      'userId': userId,
      'amount': amount,
      'category': category,
      'note': note,
      'method': method,
      'date': Timestamp.now(),
    });
  }

  static Stream<List<Map<String, dynamic>>> getTransactions(String userId) {
    return _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  // === الميزانية ===
  static Future<void> setCategoryBudget({
    required String userId,
    required String category,
    required double limit,
  }) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('categoryBudgets')
        .doc(category)
        .set({
      'limit': limit,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Stream<Map<String, double>> getCategoryBudgets(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('categoryBudgets')
        .snapshots()
        .map((snapshot) {
      final budgets = <String, double>{};
      for (var doc in snapshot.docs) {
        budgets[doc.id] = (doc.data()['limit'] ?? 0).toDouble();
      }
      return budgets;
    });
  }

  // === الأهداف المالية ===
  static Future<void> addGoal({
    required String userId,
    required String title,
    required double targetAmount,
    required String deadline,
    required String emoji,
  }) async {
    await _firestore.collection('goals').add({
      'userId': userId,
      'title': title,
      'targetAmount': targetAmount,
      'savedAmount': 0.0,
      'deadline': deadline,
      'emoji': emoji,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Stream<List<Map<String, dynamic>>> getGoals(String userId) {
    return _firestore
        .collection('goals')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }
}