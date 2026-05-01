import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/theme.dart';
import '../services/local_service.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  double _monthlyBudget = 4800;
  double _totalExpenses = 0;
  Map<String, double> _categorySpent = {};
  Map<String, double> _categoryLimits = {};
  bool _isLoading = true;

  final List<Map<String, dynamic>> _allCategories = [
    {'name': 'طعام', 'icon': '🍔', 'color': const Color(0xFF0F4C3A)},
    {'name': 'مواصلات', 'icon': '🚗', 'color': const Color(0xFFD4AF37)},
    {'name': 'تسوق', 'icon': '🛒', 'color': const Color(0xFF8B5CF6)},
    {'name': 'ترفيه', 'icon': '🎮', 'color': const Color(0xFFF97316)},
    {'name': 'صحة', 'icon': '💊', 'color': const Color(0xFF10B981)},
    {'name': 'تعليم', 'icon': '📚', 'color': const Color(0xFF3B82F6)},
    {'name': 'سكن', 'icon': '🏠', 'color': const Color(0xFF6366F1)},
    {'name': 'أخرى', 'icon': '📌', 'color': const Color(0xFF6B7280)},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final userData = await LocalService.getUserData();
    final transactions = await LocalService.getTransactions();
    final savedLimits = await _loadCategoryLimits();

    final now = DateTime.now();
    double totalExpense = 0;
    Map<String, double> categoryTotals = {};

    for (var tx in transactions) {
      final amount = (tx['amount'] ?? 0).toDouble();
      final dateStr = tx['date'] as String?;
      final date = dateStr != null ? DateTime.tryParse(dateStr) ?? now : now;
      final category = tx['category'] ?? 'أخرى';
      if (date.month == now.month && date.year == now.year && amount < 0) {
        totalExpense += amount.abs();
        categoryTotals[category] = (categoryTotals[category] ?? 0) + amount.abs();
      }
    }

    if (mounted) {
      setState(() {
        _monthlyBudget = (userData['monthly_budget'] ?? 4800).toDouble();
        _totalExpenses = totalExpense;
        _categorySpent = categoryTotals;
        _categoryLimits = savedLimits;
        _isLoading = false;
      });
    }
  }

  Future<Map<String, double>> _loadCategoryLimits() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('category_limits');
    if (stored != null) {
      final Map<String, dynamic> decoded = Map<String, dynamic>.from(
        jsonDecode(stored),
      );
      return decoded.map((k, v) => MapEntry(k, (v as num).toDouble()));
    }
    return {
      'طعام': _monthlyBudget * 0.30,
      'مواصلات': _monthlyBudget * 0.15,
      'تسوق': _monthlyBudget * 0.20,
      'ترفيه': _monthlyBudget * 0.10,
    };
  }

  Future<void> _saveCategoryLimits() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('category_limits', jsonEncode(_categoryLimits));
  }

  void _showSetLimitDialog(String category) {
    final currentLimit = _categoryLimits[category] ?? 0.0;
    final controller = TextEditingController(
      text: currentLimit > 0 ? currentLimit.toStringAsFixed(0) : '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(textDirection: TextDirection.rtl, children: [
          Text('${_getCategoryEmoji(category)} $category'),
        ]),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: 'المبلغ بالشيكل',
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  _categoryLimits[category] = double.tryParse(controller.text) ?? 0;
                });
                _saveCategoryLimits();
                Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✅ تم تحديد سقف $category'),
                      backgroundColor: AppColors.success,
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showMonthlyBudgetDialog() {
    final controller = TextEditingController(
      text: _monthlyBudget.toStringAsFixed(0),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('الميزانية الشهرية'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: 'المبلغ الإجمالي للشهر',
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                final amount = double.tryParse(controller.text) ?? _monthlyBudget;
                await LocalService.saveUserData({
                  'name': 'أحمد',
                  'monthly_income': 6500,
                  'monthly_budget': amount,
                  'currency': 'ILS',
                });
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
                if (mounted) {
                  setState(() => _monthlyBudget = amount);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('✅ تم تحديث الميزانية'),
                      backgroundColor: AppColors.success,
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.gold)),
      );
    }

    final budgetPercent = _monthlyBudget > 0
        ? (_totalExpenses / _monthlyBudget).clamp(0.0, 1.0)
        : 0.0;
    final remaining = _monthlyBudget - _totalExpenses;
    final isOverBudget = budgetPercent >= 1.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 170,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0F4C3A), Color(0xFF071F17)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 50, 20, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          '🎯 الميزانية والأهداف',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'تحكم في إنفاقك وحقق أهدافك',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: _showMonthlyBudgetDialog,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              textDirection: TextDirection.rtl,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'الميزانية الشهرية',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.7),
                                          fontSize: 11,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${_totalExpenses.toStringAsFixed(0)} / ${_monthlyBudget.toStringAsFixed(0)} ₪',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.edit,
                                  color: Colors.white54,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          textDirection: TextDirection.rtl,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '📊 حالة الميزانية',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: isOverBudget
                                    ? AppColors.error.withValues(alpha: 0.1)
                                    : AppColors.success.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isOverBudget ? '⚠️ تجاوز' : '✅ منتظم',
                                style: TextStyle(
                                  color: isOverBudget
                                      ? AppColors.error
                                      : AppColors.success,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: budgetPercent,
                              backgroundColor: AppColors.grayLight,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isOverBudget ? AppColors.error : AppColors.gold,
                              ),
                              minHeight: 10,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          textDirection: TextDirection.rtl,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'متبقي ${remaining.toStringAsFixed(0)} ₪',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.gray,
                              ),
                            ),
                            Text(
                              '${(budgetPercent * 100).toInt()}%',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.gray,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '📂 سقوف الفئات',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'اضغط على أي فئة لتحديد سقف الإنفاق',
                    style: TextStyle(fontSize: 11, color: AppColors.gray),
                  ),
                  const SizedBox(height: 12),
                  ..._allCategories.map((cat) {
                    final name = cat['name'] as String;
                    final spent = _categorySpent[name] ?? 0;
                    final limit = _categoryLimits[name] ?? 0;
                    final hasLimit = limit > 0;
                    final percent =
                        hasLimit ? (spent / limit).clamp(0.0, 1.0) : 0.0;
                    final isOver = hasLimit && spent > limit;
                    final isWarning =
                        hasLimit && percent >= 0.8 && !isOver;
                    final color = cat['color'] as Color;

                    return GestureDetector(
                      onTap: () => _showSetLimitDialog(name),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 6,
                            ),
                          ],
                          border: isOver
                              ? Border.all(
                                  color:
                                      AppColors.error.withValues(alpha: 0.5),
                                )
                              : isWarning
                                  ? Border.all(
                                      color: const Color(0xFFF97316)
                                          .withValues(alpha: 0.5),
                                    )
                                  : null,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              textDirection: TextDirection.rtl,
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      cat['icon'] as String,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Row(
                                    textDirection: TextDirection.rtl,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (hasLimit)
                                        Text(
                                          '${spent.toStringAsFixed(0)} / ${limit.toStringAsFixed(0)} ₪',
                                          style:
                                              const TextStyle(fontSize: 12),
                                        )
                                      else
                                        Text(
                                          '${spent.toStringAsFixed(0)} ₪',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.gray,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.edit,
                                  size: 14,
                                  color: AppColors.grayLight,
                                ),
                              ],
                            ),
                            if (hasLimit) ...[
                              const SizedBox(height: 8),
                              Directionality(
                                textDirection: TextDirection.ltr,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(3),
                                  child: LinearProgressIndicator(
                                    value: percent,
                                    backgroundColor: AppColors.grayLight,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      isOver
                                          ? AppColors.error
                                          : (isWarning
                                              ? const Color(0xFFF97316)
                                              : color),
                                    ),
                                    minHeight: 5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isOver
                                    ? '🚨 تجاوزت السقف بـ ${(spent - limit).toStringAsFixed(0)} ₪'
                                    : isWarning
                                        ? '⚠️ متبقي ${(limit - spent).toStringAsFixed(0)} ₪'
                                        : '✅ متبقي ${(limit - spent).toStringAsFixed(0)} ₪',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isOver
                                      ? AppColors.error
                                      : (isWarning
                                          ? const Color(0xFFF97316)
                                          : AppColors.success),
                                ),
                              ),
                            ],
                            if (!hasLimit)
                              const Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Text(
                                  'اضغط لتحديد سقف الإنفاق',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.grayLight,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
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
}