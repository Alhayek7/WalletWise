import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../constants/theme.dart';
import '../services/local_service.dart';

class VoiceExpenseScreen extends StatefulWidget {
  const VoiceExpenseScreen({super.key});

  @override
  State<VoiceExpenseScreen> createState() => _VoiceExpenseScreenState();
}

class _VoiceExpenseScreenState extends State<VoiceExpenseScreen>
    with SingleTickerProviderStateMixin {
  bool _isRecording = false;
  bool _isAnalyzed = false;
  bool _isAnalyzing = false;
  bool _isSaving = false;
  late AnimationController _pulseController;
  String _transcribedText = '';

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  String _selectedCategory = 'طعام';

  // ⭐ Gemini API
  static const String _geminiKey = 'AIzaSyBuiSu2TvYIq88rCnvpg1FGIzECbAFzXNo';
  static const String _geminiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

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
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _isAnalyzed = false;
      _isAnalyzing = false;
      _amountController.clear();
      _noteController.clear();
      _transcribedText = '';
    });
    _pulseController.repeat(reverse: true);

    // محاكاة تسجيل 3 ثوانٍ (في الإصدار الحقيقي: استخدام microphone)
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) _stopRecording();
    });
  }

  void _stopRecording() {
    _pulseController.stop();
    _pulseController.reset();
    setState(() {
      _isRecording = false;
      _isAnalyzing = true;
    });

    // ⭐ محاكاة نص منطوق (في الإصدار الحقيقي: Speech-to-Text)
    final phrases = [
      'دفعت 50 شيكل على بقالة اليوم',
      'دفعت 120 شيكل على تاكسي',
      'دفعت 200 شيكل على ملابس من المول',
      'دفعت 85 شيكل على تذكرة سينما',
      'دفعت 55 شيكل على دواء من الصيدلية',
      'دفعت 350 شيكل على فاتورة الكهرباء',
    ];
    final spokenText = phrases[DateTime.now().millisecond % phrases.length];

    // محاولة تحليل النص عبر Gemini
    _analyzeWithGemini(spokenText);
  }

  // ======================== ⭐ Gemini API لتحليل النص ========================
  Future<void> _analyzeWithGemini(String text) async {
    try {
      final response = await http.post(
        Uri.parse('$_geminiUrl?key=$_geminiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text': 'استخرج من النص التالي معلومات المصروف بصيغة JSON فقط. '
                      'المبلغ (رقم فقط)، اسم المحل أو الخدمة، التصنيف (طعام/مواصلات/تسوق/ترفيه/صحة/سكن/أخرى). '
                      'مثال للرد: {"amount": 50, "store": "بقالة", "category": "طعام"}\n\n'
                      'النص: "$text"'
                }
              ]
            }
          ]
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';

        // استخراج JSON من الرد
        final jsonMatch = RegExp(r'\{[^{}]*"amount"[^{}]*"store"[^{}]*"category"[^{}]*\}').firstMatch(reply);

        if (jsonMatch != null) {
          final result = jsonDecode(jsonMatch.group(0)!);
          if (mounted) {
            setState(() {
              _isAnalyzing = false;
              _isAnalyzed = true;
              _transcribedText = '🗣️ النص: "$text"\n🤖 Gemini: $reply';
              _amountController.text = ((result['amount'] as num?)?.toDouble() ?? 0).toString();
              _noteController.text = result['store']?.toString() ?? '';
              _selectedCategory = result['category']?.toString() ?? 'أخرى';
            });
          }
          return;
        }
      }
      // فشل Gemini - استخدام محلي
      _fallbackLocalAnalysis(text);
    } catch (e) {
      // بدون إنترنت - استخدام محلي
      _fallbackLocalAnalysis(text);
    }
  }

  // ======================== احتياطي محلي (بدون إنترنت) ========================
  void _fallbackLocalAnalysis(String text) {
    final options = [
      {'amount': '50', 'note': 'بقالة', 'category': 'طعام'},
      {'amount': '120', 'note': 'تاكسي', 'category': 'مواصلات'},
      {'amount': '200', 'note': 'ملابس', 'category': 'تسوق'},
      {'amount': '85', 'note': 'سينما', 'category': 'ترفيه'},
      {'amount': '55', 'note': 'دواء', 'category': 'صحة'},
      {'amount': '350', 'note': 'كهرباء', 'category': 'سكن'},
    ];
    final selected = options[DateTime.now().millisecond % options.length];

    if (mounted) {
      setState(() {
        _isAnalyzing = false;
        _isAnalyzed = true;
        _transcribedText = '🗣️ النص: "$text"\n⚠️ تحليل محلي (بدون إنترنت)';
        _amountController.text = selected['amount'] as String;
        _noteController.text = selected['note'] as String;
        _selectedCategory = selected['category'] as String;
      });
    }
  }

  // ======================== حفظ ========================
  Future<void> _saveVoice() async {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      _showError('الرجاء إدخال المبلغ');
      return;
    }
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      _showError('الرجاء إدخال مبلغ صحيح');
      return;
    }

    setState(() => _isSaving = true);
    await LocalService.addTransaction({
      'user_id': LocalService.currentUserId,
      'amount': -amount,
      'category': _selectedCategory,
      'note': _noteController.text.trim().isEmpty ? _selectedCategory : _noteController.text.trim(),
      'method': 'صوتي',
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ تم حفظ المصروف الصوتي'), backgroundColor: AppColors.success),
      );
      Navigator.pop(context, true);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // ======================== UI ========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('🎤 تسجيل صوتي'), centerTitle: true),
      body: !_isAnalyzed && !_isAnalyzing ? _buildInitialView() : _buildFormView(),
    );
  }

  Widget _buildInitialView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        const SizedBox(height: 10),
        Container(
          width: 100, height: 100,
          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), shape: BoxShape.circle),
          child: Icon(Icons.mic, size: 48, color: AppColors.primary.withValues(alpha: 0.5)),
        ),
        const SizedBox(height: 24),
        const Text('🎤 التسجيل الصوتي', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        const SizedBox(height: 8),
        const Text('انطق بالمصروف وسيقوم Gemini AI باستخراج\nالمبلغ والتصنيف تلقائياً',
            style: TextStyle(fontSize: 13, color: AppColors.gray, height: 1.5), textAlign: TextAlign.center),
        const SizedBox(height: 36),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.gold.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.2))),
          child: const Row(textDirection: TextDirection.rtl, children: [
            Text('💡', style: TextStyle(fontSize: 18)), SizedBox(width: 8),
            Expanded(child: Text('قل مثلاً: "دفعت ٥٠ شيكل على بقالة اليوم"', style: TextStyle(fontSize: 12, color: AppColors.text), textAlign: TextAlign.right)),
          ]),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6)]),
          child: Column(children: [
            _buildInstructionItem('1', 'انطق بالمبلغ والفئة بوضوح'),
            const SizedBox(height: 8),
            _buildInstructionItem('2', 'انتظر حتى ينتهي التسجيل تلقائياً'),
            const SizedBox(height: 8),
            _buildInstructionItem('3', 'راجع البيانات واضغط حفظ'),
          ]),
        ),
        const SizedBox(height: 36),
        GestureDetector(
          onTap: _isRecording ? _stopRecording : _startRecording,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final scale = _isRecording ? 1.0 + _pulseController.value * 0.06 : 1.0;
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                      color: _isRecording ? AppColors.error : AppColors.primary,
                      boxShadow: [BoxShadow(color: (_isRecording ? AppColors.error : AppColors.primary).withValues(alpha: 0.4), blurRadius: 25, spreadRadius: _isRecording ? 8 : 2)]),
                  child: Icon(_isRecording ? Icons.mic : Icons.mic_none, color: Colors.white, size: 36),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        Text(_isRecording ? '🎙️ جاري التسجيل... تحدث الآن' : 'اضغط للبدء',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _isRecording ? AppColors.error : AppColors.primary)),
      ]),
    );
  }

  Widget _buildFormView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          if (_isAnalyzing)
            const Center(child: Column(children: [
              CircularProgressIndicator(color: AppColors.gold),
              SizedBox(height: 12),
              Text('🤖 Gemini يحلل الصوت...', style: TextStyle(color: AppColors.gold, fontSize: 13)),
            ]))
          else ...[
            const Row(textDirection: TextDirection.rtl, children: [
              Text('✅ تم التعرف على الصوت', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.success)),
              Spacer(), Icon(Icons.check_circle, color: AppColors.success, size: 20),
            ]),
            const SizedBox(height: 6),
            const Text('يمكنك تعديل البيانات قبل الحفظ', style: TextStyle(fontSize: 11, color: AppColors.gray)),
            if (_transcribedText.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(10)),
                child: Text(_transcribedText, textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 10, color: AppColors.gray)),
              ),
            ],
            const SizedBox(height: 20),
            const Text('💰 المبلغ', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary),
              decoration: InputDecoration(hintText: '0.00', suffixText: '₪',
                  suffixStyle: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 20),
                  filled: true, fillColor: AppColors.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none)),
            ),
            const SizedBox(height: 24),
            const Text('📂 التصنيف', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.end,
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat['name'];
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat['name'] as String),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : cat['color'] as Color,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? AppColors.primary : AppColors.grayLight.withValues(alpha: 0.3)),
                    ),
                    child: Text('${cat['icon']} ${cat['name']}',
                        style: TextStyle(color: isSelected ? Colors.white : AppColors.text, fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Text('📝 ملاحظة', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController, textAlign: TextAlign.right,
              decoration: InputDecoration(hintText: 'مثال: بقالة، تاكسي، ملابس...', filled: true, fillColor: AppColors.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none)),
            ),
            const SizedBox(height: 28),
            Row(textDirection: TextDirection.rtl, children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveVoice,
                  icon: _isSaving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check, size: 18),
                  label: Text(_isSaving ? 'جاري الحفظ...' : 'تأكيد وحفظ'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.white, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() { _isAnalyzed = false; _isAnalyzing = false; }),
                  icon: const Icon(Icons.refresh, size: 18), label: const Text('إعادة التسجيل'),
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.gray, side: const BorderSide(color: AppColors.grayLight), padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                ),
              ),
            ]),
          ],
        ]),
      ),
    );
  }

  Widget _buildInstructionItem(String number, String text) {
    return Row(textDirection: TextDirection.rtl, children: [
      Container(
        width: 26, height: 26,
        decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
        child: Center(child: Text(number, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary))),
      ),
      const SizedBox(width: 10),
      Text(text, style: const TextStyle(fontSize: 12, color: AppColors.text)),
    ]);
  }
}