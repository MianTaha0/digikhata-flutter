import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/db/database.dart';
import '../../data/db/database_provider.dart';
import '../clients/clients_providers.dart';
import 'stock_providers.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  final int? productId;
  const ProductFormScreen({super.key, this.productId});

  @override
  ConsumerState<ProductFormScreen> createState() =>
      _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _sku = TextEditingController();
  final _cost = TextEditingController(text: '0');
  final _sell = TextEditingController(text: '0');
  final _qty = TextEditingController(text: '0');
  final _threshold = TextEditingController(text: '0');
  final _unit = TextEditingController(text: 'pcs');
  bool _loaded = false;

  @override
  void dispose() {
    _name.dispose();
    _sku.dispose();
    _cost.dispose();
    _sell.dispose();
    _qty.dispose();
    _threshold.dispose();
    _unit.dispose();
    super.dispose();
  }

  double _num(TextEditingController c) =>
      double.tryParse(c.text.trim()) ?? 0;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final db = ref.read(appDatabaseProvider);
    final bizId = await ref.read(currentBusinessIdProvider.future);
    final sku = _sku.text.trim();
    if (widget.productId == null) {
      await db.productsDao.insertProduct(ProductsCompanion.insert(
        businessId: bizId,
        name: _name.text.trim(),
        sku: Value(sku.isEmpty ? null : sku),
        costPrice: Value(_num(_cost)),
        sellPrice: Value(_num(_sell)),
        quantity: Value(_num(_qty)),
        lowStockThreshold: Value(_num(_threshold)),
        unit: Value(_unit.text.trim().isEmpty ? 'pcs' : _unit.text.trim()),
      ));
    } else {
      final existing =
          await db.productsDao.findById(widget.productId!);
      if (existing != null) {
        await db.productsDao.updateProduct(existing.copyWith(
          name: _name.text.trim(),
          sku: Value(sku.isEmpty ? null : sku),
          costPrice: _num(_cost),
          sellPrice: _num(_sell),
          quantity: _num(_qty),
          lowStockThreshold: _num(_threshold),
          unit: _unit.text.trim().isEmpty ? 'pcs' : _unit.text.trim(),
        ));
      }
    }
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.productId != null;
    if (isEdit && !_loaded) {
      ref.watch(productByIdProvider(widget.productId!)).whenData((p) {
        if (p != null && !_loaded) {
          _name.text = p.name;
          _sku.text = p.sku ?? '';
          _cost.text = p.costPrice.toString();
          _sell.text = p.sellPrice.toString();
          _qty.text = p.quantity.toString();
          _threshold.text = p.lowStockThreshold.toString();
          _unit.text = p.unit;
          _loaded = true;
        }
      });
    }

    InputDecoration deco(String label) =>
        InputDecoration(labelText: label, border: const OutlineInputBorder());

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit product' : 'Add product'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _name,
                decoration: deco('Name *'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Name is required'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                  controller: _sku, decoration: deco('SKU (optional)')),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _cost,
                    decoration: deco('Cost price'),
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _sell,
                    decoration: deco('Sell price'),
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _qty,
                    decoration: deco('Quantity'),
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _unit,
                    decoration: deco('Unit'),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              TextFormField(
                controller: _threshold,
                decoration: deco('Low-stock threshold'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: Text(isEdit ? 'Save changes' : 'Add product'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
