import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../repositories/admin_repository.dart';

class AdminAuditScreen extends ConsumerWidget {
  const AdminAuditScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(adminAuditLogProvider);
    return events.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Journal indisponible.'),
              Text(error.toString()),
              OutlinedButton(
                onPressed: () => ref.invalidate(adminAuditLogProvider),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
      data: (items) => items.isEmpty
          ? const Center(
              child: Text('Aucune action administrateur enregistrée.'),
            )
          : RefreshIndicator(
              onRefresh: () async => ref.invalidate(adminAuditLogProvider),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final date = DateFormat.yMMMd('fr')
                      .add_Hm()
                      .format(item.createdAt.toLocal());
                  return Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      leading: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary
                              .withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(
                          _actionIcon(item.action),
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      title: Text(
                        _actionLabel(item.action),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${item.actorEmail ?? 'Administrateur supprimé'}\n$date${item.targetUserId == null ? '' : '\nCompte cible : ${item.targetUserId}'}',
                      ),
                      isThreeLine: item.targetUserId != null,
                      trailing: item.metadata.isEmpty
                          ? null
                          : const Icon(Icons.chevron_right),
                      onTap: item.metadata.isEmpty
                          ? null
                          : () => showDialog<void>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Détails de l’action'),
                                content: SelectableText(
                                  item.metadata.toString(),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Fermer'),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

String _actionLabel(String action) => switch (action) {
  'user_role_changed' => 'Rôle modifié',
  'user_suspended' => 'Compte suspendu',
  'user_reactivated' => 'Compte réactivé',
  'user_deleted' => 'Compte supprimé',
  'support_request_updated' => 'Demande d’assistance mise à jour',
  'admin_action_failed' => 'Action administrateur échouée',
  _ => action,
};

IconData _actionIcon(String action) => switch (action) {
  'user_role_changed' => Icons.manage_accounts_outlined,
  'user_suspended' => Icons.block_outlined,
  'user_reactivated' => Icons.check_circle_outline,
  'user_deleted' => Icons.delete_outline,
  'support_request_updated' => Icons.support_agent,
  'admin_action_failed' => Icons.warning_amber_outlined,
  _ => Icons.history,
};
