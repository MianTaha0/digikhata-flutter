import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('DigiKhata'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            tooltip: 'Reports',
            onPressed: () => context.push('/reports'),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Reminders',
            onPressed: () => context.push('/reminders'),
          ),
          IconButton(
            icon: const Icon(Icons.backup_outlined),
            tooltip: 'Backup',
            onPressed: () => context.push('/backup'),
          ),
        ],
      ),
      body: _tabs[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.payments_outlined),
              selectedIcon: Icon(Icons.payments),
              label: 'Cash'),
          NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2),
              label: 'Stock'),
          NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'Bills'),
          NavigationDestination(
              icon: Icon(Icons.money_off_outlined),
              selectedIcon: Icon(Icons.money_off),
              label: 'Expense'),
        ],
      ),
    );
  }
}
