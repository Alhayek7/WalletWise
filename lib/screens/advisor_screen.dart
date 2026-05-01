import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../constants/theme.dart';
import '../services/local_service.dart';

class AdvisorScreen extends StatefulWidget {
  const AdvisorScreen({super.key});

  @override
  State<AdvisorScreen> createState() => _AdvisorScreenState();
}

class _AdvisorScreenState extends State<AdvisorScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;
  bool _isLoading = true;
  final bool _useAI = true; // ⭐ تفعيل Gemini API

  // بيانات المستخدم
  double _totalExpenses = 0;
  double _monthlyIncome = 6500;
  double _monthlyBudget = 4800;
  Map<String, double> _categorySpending = {};
  List<Map<String, dynamic>> _allTransactions = [];
  String _userName = 'أحمد';
  int _totalTransactions = 0;
  int _conversationCount = 1;
  int _userPoints = 0;
  String _userLevel = 'مبتدئ';

  // Gemini API Key - مجاني
  static const String _geminiKey = 'AIzaSyBuiSu2TvYIq88rCnvpg1FGIzECbAFzXNo';
  static const String _geminiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    final userData = await LocalService.getUserData();
    final transactions = await LocalService.getTransactions();
    final now = DateTime.now();
    double totalExpense = 0;
    Map<String, double> cats = {};

    for (var tx in transactions) {
      final amount = (tx['amount'] ?? 0).toDouble();
      final dateStr = tx['date'] as String?;
      final date = dateStr != null ? DateTime.tryParse(dateStr) ?? now : now;
      final category = tx['category'] ?? 'أخرى';
      if (date.month == now.month && date.year == now.year && amount < 0) {
        totalExpense += amount.abs();
        cats[category] = (cats[category] ?? 0) + amount.abs();
      }
    }

    // ⭐ حساب النقاط
    final budgetPercent = _monthlyBudget > 0
        ? (totalExpense / _monthlyBudget).clamp(0.0, 1.0)
        : 0.0;
    int points = 0;
    if (budgetPercent < 0.5) {
      points = 100;
    } else if (budgetPercent < 0.8) {
      points = 50;
    } else if (budgetPercent < 1.0) {
      points = 25;
    }
    points += transactions.length * 2;

    String level = 'مبتدئ';
    if (points > 200) {
      level = 'محترف';
    } else if (points > 100) {
      level = 'متقدم';
    } else if (points > 50) {
      level = 'مهتم';
    }

    if (mounted) {
      setState(() {
        _userName = userData['name'] ?? 'أحمد';
        _monthlyIncome = (userData['monthly_income'] ?? 6500).toDouble();
        _monthlyBudget = (userData['monthly_budget'] ?? 4800).toDouble();
        _totalExpenses = totalExpense;
        _categorySpending = cats;
        _allTransactions = transactions;
        _totalTransactions = transactions.length;
        _userPoints = points;
        _userLevel = level;
        _isLoading = false;
      });
      _addWelcomeMessage();
    }
  }

  void _addWelcomeMessage() {
    final remaining = _monthlyBudget - _totalExpenses;
    // final budgetPercent = _monthlyBudget > 0
    //     ? (_totalExpenses / _monthlyBudget).clamp(0.0, 1.0)
    //     : 0.0;
    final savings = _monthlyIncome - _totalExpenses;
    final topCategory = _categorySpending.isNotEmpty
        ? _categorySpending.entries
              .reduce((a, b) => a.value > b.value ? a : b)
              .key
        : '';
    final topDay = _analyzeTopDay();

    String welcome =
        '✅ مرحباً $_userName! 🏆 $_userLevel ($_userPoints نقطة)\n\n';

    if (_totalTransactions == 0) {
      welcome +=
          'أنا مستشارك المالي الذكي. لا توجد معاملات بعد.\n\n💡 ابدأ بإضافة مصاريفك وسأحللها لك!';
    } else {
      welcome +=
          '📊 المصاريف: ${_totalExpenses.toStringAsFixed(0)} ₪\n'
          '💵 متبقي: ${remaining.toStringAsFixed(0)} ₪\n'
          '💰 الادخار: ${savings.toStringAsFixed(0)} ₪\n'
          '📋 المعاملات: $_totalTransactions\n';
      if (topCategory.isNotEmpty) welcome += '🔝 الأعلى: $topCategory\n';
      if (topDay.isNotEmpty) welcome += '$topDay\n';
      welcome += '\n💡 اسألني أي سؤال أو استخدم الأزرار أدناه!';
    }

    _addMessage(true, welcome);
  }

  // ⭐ تحليل أفضل يوم إنفاق
  String _analyzeTopDay() {
    final weekDays = <int, double>{};
    final now = DateTime.now();
    for (var tx in _allTransactions) {
      final date = DateTime.tryParse(tx['date'] ?? '') ?? now;
      if (date.month == now.month) {
        weekDays[date.weekday] =
            (weekDays[date.weekday] ?? 0) +
            ((tx['amount'] as num?)?.abs() ?? 0);
      }
    }
    if (weekDays.isEmpty) return '';
    final top = weekDays.entries.reduce((a, b) => a.value > b.value ? a : b);
    const days = [
      '',
      'الإثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد',
    ];
    return '📅 أكثر يوم إنفاق: ${days[top.key]} (${top.value.toStringAsFixed(0)} ₪)';
  }

  // ⭐ التنبؤ بمصاريف الشهر القادم
  String _predictNextMonth() {
    if (_allTransactions.length < 2) return '';
    final now = DateTime.now();
    double lastMonth = 0, twoMonthsAgo = 0;
    for (var tx in _allTransactions) {
      final date = DateTime.tryParse(tx['date'] ?? '') ?? now;
      final amount = (tx['amount'] as num?)?.abs() ?? 0;
      if (date.month == now.month - 1 && date.year == now.year) {
        lastMonth += amount;
      }
      if (date.month == now.month - 2 && date.year == now.year) {
        twoMonthsAgo += amount;
      }
    }
    if (lastMonth == 0) return '';
    final trend = twoMonthsAgo > 0
        ? ((lastMonth - twoMonthsAgo) / twoMonthsAgo * 100).toInt()
        : 0;
    final predicted = lastMonth * (1 + trend / 100);
    return '🔮 توقع الشهر القادم: ${predicted.toStringAsFixed(0)} ₪ (${trend >= 0 ? '+' : ''}$trend%)';
  }

  void _addMessage(bool isBot, String text) {
    final now = DateTime.now();
    _messages.add({
      'isBot': isBot,
      'text': text,
      'time':
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
    });
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    _addMessage(false, text);
    _messageController.clear();
    setState(() {
      _isTyping = true;
      _conversationCount++;
    });

    if (_useAI && _totalTransactions > 0) {
      _askGemini(text);
    } else {
      Future.delayed(const Duration(milliseconds: 700), () {
        if (!mounted) return;
        _addMessage(true, _generateLocalReply(text));
        setState(() => _isTyping = false);
        _scrollToBottom();
      });
    }
  }

  // ⭐ Gemini API
  Future<void> _askGemini(String question) async {
    try {
      final context =
          '''
أنت مستشار مالي ذكي في تطبيق WalletWise. اسم المستخدم: $_userName.
دخله الشهري: $_monthlyIncome ₪. ميزانيته: $_monthlyBudget ₪.
مصاريفه هذا الشهر: $_totalExpenses ₪. عدد المعاملات: $_totalTransactions.
توزيع المصاريف: ${_categorySpending.entries.map((e) => '${e.key}: ${e.value.toStringAsFixed(0)} ₪').join('، ')}.
أكثر يوم إنفاق: ${_analyzeTopDay()}.
${_predictNextMonth()}.
المستخدم مستواه: $_userLevel ولديه $_userPoints نقطة.
أجب بالعربية. كن ودوداً ومفيداً. قدم نصائح مالية. لا تتجاوز 3 جمل.''';

      final response = await http
          .post(
            Uri.parse('$_geminiUrl?key=$_geminiKey'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'contents': [
                {
                  'parts': [
                    {'text': '$context\n\nسؤال المستخدم: $question'},
                  ],
                },
              ],
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final reply =
            data['candidates']?[0]?['content']?['parts']?[0]?['text'] ??
            'عذراً، لم أفهم. حاول مرة أخرى.';
        if (mounted) {
          _addMessage(true, reply.trim());
          setState(() => _isTyping = false);
          _scrollToBottom();
        }
      } else {
        _fallbackReply(question);
      }
    } catch (e) {
      _fallbackReply(question);
    }
  }

  void _fallbackReply(String q) {
    if (mounted) {
      _addMessage(true, _generateLocalReply(q));
      setState(() => _isTyping = false);
      _scrollToBottom();
    }
  }

  // النموذج المحلي (احتياطي)
  String _generateLocalReply(String question) {
    final q = question.trim();
    final lower = q.toLowerCase();

    if (_any(lower, [
      'مرحبا',
      'هلا',
      'السلام',
      'اهلا',
      'hi',
      'hello',
      'صباح',
      'مساء',
    ])) {
      return '👋 أهلًا $_userName! 🏆 $_userLevel ($_userPoints نقطة)\n\n💡 اسألني عن مصاريفك أو كيف توفر أكثر!';
    }
    if (_any(lower, ['شكرا', 'تسلم', 'يعطيك', 'مشكور', 'thanks'])) {
      return 'العفو $_userName! 😊 +5 نقاط لك!';
    }
    if (_any(lower, ['مصاريف', 'صرفت', 'انفقت', 'كم صرفت', 'إجمالي', 'كم'])) {
      final r = _monthlyBudget - _totalExpenses;
      final p = _monthlyBudget > 0
          ? (_totalExpenses / _monthlyBudget * 100).toInt()
          : 0;
      final s = p > 90
          ? '🔴 خطر'
          : p > 70
          ? '🟡 انتبه'
          : '✅ ممتاز';
      return '📊 **مصاريفك**: ${_totalExpenses.toStringAsFixed(0)} ₪ ($p%)\n💵 متبقي: ${r.toStringAsFixed(0)} ₪\n📋 المعاملات: $_totalTransactions\n📊 الحالة: $s\n${_predictNextMonth()}';
    }
    if (_any(lower, ['أكبر', 'أكثر', 'فئة', 'بند', 'اعلى'])) {
      if (_categorySpending.isEmpty) return 'لا توجد معاملات بعد.';
      final t = _categorySpending.entries.reduce(
        (a, b) => a.value > b.value ? a : b,
      );
      return '🔝 **${t.key}**: ${t.value.toStringAsFixed(0)} ₪\n\n${_analyzeTopDay()}\n💡 ${_advice(t.key)}';
    }
    if (_any(lower, ['ادخار', 'وفر', 'توفير', 'save'])) {
      final s = _monthlyIncome - _totalExpenses;
      if (s <= 0) return '⚠️ لا يوجد ادخار. قلل ${_topCat()} فوراً!';
      return '💰 تدخر: $s ₪\n📈 6 أشهر: ${(s * 6).toStringAsFixed(0)} ₪\n📈 سنة: ${(s * 12).toStringAsFixed(0)} ₪\n${_predictNextMonth()}';
    }
    if (_any(lower, ['تقرير', 'ملخص', 'وضعي', 'report'])) {
      final s = _monthlyIncome - _totalExpenses;
      return '📋 **تقرير $_userName** 🏆 $_userLevel\n\n💰 الدخل: ${_monthlyIncome.toStringAsFixed(0)} ₪\n💸 المصاريف: ${_totalExpenses.toStringAsFixed(0)} ₪\n💵 الادخار: $s ₪\n📂 الفئات: ${_categorySpending.length}\n📋 المعاملات: $_totalTransactions\n⭐ النقاط: $_userPoints\n🔝 الأعلى: ${_topCat()}\n${_analyzeTopDay()}\n${_predictNextMonth()}';
    }
    if (_any(lower, ['نصيحة', 'ساعد', 'مساعدة', 'اقتراح', 'خطة'])) {
      return '💡 **نصائح مخصصة**\n\n1️⃣ ${_advice1()}\n2️⃣ ${_advice2()}\n3️⃣ ${_advice3()}\n\n⭐ نقاطك: $_userPoints';
    }
    if (_any(lower, ['مطاعم', 'اكل', 'طعام', 'قهوة'])) {
      return _catAnalysis('طعام', '🍔');
    }
    if (_any(lower, ['مواصلات', 'بنزين', 'وقود', 'تاكسي'])) {
      return _catAnalysis('مواصلات', '🚗');
    }
    if (_any(lower, ['تسوق', 'ملابس', 'شراء'])) {
      return _catAnalysis('تسوق', '🛒');
    }
    if (_any(lower, ['ترفيه', 'سينما', 'العاب'])) {
      return _catAnalysis('ترفيه', '🎮');
    }

    return '🧠 سؤال جميل!\n\n💰 مصاريفك: ${_totalExpenses.toStringAsFixed(0)} ₪\n\n💡 جرب:\n• "كم صرفت؟"\n• "كيف أوفر؟"\n• "تقرير كامل"\n• "أكبر مصاريفي"';
  }

  // دوال مساعدة
  bool _any(String t, List<String> k) => k.any((w) => t.contains(w));
  String _topCat() => _categorySpending.isEmpty
      ? 'لا توجد'
      : _categorySpending.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;

  String _catAnalysis(String cat, String emoji) {
    final spent = _categorySpending[cat] ?? 0;
    final pct = _monthlyBudget > 0 ? (spent / _monthlyBudget * 100).toInt() : 0;
    final status = pct > 30
        ? '⚠️ مرتفع'
        : pct > 15
        ? '🟡 متوسط'
        : '✅ منخفض';
    return '$emoji **$cat**: ${spent.toStringAsFixed(0)} ₪ ($pct%) - $status\n💡 ${_advice(cat)}';
  }

  String _advice(String c) {
    switch (c) {
      case 'طعام':
        return 'الطبخ المنزلي يوفر 40%. خطط لوجباتك.';
      case 'مواصلات':
        return 'استخدم المواصلات العامة.';
      case 'تسوق':
        return 'قاعدة 24 ساعة: انتظر قبل الشراء.';
      case 'ترفيه':
        return 'ابحث عن فعاليات مجانية.';
      default:
        return 'راقب إنفاقك وحاول تقليله 10%.';
    }
  }

  String _advice1() =>
      _categorySpending.isEmpty ? 'سجل مصاريفك' : 'قلل "${_topCat()}" 20%';
  String _advice2() {
    final r = _monthlyBudget - _totalExpenses;
    return r > 0
        ? 'ادخر ${(r * 0.5).toStringAsFixed(0)} ₪'
        : 'تجنب المصاريف غير الضرورية';
  }

  String _advice3() =>
      'حدد هدفاً: ${(_monthlyIncome * 0.2).toStringAsFixed(0)} ₪ شهرياً';

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ======================== UI ========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.gold),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (c, i) => i == _messages.length
                        ? _typing()
                        : _bubble(_messages[i]),
                  ),
          ),
          if (!_isLoading) _chipsRow(),
          _inputBar(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 50, 16, 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F4C3A), Color(0xFF071F17)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.gold, Color(0xFFF0CC5A)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Text('🤖', style: TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  textDirection: TextDirection.rtl,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text(
                      'المستشار المالي الذكي',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (_useAI) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'AI',
                          style: TextStyle(
                            color: AppColors.gold,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  textDirection: TextDirection.rtl,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '🏆 $_userLevel • ⭐ $_userPoints • 💬 $_conversationCount',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.circle,
                      size: 6,
                      color: Colors.greenAccent,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble(Map<String, dynamic> m) {
    final isBot = m['isBot'] as bool;
    return Align(
      alignment: isBot ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: isBot ? AppColors.white : AppColors.primary,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: isBot
                ? const Radius.circular(18)
                : const Radius.circular(4),
            bottomRight: isBot
                ? const Radius.circular(4)
                : const Radius.circular(18),
          ),
          boxShadow: isBot
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: isBot
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              m['text'],
              style: TextStyle(
                color: isBot ? AppColors.text : Colors.white,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              m['time'],
              style: TextStyle(
                color: isBot ? AppColors.grayLight : Colors.white54,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typing() {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dot(),
            const SizedBox(width: 4),
            _dot(),
            const SizedBox(width: 4),
            _dot(),
          ],
        ),
      ),
    );
  }

  Widget _dot() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: const Duration(milliseconds: 800),
      builder: (c, v, _) => Opacity(
        opacity: v,
        child: Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: AppColors.gray,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _chipsRow() {
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _chip('📊 مصاريفي', 'كم صرفت هذا الشهر؟'),
          _chip('💡 توفير', 'كيف أوفر أكثر؟'),
          _chip('📋 تقرير', 'تقرير كامل'),
          _chip('🔝 الأعلى', 'ما أكبر مصاريفي؟'),
          _chip('📅 نمطي', 'ما هو نمط إنفاقي؟'),
        ],
      ),
    );
  }

  Widget _chip(String label, String query) {
    return GestureDetector(
      onTap: () => _sendMessage(query),
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.grayLight),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.text),
        ),
      ),
    );
  }

  Widget _inputBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.grayLight)),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              textAlign: TextAlign.right,
              onSubmitted: _sendMessage,
              decoration: InputDecoration(
                hintText: 'اسأل مستشارك المالي...',
                hintStyle: const TextStyle(
                  color: AppColors.grayLight,
                  fontSize: 13,
                ),
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _sendMessage(_messageController.text),
            child: Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
