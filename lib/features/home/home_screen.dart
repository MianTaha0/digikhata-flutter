import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import 'tabs/bills_tab.dart';
import 'tabs/cash_tab.dart';
import 'tabs/expense_tab.dart';
import 'tabs/home_tab.dart';
import 'tabs/stock_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  static const _tabs = <Widget>[
    HomeTab(),
    CashTab(),
    StockTab(),
    BillsTab(),
    ExpenseTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(t.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            tooltip: t.actionReports,
            onPressed: () => context.push('/reports'),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: t.actionReminders,
            onPressed: () => context.push('/reminders'),
          ),
          IconButton(
            icon: const Icon(Icons.backup_outlined),
            tooltip: t.actionBackup,
            onPressed: () => context.push('/backup'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: t.actionSettings,
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: _tabs[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home),
              label: t.tabHome),
          NavigationDestination(
              icon: const Icon(Icons.payments_outlined),
              selectedIcon: const Icon(Icons.payments),
              label: t.tabCash),
          NavigationDestination(
              icon: const Icon(Icons.inventory_2_outlined),
              selectedIcon: const Icon(Icons.inventory_2),
              label: t.tabStock),
          NavigationDestination(
              icon: const Icon(Icons.receipt_long_outlined),
              selectedIcon: const Icon(Icons.receipt_long),
              label: t.tabBills),
          NavigationDestination(
              icon: const Icon(Icons.money_off_outlined),
              selectedIcon: const Icon(Icons.money_off),
              label: t.tabExpense),
        ],
      ),
    );
  }
}
