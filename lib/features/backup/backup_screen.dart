import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../clients/clients_providers.dart';
import 'backup_providers.dart';
import 'import_service.dart';

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _busy = false;
  String? _status;

  Future<void> _exportAll() async {
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      final bizId = await ref.read(currentBusinessIdProvider.future);
      final service = ref.read(exportServiceProvider);
      final dir = await service.exportAllToCsv(bizId);
      final files = dir
          .listSync()
          .whereType<File>()
          .map((f) => XFile(f.path))
          .toList();
      if (!mounted) return;
      await Share.shareXFiles(files, text: 'DigiKhata CSV export');
      setState(() => _status = 'Exported to ${dir.path}');
    } catch (e) {
      setState(() => _status = 'Export failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _importClients() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (res == null || res.files.single.path == null) return;
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      final bizId = await ref.read(currentBusinessIdProvider.future);
      final report = await ref
          .read(importServiceProvider)
          .importClients(File(res.files.single.path!), bizId);
      setState(() => _status = _fmtReport('Clients', report));
    } catch (e) {
      setState(() => _status = 'Import failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _importTransactions() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (res == null || res.files.single.path == null) return;
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      final bizId = await ref.read(currentBusinessIdProvider.future);
      final report = await ref
          .read(importServiceProvider)
          .importTransactions(File(res.files.single.path!), bizId);
      setState(() => _status = _fmtReport('Transactions', report));
    } catch (e) {
      setState(() => _status = 'Import failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _fmtReport(String label, ImportReport r) {
    final n = label == 'Clients' ? r.clients : r.transactions;
    final head = '$label imported: $n';
    if (r.errors.isEmpty) return head;
    return '$head\nErrors (${r.errors.length}):\n${r.errors.take(5).join('\n')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Restore')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Export',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  const Text(
                    'Dumps every table to CSV in one folder, then opens the system share sheet.',
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _busy ? null : _exportAll,
                    icon: const Icon(Icons.ios_share),
                    label: const Text('Export all to CSV'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Import',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  const Text(
                    'CSV with the same headers produced by Export. '
                    'Import clients first, then transactions.',
                  ),
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _importClients,
                      icon: const Icon(Icons.person_add_alt),
                      label: const Text('Import clients.csv'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _importTransactions,
                      icon: const Icon(Icons.swap_horiz),
                      label: const Text('Import transactions.csv'),
                    ),
                  ]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_busy) const LinearProgressIndicator(),
          if (_status != null) ...[
            const SizedBox(height: 12),
            Card(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(_status!),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
