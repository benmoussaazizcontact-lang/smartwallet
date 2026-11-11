import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/admin_support_request.dart';
import '../repositories/admin_repository.dart';

class AdminSupportScreen extends ConsumerStatefulWidget {
  const AdminSupportScreen({super.key});
  @override
  ConsumerState<AdminSupportScreen> createState() => _AdminSupportScreenState();
}

class _AdminSupportScreenState extends ConsumerState<AdminSupportScreen> {
  String? _status;

  @override
  Widget build(BuildContext context) {
    final requests = ref.watch(adminSupportRequestsProvider(_status));
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.filter_list,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Filtrer',
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 10),
                  DropdownButton<String?>(
                    value: _status,
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Toutes')),
                      DropdownMenuItem(value: 'open', child: Text('Ouvertes')),
                      DropdownMenuItem(
                        value: 'in_progress',
                        child: Text('En cours'),
                      ),
                      DropdownMenuItem(
                        value: 'resolved',
                        child: Text('Résolues'),
                      ),
                      DropdownMenuItem(value: 'closed', child: Text('Fermées')),
                    ],
                    onChanged: (value) => setState(() => _status = value),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Actualiser',
                    onPressed: () =>
                        ref.invalidate(adminSupportRequestsProvider(_status)),
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: requests.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _error(
              context,
              'Chargement impossible : $e',
              () => ref.invalidate(adminSupportRequestsProvider(_status)),
            ),
            data: (items) => items.isEmpty
                ? const Center(child: Text('Aucune demande pour ce filtre.'))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) => _RequestTile(
                      request: items[index],
                      onSaved: () {
                        ref.invalidate(adminSupportRequestsProvider(_status));
                        ref.invalidate(adminUserMetricsProvider);
                        ref.invalidate(adminAuditLogProvider);
                      },
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _RequestTile extends ConsumerWidget {
  const _RequestTile({required this.request, required this.onSaved});
  final AdminSupportRequest request;
  final VoidCallback onSaved;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: request.requestType == 'account_deletion'
              ? Theme.of(context).colorScheme.error.withValues(alpha: .12)
              : Theme.of(context).colorScheme.primary.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(
          request.requestType == 'account_deletion'
              ? Icons.delete_outline
              : Icons.support_agent,
          color: request.requestType == 'account_deletion'
              ? Theme.of(context).colorScheme.error
              : Theme.of(context).colorScheme.primary,
        ),
      ),
      title: Text(
        request.subject,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${request.email}\n${request.message}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      isThreeLine: true,
      trailing: _RequestStatus(status: request.status),
      onTap: () => _editRequest(context, ref),
    ),
  );

  Future<void> _editRequest(BuildContext context, WidgetRef ref) async {
    final responseController = TextEditingController(
      text: request.response ?? '',
    );
    var status = request.status;
    final date = DateFormat.yMMMd('fr')
        .add_Hm()
        .format(request.createdAt.toLocal());
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            request.requestType == 'account_deletion'
                ? 'Demande de suppression'
                : 'Demande d’assistance',
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${request.email}\n$date\n\n${request.message}'),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: status,
                    decoration: const InputDecoration(labelText: 'État'),
                    items: const [
                      DropdownMenuItem(value: 'open', child: Text('Ouverte')),
                      DropdownMenuItem(
                        value: 'in_progress',
                        child: Text('En cours'),
                      ),
                      DropdownMenuItem(
                        value: 'resolved',
                        child: Text('Résolue'),
                      ),
                      DropdownMenuItem(value: 'closed', child: Text('Fermée')),
                    ],
                    onChanged: (value) {
                      if (value != null) setDialogState(() => status = value);
                    },
                  ),
                  TextField(
                    controller: responseController,
                    maxLines: 4,
                    maxLength: 5000,
                    decoration: const InputDecoration(
                      labelText: 'Réponse interne / suivi',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            if (request.requestType == 'account_deletion' &&
                request.email.isNotEmpty &&
                !request.email.startsWith('('))
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () {
                  Navigator.pop(dialogContext, false);
                  _confirmAndDelete(context, ref);
                },
                child: const Text('Traiter et supprimer'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
    final response = responseController.text;
    responseController.dispose();
    if (saved != true) return;
    try {
      await ref
          .read(adminRepositoryProvider)
          .updateSupportRequest(
            requestId: request.id,
            status: status,
            response: response,
          );
      onSaved();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Demande mise à jour.')));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Mise à jour échouée : $error')));
      }
    }
  }

  Future<void> _confirmAndDelete(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final email = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer le compte'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cette action efface les données liées au compte de ${request.email}. Elle est irréversible. Saisissez son adresse exacte.',
            ),
            TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: 'E-mail exact'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (email?.toLowerCase() != request.email.toLowerCase()) return;
    try {
      await ref
          .read(adminRepositoryProvider)
          .performUserAction(
            action: 'delete',
            userId: request.userId,
            confirmEmail: email,
          );
      onSaved();
      if (context.mounted) {
        ref.invalidate(adminUserListProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Compte supprimé et données de l’utilisateur effacées.',
            ),
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Suppression non effectuée : $error')),
        );
      }
    }
  }
}

class _RequestStatus extends StatelessWidget {
  const _RequestStatus({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'open' => ('Ouverte', const Color(0xFFFFB74D)),
      'in_progress' => ('En cours', Theme.of(context).colorScheme.primary),
      'resolved' => ('Résolue', const Color(0xFF35C99A)),
      'closed' => ('Fermée', Theme.of(context).colorScheme.onSurfaceVariant),
      _ => (status, Theme.of(context).colorScheme.onSurfaceVariant),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

Widget _error(BuildContext context, String message, VoidCallback retry) =>
    Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: retry, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
