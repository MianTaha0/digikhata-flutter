import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/format/money.dart';
import '../../core/theme/colors.dart';
import '../../data/db/database_provider.dart';
import 'stock_providers.dart';

class ProductDetailScreen extends ConsumerWidget {
  final int productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productByIdProvider(productId));
    final movesAsync = ref.watch(stockMovementsProvider(productId));
    final dateFmt = DateFormat('d MMM, h:mm a');

    return Scaffold(
      appBar: AppBar(
        title: productAsync.when(
          data: (p) => Text(p?.name ?? 'Product'),
          loading: () => const Text('Product'),
          error: (_, __) => const Text('Product'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/products/$productId/edit'),
          ),
        ],
      ),
      body: productAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (p) {
          if (p == null) return const Center(child: Text('Not found'));
          final low = p.quantity <= p.lowStockThreshold;
          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Column(
                  children: [
                    Text(
                      '${p.quantity} ${p.unit} in stock',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(
                            color: low ? AppColors.digiError : null,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 16,
                      children: [
                        Text('Cost: ${formatMoney(p.costPrice)}'),
                        Text('Sell: ${formatMoney(p.sellPrice)}'),
                        if (p.sku != null) Text('SKU: ${p.sku}'),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Stock in'),
                        onPressed: () =>
                            _adjustDialog(context, ref, productId, sign: 1),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.remove),
                        label: const Text('Stock out'),
                        onPressed: () =>
                            _adjustDialog(context, ref, productId, sign: -1),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: movesAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (moves) {
                    if (moves.isEmpty) {
                      return const Center(
                          child: Text('No stock movements yet.'));
                    }
                    return ListView.separated(
                      itemCount: moves.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final m = moves[i];
                        final positive = m.delta > 0;
                        return ListTile(
                          leading: Icon(
                            positive
                                ? Icons.arrow_downward
                                : Icons.arrow_upward,
                            color: positive
                                ? AppColors.digiGreen
                                : AppColors.digiError,
                          ),
                          title: Text(
                            '${positive ? "+" : ""}${m.delta}',
                            style: TextStyle(
                              color: positive
                                  ? AppColors.digiGreen
                                  : AppColors.digiError,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            '${dateFmt.format(m.createdAt)}'
                            '${m.reason != null ? " · ${m.reason}" : ""}',
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

Future<void> _adjustDialog(
  BuildContext context,
  WidgetRef ref,
  int productId, {
  required int sign,
}) async {
  final qtyCtl = TextEditingController();
  final reasonCtl = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(sign > 0 ? 'Stock in' : 'Stock out'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: qtyCtl,
            autofocus: true,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Quantity'),
          ),
          TextField(
            controller: reasonCtl,
            decoration:
                const InputDecoration(labelText: 'Reason (optional)'),
          ),
        ],
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
  final qty = double.tryParse(qtyCtl.text.trim());
  if (qty == null || qty <= 0) return;
  final reason = reasonCtl.text.trim();
  await ref.read(appDatabaseProvider).productsDao.adjustStock(
        productId: productId,
        delta: sign * qty,
        reason: reason.isEmpty
            ? (sign > 0 ? 'Stock in' : 'Stock out')
            : reason,
      );
}
