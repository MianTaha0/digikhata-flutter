import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/format/money.dart';
import '../../core/theme/colors.dart';
import 'expenses_providers.dart';

class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalAsync = ref.watch(expensesTotalProvider);
    final entriesAsync = ref.watch(expensesEntriesProvider);
    final dateFmt = DateFormat('d MMM, h:mm a');

    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Column(
              children: [
                Text('Total expenses',
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 4),
                Text(
                  formatMoney(totalAsync.value ?? 0),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.digiError,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
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
                        'No expenses yet.\nTap + to add one.',
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
                    return ListTile(
                      leading: const Icon(Icons.money_off,
                          color: AppColors.digiError),
                      title: Text(
                        '${e.category} · ${formatMoney(e.amount)}',
                        style: const TextStyle(
                            color: AppColors.digiError,
                            fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${e.paymentMethod} · ${dateFmt.format(e.entryDate)}'
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
        onPressed: () => context.push('/expenses/new'),
        icon: const Icon(Icons.add),
        label: const Text('Add expense'),
      ),
    );
  }
}
