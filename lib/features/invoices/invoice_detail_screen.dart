import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../../core/format/money.dart';
import '../../core/theme/colors.dart';
import '../../data/db/database_provider.dart';
import '../backup/backup_providers.dart';
import 'invoices_providers.dart';

class InvoiceDetailScreen extends ConsumerWidget {
  final int invoiceId;
  const InvoiceDetailScreen({super.key, required this.invoiceId});

  Future<void> _printInvoice(WidgetRef ref) async {
    final pdf = await ref.read(pdfServiceProvider).buildInvoice(invoiceId);
    final bytes = await pdf.save();
    await Printing.sharePdf(bytes: bytes, filename: 'invoice-$invoiceId.pdf');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(invoiceWithItemsProvider(invoiceId));
    final dateFmt = DateFormat('d MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Export PDF',
            onPressed: () => _printInvoice(ref),
          ),
        ],
      ),
      body: dataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (data) {
          if (data == null) return const Center(child: Text('Not found'));
          final inv = data.invoice;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Text('#${inv.sequenceNumber}',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text(dateFmt.format(inv.issueDate)),
                ],
              ),
              const SizedBox(height: 4),
              Text(data.customerName,
                  style: Theme.of(context).textTheme.titleMedium),
              const Divider(height: 24),
              ...data.items.map((item) {
                final lineTotal = item.quantity *
                    item.unitPrice *
                    (1 + item.taxPercent / 100);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            Text(
                              '${item.quantity} × ${formatMoney(item.unitPrice)}'
                              '${item.taxPercent > 0 ? " · ${item.taxPercent}% tax" : ""}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          formatMoney(lineTotal),
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const Divider(height: 24),
              _row(context, 'Subtotal', formatMoney(data.subtotal)),
              if (data.discountAmount > 0)
                _row(context, 'Discount',
                    '- ${formatMoney(data.discountAmount)}'),
              _row(context, 'Total', formatMoney(data.total),
                  bold: true, large: true),
              const SizedBox(height: 8),
              _row(context, 'Paid', formatMoney(inv.amountPaid),
                  color: AppColors.digiGreen),
              if (data.balanceDue > 0)
                _row(context, 'Balance', formatMoney(data.balanceDue),
                    color: AppColors.digiError, bold: true),
              if (inv.notes != null) ...[
                const Divider(height: 24),
                Text('Notes', style: Theme.of(context).textTheme.bodySmall),
                Text(inv.notes!),
              ],
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => _payDialog(context, ref, data),
                icon: const Icon(Icons.payments_outlined),
                label: const Text('Record payment'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _row(BuildContext c, String l, String v,
      {bool bold = false, bool large = false, Color? color}) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
      fontSize: large ? 18 : 14,
      color: color,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(l, style: style),
          const Spacer(),
          Text(v, style: style),
        ],
      ),
    );
  }
}

Future<void> _payDialog(
    BuildContext context, WidgetRef ref, dynamic data) async {
  final ctl = TextEditingController(text: data.invoice.amountPaid.toString());
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Record payment'),
      content: TextField(
        controller: ctl,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(labelText: 'Amount paid (total)'),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel')),
        FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save')),
      ],
    ),
  );
  if (ok != true) return;
  final amount = double.tryParse(ctl.text.trim()) ?? 0;
  await ref
      .read(appDatabaseProvider)
      .invoicesDao
      .updatePayment(data.invoice.id, amount);
  ref.invalidate(invoiceWithItemsProvider(data.invoice.id));
}
