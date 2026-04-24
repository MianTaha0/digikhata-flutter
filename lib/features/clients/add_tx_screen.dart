import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/colors.dart';
import '../../data/db/database.dart';
import '../../data/db/database_provider.dart';
import 'clients_providers.dart';

class AddTxScreen extends ConsumerStatefulWidget {
  final int clientId;

  /// 0 = you gave, 1 = you got.
  final int type;
  const AddTxScreen({super.key, required this.clientId, required this.type});

  @override
  ConsumerState<AddTxScreen> createState() => _AddTxScreenState();
}

class _AddTxScreenState extends ConsumerState<AddTxScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _notes = TextEditingController();

  @override
  void dispose() {
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final db = ref.read(appDatabaseProvider);
    final bizId = await ref.read(currentBusinessIdProvider.future);
    final amount = double.parse(_amount.text.trim());
    final notes = _notes.text.trim();
    await db.transactionsDao.insertTx(TransactionsCompanion.insert(
      clientId: widget.clientId,
      businessId: bizId,
      amount: amount,
      type: widget.type,
      entryDate: DateTime.now(),
      notes: Value(notes.isEmpty ? null : notes),
    ));
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isGot = widget.type == 1;
    final color = isGot ? AppColors.digiGreen : AppColors.digiError;
    return Scaffold(
      appBar: AppBar(
        title: Text(isGot ? 'You got' : 'You gave'),
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _amount,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: Theme.of(context).textTheme.headlineMedium,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixText: 'Rs ',
                  border: const OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: color, width: 2),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter an amount';
                  final n = double.tryParse(v.trim());
                  if (n == null || n <= 0) return 'Enter a valid amount';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notes,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
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
