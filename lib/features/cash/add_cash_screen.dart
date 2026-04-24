import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/colors.dart';
import '../../data/db/database.dart';
import '../../data/db/database_provider.dart';
import '../clients/clients_providers.dart';

class AddCashScreen extends ConsumerStatefulWidget {
  const AddCashScreen({super.key});

  @override
  ConsumerState<AddCashScreen> createState() => _AddCashScreenState();
}

class _AddCashScreenState extends ConsumerState<AddCashScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _category = TextEditingController(text: 'General');
  final _note = TextEditingController();
  int _type = 1; // 1 = in, 0 = out

  @override
  void dispose() {
    _amount.dispose();
    _category.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final db = ref.read(appDatabaseProvider);
    final bizId = await ref.read(currentBusinessIdProvider.future);
    final note = _note.text.trim();
    await db.cashDao.insertEntry(CashEntriesCompanion.insert(
      businessId: bizId,
      amount: double.parse(_amount.text.trim()),
      type: _type,
      category: Value(_category.text.trim().isEmpty
          ? 'General'
          : _category.text.trim()),
      note: Value(note.isEmpty ? null : note),
      entryDate: DateTime.now(),
    ));
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isIn = _type == 1;
    final color = isIn ? AppColors.digiGreen : AppColors.digiError;
    return Scaffold(
      appBar: AppBar(title: const Text('Add cash entry')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 1, label: Text('Cash In')),
                  ButtonSegment(value: 0, label: Text('Cash Out')),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() => _type = s.first),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amount,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixText: 'Rs ',
                  border: const OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: color, width: 2),
                  ),
                ),
                validator: (v) {
                  final n = double.tryParse((v ?? '').trim());
                  if (n == null || n <= 0) return 'Enter a valid amount';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _note,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: color),
                onPressed: _save,
                icon: const Icon(Icons.check),
                label: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
