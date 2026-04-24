import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/db/database.dart';
import '../../data/db/database_provider.dart';
import 'clients_providers.dart';

class ClientFormScreen extends ConsumerStatefulWidget {
  /// null = new client.
  final int? clientId;
  const ClientFormScreen({super.key, this.clientId});

  @override
  ConsumerState<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends ConsumerState<ClientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  bool _loaded = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final db = ref.read(appDatabaseProvider);
    final bizId = await ref.read(currentBusinessIdProvider.future);
    final phone = _phone.text.trim();
    final address = _address.text.trim();
    if (widget.clientId == null) {
      await db.clientsDao.insertClient(
        ClientsCompanion.insert(
          businessId: bizId,
          name: _name.text.trim(),
          phone: Value(phone.isEmpty ? null : phone),
          address: Value(address.isEmpty ? null : address),
        ),
      );
    } else {
      final existing = await db.clientsDao.findById(widget.clientId!);
      if (existing != null) {
        await db.clientsDao.updateClient(existing.copyWith(
          name: _name.text.trim(),
          phone: Value(phone.isEmpty ? null : phone),
          address: Value(address.isEmpty ? null : address),
        ));
      }
    }
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.clientId != null;
    if (isEdit && !_loaded) {
      final async = ref.watch(clientByIdProvider(widget.clientId!));
      async.whenData((c) {
        if (c != null && !_loaded) {
          _name.text = c.name;
          _phone.text = c.phone ?? '';
          _address.text = c.address ?? '';
          _loaded = true;
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit customer' : 'Add customer'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _address,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: Text(isEdit ? 'Save changes' : 'Add customer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
