import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format/money.dart';
import '../../core/theme/colors.dart';
import 'clients_providers.dart';

class ClientsListScreen extends ConsumerWidget {
  const ClientsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientsAsync = ref.watch(clientsWithBalanceProvider);
    final totalsAsync = ref.watch(businessTotalsProvider);

    return Scaffold(
      body: Column(
        children: [
          totalsAsync.when(
            data: (t) => _TotalsStrip(youGave: t.youGave, youGot: t.youGot),
            loading: () => const _TotalsStrip(youGave: 0, youGot: 0),
            error: (e, _) => _TotalsStrip(youGave: 0, youGot: 0, error: '$e'),
          ),
          Expanded(
            child: clientsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (rows) {
                if (rows.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No customers yet.\nTap + to add one.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final r = rows[i];
                    final bal = r.balance;
                    final color = bal > 0
                        ? AppColors.digiGreen
                        : (bal < 0 ? AppColors.digiError : Colors.grey);
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          r.client.name.isNotEmpty
                              ? r.client.name[0].toUpperCase()
                              : '?',
                        ),
                      ),
                      title: Text(r.client.name),
                      subtitle: r.client.phone != null
                          ? Text(r.client.phone!)
                          : null,
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            formatMoney(bal),
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            bal > 0
                                ? 'will get'
                                : (bal < 0 ? 'will give' : 'settled'),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      onTap: () =>
                          context.push('/clients/${r.client.id}'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/clients/new'),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add customer'),
      ),
    );
  }
}

class _TotalsStrip extends StatelessWidget {
  final double youGave;
  final double youGot;
  final String? error;
  const _TotalsStrip({
    required this.youGave,
    required this.youGot,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          Expanded(
            child: _Cell(
              label: "You'll give",
              amount: youGave,
              color: AppColors.digiError,
            ),
          ),
          Container(
            height: 40,
            width: 1,
            color: Theme.of(context).dividerColor,
          ),
          Expanded(
            child: _Cell(
              label: "You'll get",
              amount: youGot,
              color: AppColors.digiGreen,
            ),
          ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  const _Cell({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(
          formatMoney(amount),
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(color: color, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
