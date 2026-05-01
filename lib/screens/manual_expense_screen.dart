import 'package:flutter/material.dart';
import '../constants/theme.dart';
import '../services/local_service.dart';

class ManualExpenseScreen extends StatefulWidget {
  const ManualExpenseScreen({super.key});

  @override
  State<ManualExpenseScreen> createState() => _ManualExpenseScreenState();
}

class _ManualExpenseScreenState extends State<ManualExpenseScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _selectedCategory = 'طعام';
  String _selectedMember = 'أنا';
  List<Map<String, dynamic>> _familyMembers = [];
  bool _isSaving = false;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'طعام', 'icon': '🍔', 'color': const Color(0xFFFFF0E6)},
    {'name': 'مواصلات', 'icon': '🚗', 'color': const Color(0xFFF0F9FF)},
    {'name': 'تسوق', 'icon': '🛒', 'color': const Color(0xFFFAF5FF)},
    {'name': 'ترفيه', 'icon': '🎮', 'color': const Color(0xFFFEF2F2)},
    {'name': 'صحة', 'icon': '💊', 'color': const Color(0xFFF0FDF4)},
    {'name': 'تعليم', 'icon': '📚', 'color': const Color(0xFFFEF9C3)},
    {'name': 'سكن', 'icon': '🏠', 'color': const Color(0xFFEFF6FF)},
    {'name': 'أخرى', 'icon': '📌', 'color': const Color(0xFFF5F5F5)},
  ];

  @override
  void initState() {
    super.initState();
    _loadFamilyMembers();
  }

  Future<void> _loadFamilyMembers() async {
    _familyMembers = await LocalService.getFamilyMembers();
    if (_familyMembers.isEmpty) {
      _familyMembers = [{'id': 'user_1', 'name': 'أنا', 'avatar': '👤'}];
    }
    setState(() {});
  }

  Future<void> _saveExpense() async {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال المبلغ'), backgroundColor: AppColors.error),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال مبلغ صحيح'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isSaving = true);

    await LocalService.addTransaction({
      'user_id': LocalService.currentUserId,
      'amount': -amount,
      'category': _selectedCategory,
      'note': _noteController.text.isEmpty ? _selectedCategory : _noteController.text.trim(),
      'method': 'يدوي',
      'family_member': _selectedMember,
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ تم حفظ المصروف بنجاح'), backgroundColor: AppColors.success),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('إضافة مصروف'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          // ⭐ المبلغ
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12)],
            ),
            child: Column(children: [
              const Text('💰 المبلغ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                SizedBox(
                  width: 180,
                  child: TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: -2),
                    decoration: InputDecoration(hintText: '0.00', hintStyle: TextStyle(color: AppColors.grayLight, fontSize: 48, fontWeight: FontWeight.bold), border: InputBorder.none),
                  ),
                ),
                const SizedBox(width: 4),
                const Text('₪', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.gold)),
              ]),
              Divider(color: AppColors.grayLight.withValues(alpha: 0.3)),
            ]),
          ),

          const SizedBox(height: 24),

          // ⭐ اختيار فرد العائلة
          if (_familyMembers.length > 1) ...[
            const Text('👤 من صرف؟', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8, runSpacing: 8, alignment: WrapAlignment.end,
              children: _familyMembers.map((m) {
                final isSelected = _selectedMember == m['name'];
                return GestureDetector(
                  onTap: () => setState(() => _selectedMember = m['name'] as String),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? AppColors.primary : AppColors.grayLight.withValues(alpha: 0.3)),
                    ),
                    child: Text('${m['avatar'] ?? '👤'} ${m['name']}',
                        style: TextStyle(color: isSelected ? Colors.white : AppColors.text, fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],

          // ⭐ التصنيف
          const Text('📂 اختر التصنيف', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10, runSpacing: 10,
            children: _categories.map((cat) {
              final isSelected = _selectedCategory == cat['name'];
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = cat['name'] as String),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : cat['color'],
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isSelected ? AppColors.primary : AppColors.grayLight.withValues(alpha: 0.3), width: isSelected ? 2 : 1),
                    boxShadow: isSelected ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))] : null,
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(cat['icon'] as String, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 6),
                    Text(cat['name'] as String, style: TextStyle(color: isSelected ? AppColors.white : AppColors.text, fontWeight: FontWeight.w600, fontSize: 13)),
                    if (isSelected) ...[const SizedBox(width: 4), const Icon(Icons.check_circle, color: AppColors.white, size: 16)],
                  ]),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // ⭐ ملاحظة
          const Text('📝 ملاحظة', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)]),
            child: TextField(
              controller: _noteController, textAlign: TextAlign.right, maxLines: 2,
              decoration: InputDecoration(hintText: 'مثال: غداء مع الأصدقاء في مطعم', hintStyle: const TextStyle(color: AppColors.grayLight, fontSize: 14), contentPadding: const EdgeInsets.all(16), border: InputBorder.none),
            ),
          ),

          const SizedBox(height: 32),

          // ⭐ زر الحفظ
          SizedBox(
            width: double.infinity, height: 56,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveExpense,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.white, elevation: 3, shadowColor: AppColors.primary.withValues(alpha: 0.4), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: _isSaving
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2))
                  : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.save, size: 20), SizedBox(width: 8), Text('💾 حفظ المصروف', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))]),
            ),
          ),

          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.gray, side: const BorderSide(color: AppColors.grayLight), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: const Text('إلغاء', style: TextStyle(fontSize: 14)),
            ),
          ),
        ]),
      ),
    );
  }
}