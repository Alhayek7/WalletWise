import 'package:flutter/material.dart';
import '../constants/theme.dart';
import '../services/local_service.dart';
import '../screens/manual_expense_screen.dart';
import '../screens/ocr_expense_screen.dart';
// import '../screens/advisor_screen.dart';
// import '../screens/family_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _userName = 'أحمد';
  double _monthlyIncome = 6500;
  double _monthlyBudget = 4800;
  double _totalExpenses = 0;
  double _totalSavings = 0;
  List<Map<String, dynamic>> _recentTransactions = [];
  Map<String, double> _categorySpending = {};
  bool _isLoading = true;
  int _unreadNotifications = 3;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final userData = await LocalService.getUserData();
    final transactions = await LocalService.getTransactions();

    final now = DateTime.now();
    double totalExpense = 0;
    Map<String, double> categoryTotals = {};

    for (var tx in transactions) {
      final amount = (tx['amount'] ?? 0).toDouble();
      final date = DateTime.tryParse(tx['date'] ?? '') ?? DateTime.now();
      final category = tx['category'] ?? 'أخرى';
      if (date.month == now.month && date.year == now.year && amount < 0) {
        totalExpense += amount.abs();
        categoryTotals[category] = (categoryTotals[category] ?? 0) + amount.abs();
      }
    }

    setState(() {
      _userName = userData['name'] ?? 'أحمد';
      _monthlyIncome = (userData['monthly_income'] ?? 6500).toDouble();
      _monthlyBudget = (userData['monthly_budget'] ?? 4800).toDouble();
      _totalExpenses = totalExpense;
      _totalSavings = _monthlyIncome - totalExpense;
      _categorySpending = categoryTotals;
      _recentTransactions = transactions.take(5).toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.gold)),
      );
    }

    final budgetPercent = _monthlyBudget > 0 ? (_totalExpenses / _monthlyBudget).clamp(0.0, 1.0) : 0.0;
    final remaining = _monthlyBudget - _totalExpenses;
    final savingsPercent = _monthlyIncome > 0 ? (_totalSavings / _monthlyIncome).clamp(0.0, 1.0) : 0.0;
    final isOverBudget = budgetPercent >= 1.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.gold,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildHeader(budgetPercent, remaining, isOverBudget),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // بطاقة أين راح راتبك
                    _buildSalaryBreakdown(savingsPercent),
                    const SizedBox(height: 20),

                    // إجراءات سريعة
                    _buildQuickActions(),
                    const SizedBox(height: 20),

                    // توزيع المصاريف
                    if (_categorySpending.isNotEmpty) ...[
                      _buildSectionHeader('📊 توزيع المصاريف', 'عرض الكل', () {}),
                      const SizedBox(height: 12),
                      _buildCategoryDistribution(),
                      const SizedBox(height: 20),
                    ],

                    // آخر المعاملات
                    _buildSectionHeader('📋 آخر المعاملات', 'عرض الكل', () {}),
                    const SizedBox(height: 12),
                    if (_recentTransactions.isEmpty)
                      _buildEmptyState()
                    else
                      ..._recentTransactions.map((tx) => _buildTransactionTile(tx)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =================== هيدر ===================
  Widget _buildHeader(double budgetPercent, double remaining, bool isOverBudget) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 55, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F4C3A), Color(0xFF071F17)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [BoxShadow(color: Color(0x29000000), blurRadius: 25, offset: Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // صورة وترحيب وإشعارات
          Row(
            textDirection: TextDirection.rtl,
            children: [
              // أيقونة المستخدم
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.gold, Color(0xFFF0CC5A)]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(child: Text('👨', style: TextStyle(fontSize: 24))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('مرحباً، $_userName 👋',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('🏆 8 أوسمة • 2,450 نقطة',
                          style: TextStyle(color: AppColors.gold, fontSize: 10, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
                            const SizedBox(width: 12),
              // زر الإعدادات
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(13)),
                  child: const Icon(Icons.settings_outlined, color: Colors.white, size: 22),
                ),
              ),
              const SizedBox(width: 8),
              // زر الإشعارات
              GestureDetector(
                onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                      ).then((_) {
                        setState(() => _unreadNotifications = 0);
                      });
                    },
                child: Stack(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 22),
                    ),
                    if (_unreadNotifications > 0)
                      Positioned(
                        top: 8, right: 8,
                        child: Container(
                          width: 9, height: 9,
                          decoration: const BoxDecoration(
                            color: AppColors.gold, shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // بطاقة المصاريف
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white.withValues(alpha: 0.18), Colors.white.withValues(alpha: 0.08)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  textDirection: TextDirection.rtl,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isOverBudget ? AppColors.error.withValues(alpha: 0.3) : AppColors.success.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isOverBudget ? '⚠️ تجاوز' : '✅ منتظم',
                        style: TextStyle(color: isOverBudget ? const Color(0xFFFFCCCC) : const Color(0xFFCCFFCC), fontSize: 10),
                      ),
                    ),
                    const Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        Text('مصاريف هذا الشهر', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        SizedBox(width: 6),
                        Icon(Icons.account_balance_wallet, color: Colors.white70, size: 18),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('${_totalExpenses.toStringAsFixed(0)} ₪',
                    textAlign: TextAlign.right,
                    style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text('من ميزانية ${_monthlyBudget.toStringAsFixed(0)} ₪ الشهرية',
                    textAlign: TextAlign.right,
                    style: const TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 16),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: budgetPercent,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(isOverBudget ? AppColors.error : AppColors.gold),
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  textDirection: TextDirection.rtl,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('متبقي ${remaining.toStringAsFixed(0)} ₪',
                        style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    Text('${(budgetPercent * 100).toInt()}%',
                        style: const TextStyle(color: Colors.white54, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =================== أين راح راتبك ===================
  Widget _buildSalaryBreakdown(double savingsPercent) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withValues(alpha: 0.05), AppColors.gold.withValues(alpha: 0.08)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Row(
            textDirection: TextDirection.rtl,
            children: [
              Text('أين راح راتبك؟', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text)),
              SizedBox(width: 8),
              Text('💡', style: TextStyle(fontSize: 20)),
            ],
          ),
          const SizedBox(height: 4),
          Text('ملخص الدخل الشهري ${_monthlyIncome.toStringAsFixed(0)} ₪',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 11, color: AppColors.gray)),
          const SizedBox(height: 16),

          // مصاريف
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      textDirection: TextDirection.rtl,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${_totalExpenses.toStringAsFixed(0)} ₪',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.error)),
                        const Text('مصاريف', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _monthlyIncome > 0 ? (_totalExpenses / _monthlyIncome).clamp(0.0, 1.0) : 0,
                          backgroundColor: AppColors.grayLight,
                          valueColor: const AlwaysStoppedAnimation(AppColors.error),
                          minHeight: 6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Text('📤', style: TextStyle(fontSize: 16)),
            ],
          ),

          const SizedBox(height: 14),

          // ادخار
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      textDirection: TextDirection.rtl,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${_totalSavings.toStringAsFixed(0)} ₪',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.success)),
                        const Text('ادخار', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: savingsPercent,
                          backgroundColor: AppColors.grayLight,
                          valueColor: const AlwaysStoppedAnimation(AppColors.success),
                          minHeight: 6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Text('📥', style: TextStyle(fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: savingsPercent > 0.4 ? AppColors.success.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                Expanded(
                  child: Text(
                    savingsPercent > 0.4
                        ? 'أحسنت! أنت تدخر أكثر من 40% من دخلك. استمر!'
                        : 'حاول زيادة الادخار إلى 30% على الأقل من دخلك الشهري.',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 11, color: savingsPercent > 0.4 ? AppColors.success : AppColors.error),
                  ),
                ),
                const SizedBox(width: 8),
                Text(savingsPercent > 0.4 ? '🎉' : '⚠️', style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =================== إجراءات سريعة ===================
  Widget _buildQuickActions() {
    final actions = [
      {'icon': '📷', 'label': 'تصوير فاتورة', 'color': const Color(0xFFFFF0E6), 'screen': 'ocr'},
      {'icon': '✏️', 'label': 'إضافة يدوي', 'color': const Color(0xFFF0F9FF), 'screen': 'manual'},
      {'icon': '🤖', 'label': 'استشارة مالية', 'color': const Color(0xFFFAF5FF), 'screen': 'advisor'},
      {'icon': '👨‍👩‍👧', 'label': 'المحفظة العائلية', 'color': const Color(0xFFF0FDF4), 'screen': 'family'},
    ];

    return Row(
      textDirection: TextDirection.rtl,
      children: actions.map((action) {
        return Expanded(
          child: GestureDetector(
            onTap: () {
              switch (action['screen']) {
                case 'manual':
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ManualExpenseScreen())).then((_) => _loadData());
                  break;
                case 'ocr':
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const OCRExpenseScreen()));
                  break;
                case 'advisor':
                  // ينتقل لتبويب المستشار
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('اذهب إلى تبويب المستشار'), duration: Duration(seconds: 1)),
                  );
                  break;
                case 'family':
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('اذهب إلى تبويب العائلة'), duration: Duration(seconds: 1)),
                  );
                  break;
              }
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: action['color'] as Color,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Text(action['icon'] as String, style: const TextStyle(fontSize: 24)),
                  const SizedBox(height: 6),
                  Text(action['label'] as String,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.text)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // =================== توزيع المصاريف ===================
  Widget _buildCategoryDistribution() {
    final categories = _categorySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final colors = [AppColors.primary, AppColors.gold, const Color(0xFF8B5CF6), const Color(0xFFF97316)];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
      ),
      child: Column(
        children: List.generate(4.clamp(0, categories.length), (i) {
          final cat = categories[i];
          final percent = _totalExpenses > 0 ? (cat.value / _totalExpenses).clamp(0.0, 1.0) : 0.0;
          return _buildCategoryRow(cat.key, cat.value, percent, colors[i % colors.length]);
        }),
      ),
    );
  }

  Widget _buildCategoryRow(String name, double amount, double percent, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Center(child: Text(_getCategoryEmoji(name), style: const TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  textDirection: TextDirection.rtl,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${amount.toStringAsFixed(0)} ₪',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 4),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: percent,
                      backgroundColor: AppColors.grayLight,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =================== المعاملات ===================
  Widget _buildTransactionTile(Map<String, dynamic> tx) {
    final amount = (tx['amount'] ?? 0).toDouble();
    final isExpense = amount < 0;
    final category = tx['category'] ?? 'أخرى';
    final note = tx['note'] ?? '';
    final method = tx['method'] ?? 'يدوي';
    final dateStr = tx['date'] as String?;
    final date = dateStr != null ? DateTime.tryParse(dateStr) ?? DateTime.now() : DateTime.now();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6)],
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: isExpense ? AppColors.error.withValues(alpha: 0.08) : AppColors.success.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Center(child: Text(_getCategoryEmoji(category), style: const TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(note.isNotEmpty ? note : category,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text(_formatDate(date), style: const TextStyle(fontSize: 10, color: AppColors.gray)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${isExpense ? '-' : '+'}${amount.abs().toStringAsFixed(0)} ₪',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold,
                      color: isExpense ? AppColors.error : AppColors.success)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(6)),
                child: Text(method, style: const TextStyle(fontSize: 8, color: AppColors.gray)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =================== مكونات مساعدة ===================
  Widget _buildSectionHeader(String title, String action, VoidCallback onAction) {
    return Row(
      textDirection: TextDirection.rtl,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (action.isNotEmpty)
          GestureDetector(
            onTap: onAction,
            child: Text(action, style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          const Text('📭', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          const Text('لا توجد معاملات بعد', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('ابدأ بإضافة مصروفك الأول', style: TextStyle(color: AppColors.gray, fontSize: 13)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ManualExpenseScreen())).then((_) => _loadData());
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('إضافة مصروف'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.white),
          ),
        ],
      ),
    );
  }

  String _getCategoryEmoji(String category) {
    switch (category) {
      case 'طعام': return '🍔';
      case 'مواصلات': return '🚗';
      case 'تسوق': return '🛒';
      case 'ترفيه': return '🎮';
      case 'صحة': return '💊';
      case 'سكن': return '🏠';
      case 'تعليم': return '📚';
      default: return '📌';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.day == now.day && date.month == now.month && date.year == now.year) {
      return 'اليوم، ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (date.day == now.day - 1 && date.month == now.month) {
      return 'أمس';
    } else {
      return '${date.day}/${date.month}';
    }
  }
}