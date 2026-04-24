import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/format/money.dart';
import '../clients/clients_providers.dart';
import 'invoices_providers.dart';

class InvoicesListScreen extends ConsumerWidget {
  const InvoicesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoicesAsync = ref.watch(invoicesProvider);
    final clientsAsync = ref.watch(clientsWithBalanceProvider);
    final dateFmt = DateFormat('d MMM yyyy');

    return Scaffold(
      body: invoicesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No invoices yet.\nTap + to create one.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          // map clientId -> name (no n+1 lookups)
          final names = <int, String>{};
          for (final c in clientsAsync.value ?? const []) {
            names[c.client.id] = c.client.name;
          }
          return ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final inv = list[i];
              final name = names[inv.customerId] ?? 'Customer #${inv.customerId}';
              return ListTile(
                leading: CircleAvatar(
                  child: Text('#${inv.sequenceNumber}'),
                ),
                title: Text(name),
                subtitle:
                    Text('Issued ${dateFmt.format(inv.issueDate)}'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatMoney(inv.amountPaid),
                      style:
                          const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text('paid',
                        style:
                            Theme.of(context).textTheme.bodySmall),
                  ],
                ),
                onTap: () => context.push('/invoices/${inv.id}'),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/invoices/new'),
        icon: const Icon(Icons.receipt_long),
        label: const Text('New invoice'),
      ),
    );
  }
}
