import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/format/money.dart';
import '../../core/theme/colors.dart';
import 'cash_providers.dart';

class CashScreen extends ConsumerWidget {
  const CashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalsAsync = ref.watch(cashTotalsProvider);
    final entriesAsync = ref.watch(cashEntriesProvider);
    final dateFmt = DateFormat('d MMM, h:mm a');

    return Scaffold(
      body: Column(
        children: [
          totalsAsync.when(
            data: (t) => _CashTotalsBar(
              cashIn: t.cashIn,
              cashOut: t.cashOut,
              balance: t.balance,
            ),
            loading: () => const _CashTotalsBar(
                cashIn: 0, cashOut: 0, balance: 0),
            error: (e, _) => _CashTotalsBar(
                cashIn: 0, cashOut: 0, balance: 0, error: '$e'),
          ),
          Expanded(
            child: entriesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (list) {
                if (list.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No cash entries yet.\nTap + to add one.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final e = list[i];
                    final isIn = e.type == 1;
                    final c =
                        isIn ? AppColors.digiGreen : AppColors.digiError;
                    return ListTile(
                      leading: Icon(
                        isIn ? Icons.arrow_downward : Icons.arrow_upward,
                        color: c,
                      ),
                      title: Text(
                        '${isIn ? "Cash In" : "Cash Out"} ${formatMoney(e.amount)}',
                        style: TextStyle(
                            color: c, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${e.category} · ${dateFmt.format(e.entryDate)}'
                        '${e.note != null ? " · ${e.note}" : ""}',
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/cash/new'),
        icon: const Icon(Icons.add),
        label: const Text('Add entry'),
      ),
    );
  }
}

class _CashTotalsBar extends StatelessWidget {
  final double cashIn;
  final double cashOut;
  final double balance;
  final String? error;
  const _CashTotalsBar({
    required this.cashIn,
    required this.cashOut,
    required this.balance,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Column(
        children: [
          Text('Cash in hand',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(
            formatMoney(balance),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: balance >= 0
                      ? AppColors.digiGreen
                      : AppColors.digiError,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _Chip(
                  label: 'In',
                  amount: cashIn,
                  color: AppColors.digiGreen,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Chip(
                  label: 'Out',
                  amount: cashOut,
                  color: AppColors.digiError,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  const _Chip(
      {required this.label, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('$label: ',
              style: TextStyle(color: color, fontWeight: FontWeight.w500)),
          Text(formatMoney(amount),
              style: TextStyle(color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
