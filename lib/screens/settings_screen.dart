import 'package:flutter/material.dart';
import '../constants/theme.dart';
import '../services/local_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameController = TextEditingController();
  final _incomeController = TextEditingController();
  final _budgetController = TextEditingController();
  final _emailController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  bool _isSaving = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _notificationsEnabled = true;
  bool _advisorAlerts = true;
  bool _budgetWarnings = true;
  bool _biometricLock = false;
  String _currency = 'ILS';
  // String _language = 'العربية';
  Map<String, dynamic> _userData = {};

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final data = await LocalService.getUserData();
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email') ?? '';

    setState(() {
      _userData = data;
      _nameController.text = data['name'] ?? 'أحمد';
      _incomeController.text = (data['monthly_income'] ?? 6500).toString();
      _budgetController.text = (data['monthly_budget'] ?? 4800).toString();
      _emailController.text = email;
      _currency = data['currency'] ?? 'ILS';
    });
  }

  // ⭐ حفظ الملف الشخصي
  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);

    final data = {
      'name': _nameController.text.trim().isEmpty
          ? 'أحمد'
          : _nameController.text.trim(),
      'monthly_income': double.tryParse(_incomeController.text) ?? 6500,
      'monthly_budget': double.tryParse(_budgetController.text) ?? 4800,
      'email': _emailController.text.trim(),
      'currency': _currency,
    };

    await LocalService.saveUserData(data);

    // حفظ البريد أيضاً
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('user_email', _emailController.text.trim());

    if (mounted) {
      setState(() {
        _isSaving = false;
        _userData = data;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ تم حفظ التغييرات بنجاح'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ⭐ تغيير كلمة المرور
  Future<void> _changePassword() async {
    final currentPass = _currentPasswordController.text.trim();
    final newPass = _newPasswordController.text.trim();

    if (currentPass.isEmpty || newPass.isEmpty) {
      _showError('الرجاء إدخال كلمة المرور');
      return;
    }
    if (newPass.length < 6) {
      _showError('كلمة المرور الجديدة 6 أحرف على الأقل');
      return;
    }

    final email = _emailController.text.trim();
    final savedPass = await LocalService.getSavedPassword(email);

    if (savedPass != null && savedPass != currentPass) {
      _showError('كلمة المرور الحالية غير صحيحة');
      return;
    }

    await LocalService.updatePassword(email, newPass);

    _currentPasswordController.clear();
    _newPasswordController.clear();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ تم تغيير كلمة المرور بنجاح'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ⭐ حذف جميع البيانات
  Future<void> _deleteAllData() async {
    await LocalService.clearAll();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🗑️ تم حذف جميع البيانات'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  // ⭐ تسجيل الخروج
  Future<void> _logout() async {
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          textDirection: TextDirection.rtl,
          children: [
            Icon(Icons.warning_amber, color: AppColors.error),
            SizedBox(width: 8),
            Text('تأكيد الحذف'),
          ],
        ),
        content: const Text(
          'هل أنت متأكد من حذف جميع بياناتك؟ هذا الإجراء لا يمكن التراجع عنه.',
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteAllData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('حذف الكل'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _incomeController.dispose();
    _budgetController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('⚙️ الإعدادات'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ⭐ بطاقة الملف الشخصي
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFF0A3328)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.gold, Color(0xFFF0CC5A)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text('👨', style: TextStyle(fontSize: 28)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _userData['name'] ?? 'المستخدم',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _emailController.text,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '⭐ النسخة المجانية',
                          style: TextStyle(
                            color: AppColors.gold,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ⭐ تعديل البيانات
          _sectionTitle('👤 تعديل البيانات الشخصية'),
          const SizedBox(height: 10),
          _card([
            _textField('الاسم', _nameController, Icons.person),
            const SizedBox(height: 12),
            _textField('البريد الإلكتروني', _emailController, Icons.email),
            const SizedBox(height: 12),
            _textField(
              'الدخل الشهري (₪)',
              _incomeController,
              Icons.monetization_on,
              isNumber: true,
            ),
            const SizedBox(height: 12),
            _textField(
              'الميزانية الشهرية (₪)',
              _budgetController,
              Icons.account_balance_wallet,
              isNumber: true,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveProfile,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save, size: 18),
                label: Text(_isSaving ? 'جاري الحفظ...' : '💾 حفظ التغييرات'),
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
          ]),

          const SizedBox(height: 20),

          // ⭐ تغيير كلمة المرور
          _sectionTitle('🔒 تغيير كلمة المرور'),
          const SizedBox(height: 10),
          _card([
            _textField(
              'كلمة المرور الحالية',
              _currentPasswordController,
              Icons.lock,
              obscure: _obscureCurrent,
              suffix: IconButton(
                icon: Icon(
                  _obscureCurrent ? Icons.visibility_off : Icons.visibility,
                  size: 18,
                ),
                onPressed: () =>
                    setState(() => _obscureCurrent = !_obscureCurrent),
              ),
            ),
            const SizedBox(height: 12),
            _textField(
              'كلمة المرور الجديدة',
              _newPasswordController,
              Icons.lock_outline,
              obscure: _obscureNew,
              suffix: IconButton(
                icon: Icon(
                  _obscureNew ? Icons.visibility_off : Icons.visibility,
                  size: 18,
                ),
                onPressed: () => setState(() => _obscureNew = !_obscureNew),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _changePassword,
                icon: const Icon(Icons.vpn_key, size: 18),
                label: const Text('🔑 تغيير كلمة المرور'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ]),

          const SizedBox(height: 20),

          // ⭐ التفضيلات
          _sectionTitle('🎨 التفضيلات'),
          const SizedBox(height: 10),
          _card([
            _switchItem(
              Icons.notifications_outlined,
              'تفعيل الإشعارات',
              _notificationsEnabled,
              (v) => setState(() => _notificationsEnabled = v),
            ),
            _switchItem(
              Icons.smart_toy_outlined,
              'تنبيهات المستشار',
              _advisorAlerts,
              (v) => setState(() => _advisorAlerts = v),
            ),
            _switchItem(
              Icons.warning_amber_outlined,
              'تحذيرات الميزانية',
              _budgetWarnings,
              (v) => setState(() => _budgetWarnings = v),
            ),
          ]),

          const SizedBox(height: 20),

          // ⭐ الأمان
          _sectionTitle('🛡️ الأمان'),
          const SizedBox(height: 10),
          _card([
            _switchItem(
              Icons.fingerprint,
              'قفل بالبصمة',
              _biometricLock,
              (v) => setState(() => _biometricLock = v),
            ),
            _tileItem(Icons.privacy_tip_outlined, 'الخصوصية والبيانات', () {}),
            _tileItem(
              Icons.delete_outline,
              'حذف جميع البيانات',
              _showDeleteDialog,
              color: AppColors.error,
            ),
          ]),

          const SizedBox(height: 24),

          // ⭐ تسجيل الخروج
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout, color: AppColors.error),
              label: const Text(
                'تسجيل الخروج',
                style: TextStyle(color: AppColors.error),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),
          const Center(
            child: Text(
              'WalletWise v1.0.0',
              style: TextStyle(fontSize: 11, color: AppColors.gray),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.text,
        ),
      ),
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _textField(
    String label,
    TextEditingController ctrl,
    IconData icon, {
    bool obscure = false,
    bool isNumber = false,
    Widget? suffix,
  }) {
    return TextField(
      controller: ctrl,
      textAlign: TextAlign.right,
      obscureText: obscure,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(fontSize: 14, color: AppColors.text),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.background,
        prefixIcon: Icon(icon, size: 18, color: AppColors.gray),
        suffixIcon: suffix,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _tileItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color ?? AppColors.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color ?? AppColors.text,
                ),
              ),
            ),
            Icon(Icons.chevron_right, size: 16, color: color ?? AppColors.gray),
          ],
        ),
      ),
    );
  }

  Widget _switchItem(
    IconData icon,
    String title,
    bool value,
    Function(bool) onChange,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChange,
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

// // ⭐ Helper للوصول لـ SharedPreferences
// class SharedPreferencesHelper {
//   static Future<SharedPreferences> getInstance() async {
//     return await SharedPreferences.getInstance();
//   }
// }
