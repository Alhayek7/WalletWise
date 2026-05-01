import 'package:flutter/material.dart';
import '../constants/theme.dart';
import '../services/local_service.dart';

enum AuthMode { login, register, forgot }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  AuthMode _authMode = AuthMode.login;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _agreeTerms = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _otpController = TextEditingController();

  bool _otpSent = false;
  String _otpCode = '';

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
    _animController.forward();
  }

  // ⭐ تسجيل الدخول الذكي (يدعم المستخدمين الجدد تلقائياً)
  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError('الرجاء إدخال البريد الإلكتروني وكلمة المرور');
      return;
    }

    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // 1. محاولة تسجيل الدخول
    bool success = await LocalService.verifyLogin(email, password);

    // 2. إذا فشل - إنشاء حساب تلقائي (مستخدم جديد)
    if (!success) {
      await LocalService.saveUserCredentials(email, password, 'مستخدم');
      success = true;
    }

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        _showSuccess('مرحباً! 🎉');
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        _showError('حدث خطأ. حاول مرة أخرى');
      }
    }
  }

  // إنشاء حساب (النموذج الكامل)
  Future<void> _register() async {
    if (_nameController.text.isEmpty) return _showError('الرجاء إدخال الاسم');
    if (_emailController.text.isEmpty) {
      return _showError('الرجاء إدخال البريد الإلكتروني');
    }
    if (_passwordController.text.length < 6) {
      return _showError('كلمة المرور 6 أحرف على الأقل');
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      return _showError('كلمة المرور غير متطابقة');
    }
    if (!_agreeTerms) return _showError('الرجاء الموافقة على شروط الاستخدام');

    setState(() => _isLoading = true);

    await LocalService.saveUserCredentials(
      _emailController.text.trim(),
      _passwordController.text.trim(),
      _nameController.text.trim(),
    );

    if (mounted) {
      setState(() => _isLoading = false);
      _showSuccess('تم إنشاء الحساب بنجاح! 🎉');
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) Navigator.pushReplacementNamed(context, '/dashboard');
      });
    }
  }

  // استعادة كلمة المرور
  Future<void> _sendOTP() async {
    if (_emailController.text.isEmpty) {
      return _showError('الرجاء إدخال البريد الإلكتروني');
    }
    setState(() => _isLoading = true);

    final savedPassword = await LocalService.getSavedPassword(
      _emailController.text.trim(),
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (savedPassword != null) {
        _otpSent = true;
        _otpCode = savedPassword.length >= 3
            ? savedPassword.substring(savedPassword.length - 3)
            : savedPassword;
        _showSuccess('تم إرسال رمز التحقق');
      } else {
        _showError('البريد الإلكتروني غير مسجل');
      }
    }
  }

  void _resetPassword() {
    if (_otpController.text != _otpCode) {
      return _showError('رمز التحقق غير صحيح');
    }
    if (_passwordController.text.length < 6) {
      return _showError('كلمة المرور 6 أحرف على الأقل');
    }

    LocalService.updatePassword(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );
    _showSuccess('تم تغيير كلمة المرور بنجاح! 🔒');
    _switchMode(AuthMode.login);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error_outline, color: Colors.white),
        const SizedBox(width: 8),
        Expanded(child: Text(msg)),
      ]),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    ));
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle, color: Colors.white),
        const SizedBox(width: 8),
        Expanded(child: Text(msg)),
      ]),
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    ));
  }

  void _switchMode(AuthMode mode) {
    setState(() {
      _authMode = mode;
      _otpSent = false;
      _resetControllers();
    });
    _animController.reset();
    _animController.forward();
  }

  void _resetControllers() {
    _emailController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
    _nameController.clear();
    _otpController.clear();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gold.withValues(alpha: 0.4),
                          blurRadius: 25,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset('assets/logo.png', fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'WalletWise',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: AppColors.text,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _getSubtitle(),
                    style: const TextStyle(fontSize: 14, color: AppColors.gray),
                  ),
                  const SizedBox(height: 36),
                  if (_authMode == AuthMode.login) _buildLoginForm(),
                  if (_authMode == AuthMode.register) _buildRegisterForm(),
                  if (_authMode == AuthMode.forgot) _buildForgotForm(),
                  const SizedBox(height: 24),
                  _buildModeSwitcher(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getSubtitle() {
    switch (_authMode) {
      case AuthMode.login:
        return 'مساعدك المالي الذكي';
      case AuthMode.register:
        return 'انضم لآلاف المستخدمين';
      case AuthMode.forgot:
        return 'استعادة كلمة المرور';
    }
  }

  Widget _buildLoginForm() {
    return Column(children: [
      _field(
        controller: _emailController,
        hint: 'البريد الإلكتروني',
        icon: Icons.email_outlined,
        keyboardType: TextInputType.emailAddress,
      ),
      const SizedBox(height: 16),
      _field(
        controller: _passwordController,
        hint: 'كلمة المرور',
        icon: Icons.lock_outlined,
        obscure: _obscurePassword,
        suffix: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: AppColors.gray,
            size: 20,
          ),
          onPressed: () =>
              setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
      const SizedBox(height: 8),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          onPressed: () => _switchMode(AuthMode.forgot),
          child: const Text(
            'نسيت كلمة المرور؟',
            style: TextStyle(color: AppColors.primary, fontSize: 13),
          ),
        ),
      ),
      const SizedBox(height: 16),
      _btn('دخول', _login, _isLoading),
      const SizedBox(height: 12),
      const Text('أو', style: TextStyle(color: AppColors.grayLight, fontSize: 13)),
      const SizedBox(height: 12),
      _outlineBtn('🔵 الدخول السريع', () {
        _emailController.text = 'ahmed@walletwise.com';
        _passwordController.text = '123456';
      }),
    ]);
  }

  Widget _buildRegisterForm() {
    return Column(children: [
      _field(
        controller: _nameController,
        hint: 'الاسم الكامل',
        icon: Icons.person_outlined,
      ),
      const SizedBox(height: 16),
      _field(
        controller: _emailController,
        hint: 'البريد الإلكتروني',
        icon: Icons.email_outlined,
        keyboardType: TextInputType.emailAddress,
      ),
      const SizedBox(height: 16),
      _field(
        controller: _passwordController,
        hint: 'كلمة المرور (6 أحرف على الأقل)',
        icon: Icons.lock_outlined,
        obscure: _obscurePassword,
        suffix: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: AppColors.gray,
            size: 20,
          ),
          onPressed: () =>
              setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
      const SizedBox(height: 16),
      _field(
        controller: _confirmPasswordController,
        hint: 'تأكيد كلمة المرور',
        icon: Icons.lock_outlined,
        obscure: _obscureConfirm,
        suffix: IconButton(
          icon: Icon(
            _obscureConfirm ? Icons.visibility_off : Icons.visibility,
            color: AppColors.gray,
            size: 20,
          ),
          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
        ),
      ),
      const SizedBox(height: 12),
      Row(children: [
        GestureDetector(
          onTap: () => setState(() => _agreeTerms = !_agreeTerms),
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _agreeTerms ? AppColors.primary : AppColors.grayLight,
                width: 2,
              ),
              color: _agreeTerms ? AppColors.primary : Colors.transparent,
            ),
            child: _agreeTerms
                ? const Icon(Icons.check, color: Colors.white, size: 14)
                : null,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text.rich(
            TextSpan(
              text: 'أوافق على ',
              style: TextStyle(fontSize: 12, color: AppColors.gray),
              children: [
                TextSpan(
                  text: 'الشروط والأحكام',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(text: ' و'),
                TextSpan(
                  text: ' سياسة الخصوصية',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ]),
      const SizedBox(height: 20),
      _btn('إنشاء حساب', _register, _isLoading),
    ]);
  }

  Widget _buildForgotForm() {
    return Column(children: [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.gold.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(children: [
          Icon(Icons.lock_reset, size: 48, color: AppColors.gold),
          SizedBox(height: 12),
          Text(
            'أدخل بريدك الإلكتروني وسنرسل لك\nرمز التحقق لإعادة تعيين كلمة المرور',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.gray, fontSize: 13),
          ),
        ]),
      ),
      const SizedBox(height: 20),
      _field(
        controller: _emailController,
        hint: 'البريد الإلكتروني',
        icon: Icons.email_outlined,
        keyboardType: TextInputType.emailAddress,
      ),
      const SizedBox(height: 16),
      if (!_otpSent)
        _btn('إرسال رمز التحقق', _sendOTP, _isLoading)
      else ...[
        _field(
          controller: _otpController,
          hint: 'رمز التحقق (آخر 3 خانات)',
          icon: Icons.pin_outlined,
          keyboardType: TextInputType.number,
          maxLength: 3,
        ),
        const SizedBox(height: 12),
        _field(
          controller: _passwordController,
          hint: 'كلمة المرور الجديدة',
          icon: Icons.lock_outlined,
          obscure: _obscurePassword,
        ),
        const SizedBox(height: 16),
        _btn('حفظ كلمة المرور', _resetPassword, false),
      ],
    ]);
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffix,
    int? maxLength,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grayLight.withValues(alpha: 0.5)),
      ),
      child: TextField(
        controller: controller,
        textAlign: TextAlign.right,
        obscureText: obscure,
        keyboardType: keyboardType,
        maxLength: maxLength,
        style: const TextStyle(fontSize: 15, color: AppColors.text),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.grayLight, fontSize: 14),
          prefixIcon: Icon(icon, color: AppColors.gray, size: 20),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
          counterText: '',
        ),
      ),
    );
  }

  Widget _btn(String text, VoidCallback onPressed, bool isLoading) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          elevation: 3,
          shadowColor: AppColors.primary.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                text,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Widget _outlineBtn(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.gray,
          side: BorderSide(color: AppColors.grayLight.withValues(alpha: 0.3)),
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.gray)),
      ),
    );
  }

  Widget _buildModeSwitcher() {
    switch (_authMode) {
      case AuthMode.login:
        return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('ليس لديك حساب؟', style: TextStyle(color: AppColors.gray, fontSize: 13)),
          TextButton(
            onPressed: () => _switchMode(AuthMode.register),
            child: const Text('إنشاء حساب جديد',
                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ]);
      case AuthMode.register:
        return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('لديك حساب بالفعل؟', style: TextStyle(color: AppColors.gray, fontSize: 13)),
          TextButton(
            onPressed: () => _switchMode(AuthMode.login),
            child: const Text('تسجيل الدخول',
                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ]);
      case AuthMode.forgot:
        return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          TextButton.icon(
            onPressed: () => _switchMode(AuthMode.login),
            icon: const Icon(Icons.arrow_forward, size: 16, color: AppColors.primary),
            label: const Text('العودة لتسجيل الدخول',
                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ]);
    }
  }
}