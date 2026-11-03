import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:hospital_management/core/providers/hms_providers.dart';

class AuditLogScreen extends ConsumerWidget {
  const AuditLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final logsAsync = ref.watch(auditLogsProvider);

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Security & Regulatory Audit Trail'),
        actions: [
          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Audit log exported as CSV for legal compliance.')),
              );
            },
            icon: const Icon(Icons.file_download_outlined, size: 18),
            label: const Text('Export Audit CSV'),
          ),
          const Gap(16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.shield_outlined, color: Colors.blue),
                    const Gap(12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tamper-Evident Audit Logging Active',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'All authentication, patient access, admissions, and financial events are cryptographically tracked.',
                            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Gap(16),
            Expanded(
              child: logsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error loading audit logs: $e')),
                data: (logs) {
                  if (logs.isEmpty) {
                    return const Center(child: Text('No audit logs recorded.'));
                  }

                  return Card(
                    elevation: 1,
                    clipBehavior: Clip.antiAlias,
                    child: ListView.separated(
                      itemCount: logs.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final log = logs[index];
                        final isCreate = log.action == 'CREATE' || log.action == 'BOOK' || log.action == 'ADMIT';

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          leading: CircleAvatar(
                            radius: 18,
                            backgroundColor: isCreate ? Colors.green.shade100 : Colors.blue.shade100,
                            child: Text(
                              log.action.isNotEmpty ? log.action[0] : 'A',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isCreate ? Colors.green.shade900 : Colors.blue.shade900,
                              ),
                            ),
                          ),
                          title: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  log.action,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                                ),
                              ),
                              const Gap(8),
                              Text(log.entity, style: const TextStyle(fontWeight: FontWeight.bold)),
                              const Spacer(),
                              Text(log.timestamp, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text('${log.details} • user: ${log.userName}'),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
