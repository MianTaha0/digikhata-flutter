import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/db/database.dart';
import '../../data/db/database_provider.dart';
import '../clients/clients_providers.dart';
import 'notification_service.dart';
import 'reminders_providers.dart';

class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  static final _df = DateFormat('d MMM yyyy, h:mm a');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcomingAsync = ref.watch(upcomingRemindersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Reminders')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addDialog(context, ref),
        icon: const Icon(Icons.add_alert),
        label: const Text('New reminder'),
      ),
      body: upcomingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No upcoming reminders.\nTap "New reminder" to schedule one.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (ctx, i) {
              final r = list[i];
              return ListTile(
                leading: Icon(
                  r.kind == 1
                      ? Icons.receipt_long
                      : r.kind == 0
                          ? Icons.account_balance_wallet_outlined
                          : Icons.notifications_active_outlined,
                ),
                title: Text(r.title),
                subtitle: Text(
                  '${_df.format(r.triggerAt)}'
                  '${r.body != null ? "\n${r.body}" : ""}',
                ),
                isThreeLine: r.body != null,
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    await NotificationService.instance.cancel(r.id);
                    await ref
                        .read(appDatabaseProvider)
                        .remindersDao
                        .softDelete(r.id);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _addDialog(BuildContext context, WidgetRef ref) async {
    final titleCtl = TextEditingController();
    final bodyCtl = TextEditingController();
    DateTime when = DateTime.now().add(const Duration(hours: 1));

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: const Text('New reminder'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleCtl,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    TextField(
                      controller: bodyCtl,
                      decoration:
                          const InputDecoration(labelText: 'Note (optional)'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: Text(_df.format(when))),
                        TextButton.icon(
                          icon: const Icon(Icons.event),
                          label: const Text('Pick'),
                          onPressed: () async {
                            final d = await showDatePicker(
                              context: ctx,
                              initialDate: when,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now()
                                  .add(const Duration(days: 365 * 3)),
                            );
                            if (d == null) return;
                            if (!ctx.mounted) return;
                            final t = await showTimePicker(
                              context: ctx,
                              initialTime: TimeOfDay.fromDateTime(when),
                            );
                            if (t == null) return;
                            setState(() {
                              when = DateTime(d.year, d.month, d.day,
                                  t.hour, t.minute);
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final title = titleCtl.text.trim();
                    if (title.isEmpty) return;
                    final bizId = await ref
                        .read(currentBusinessIdProvider.future);
                    final db = ref.read(appDatabaseProvider);
                    final id = await db.remindersDao.insertReminder(
                      RemindersCompanion.insert(
                        businessId: bizId,
                        title: title,
                        body: Value(bodyCtl.text.trim().isEmpty
                            ? null
                            : bodyCtl.text.trim()),
                        triggerAt: when,
                        kind: const Value(2),
                      ),
                    );
                    await NotificationService.instance.schedule(
                      id: id,
                      title: title,
                      body: bodyCtl.text.trim(),
                      when: when,
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Schedule'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
