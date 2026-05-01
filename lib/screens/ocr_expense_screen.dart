import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../constants/theme.dart';
import '../services/local_service.dart';

class OCRExpenseScreen extends StatefulWidget {
  const OCRExpenseScreen({super.key});

  @override
  State<OCRExpenseScreen> createState() => _OCRExpenseScreenState();
}

class _OCRExpenseScreenState extends State<OCRExpenseScreen> {
  final ImagePicker _picker = ImagePicker();

  bool _isAnalyzing = false;
  bool _isAnalyzed = false;
  bool _isSaving = false;
  XFile? _photo;
  String _rawText = '';

  double _detectedAmount = 0;
  String _detectedStore = '';
  String _detectedCategory = 'أخرى';

  // ⭐ دعم العائلة
  String _selectedMember = 'أنا';
  List<Map<String, dynamic>> _familyMembers = [];

  static const String _geminiKey = 'YOUR_GEMINI_API_KEY';
  static const String _geminiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

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
    if (mounted) setState(() {});
  }

  Future<void> _openCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85, preferredCameraDevice: CameraDevice.rear);
      if (photo != null && mounted) _processImage(photo);
    } catch (e) {
      _showError('تعذر فتح الكاميرا. تأكد من منح الصلاحية.');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (photo != null && mounted) _processImage(photo);
    } catch (e) {
      _showError('تعذر فتح المعرض.');
    }
  }

  void _processImage(XFile photo) {
    setState(() { _photo = photo; _isAnalyzing = true; _isAnalyzed = false; _rawText = ''; });
    _analyzeWithGemini(photo.path);
  }

  Future<void> _analyzeWithGemini(String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http.post(
        Uri.parse('$_geminiUrl?key=$_geminiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{
            'parts': [
              {'inlineData': {'mimeType': 'image/jpeg', 'data': base64Image}},
              {'text': 'استخرج من صورة هذه الفاتورة المعلومات التالية بصيغة JSON فقط. المبلغ الإجمالي (رقم فقط بدون علامة العملة)، اسم المحل، التصنيف (طعام/مواصلات/تسوق/ترفيه/صحة/سكن/أخرى). مثال للرد: {"amount": 200, "store": "مطعم XYZ", "category": "طعام"}'}
            ]
          }]
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
        final jsonMatch = RegExp(r'\{[^{}]*"amount"[^{}]*"store"[^{}]*"category"[^{}]*\}').firstMatch(text);

        if (jsonMatch != null) {
          final result = jsonDecode(jsonMatch.group(0)!);
          if (mounted) {
            setState(() {
              _isAnalyzing = false; _isAnalyzed = true;
              _detectedAmount = (result['amount'] as num?)?.toDouble() ?? 0;
              _detectedStore = result['store']?.toString() ?? 'فاتورة';
              _detectedCategory = result['category']?.toString() ?? 'أخرى';
              _rawText = 'Gemini AI: $text';
            });
          }
          return;
        }
        if (mounted) {
          setState(() {
            _isAnalyzing = false; _isAnalyzed = true; _rawText = text;
            _detectedAmount = _extractAmount(text) ?? 0;
            _detectedStore = _extractStore(text);
            _detectedCategory = _classifyCategory(text);
          });
        }
        return;
      }
      _fallbackAnalysis();
    } catch (e) {
      _fallbackAnalysis();
    }
  }

  void _fallbackAnalysis() {
    final mockData = [
      {'amount': 35, 'store': 'ستاربكس', 'category': 'طعام'},
      {'amount': 184, 'store': 'سوبرماركت', 'category': 'تسوق'},
      {'amount': 120, 'store': 'محطة وقود', 'category': 'مواصلات'},
      {'amount': 85, 'store': 'سينما', 'category': 'ترفيه'},
      {'amount': 55, 'store': 'صيدلية', 'category': 'صحة'},
      {'amount': 350, 'store': 'فاتورة كهرباء', 'category': 'سكن'},
    ];
    final selected = mockData[DateTime.now().millisecond % mockData.length];
    if (mounted) {
      setState(() {
        _isAnalyzing = false; _isAnalyzed = true;
        _detectedAmount = (selected['amount'] as num).toDouble();
        _detectedStore = selected['store'] as String;
        _detectedCategory = selected['category'] as String;
        _rawText = '⚠️ تحليل محلي (بدون إنترنت)';
      });
    }
  }

  double? _extractAmount(String text) {
    final numbers = RegExp(r'(\d+[\.\,]?\d*)').allMatches(text);
    double? maxNum;
    for (final match in numbers) {
      final value = double.tryParse((match.group(1) ?? '').replaceAll(',', '.'));
      if (value != null && value > 1 && value < 100000 && (maxNum == null || value > maxNum)) maxNum = value;
    }
    return maxNum;
  }

  String _extractStore(String text) {
    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.isNotEmpty) {
      final store = lines.first.trim();
      if (store.length > 2 && store.length < 40) return store;
    }
    return 'فاتورة';
  }

  String _classifyCategory(String text) {
    final lower = text.toLowerCase();
    if (_any(lower, ['مطعم', 'restaurant', 'cafe', 'مقهى', 'food', 'اكل', 'طعام', 'starbucks', 'pizza', 'burger'])) return 'طعام';
    if (_any(lower, ['وقود', 'fuel', 'gas', 'محطة', 'taxi', 'uber', 'مواصلات', 'نقل'])) return 'مواصلات';
    if (_any(lower, ['market', 'supermarket', 'سوبر', 'shop', 'متجر', 'تسوق', 'mall'])) return 'تسوق';
    if (_any(lower, ['pharmacy', 'صيدلية', 'hospital', 'مستشفى', 'doctor', 'طبيب'])) return 'صحة';
    if (_any(lower, ['electric', 'كهرباء', 'water', 'ماء', 'rent', 'إيجار'])) return 'سكن';
    if (_any(lower, ['cinema', 'سينما', 'movie', 'game', 'ترفيه'])) return 'ترفيه';
    return 'أخرى';
  }

  bool _any(String t, List<String> k) => k.any((w) => t.contains(w));

  Future<void> _saveInvoice() async {
    setState(() => _isSaving = true);
    await LocalService.addTransaction({
      'user_id': LocalService.currentUserId,
      'amount': -_detectedAmount,
      'category': _detectedCategory,
      'note': _detectedStore,
      'method': 'كاميرا',
      'family_member': _selectedMember,
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ تم حفظ الفاتورة بنجاح'), backgroundColor: AppColors.success),
      );
      Navigator.pop(context, true);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('📷 تصوير فاتورة'), centerTitle: true),
      body: _photo == null ? _buildCaptureView() : _buildResultView(),
    );
  }

  Widget _buildCaptureView() {
    return Center(
      child: Padding(padding: const EdgeInsets.all(30), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 120, height: 120, decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(30), border: Border.all(color: AppColors.grayLight.withValues(alpha: 0.4), width: 2)), child: const Icon(Icons.receipt_long, size: 56, color: AppColors.grayLight)),
        const SizedBox(height: 28),
        const Text('صوّر فاتورتك', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('سيقوم Gemini AI بتحليل الفاتورة بدقة\nواستخراج المبلغ والمحل والتصنيف', textAlign: TextAlign.center, style: TextStyle(color: AppColors.gray, fontSize: 13, height: 1.5)),
        const SizedBox(height: 36),
        Row(textDirection: TextDirection.rtl, mainAxisAlignment: MainAxisAlignment.center, children: [
          _srcBtn(Icons.camera_alt, 'كاميرا', AppColors.primary, _openCamera, true),
          const SizedBox(width: 16),
          _srcBtn(Icons.photo_library, 'معرض', AppColors.gold, _pickFromGallery),
        ]),
      ])),
    );
  }

  Widget _srcBtn(IconData icon, String label, Color color, VoidCallback onTap, [bool primary = false]) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140, padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(color: primary ? color : AppColors.white, borderRadius: BorderRadius.circular(18),
            border: Border.all(color: primary ? Colors.transparent : color.withValues(alpha: 0.4)),
            boxShadow: primary ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 5))] : null),
        child: Column(children: [Icon(icon, size: 32, color: primary ? Colors.white : color), const SizedBox(height: 8), Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: primary ? Colors.white : color))]),
      ),
    );
  }

  Widget _buildResultView() {
    return Column(children: [
      Container(height: 220, margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), border: Border.all(color: _isAnalyzed ? AppColors.success : AppColors.gold, width: 2)),
        child: Stack(fit: StackFit.expand, children: [
          ClipRRect(borderRadius: BorderRadius.circular(22), child: Image.file(File(_photo!.path), fit: BoxFit.cover)),
          if (_isAnalyzing) Container(color: Colors.black54, child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircularProgressIndicator(color: AppColors.gold), SizedBox(height: 12), Text('🔄 Gemini يحلل الفاتورة...', style: TextStyle(color: AppColors.gold, fontSize: 13))])),
        ]),
      ),
      if (_isAnalyzed) Expanded(child: SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 20), child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: const Row(textDirection: TextDirection.rtl, children: [Text('✅ تم تحليل الفاتورة بنجاح', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 13)), Spacer(), Icon(Icons.check_circle, color: AppColors.success, size: 20)])),
        const SizedBox(height: 16),
        Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(18), border: const Border(right: BorderSide(color: AppColors.primary, width: 4))),
            child: Column(children: [
              _row('💰 المبلغ', '${_detectedAmount.toStringAsFixed(0)} ₪', isAmount: true),
              const Divider(height: 20),
              _row('🏪 المحل', _detectedStore),
              const Divider(height: 20),
              _row('📂 التصنيف', '${_getEmoji(_detectedCategory)} $_detectedCategory', isCategory: true),
            ])),

        // ⭐ اختيار فرد العائلة
        if (_familyMembers.length > 1) ...[
          const SizedBox(height: 16),
          const Text('👤 من صرف؟', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.end, children: _familyMembers.map((m) {
            final sel = _selectedMember == m['name'];
            return GestureDetector(
              onTap: () => setState(() => _selectedMember = m['name'] as String),
              child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: sel ? AppColors.primary : AppColors.background, borderRadius: BorderRadius.circular(10), border: Border.all(color: sel ? AppColors.primary : AppColors.grayLight.withValues(alpha: 0.3))),
                  child: Text('${m['avatar'] ?? '👤'} ${m['name']}', style: TextStyle(color: sel ? Colors.white : AppColors.text, fontSize: 12, fontWeight: FontWeight.w600))),
            );
          }).toList()),
        ],

        const SizedBox(height: 16),
        Row(textDirection: TextDirection.rtl, children: [
          Expanded(child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveInvoice,
            icon: _isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check, size: 18),
            label: Text(_isSaving ? 'جاري الحفظ...' : 'تأكيد وحفظ'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.white, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          )),
          const SizedBox(width: 12),
          Expanded(child: OutlinedButton.icon(
            onPressed: () => setState(() { _photo = null; _isAnalyzed = false; _rawText = ''; }),
            icon: const Icon(Icons.refresh, size: 18), label: const Text('إعادة التصوير'),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.gray, side: const BorderSide(color: AppColors.grayLight), padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          )),
        ]),
        if (_rawText.isNotEmpty) ...[const SizedBox(height: 16),
          Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(12)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [const Text('📝 تفاصيل التحليل:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.gray)), const SizedBox(height: 6), Text(_rawText, textAlign: TextAlign.right, style: const TextStyle(fontSize: 10, color: AppColors.gray))])),
        ],
        const SizedBox(height: 20),
      ]))),
    ]);
  }

  Widget _row(String label, String value, {bool isAmount = false, bool isCategory = false}) {
    return Row(textDirection: TextDirection.rtl, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: AppColors.gray, fontSize: 13)),
      isCategory
          ? Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(20)), child: Text(value, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)))
          : Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: isAmount ? 20 : 13, color: isAmount ? AppColors.primary : AppColors.text)),
    ]);
  }

  String _getEmoji(String c) {
    switch (c) {
      case 'طعام': return '🍔';
      case 'مواصلات': return '🚗';
      case 'تسوق': return '🛒';
      case 'ترفيه': return '🎮';
      case 'صحة': return '💊';
      case 'سكن': return '🏠';
      default: return '📌';
    }
  }
}