

// الكود الذي  بالاعلي هو كود بيانات وصفحة وهمية وتجريبية 
import 'dart:math';
import 'package:flutter/material.dart';
import '../constants/theme.dart';
import '../services/local_service.dart';

class FamilyScreen extends StatefulWidget {
  const FamilyScreen({super.key});

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  bool _isLoading = true;
  bool _hasFamily = false;
  String _familyName = 'عائلة الراشدي';
  String _familyCode = 'WW-2026-X7K9';
  double _familyBudget = 12000;
  String _userRole = 'admin';

  List<Map<String, dynamic>> _members = [];
  Map<String, double> _memberExpenses = {};
  List<Map<String, dynamic>> _familyGoals = [];
  List<Map<String, dynamic>> _alerts = [];

  final _nameController = TextEditingController();
  final _budgetController = TextEditingController();
  final _goalController = TextEditingController();
  final _goalAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFamilyData();
  }

Future<void> _loadFamilyData() async {
  setState(() => _isLoading = true);

  _members = await LocalService.getFamilyMembers();
  _familyGoals = await LocalService.getFamilyGoals();
  _familyName = await LocalService.getFamilyName();
  _familyCode = await LocalService.getFamilyCode();
  final transactions = await LocalService.getTransactions();
  final now = DateTime.now();

  // ⭐ حساب مصاريف كل فرد من المعاملات الحقيقية
  _memberExpenses = {};
  for (var member in _members) {
    final name = member['name'] as String;
    _memberExpenses[member['id']] = transactions
        .where((tx) {
          final date = DateTime.tryParse(tx['date'] ?? '') ?? now;
          final txMember = tx['family_member'] as String? ?? '';
          return date.month == now.month && date.year == now.year &&
              (tx['amount'] as num) < 0 && txMember == name;
        })
        .fold(0.0, (sum, tx) => sum + (tx['amount'] as num).abs());
  }

  double totalBudget = 0;
  for (var member in _members) {
    totalBudget += (member['budget'] as num).toDouble();
  }
  _familyBudget = totalBudget > 0 ? totalBudget : 12000;

  // توليد تنبيهات
  _alerts = [];
  for (var member in _members) {
    final spent = _memberExpenses[member['id']] ?? 0;
    final budget = (member['budget'] as num).toDouble();
    if (budget > 0 && spent > budget) {
      _alerts.add({
        'type': 'alert', 'icon': '🚨',
        'message': '${member['name']} تجاوز ميزانيته (${spent.toStringAsFixed(0)} / ${budget.toStringAsFixed(0)} ₪)',
        'color': AppColors.error,
      });
    } else if (budget > 0 && spent > budget * 0.8) {
      _alerts.add({
        'type': 'warning', 'icon': '⚠️',
        'message': '${member['name']} اقترب من حد ميزانيته (${spent.toStringAsFixed(0)} / ${budget.toStringAsFixed(0)} ₪)',
        'color': const Color(0xFFF97316),
      });
    }
  }

  if (mounted) {
    setState(() {
      _hasFamily = _members.isNotEmpty;
      _isLoading = false;
    });
  }
}


  // ⭐ دالة مساعدة لتحويل int إلى Color
  Color _color(dynamic value) {
    if (value is Color) return value;
    if (value is int) return Color(value);
    return AppColors.primary;
  }

  void _addMember() {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
          const Text('👤 إضافة فرد جديد', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(controller: _nameController, textAlign: TextAlign.right,
              decoration: InputDecoration(labelText: 'الاسم', filled: true, fillColor: AppColors.background, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
          const SizedBox(height: 12),
          TextField(controller: _budgetController, textAlign: TextAlign.right, keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'الميزانية الشهرية (₪)', filled: true, fillColor: AppColors.background, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () async {
              if (_nameController.text.isNotEmpty) {
                final member = {
                  'id': 'user_${DateTime.now().millisecondsSinceEpoch}',
                  'name': _nameController.text, 'role': 'viewer', 'avatar': '👤', 'status': 'نشط',
                  'budget': double.tryParse(_budgetController.text) ?? 3000,
                  'color': [0xFF0F4C3A, 0xFFD4AF37, 0xFF8B5CF6, 0xFFF97316][_members.length % 4],
                };
                _members.add(member);
                _memberExpenses[member['id'] as String] = 0;
                _familyBudget = _members.fold(0.0, (sum, m) => sum + (m['budget'] as num).toDouble());
                await LocalService.saveFamilyMembers(_members);
                _nameController.clear(); _budgetController.clear();
                setState(() {});
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: const Text('إضافة'),
          )),
        ]),
      ),
    );
  }

  void _addGoal() {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
          const Text('🎯 إضافة هدف عائلي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(controller: _goalController, textAlign: TextAlign.right, decoration: InputDecoration(labelText: 'اسم الهدف', filled: true, fillColor: AppColors.background, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
          const SizedBox(height: 12),
          TextField(controller: _goalAmountController, textAlign: TextAlign.right, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'المبلغ المستهدف (₪)', filled: true, fillColor: AppColors.background, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () async {
              if (_goalController.text.isNotEmpty && _goalAmountController.text.isNotEmpty) {
                _familyGoals.add({
                  'id': 'g${DateTime.now().millisecondsSinceEpoch}',
                  'name': _goalController.text, 'target': double.tryParse(_goalAmountController.text) ?? 0,
                  'saved': 0, 'emoji': '🎯', 'deadline': 'غير محدد',
                });
                await LocalService.saveFamilyGoals(_familyGoals);
                _goalController.clear(); _goalAmountController.clear();
                setState(() {});
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: const Text('إضافة'),
          )),
        ]),
      ),
    );
  }

  void _changeRole(int index) {
    final roles = ['admin', 'viewer', 'custom'];
    final roleNames = ['مدير', 'مشاهد', 'مخصص'];
    final currentRole = _members[index]['role'] as String;
    final nextIndex = (roles.indexOf(currentRole) + 1) % roles.length;
    setState(() => _members[index]['role'] = roles[nextIndex]);
    LocalService.saveFamilyMembers(_members);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم تغيير دور ${_members[index]['name']} إلى ${roleNames[nextIndex]}'), backgroundColor: AppColors.success, duration: const Duration(seconds: 1)),
    );
  }

  void _removeMember(int index) {
    final name = _members[index]['name'];
    setState(() {
      _members.removeAt(index);
      _familyBudget = _members.fold(0.0, (sum, m) => sum + (m['budget'] as num).toDouble());
    });
    LocalService.saveFamilyMembers(_members);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم إزالة $name'), backgroundColor: AppColors.error, duration: const Duration(seconds: 1)),
    );
  }

  String _getRoleName(String role) {
    switch (role) {
      case 'admin': return 'مدير';
      case 'viewer': return 'مشاهد';
      case 'custom': return 'مخصص';
      default: return 'عضو';
    }
  }

  String _getRoleIcon(String role) {
    switch (role) {
      case 'admin': return '👑';
      case 'viewer': return '👁️';
      case 'custom': return '⚙️';
      default: return '👤';
    }
  }

  @override
  void dispose() {
    _nameController.dispose(); _budgetController.dispose();
    _goalController.dispose(); _goalAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.gold)));
    }
    if (!_hasFamily) return _buildCreateFamily();

    final totalSpent = _memberExpenses.values.fold(0.0, (a, b) => a + b);
    final budgetPercent = _familyBudget > 0 ? (totalSpent / _familyBudget).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200, floating: false, pinned: true, backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF0F4C3A), Color(0xFF071F17)])),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 50, 20, 10),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Row(textDirection: TextDirection.rtl, children: [
                        Container(width: 52, height: 52, decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.gold, Color(0xFFF0CC5A)]), borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: AppColors.gold.withValues(alpha: 0.4), blurRadius: 12)]),
                            child: const Center(child: Text('👨‍👩‍👧', style: TextStyle(fontSize: 24)))),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Text(_familyName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('${_members.length} أفراد • $_userRole', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
                        ])),
                      ]),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.15))),
                        child: Row(textDirection: TextDirection.rtl, children: [
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                            Text('ميزانية العائلة', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
                            const SizedBox(height: 4),
                            Text('${totalSpent.toStringAsFixed(0)} / ${_familyBudget.toStringAsFixed(0)} ₪', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                          ])),
                          SizedBox(width: 52, height: 52, child: Stack(alignment: Alignment.center, children: [
                            CircularProgressIndicator(value: budgetPercent, backgroundColor: Colors.white24, valueColor: const AlwaysStoppedAnimation(AppColors.gold), strokeWidth: 5),
                            Text('${(budgetPercent * 100).toInt()}%', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ])),
                        ]),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                if (_alerts.isNotEmpty) ...[
                  const Text('🔔 تنبيهات', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ..._alerts.map((a) => Container(
                    margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: _color(a['color']).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: _color(a['color']).withValues(alpha: 0.3))),
                    child: Row(textDirection: TextDirection.rtl, children: [
                      Text(a['icon'] as String, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(a['message'] as String, style: const TextStyle(fontSize: 12))),
                    ]),
                  )),
                  const SizedBox(height: 16),
                ],
                Row(textDirection: TextDirection.rtl, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('👥 أفراد العائلة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  TextButton.icon(onPressed: _addMember, icon: const Icon(Icons.person_add, size: 16), label: const Text('إضافة', style: TextStyle(fontSize: 12))),
                ]),
                const SizedBox(height: 12),
                ..._members.asMap().entries.map((e) {
                  final i = e.key; final m = e.value;
                  final spent = _memberExpenses[m['id']] ?? 0;
                  final budget = (m['budget'] as num).toDouble();
                  final pct = budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0.0;
                  final isOver = spent > budget;
                  final c = _color(m['color']);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6)]),
                    child: Column(children: [
                      Row(textDirection: TextDirection.rtl, children: [
                        Container(width: 44, height: 44, decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Center(child: Text(m['avatar'] as String, style: const TextStyle(fontSize: 22)))),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Row(textDirection: TextDirection.rtl, children: [
                            Text(m['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(width: 6), Text(_getRoleIcon(m['role'] as String), style: const TextStyle(fontSize: 12)),
                            const SizedBox(width: 4),
                            Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)), child: Text(_getRoleName(m['role'] as String), style: TextStyle(fontSize: 9, color: c, fontWeight: FontWeight.bold))),
                          ]),
                          Text('${spent.toStringAsFixed(0)} / $budget ₪', style: TextStyle(fontSize: 12, color: isOver ? AppColors.error : AppColors.gray)),
                        ])),
                        PopupMenuButton(
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(value: 'role', child: Text('تغيير الدور')),
                            const PopupMenuItem(value: 'remove', child: Text('إزالة', style: TextStyle(color: AppColors.error))),
                          ],
                          onSelected: (v) { if (v == 'role') _changeRole(i); if (v == 'remove') _removeMember(i); },
                        ),
                      ]),
                      const SizedBox(height: 10),
                      Directionality(textDirection: TextDirection.ltr, child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: pct, backgroundColor: AppColors.grayLight, valueColor: AlwaysStoppedAnimation<Color>(isOver ? AppColors.error : c), minHeight: 6))),
                    ]),
                  );
                }),
                const SizedBox(height: 24),
                _roleCard('👑', 'مدير', 'تحكم كامل - يرى كل شيء ويعدل الميزانيات', AppColors.primary),
                const SizedBox(height: 8),
                _roleCard('👁️', 'مشاهد', 'يرى التقارير الموحدة فقط', AppColors.gold),
                const SizedBox(height: 8),
                _roleCard('⚙️', 'مخصص', 'صلاحيات يحددها المدير لكل عضو', const Color(0xFF8B5CF6)),
                const SizedBox(height: 24),
                const Text('📊 مقارنة المصاريف', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)]),
                  child: Column(children: _members.map((m) {
                    final spent = _memberExpenses[m['id']] ?? 0;
                    final maxSpent = _memberExpenses.values.fold(0.0, (a, b) => a > b ? a : b);
                    final barWidth = maxSpent > 0 ? (spent / maxSpent).clamp(0.05, 1.0) : 0.05;
                    final c = _color(m['color']);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(textDirection: TextDirection.rtl, children: [
                        SizedBox(width: 28, child: Text(m['avatar'] as String, style: const TextStyle(fontSize: 16))),
                        const SizedBox(width: 8),
                        SizedBox(width: 50, child: Text(m['name'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                        const SizedBox(width: 8),
                        Expanded(child: Directionality(textDirection: TextDirection.ltr, child: Container(height: 20, decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)), child: FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: barWidth, child: Container(decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(10))))))),
                        const SizedBox(width: 8),
                        Text('${spent.toStringAsFixed(0)} ₪', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                      ]),
                    );
                  }).toList()),
                ),
                const SizedBox(height: 24),
                Row(textDirection: TextDirection.rtl, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('🎯 أهداف عائلية', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  TextButton.icon(onPressed: _addGoal, icon: const Icon(Icons.add, size: 16), label: const Text('إضافة', style: TextStyle(fontSize: 12))),
                ]),
                const SizedBox(height: 10),
                if (_familyGoals.isEmpty)
                  Container(padding: const EdgeInsets.all(30), decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16)), child: const Center(child: Text('لا توجد أهداف عائلية', style: TextStyle(color: AppColors.gray))))
                else
                  ..._familyGoals.map((g) {
                    final target = (g['target'] as num).toDouble();
                    final saved = (g['saved'] as num).toDouble();
                    final pct = target > 0 ? (saved / target).clamp(0.0, 1.0) : 0.0;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6)]),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Row(textDirection: TextDirection.rtl, children: [
                          Text(g['emoji'] as String, style: const TextStyle(fontSize: 22)), const SizedBox(width: 8),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                            Text(g['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text(g['deadline'] as String, style: const TextStyle(fontSize: 10, color: AppColors.gray)),
                          ])),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)), child: Text('${(pct * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 11))),
                        ]),
                        const SizedBox(height: 8),
                        Directionality(textDirection: TextDirection.ltr, child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: pct, backgroundColor: AppColors.grayLight, valueColor: const AlwaysStoppedAnimation(AppColors.gold), minHeight: 6))),
                        const SizedBox(height: 4),
                        Row(textDirection: TextDirection.rtl, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text('المتبقي ${(target - saved).toStringAsFixed(0)} ₪', style: const TextStyle(fontSize: 10, color: AppColors.gray)),
                          Text('${saved.toStringAsFixed(0)} / $target ₪', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ]),
                      ]),
                    );
                  }),
                const SizedBox(height: 24),
                const Text('🔗 دعوة أفراد جدد', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)]),
                  child: Column(children: [
                    Container(width: 140, height: 140, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.text, borderRadius: BorderRadius.circular(16)), child: CustomPaint(painter: _QRPainter(_familyCode))),
                    const SizedBox(height: 12),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)), child: Row(textDirection: TextDirection.rtl, mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(_familyCode, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 3, color: AppColors.primary)),
                      const SizedBox(width: 8),
                      GestureDetector(onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ الرمز'), backgroundColor: AppColors.success)), child: const Icon(Icons.copy, size: 18, color: AppColors.primary)),
                    ])),
                    const SizedBox(height: 4), const Text('⏱ ينتهي خلال 24 ساعة', style: TextStyle(fontSize: 9, color: AppColors.gray)),
                    const SizedBox(height: 12),
                    SizedBox(width: double.infinity, child: ElevatedButton.icon(
                      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم مشاركة الرمز'), backgroundColor: AppColors.success)),
                      icon: const Icon(Icons.share, size: 16), label: const Text('📤 مشاركة الرمز'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    )),
                  ]),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateFamily() {
    return Scaffold(
      appBar: AppBar(title: const Text('المحفظة العائلية'), centerTitle: true),
      body: Center(child: Padding(padding: const EdgeInsets.all(30), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('👨‍👩‍👧', style: TextStyle(fontSize: 72)), const SizedBox(height: 16),
        const Text('أنشئ محفظتك العائلية', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), const SizedBox(height: 8),
        const Text('أدر أموال عائلتك بذكاء مع صلاحيات مخصصة', textAlign: TextAlign.center, style: TextStyle(color: AppColors.gray, fontSize: 13)), const SizedBox(height: 32),
        SizedBox(width: double.infinity, child: ElevatedButton.icon(
          onPressed: () => setState(() { _hasFamily = true; _members = [{'id': 'user_1', 'name': 'أحمد (أنت)', 'role': 'admin', 'avatar': '👨', 'status': 'نشط', 'budget': 4000, 'color': 0xFF0F4C3A}]; }),
          icon: const Icon(Icons.add_home, size: 20), label: const Text('إنشاء محفظة عائلية'),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        )),
      ]))),
    );
  }

  Widget _roleCard(String icon, String title, String desc, Color color) {
    return Container(
      padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(14), border: Border(right: BorderSide(color: color, width: 3)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4)]),
      child: Row(textDirection: TextDirection.rtl, children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Center(child: Text(icon, style: const TextStyle(fontSize: 20)))),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Text(desc, style: const TextStyle(color: AppColors.gray, fontSize: 10)),
        ])),
      ]),
    );
  }
}

class _QRPainter extends CustomPainter {
  final String code;
  _QRPainter(this.code);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.gold;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(4)), Paint()..color = Colors.white);
    final cellSize = size.width / 8;
    final random = Random(code.hashCode);
    for (var r = 0; r < 8; r++) {
      for (var c = 0; c < 8; c++) {
        if (random.nextBool()) {
          canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(c * cellSize + 2, r * cellSize + 2, cellSize - 4, cellSize - 4), const Radius.circular(2)), paint);
        }
      }
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}