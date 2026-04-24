import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format/money.dart';
import '../../core/theme/colors.dart';
import 'stock_providers.dart';

class StockScreen extends ConsumerWidget {
  const StockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);
    return Scaffold(
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No products yet.\nTap + to add one.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final p = list[i];
              final low = p.quantity <= p.lowStockThreshold;
              return ListTile(
                leading: const Icon(Icons.inventory_2_outlined),
                title: Text(p.name),
                subtitle: Text(
                  'Sell: ${formatMoney(p.sellPrice)} · Cost: ${formatMoney(p.costPrice)}'
                  '${p.sku != null ? " · ${p.sku}" : ""}',
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${p.quantity.toStringAsFixed(p.quantity == p.quantity.roundToDouble() ? 0 : 2)} ${p.unit}',
                      style: TextStyle(
                        color: low ? AppColors.digiError : null,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (low)
                      const Text(
                        'low',
                        style: TextStyle(
                            color: AppColors.digiError, fontSize: 11),
                      ),
                  ],
                ),
                onTap: () => context.push('/products/${p.id}'),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/products/new'),
        icon: const Icon(Icons.add),
        label: const Text('Add product'),
      ),
    );
  }
}
