import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format/money.dart';
import '../../core/theme/colors.dart';
import '../../data/db/daos/invoices_dao.dart';
import '../../data/db/database.dart';
import '../../data/db/database_provider.dart';
import '../clients/clients_providers.dart';
import '../stock/stock_providers.dart';

class _Line {
  final TextEditingController name;
  final TextEditingController qty;
  final TextEditingController price;
  int? productId;
  _Line({String name = '', double qty = 1, double price = 0})
      : name = TextEditingController(text: name),
        qty = TextEditingController(text: qty.toString()),
        price = TextEditingController(text: price.toString());
  void dispose() {
    name.dispose();
    qty.dispose();
    price.dispose();
  }

  double get qtyVal => double.tryParse(qty.text.trim()) ?? 0;
  double get priceVal => double.tryParse(price.text.trim()) ?? 0;
  double get total => qtyVal * priceVal;
}

class InvoiceFormScreen extends ConsumerStatefulWidget {
  const InvoiceFormScreen({super.key});

  @override
  ConsumerState<InvoiceFormScreen> createState() =>
      _InvoiceFormScreenState();
}

class _InvoiceFormScreenState extends ConsumerState<InvoiceFormScreen> {
  int? _customerId;
  final _notes = TextEditingController();
  final _amountPaid = TextEditingController(text: '0');
  final List<_Line> _lines = [_Line()];

  @override
  void dispose() {
    for (final l in _lines) {
      l.dispose();
    }
    _notes.dispose();
    _amountPaid.dispose();
    super.dispose();
  }

  double get _subtotal =>
      _lines.fold<double>(0, (s, l) => s + l.total);

  Future<void> _pickProduct(_Line line) async {
    final products = await ref.read(productsProvider.future);
    if (!mounted || products.isEmpty) return;
    final picked = await showModalBottomSheet<Product>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          children: products
              .map((p) => ListTile(
                    title: Text(p.name),
                    subtitle: Text(
                      'In stock: ${p.quantity} ${p.unit} · ${formatMoney(p.sellPrice)}',
                    ),
                    onTap: () => Navigator.pop(ctx, p),
                  ))
              .toList(),
        ),
      ),
    );
    if (picked != null) {
      setState(() {
        line.name.text = picked.name;
        line.price.text = picked.sellPrice.toString();
        line.productId = picked.id;
      });
    }
  }

  Future<void> _save() async {
    if (_customerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick a customer')),
      );
      return;
    }
    final validLines = _lines
        .where((l) =>
            l.name.text.trim().isNotEmpty && l.qtyVal > 0 && l.priceVal >= 0)
        .toList();
    if (validLines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one line')),
      );
      return;
    }
    final db = ref.read(appDatabaseProvider);
    final bizId = await ref.read(currentBusinessIdProvider.future);
    await db.invoicesDao.createInvoice(
      businessId: bizId,
      customerId: _customerId!,
      issueDate: DateTime.now(),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      amountPaid: double.tryParse(_amountPaid.text.trim()) ?? 0,
      lines: validLines
          .map((l) => InvoiceLineDraft(
                name: l.name.text.trim(),
                quantity: l.qtyVal,
                unitPrice: l.priceVal,
                productId: l.productId,
              ))
          .toList(),
    );
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientsWithBalanceProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('New invoice'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _save,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          clientsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (e, _) => Text('Error: $e'),
            data: (rows) {
              return DropdownButtonFormField<int>(
                initialValue: _customerId,
                decoration: const InputDecoration(
                  labelText: 'Customer *',
                  border: OutlineInputBorder(),
                ),
                items: rows
                    .map((r) => DropdownMenuItem(
                          value: r.client.id,
                          child: Text(r.client.name),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _customerId = v),
              );
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text('Line items',
                  style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              TextButton.icon(
                onPressed: () => setState(() => _lines.add(_Line())),
                icon: const Icon(Icons.add),
                label: const Text('Add line'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...List.generate(_lines.length, (i) {
            final line = _lines[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: line.name,
                            decoration: const InputDecoration(
                              labelText: 'Item',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'From products',
                          icon: const Icon(Icons.inventory_2_outlined),
                          onPressed: () => _pickProduct(line),
                        ),
                        if (_lines.length > 1)
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => setState(() {
                              line.dispose();
                              _lines.removeAt(i);
                            }),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: line.qty,
                            decoration: const InputDecoration(
                              labelText: 'Qty',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: line.price,
                            decoration: const InputDecoration(
                              labelText: 'Price',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            formatMoney(line.total),
                            textAlign: TextAlign.end,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    if (line.productId != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.link,
                                size: 14, color: AppColors.digiGreen),
                            const SizedBox(width: 4),
                            Text(
                              'Stock will decrement',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.digiGreen),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Text('Subtotal',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                Text(formatMoney(_subtotal),
                    style:
                        const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountPaid,
            decoration: const InputDecoration(
              labelText: 'Amount paid',
              prefixText: 'Rs ',
              border: OutlineInputBorder(),
            ),
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notes,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: const Text('Create invoice'),
          ),
        ],
      ),
    );
  }
}
