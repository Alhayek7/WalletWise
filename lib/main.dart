import 'package:flutter/material.dart';
import 'constants/theme.dart';
// import 'services/local_service.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/add_expense_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/advisor_screen.dart';
import 'screens/family_screen.dart';
import 'screens/manual_expense_screen.dart';
import 'screens/ocr_expense_screen.dart';
import 'screens/voice_expense_screen.dart';
import 'screens/sms_expense_screen.dart';
import 'screens/budget_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/goals_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // LocalService لا يحتاج تهيئة
  runApp(const WalletWiseApp());
}

class WalletWiseApp extends StatelessWidget {
  const WalletWiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WalletWise',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const MainScreen(),
        '/manual_expense': (context) => const ManualExpenseScreen(),
        '/ocr_expense': (context) => const OCRExpenseScreen(),
        '/voice_expense': (context) => const VoiceExpenseScreen(),
        '/sms_expense': (context) => const SMSExpenseScreen(),
        '/budget': (context) => const BudgetScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/notifications': (context) => const NotificationsScreen(),
        '/goals': (context) => const GoalsScreen(),
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const AddExpenseScreen(),
    const ReportsScreen(),
    const AdvisorScreen(),
    const FamilyScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.gray,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'الرئيسية'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'مصاريف'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'تقارير'),
          BottomNavigationBarItem(icon: Icon(Icons.smart_toy), label: 'مستشار'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline), label: 'عائلة'),
        ],
      ),
    );
  }
}