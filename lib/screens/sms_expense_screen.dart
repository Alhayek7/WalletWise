import 'package:flutter/material.dart';
import '../constants/theme.dart';
import '../services/firebase_service.dart';

class SMSExpenseScreen extends StatefulWidget {
  const SMSExpenseScreen({super.key});

  @override
  State<SMSExpenseScreen> createState() => _SMSExpenseScreenState();
}

class _SMSExpenseScreenState extends State<SMSExpenseScreen> {
  bool _isScanning = false;
  bool _isScanned = false;
  bool _isSaving = false;
  List<Map<String, dynamic>> _foundTransactions = [];

  void _scanSMS() {
    setState(() {
      _isScanning = true;
      _foundTransactions = [];
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _isScanned = true;
          _foundTransactions = [
            {
              'bank': 'البنك العربي',
              'amount': 200,
              'store': 'XYZ سوبرماركت',
              'date': 'اليوم',
              'category': 'طعام',
            },
            {
              'bank': 'بنك فلسطين',
              'amount': 85.5,
              'store': 'محطة وقود',
              'date': 'أمس',
              'category': 'مواصلات',
            },
            {
              'bank': 'البنك العربي',
              'amount': 350,
              'store': 'فاتورة كهرباء',
              'date': '23 أبريل',
              'category': 'سكن',
            },
          ];
        });
      }
    });
  }

  Future<void> _saveAll() async {
    setState(() => _isSaving = true);
    final user = FirebaseService.currentUser;
    if (user != null) {
      for (var tx in _foundTransactions) {
        await FirebaseService.addTransaction(
          userId: user.uid,
          amount: -((tx['amount'] as num).toDouble()),
          category: tx['category'] as String,
          note: tx['store'] as String,
          method: 'SMS',
        );
      }
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ تم حفظ ${_foundTransactions.length} معاملات'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('💬 استيراد SMS'), centerTitle: true),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFF3B82F6)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'سيقوم التطبيق بقراءة رسائل البنك الواردة واستخراج المعاملات تلقائياً',
                    style: TextStyle(fontSize: 12, color: Color(0xFF1E40AF)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          if (!_isScanned)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 15,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.sms,
                        size: 42,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'فحص رسائل البنك',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'يستخرج المصاريف من إشعارات البنك',
                      style: TextStyle(color: AppColors.gray, fontSize: 13),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: 200,
                      child: ElevatedButton.icon(
                        onPressed: _isScanning ? null : _scanSMS,
                        icon: _isScanning
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.search),
                        label: Text(
                          _isScanning ? 'جاري الفحص...' : 'بدء الفحص',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (_isScanned)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: AppColors.success,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'تم العثور على ${_foundTransactions.length} معاملات',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: ListView.separated(
                        itemCount: _foundTransactions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final tx = _foundTransactions[index];
                          return Container(
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
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.08,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.receipt,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tx['store'] as String,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Text(
                                        '${tx['bank']} • ${tx['date']}',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: AppColors.gray,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '-${(tx['amount'] as num).toStringAsFixed(1)} ₪',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: AppColors.error,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveAll,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save_alt, size: 18),
                        label: Text(
                          _isSaving ? 'جاري الحفظ...' : 'حفظ جميع المعاملات',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
