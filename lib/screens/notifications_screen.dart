import 'package:flutter/material.dart';
import '../constants/theme.dart';
import '../services/local_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _selectedFilter = 'الكل';
  List<Map<String, dynamic>> _allNotifications = [];
  bool _isLoading = true;
  bool _hasUnread = false;

  @override
  void initState() {
    super.initState();
    _generateNotifications();
  }

  Future<void> _generateNotifications() async {
    setState(() => _isLoading = true);

    final userData = await LocalService.getUserData();
    final transactions = await LocalService.getTransactions();
    final monthlyBudget = (userData['monthly_budget'] ?? 4800).toDouble();
    final monthlyIncome = (userData['monthly_income'] ?? 6500).toDouble();
    final now = DateTime.now();

    double totalExpense = 0;
    Map<String, double> categorySpent = {};

    for (var tx in transactions) {
      final amount = (tx['amount'] ?? 0).toDouble();
      final date = DateTime.tryParse(tx['date'] ?? '') ?? now;
      final category = tx['category'] ?? 'أخرى';
      if (date.month == now.month && date.year == now.year && amount < 0) {
        totalExpense += amount.abs();
        categorySpent[category] = (categorySpent[category] ?? 0) + amount.abs();
      }
    }

    final notifications = <Map<String, dynamic>>[];
    final budgetPercent = monthlyBudget > 0 ? totalExpense / monthlyBudget : 0;

    if (budgetPercent >= 1.0) {
      notifications.add(_createNotif('alert', '🚨', 'تجاوزت الميزانية الشهرية!',
          'أنفقت ${totalExpense.toStringAsFixed(0)}₪ من ${monthlyBudget.toStringAsFixed(0)}₪.', AppColors.error));
    } else if (budgetPercent >= 0.8) {
      notifications.add(_createNotif('warning', '⚠️', 'اقتربت من حد الميزانية',
          'صرفت ${(budgetPercent * 100).toInt()}% من ميزانيتك.', const Color(0xFFF97316)));
    }

    final categoryLimits = {'طعام': monthlyBudget * 0.3, 'مواصلات': monthlyBudget * 0.15, 'تسوق': monthlyBudget * 0.2, 'ترفيه': monthlyBudget * 0.1};
    for (var entry in categorySpent.entries) {
      final limit = categoryLimits[entry.key] ?? monthlyBudget * 0.3;
      final pct = entry.value / limit;
      if (pct >= 1.0) {
        notifications.add(_createNotif('alert', '🔴', 'تجاوزت حد ${entry.key}!',
            'أنفقت ${entry.value.toStringAsFixed(0)}₪.', AppColors.error));
      } else if (pct >= 0.8) {
        notifications.add(_createNotif('warning', '🟡', 'اقتربت من حد ${entry.key}',
            '${(pct * 100).toInt()}% مستهلك.', const Color(0xFFF97316)));
      }
    }

    final savings = monthlyIncome - totalExpense;
    final savingsPct = monthlyIncome > 0 ? (savings / monthlyIncome * 100).toInt() : 0;
    notifications.add(_createNotif('info', '🤖', 'نصيحة المستشار',
        savingsPct > 30 ? 'أحسنت! تدخر $savingsPct% من دخلك.' : 'حاول توفير 20% من دخلك.', const Color(0xFF3B82F6)));

    final readStatus = await LocalService.getNotificationReadStatus();
    for (var notif in notifications) {
      final id = notif['id'] as String;
      notif['read'] = readStatus[id] ?? false;
    }

    final hasUnread = notifications.any((n) => !(n['read'] as bool));

    if (mounted) {
      setState(() {
        _allNotifications = notifications;
        _hasUnread = hasUnread;
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _createNotif(String type, String icon, String title, String body, Color color) {
    return {
      'id': '${type}_${title.hashCode}_${DateTime.now().millisecondsSinceEpoch}',
      'type': type, 'icon': icon, 'title': title, 'body': body,
      'time': 'الآن', 'read': false, 'color': color,
    };
  }

  List<Map<String, dynamic>> get _filtered {
    if (_selectedFilter == 'الكل') return _allNotifications;
    final typeMap = {'تنبيهات': 'alert', 'تحذيرات': 'warning', 'نصائح': 'info'};
    return _allNotifications.where((n) => n['type'] == (typeMap[_selectedFilter] ?? '')).toList();
  }

  Future<void> _markAllAsRead() async {
    final ids = <String>{};
    for (var n in _allNotifications) {
      n['read'] = true;
      ids.add(n['id'] as String);
    }
    await LocalService.markNotificationsRead(ids.toList());
    setState(() => _hasUnread = false);
  }

  Future<void> _markAsRead(int index) async {
    setState(() {
      _allNotifications[index]['read'] = true;
      _hasUnread = _allNotifications.any((n) => !(n['read'] as bool));
    });
    final id = _allNotifications[index]['id'] as String;
    await LocalService.markNotificationRead(id);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.gold)));
    }

    final notifications = _filtered;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(textDirection: TextDirection.rtl, mainAxisSize: MainAxisSize.min, children: [
          const Text('🔔 الإشعارات'),
          if (_hasUnread) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(10)),
              child: Text('${_allNotifications.where((n) => !(n['read'] as bool)).length}',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ],
        ]),
        centerTitle: true,
        actions: [
          if (_hasUnread)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text('تحديد الكل كمقروء', style: TextStyle(color: AppColors.gold, fontSize: 12)),
            ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: ['الكل', 'تنبيهات', 'تحذيرات', 'نصائح'].map((f) {
                final sel = _selectedFilter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedFilter = f),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.primary : AppColors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: sel ? AppColors.primary.withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
                      ),
                      child: Text(f, style: TextStyle(color: sel ? Colors.white : AppColors.text, fontWeight: FontWeight.w600, fontSize: 12)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: notifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🔕', style: TextStyle(fontSize: 52)),
                        const SizedBox(height: 14),
                        const Text('لا توجد إشعارات', style: TextStyle(fontSize: 16, color: AppColors.gray)),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _generateNotifications,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('تحديث'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _generateNotifications,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: notifications.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (c, i) {
                        final n = notifications[i];
                        final isRead = n['read'] as bool;
                        final color = (n['color'] as Color?) ?? AppColors.primary;
                        return GestureDetector(
                          onTap: () => _markAsRead(i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border(right: BorderSide(color: color, width: isRead ? 1 : 3)),
                              boxShadow: isRead ? null : [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 6)],
                            ),
                            child: Row(
                              textDirection: TextDirection.rtl,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 42, height: 42,
                                  decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                                  child: Center(child: Text(n['icon'] as String, style: const TextStyle(fontSize: 18))),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Row(
                                        textDirection: TextDirection.rtl,
                                        children: [
                                          if (!isRead)
                                            Container(width: 7, height: 7, margin: const EdgeInsets.only(left: 6),
                                                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                                          Expanded(
                                            child: Text(n['title'] as String, textAlign: TextAlign.right,
                                                style: TextStyle(fontWeight: isRead ? FontWeight.w600 : FontWeight.bold, fontSize: 13)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(n['body'] as String, textAlign: TextAlign.right,
                                          style: const TextStyle(color: AppColors.gray, fontSize: 11, height: 1.3)),
                                      const SizedBox(height: 4),
                                      Text(n['time'] as String, style: const TextStyle(color: AppColors.grayLight, fontSize: 9)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}