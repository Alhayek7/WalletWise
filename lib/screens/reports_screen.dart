import 'dart:math';
import 'package:flutter/material.dart';
import '../constants/theme.dart';
import '../services/local_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  // المتغيرات الأساسية
  String _selectedPeriod = 'الشهر';
  String _selectedCategoryFilter = 'الكل';
  double _totalExpenses = 0;
  double _monthlyIncome = 6500;
  double _monthlyBudget = 4800;
  double _lastMonthExpenses = 0;
  // double _lastMonthIncome = 0;
  Map<String, double> _categorySpent = {};
  Map<String, double> _lastMonthCategorySpent = {};
  List<Map<String, dynamic>> _allTransactions = [];
  List<Map<String, dynamic>> _filteredTransactions = [];
  bool _isLoading = true;

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
    double lastMonth = 0;
    Map<String, double> categoryTotals = {};
    Map<String, double> lastMonthCategories = {};
    List<Map<String, dynamic>> thisMonthTx = [];

    for (var tx in transactions) {
      final amount = (tx['amount'] ?? 0).toDouble();
      final dateStr = tx['date'] as String?;
      final date = dateStr != null ? DateTime.tryParse(dateStr) ?? now : now;
      final category = tx['category'] ?? 'أخرى';

      // هذا الشهر - مصاريف
      if (date.month == now.month && date.year == now.year) {
        if (amount < 0) {
          totalExpense += amount.abs();
          categoryTotals[category] = (categoryTotals[category] ?? 0) + amount.abs();
        }
        thisMonthTx.add(tx);
      }

      // الشهر الماضي
      if (date.month == (now.month - 1 == 0 ? 12 : now.month - 1) && date.year == (now.month - 1 == 0 ? now.year - 1 : now.year)) {
        if (amount < 0) {
          lastMonth += amount.abs();
          lastMonthCategories[category] = (lastMonthCategories[category] ?? 0) + amount.abs();
        }
      }
    }

    // ترتيب المعاملات من الأحدث للأقدم
    thisMonthTx.sort((a, b) {
      final da = DateTime.tryParse(a['date'] ?? '') ?? now;
      final db = DateTime.tryParse(b['date'] ?? '') ?? now;
      return db.compareTo(da);
    });

    if (mounted) {
      setState(() {
        _monthlyIncome = (userData['monthly_income'] ?? 6500).toDouble();
        _monthlyBudget = (userData['monthly_budget'] ?? 4800).toDouble();
        _totalExpenses = totalExpense;
        _lastMonthExpenses = lastMonth;
        _categorySpent = categoryTotals;
        _lastMonthCategorySpent = lastMonthCategories;
        _allTransactions = thisMonthTx;
        _filteredTransactions = thisMonthTx;
        _isLoading = false;
      });
    }
  }

  // ⭐ فلترة حسب الفئة
  void _applyFilter(String category) {
    setState(() {
      _selectedCategoryFilter = category;
      if (category == 'الكل') {
        _filteredTransactions = _allTransactions;
      } else {
        _filteredTransactions = _allTransactions.where((tx) => tx['category'] == category).toList();
      }
    });
  }

  // ⭐ 1. حساب نسبة الفئة للمخطط الدائري
  double _getCategoryPercent(String category) {
    if (_totalExpenses == 0) return 0;
    return (_categorySpent[category] ?? 0) / _totalExpenses;
  }

  // ⭐ 2. مقارنة شهرية محسنة
  String _getMonthComparison() {
    if (_lastMonthExpenses == 0) return 'لا توجد بيانات للشهر الماضي';
    final diff = _totalExpenses - _lastMonthExpenses;
    final pct = _lastMonthExpenses > 0 ? (diff / _lastMonthExpenses * 100).abs().toInt() : 0;
    if (diff > 0) return '📈 ارتفعت ${diff.toStringAsFixed(0)} ₪ (+$pct%) عن الشهر الماضي';
    if (diff < 0) return '📉 انخفضت ${diff.abs().toStringAsFixed(0)} ₪ (-$pct%) عن الشهر الماضي';
    return '➡️ متساوية مع الشهر الماضي';
  }

  // ⭐ 3. مقارنة الفئات بين شهرين
  String _getCategoryComparison(String category) {
    final thisMonth = _categorySpent[category] ?? 0;
    final lastMonth = _lastMonthCategorySpent[category] ?? 0;
    if (lastMonth == 0) return '';
    final diff = thisMonth - lastMonth;
    if (diff > 0) return '▲${diff.toStringAsFixed(0)} ₪';
    if (diff < 0) return '▼${diff.abs().toStringAsFixed(0)} ₪';
    return '---';
  }

  // ⭐ 4. أفضل إنجاز
  String _getBestAchievement() {
    if (_allTransactions.isEmpty) return 'ابدأ بإضافة معاملاتك';
    final savings = _monthlyIncome - _totalExpenses;
    final savingsPct = _monthlyIncome > 0 ? (savings / _monthlyIncome * 100).toInt() : 0;
    if (savingsPct >= 30) return '🏆 تدخر $savingsPct% من دخلك - ممتاز!';
    if (_totalExpenses < _monthlyBudget * 0.7) return '✅ ملتزم بميزانيتك بنجاح';
    if (_lastMonthExpenses > 0 && _totalExpenses < _lastMonthExpenses) return '📉 أنفقت أقل من الشهر الماضي';
    if (_categorySpent.length >= 3) return '📊 تتابع ${_categorySpent.length} فئات بنشاط';
    return '💪 استمر في تتبع مصاريفك';
  }

  // ⭐ 5. متوسط الإنفاق اليومي
  double get _dailyAverage {
    final days = DateTime.now().day;
    return days > 0 ? _totalExpenses / days : 0;
  }

  // ⭐ 6. توقع نهاية الشهر
  String _getEndOfMonthPrediction() {
    final daysInMonth = DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day;
    final currentDay = DateTime.now().day;
    final remainingDays = daysInMonth - currentDay;
    final predictedTotal = _totalExpenses + (_dailyAverage * remainingDays);
    final predictedDiff = _monthlyBudget - predictedTotal;
    if (predictedDiff > 0) return 'متوقع توفير ${predictedDiff.toStringAsFixed(0)} ₪';
    return '⚠️ متوقع تجاوز بـ ${predictedDiff.abs().toStringAsFixed(0)} ₪';
  }

  // ⭐ 7. أكثر طريقة دفع استخداماً
  String _getTopPaymentMethod() {
    Map<String, int> methods = {};
    for (var tx in _allTransactions) {
      final method = tx['method'] ?? 'يدوي';
      methods[method] = (methods[method] ?? 0) + 1;
    }
    if (methods.isEmpty) return 'لا توجد';
    return methods.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.gold)),
      );
    }

    final savings = _monthlyIncome - _totalExpenses;
    final budgetPercent = _monthlyBudget > 0 ? (_totalExpenses / _monthlyBudget).clamp(0.0, 1.0) : 0.0;
    final topCategory = _categorySpent.isNotEmpty
        ? _categorySpent.entries.reduce((a, b) => a.value > b.value ? a : b).key
        : 'لا توجد';
    final savingsPct = _monthlyIncome > 0 ? (savings / _monthlyIncome * 100).toInt() : 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // الهيدر
          SliverAppBar(
            expandedHeight: 155,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
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
                          '📊 التقارير والتحليل',
                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'فهم حقيقي لأين تذهب أموالك',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                        ),
                        const Spacer(),
                        Row(
                          textDirection: TextDirection.rtl,
                          children: ['الأسبوع', 'الشهر', 'السنة'].map((period) {
                            final isSelected = _selectedPeriod == period;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedPeriod = period),
                              child: Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  period,
                                  style: TextStyle(
                                    color: isSelected ? AppColors.primary : Colors.white70,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // المحتوى
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // ⭐ 4 بطاقات ملخصة
                  Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          '📤 إجمالي المصاريف',
                          '${_totalExpenses.toStringAsFixed(0)} ₪',
                          '${_categorySpent.length} فئات',
                          AppColors.error.withValues(alpha: 0.08),
                          AppColors.error,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildSummaryCard(
                          '📥 صافي التوفير',
                          '${savings.toStringAsFixed(0)} ₪',
                          '$savingsPct% من الدخل',
                          AppColors.success.withValues(alpha: 0.08),
                          AppColors.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          '🔝 أكثر فئة',
                          topCategory,
                          '${_getCategoryEmoji(topCategory)} ${_categorySpent[topCategory]?.toStringAsFixed(0) ?? 0} ₪',
                          AppColors.gold.withValues(alpha: 0.08),
                          AppColors.gold,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildSummaryCard(
                          '📊 الميزانية',
                          '${budgetPercent > 0 ? (budgetPercent * 100).toInt() : 0}%',
                          budgetPercent > 0.9 ? '⚠️ مرتفع' : '✅ منتظم',
                          AppColors.primary.withValues(alpha: 0.08),
                          AppColors.primary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ⭐ 1. مخطط دائري مع توزيع المصاريف
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Row(
                          textDirection: TextDirection.rtl,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('📊 توزيع المصاريف', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            Icon(Icons.pie_chart, color: AppColors.gold),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_categorySpent.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Text('لا توجد مصاريف هذا الشهر', style: TextStyle(color: AppColors.gray)),
                            ),
                          )
                        else
                          SizedBox(
                            height: 220,
                            child: Row(
                              textDirection: TextDirection.rtl,
                              children: [
                                // المخطط الدائري
                                Expanded(
                                  flex: 3,
                                  child: CustomPaint(
                                    size: const Size(160, 160),
                                    painter: _PieChartPainter(
                                      _categorySpent.map((k, v) => MapEntry(k, _getCategoryPercent(k))),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // القائمة مع المقارنة
                                Expanded(
                                  flex: 4,
                                  child: ListView(
                                    children: _categorySpent.entries.map((e) {
                                      final pct = _totalExpenses > 0 ? (e.value / _totalExpenses * 100).toInt() : 0;
                                      final comp = _getCategoryComparison(e.key);
                                      final color = _getColor(e.key);
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: Row(
                                          textDirection: TextDirection.rtl,
                                          children: [
                                            Container(
                                              width: 10,
                                              height: 10,
                                              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                '${_getCategoryEmoji(e.key)} ${e.key}',
                                                style: const TextStyle(fontSize: 11),
                                              ),
                                            ),
                                            Text(
                                              '${e.value.toStringAsFixed(0)} ₪ ($pct%)',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                                            ),
                                            if (comp.isNotEmpty) ...[
                                              const SizedBox(width: 4),
                                              Text(comp, style: TextStyle(fontSize: 9, color: comp.startsWith('▲') ? AppColors.error : AppColors.success)),
                                            ],
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ⭐ 2. مقارنة شهرية
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
                    ),
                    child: Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.compare_arrows, color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('مقارنة بالشهر الماضي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 2),
                              Text(_getMonthComparison(), style: const TextStyle(fontSize: 11, color: AppColors.gray)),
                            ],
                          ),
                        ),
                        if (_lastMonthExpenses > 0)
                          Text('${_lastMonthExpenses.toStringAsFixed(0)} ₪',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.gray)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ⭐ 3. بطاقة الإنجاز + توقع نهاية الشهر
                  Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF0A3328)]),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Row(
                                textDirection: TextDirection.rtl,
                                children: [
                                  Text('🏆', style: TextStyle(fontSize: 24)),
                                  SizedBox(width: 8),
                                  Text('إنجازك', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(_getBestAchievement(),
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Row(
                                textDirection: TextDirection.rtl,
                                children: [
                                  Text('🔮', style: TextStyle(fontSize: 24)),
                                  SizedBox(width: 8),
                                  Text('التوقع', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(_getEndOfMonthPrediction(), style: const TextStyle(fontSize: 11)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ⭐ 4. متوسط يومي + أكثر طريقة دفع
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
                    ),
                    child: Column(
                      children: [
                        Row(
                          textDirection: TextDirection.rtl,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('📅 متوسط الإنفاق اليومي', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            Text('${_dailyAverage.toStringAsFixed(0)} ₪',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
                          ],
                        ),
                        const Divider(height: 16),
                        Row(
                          textDirection: TextDirection.rtl,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('💳 أكثر طريقة استخداماً', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(_getTopPaymentMethod(),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ⭐ 5. فلتر حسب الفئة
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: ['الكل', 'طعام', 'مواصلات', 'تسوق', 'ترفيه', 'صحة', 'سكن', 'أخرى'].map((c) {
                        final sel = _selectedCategoryFilter == c;
                        final emoji = c == 'الكل' ? '📋' : _getCategoryEmoji(c);
                        return GestureDetector(
                          onTap: () => _applyFilter(c),
                          child: Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: sel ? AppColors.primary : AppColors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)],
                            ),
                            child: Text('$emoji $c',
                                style: TextStyle(color: sel ? Colors.white : AppColors.text, fontWeight: FontWeight.w600, fontSize: 12)),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ⭐ 6. سجل المعاملات المفلتر
                  Row(
                    textDirection: TextDirection.rtl,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('📋 سجل المعاملات', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('${_filteredTransactions.length} معاملة',
                          style: const TextStyle(fontSize: 11, color: AppColors.gray)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_filteredTransactions.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16)),
                      child: const Center(child: Text('لا توجد معاملات', style: TextStyle(color: AppColors.gray))),
                    )
                  else
                    ..._filteredTransactions.take(20).map((tx) => _buildTransactionTile(tx)),

                  const SizedBox(height: 24),

                  // ⭐ 7. ملخص الإنجازات النهائي
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('🏆 ملخص الإنجازات', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 14),
                        _achievementRow('📋', 'إجمالي المعاملات', '${_allTransactions.length} معاملة'),
                        const SizedBox(height: 8),
                        _achievementRow('📂', 'عدد الفئات النشطة', '${_categorySpent.length} فئات'),
                        const SizedBox(height: 8),
                        _achievementRow('💰', 'معدل الادخار', '$savingsPct% من الدخل'),
                        const SizedBox(height: 8),
                        _achievementRow('📊', 'نسبة الالتزام بالميزانية', '${budgetPercent > 1 ? 0 : ((1 - budgetPercent) * 100).toInt()}%'),
                        const SizedBox(height: 8),
                        _achievementRow('🎯', 'متوسط يومي', '${_dailyAverage.toStringAsFixed(0)} ₪'),
                        const SizedBox(height: 8),
                        _achievementRow('💳', 'أكثر طريقة دفع', _getTopPaymentMethod()),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, String subtitle, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(title, style: const TextStyle(fontSize: 11, color: AppColors.gray)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: fg)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.gray)),
        ],
      ),
    );
  }

  Widget _achievementRow(String icon, String label, String value) {
    return Row(
      textDirection: TextDirection.rtl,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('$icon $label', style: const TextStyle(fontSize: 12, color: AppColors.text)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
      ],
    );
  }

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
      padding: const EdgeInsets.all(14),
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
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: Text(_getCategoryEmoji(category), style: const TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(note.isNotEmpty ? note : category, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 2),
                Text('$method • ${date.day}/${date.month}/${date.year}',
                    style: const TextStyle(fontSize: 10, color: AppColors.gray)),
              ],
            ),
          ),
          Text(
            '${isExpense ? '-' : '+'}${amount.abs().toStringAsFixed(0)} ₪',
            style: TextStyle(fontWeight: FontWeight.bold, color: isExpense ? AppColors.error : AppColors.success),
          ),
        ],
      ),
    );
  }

  Color _getColor(String category) {
    switch (category) {
      case 'طعام': return AppColors.primary;
      case 'مواصلات': return AppColors.gold;
      case 'تسوق': return const Color(0xFF8B5CF6);
      case 'ترفيه': return const Color(0xFFF97316);
      case 'صحة': return AppColors.success;
      case 'سكن': return const Color(0xFF3B82F6);
      default: return AppColors.gray;
    }
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

// ⭐ رسام المخطط الدائري
class _PieChartPainter extends CustomPainter {
  final Map<String, double> data;

  _PieChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 15;
    double startAngle = -pi / 2;

    final colors = [
      AppColors.primary,
      AppColors.gold,
      const Color(0xFF8B5CF6),
      const Color(0xFFF97316),
      const Color(0xFF3B82F6),
      AppColors.success,
      AppColors.error,
    ];

    // رسم الظل
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center, radius, shadowPaint);

    int i = 0;
    for (var entry in data.entries) {
      final sweepAngle = entry.value * 2 * pi;
      if (sweepAngle <= 0) continue;

      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      startAngle += sweepAngle;
      i++;
    }

    // دائرة بيضاء في المنتصف (Donut style)
    final innerPaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, radius * 0.55, innerPaint);

    // النص في المنتصف
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${data.length}',
        style: const TextStyle(color: AppColors.text, fontSize: 28, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2 - 8));

    final subPainter = TextPainter(
      text: const TextSpan(
        text: 'فئات',
        style: TextStyle(color: AppColors.gray, fontSize: 11),
      ),
      textDirection: TextDirection.ltr,
    );
    subPainter.layout();
    subPainter.paint(canvas, Offset(center.dx - subPainter.width / 2, center.dy + 8));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}