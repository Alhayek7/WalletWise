import 'package:flutter/material.dart';
import '../constants/theme.dart';
import '../services/local_service.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  String _selectedEmoji = '💻';
  double _monthlySavings = 0;
  bool _isSavingGoal = false;
  List<Map<String, dynamic>> _goals = [];
  bool _isLoading = true;

  static const List<String> _emojiList = [
    '💻', '✈️', '🏠', '🚗', '📱', '🎓', '💍', '🏦',
    '🎮', '📚', '🐱', '🎸', '📷', '⌚', '🛵', '💼',
  ];

  static const Color _whatIfColor = Color(0xFF1E40AF);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    _goals = await LocalService.getGoals();
    final transactions = await LocalService.getTransactions();
    // final userData = await LocalService.getUserData();
    final now = DateTime.now();
    double totalIncome = 0;
    double totalExpense = 0;

    for (final tx in transactions) {
      final amount = (tx['amount'] ?? 0).toDouble();
      final dateStr = tx['date'] as String?;
      final date = dateStr != null ? DateTime.tryParse(dateStr) ?? now : now;
      if (date.month == now.month && date.year == now.year) {
        if (amount > 0) { totalIncome += amount; } else { totalExpense += amount.abs(); }
      }
    }

    if (mounted) {
      setState(() {
        _monthlySavings = (totalIncome - totalExpense).clamp(0, double.infinity);
        _isLoading = false;
      });
    }
  }

  void _showAddGoalDialog() {
    _titleController.clear();
    _amountController.clear();
    _selectedEmoji = '💻';

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          decoration: const BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
              Center(child: Container(width: 44, height: 5, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: AppColors.grayLight, borderRadius: BorderRadius.circular(3)))),
              const Text('🎯 إضافة هدف جديد', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.text)),
              const SizedBox(height: 6),
              const Text('حدد هدفاً وابدأ رحلة الادخار', style: TextStyle(fontSize: 13, color: AppColors.gray)),
              const SizedBox(height: 24),
              const Text('اختر أيقونة', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 10),
              Wrap(spacing: 10, runSpacing: 10, children: _emojiList.map((emoji) {
                final isSelected = _selectedEmoji == emoji;
                return GestureDetector(
                  onTap: () => setModalState(() => _selectedEmoji = emoji),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200), padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? AppColors.primary : Colors.transparent, width: 2),
                      boxShadow: isSelected ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 6)] : null,
                    ),
                    child: Text(emoji, style: const TextStyle(fontSize: 26)),
                  ),
                );
              }).toList()),
              const SizedBox(height: 20),
              TextField(
                controller: _titleController, textAlign: TextAlign.right, textInputAction: TextInputAction.next,
                decoration: InputDecoration(labelText: 'اسم الهدف', hintText: 'مثال: لابتوب جديد', filled: true, fillColor: AppColors.background,
                    prefixIcon: const Icon(Icons.flag, color: AppColors.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 2))),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _amountController, textAlign: TextAlign.right, keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'المبلغ المستهدف (₪)', hintText: '5000', filled: true, fillColor: AppColors.background,
                    prefixIcon: const Icon(Icons.monetization_on, color: AppColors.gold), suffixText: '₪',
                    suffixStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 2))),
              ),
              const SizedBox(height: 24),
              SizedBox(width: double.infinity, height: 54, child: ElevatedButton(
                onPressed: () => _saveGoal(ctx, setModalState),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.white, elevation: 3, shadowColor: AppColors.primary.withValues(alpha: 0.3), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: _isSavingGoal ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('💾 حفظ الهدف', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              )),
              const SizedBox(height: 12),
            ]),
          ),
        ),
      ),
    );
  }

  Future<void> _saveGoal(BuildContext ctx, void Function(VoidCallback) setModalState) async {
    if (_titleController.text.trim().isEmpty) { _showSnack('الرجاء إدخال اسم الهدف', isError: true); return; }
    if (_amountController.text.isEmpty || double.tryParse(_amountController.text) == null) { _showSnack('الرجاء إدخال مبلغ صحيح', isError: true); return; }

    setModalState(() => _isSavingGoal = true);

    _goals.add({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': _titleController.text.trim(),
      'target': double.parse(_amountController.text),
      'saved': 0.0,
      'deadline': 'غير محدد',
      'emoji': _selectedEmoji,
    });

    await LocalService.saveGoals(_goals);
    setModalState(() => _isSavingGoal = false);
    _titleController.clear();
    _amountController.clear();
    if (ctx.mounted) Navigator.pop(ctx);
    if (mounted) setState(() {});
    _showSnack('✅ تم إضافة الهدف بنجاح');
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: isError ? AppColors.error : AppColors.success, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), margin: const EdgeInsets.all(16), duration: const Duration(seconds: 2)));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.gold)));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('🎯 الأهداف المالية'), centerTitle: true,
        actions: [
          IconButton(
            icon: Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.gold.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.add, color: AppColors.gold, size: 20)),
            onPressed: _showAddGoalDialog,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _goals.isEmpty ? _buildEmptyState() : ListView.builder(
        padding: const EdgeInsets.all(20), itemCount: _goals.length + 1,
        itemBuilder: (context, index) {
          if (index == _goals.length) return _buildWhatIfCard();
          return _buildGoalCard(_goals[index]);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(child: Padding(padding: const EdgeInsets.all(30), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: 90, height: 90, decoration: BoxDecoration(color: AppColors.gold.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(22)), child: const Center(child: Text('🎯', style: TextStyle(fontSize: 42)))),
      const SizedBox(height: 20),
      const Text('لا توجد أهداف بعد', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text)),
      const SizedBox(height: 8),
      const Text('أضف هدفك الأول وابدأ رحلة الادخار\nنحو تحقيق أحلامك المالية', textAlign: TextAlign.center, style: TextStyle(color: AppColors.gray, fontSize: 13, height: 1.5)),
      const SizedBox(height: 28),
      ElevatedButton.icon(onPressed: _showAddGoalDialog, icon: const Icon(Icons.add, size: 20), label: const Text('إضافة هدف جديد'), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.white, padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)))),
    ])));
  }

  Widget _buildGoalCard(Map<String, dynamic> goal) {
    final target = (goal['target'] as num?)?.toDouble() ?? 0;
    final saved = (goal['saved'] as num?)?.toDouble() ?? 0;
    final title = goal['title'] as String? ?? 'هدف';
    final emoji = goal['emoji'] as String? ?? '🎯';
    final percent = target > 0 ? (saved / target).clamp(0.0, 1.0) : 0.0;
    final remaining = target - saved;

    String? timeEstimate;
    Color timeColor = AppColors.success;
    if (_monthlySavings > 0 && saved < target) {
      final months = (remaining / _monthlySavings).ceil();
      if (months <= 3) { timeEstimate = '🎉 متوقع خلال $months أشهر'; timeColor = AppColors.success; }
      else if (months <= 12) { timeEstimate = '📅 متوقع خلال $months شهراً'; timeColor = const Color(0xFFF97316); }
      else { timeEstimate = '⏳ متوقع خلال $months شهراً'; timeColor = AppColors.error; }
    } else if (saved >= target && target > 0) { timeEstimate = '🏆 تم الإنجاز!'; timeColor = AppColors.success; }

    return Dismissible(
      key: Key(goal['id'] as String? ?? ''),
      direction: DismissDirection.endToStart,
      background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(18)), child: const Icon(Icons.delete, color: Colors.white)),
      confirmDismiss: (direction) async {
        _goals.remove(goal);
        await LocalService.saveGoals(_goals);
        if (mounted) setState(() {});
        return false;
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))], border: saved >= target && target > 0 ? Border.all(color: AppColors.success.withValues(alpha: 0.4), width: 1.5) : null),
        child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Row(textDirection: TextDirection.rtl, children: [
            Container(width: 50, height: 50, decoration: BoxDecoration(gradient: LinearGradient(colors: saved >= target && target > 0 ? [AppColors.success.withValues(alpha: 0.15), AppColors.success.withValues(alpha: 0.05)] : [AppColors.primary.withValues(alpha: 0.1), AppColors.primary.withValues(alpha: 0.03)]), borderRadius: BorderRadius.circular(14)), child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24)))),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              if (timeEstimate != null) Text(timeEstimate, style: TextStyle(fontSize: 11, color: timeColor, fontWeight: FontWeight.w500)),
            ])),
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: saved >= target && target > 0 ? AppColors.success.withValues(alpha: 0.12) : AppColors.gold.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)), child: Text('${(percent * 100).toInt()}%', style: TextStyle(color: saved >= target && target > 0 ? AppColors.success : AppColors.gold, fontWeight: FontWeight.bold, fontSize: 12))),
          ]),
          const SizedBox(height: 16),
          Directionality(textDirection: TextDirection.ltr, child: ClipRRect(borderRadius: BorderRadius.circular(5), child: LinearProgressIndicator(value: percent, backgroundColor: AppColors.grayLight.withValues(alpha: 0.5), valueColor: AlwaysStoppedAnimation<Color>(saved >= target && target > 0 ? AppColors.success : AppColors.gold), minHeight: 8))),
          const SizedBox(height: 10),
          Row(textDirection: TextDirection.rtl, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(textDirection: TextDirection.rtl, children: [const Icon(Icons.savings, size: 14, color: AppColors.primary), const SizedBox(width: 4), Text('${saved.toStringAsFixed(0)} ₪ وُفِّرت', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12))]),
            Text('المتبقي ${remaining.toStringAsFixed(0)} ₪', style: const TextStyle(color: AppColors.gray, fontSize: 11)),
          ]),
        ]),
      ),
    );
  }

  Widget _buildWhatIfCard() {
    final hasSavings = _monthlySavings > 0;
    return Container(
      margin: const EdgeInsets.only(top: 10), padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: LinearGradient(colors: [const Color(0xFFEFF6FF), Colors.indigo.shade50]), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFBFDBFE))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        const Row(textDirection: TextDirection.rtl, children: [Text('🔮', style: TextStyle(fontSize: 24)), SizedBox(width: 8), Text('توقع ذكي للادخار', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: _whatIfColor))]),
        const SizedBox(height: 6),
        Text(hasSavings ? 'بناءً على معدل ادخارك الحالي (${_monthlySavings.toStringAsFixed(0)} ₪ شهرياً):' : 'ابدأ بإضافة دخلك الشهري لتظهر التوقعات', style: TextStyle(color: _whatIfColor.withValues(alpha: 0.7), fontSize: 12)),
        const SizedBox(height: 16),
        if (hasSavings) ...[
          _whatIfRow('📆 خلال 6 أشهر', '${(_monthlySavings * 6).toStringAsFixed(0)} ₪'),
          const SizedBox(height: 10),
          _whatIfRow('📅 خلال سنة', '${(_monthlySavings * 12).toStringAsFixed(0)} ₪'),
          const SizedBox(height: 10),
          _whatIfRow('🎯 خلال 5 سنوات', '${(_monthlySavings * 60).toStringAsFixed(0)} ₪'),
        ],
      ]),
    );
  }

  Widget _whatIfRow(String label, String value) {
    return Row(textDirection: TextDirection.rtl, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: _whatIfColor.withValues(alpha: 0.8), fontSize: 13)),
      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: _whatIfColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)), child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: _whatIfColor, fontSize: 13))),
    ]);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }
}