import 'package:flutter/material.dart';
import '../constants/theme.dart';
import 'manual_expense_screen.dart';
import 'ocr_expense_screen.dart';
import 'voice_expense_screen.dart';
import 'sms_expense_screen.dart';

class AddExpenseScreen extends StatelessWidget {
  const AddExpenseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('إضافة مصروف'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 10),

            // أيقونة مركزية
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.gold, Color(0xFFF0CC5A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Center(
                child: Text('💳', style: TextStyle(fontSize: 34)),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'كيف تحب تسجل مصروفك؟',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              'اختر الطريقة الأنسب لك لتوثيق نفقاتك بذكاء',
              style: TextStyle(fontSize: 13, color: AppColors.gray),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),

            // شبكة الطرق الأربع
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 0.9,
                children: [
                  _buildMethodCard(
                    context,
                    icon: Icons.camera_alt,
                    emoji: '📷',
                    title: 'تصوير فاتورة',
                    subtitle: 'OCR ذكي',
                    bgColor: const Color(0xFFFFF0E6),
                    featured: true,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const OCRExpenseScreen()),
                    ),
                  ),
                  _buildMethodCard(
                    context,
                    icon: Icons.mic,
                    emoji: '🎤',
                    title: 'تسجيل صوتي',
                    subtitle: 'أمر صوتي',
                    bgColor: const Color(0xFFF0FDF4),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const VoiceExpenseScreen()),
                    ),
                  ),
                  _buildMethodCard(
                    context,
                    icon: Icons.sms,
                    emoji: '💬',
                    title: 'رسالة SMS',
                    subtitle: 'استيراد تلقائي',
                    bgColor: const Color(0xFFF0F9FF),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SMSExpenseScreen()),
                    ),
                  ),
                  _buildMethodCard(
                    context,
                    icon: Icons.edit,
                    emoji: '✏️',
                    title: 'إدخال يدوي',
                    subtitle: 'نموذج سريع',
                    bgColor: const Color(0xFFFAF5FF),
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ManualExpenseScreen()),
                      );
                      // تحديث الصفحة الرئيسية بعد العودة
                      if (result == true && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ تم حفظ المصروف بنجاح'),
                            backgroundColor: AppColors.success,
                            duration: Duration(seconds: 1),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),
            Text(
              '💡 جميع الطرق تحفظ مباشرة في سجل معاملاتك',
              style: TextStyle(fontSize: 11, color: AppColors.gray.withValues(alpha: 0.7)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodCard(
    BuildContext context, {
    required IconData icon,
    required String emoji,
    required String title,
    required String subtitle,
    required Color bgColor,
    bool featured = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: featured
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, Color(0xFF1A6B4F)],
                )
              : null,
          color: featured ? null : AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: featured ? AppColors.gold.withValues(alpha: 0.3) : AppColors.grayLight.withValues(alpha: 0.3),
            width: featured ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: featured
                  ? AppColors.primary.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: featured ? 12 : 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: featured ? Colors.white.withValues(alpha: 0.2) : bgColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: featured
                    ? Icon(icon, color: AppColors.white, size: 28)
                    : Text(emoji, style: const TextStyle(fontSize: 26)),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: featured ? AppColors.white : AppColors.text,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: featured ? Colors.white70 : AppColors.gray,
              ),
              textAlign: TextAlign.center,
            ),
            if (featured) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '✨ موصى به',
                  style: TextStyle(
                    fontSize: 8,
                    color: AppColors.gold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}