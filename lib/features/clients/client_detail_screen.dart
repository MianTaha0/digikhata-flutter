import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../../core/format/money.dart';
import '../../core/theme/colors.dart';
import '../backup/backup_providers.dart';
import 'clients_providers.dart';

class ClientDetailScreen extends ConsumerWidget {
  final int clientId;
  const ClientDetailScreen({super.key, required this.clientId});

  Future<void> _printStatement(WidgetRef ref) async {
    final pdf = await ref.read(pdfServiceProvider).buildClientStatement(clientId);
    final bytes = await pdf.save();
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'ledger-$clientId.pdf',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientAsync = ref.watch(clientByIdProvider(clientId));
    final txsAsync = ref.watch(clientTransactionsProvider(clientId));
    final dateFmt = DateFormat('d MMM, h:mm a');

    return Scaffold(
      appBar: AppBar(
        title: clientAsync.when(
          data: (c) => Text(c?.name ?? 'Customer'),
          loading: () => const Text('Customer'),
          error: (_, __) => const Text('Customer'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Export PDF statement',
            onPressed: () => _printStatement(ref),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/clients/$clientId/edit'),
          ),
        ],
      ),
      body: txsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (txs) {
          final balance = txs.fold<double>(
            0,
            (sum, t) => sum + (t.type == 1 ? t.amount : -t.amount),
          );
          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Column(
                  children: [
                    Text(
                      balance == 0
                          ? 'Settled'
                          : (balance > 0 ? 'Will get' : 'Will give'),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatMoney(balance),
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(
                            color: balance > 0
                                ? AppColors.digiGreen
                                : (balance < 0
                                    ? AppColors.digiError
                                    : Colors.grey),
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: txs.isEmpty
                    ? const Center(child: Text('No transactions yet.'))
                    : ListView.separated(
                        itemCount: txs.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final t = txs[i];
                          final isGot = t.type == 1;
                          return ListTile(
                            leading: Icon(
                              isGot
                                  ? Icons.arrow_downward
                                  : Icons.arrow_upward,
                              color: isGot
                                  ? AppColors.digiGreen
                                  : AppColors.digiError,
                            ),
                            title: Text(
                              '${isGot ? "You got" : "You gave"} ${formatMoney(t.amount)}',
                              style: TextStyle(
                                color: isGot
                                    ? AppColors.digiGreen
                                    : AppColors.digiError,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              '${dateFmt.format(t.entryDate)}${t.notes != null ? " · ${t.notes}" : ""}',
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.digiError,
                  ),
                  onPressed: () =>
                      context.push('/clients/$clientId/tx/new?type=0'),
                  icon: const Icon(Icons.arrow_upward),
                  label: const Text('You gave'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.digiGreen,
                  ),
                  onPressed: () =>
                      context.push('/clients/$clientId/tx/new?type=1'),
                  icon: const Icon(Icons.arrow_downward),
                  label: const Text('You got'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
