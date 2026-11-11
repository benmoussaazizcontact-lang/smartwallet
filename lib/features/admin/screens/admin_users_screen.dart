import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/admin_user.dart';
import '../repositories/admin_repository.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final _search = TextEditingController();
  DateTime? _from;
  DateTime? _to;
  String? _role;
  String? _status;
  int _page = 0;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  AdminUserSearch get _filters => AdminUserSearch(
    query: _search.text.trim(),
    from: _from,
    to: _endExclusive,
    role: _role,
    status: _status,
    page: _page,
  );

  DateTime? get _endExclusive {
    final end = _to;
    return end == null ? null : DateTime(end.year, end.month, end.day + 1);
  }

  Future<void> _chooseDate({required bool start}) async {
    final initial = start ? (_from ?? DateTime.now()) : (_to ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (start) {
        _from = picked;
      } else {
        _to = picked;
      }
      _page = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final users = ref.watch(adminUserListProvider(_filters));
    final dateFormat = DateFormat.yMMMd('fr');
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.manage_search,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 9),
                      Text(
                        'Rechercher un compte',
                        style: Theme.of(context).textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _search,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => setState(() => _page = 0),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'Rechercher par nom ou e-mail',
                      suffixIcon: IconButton(
                        tooltip: 'Lancer la recherche',
                        onPressed: () => setState(() => _page = 0),
                        icon: const Icon(Icons.arrow_forward),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _chooseDate(start: true),
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text(_formatDay(_from, dateFormat, 'Depuis')),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _chooseDate(start: false),
                          icon: const Icon(Icons.event, size: 16),
                          label: Text(_formatDay(_to, dateFormat, 'Jusqu’au')),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Effacer les filtres',
                        onPressed: () => setState(() {
                          _search.clear();
                          _from = null;
                          _to = null;
                          _role = null;
                          _status = null;
                          _page = 0;
                        }),
                        icon: const Icon(Icons.filter_alt_off),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String?>(
                          initialValue: _role,
                          decoration: const InputDecoration(labelText: 'Rôle'),
                          items: const [
                            DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Tous les rôles'),
                            ),
                            DropdownMenuItem<String?>(
                              value: 'user',
                              child: Text('Utilisateur'),
                            ),
                            DropdownMenuItem<String?>(
                              value: 'admin',
                              child: Text('Administrateur'),
                            ),
                          ],
                          onChanged: (value) => setState(() {
                            _role = value;
                            _page = 0;
                          }),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String?>(
                          initialValue: _status,
                          decoration: const InputDecoration(labelText: 'État'),
                          items: const [
                            DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Tous les états'),
                            ),
                            DropdownMenuItem<String?>(
                              value: 'active',
                              child: Text('Actif'),
                            ),
                            DropdownMenuItem<String?>(
                              value: 'suspended',
                              child: Text('Suspendu'),
                            ),
                          ],
                          onChanged: (value) => setState(() {
                            _status = value;
                            _page = 0;
                          }),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: users.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _RetryMessage(
              message: 'Impossible de charger les comptes : $error',
              onRetry: () => ref.invalidate(adminUserListProvider(_filters)),
            ),
            data: (rows) => rows.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Aucun compte ne correspond à ces filtres.'),
                        if (_page > 0)
                          TextButton.icon(
                            onPressed: () => setState(() => _page--),
                            icon: const Icon(Icons.chevron_left),
                            label: const Text('Page précédente'),
                          ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    itemCount: rows.length + 1,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      if (index == rows.length) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: _page == 0
                                  ? null
                                  : () => setState(() => _page--),
                              icon: const Icon(Icons.chevron_left),
                            ),
                            Text('Page ${_page + 1}'),
                            IconButton(
                              onPressed: rows.length < 50
                                  ? null
                                  : () => setState(() => _page++),
                              icon: const Icon(Icons.chevron_right),
                            ),
                          ],
                        );
                      }
                      final user = rows[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: user.isSuspended
                                ? Theme.of(context).colorScheme.errorContainer
                                : Theme.of(context).colorScheme.primary
                                      .withValues(alpha: .13),
                            foregroundColor: user.isSuspended
                                ? Theme.of(context).colorScheme.error
                                : Theme.of(context).colorScheme.primary,
                            child: Text(
                              user.name.isNotEmpty
                                  ? user.name.characters.first.toUpperCase()
                                  : user.email.characters.firstOrNull
                                            ?.toUpperCase() ??
                                        '?',
                            ),
                          ),
                          title: Text(
                            user.name.isEmpty ? 'Sans nom' : user.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.email,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    _StatusChip(
                                      label: user.role == 'admin'
                                          ? 'Administrateur'
                                          : 'Utilisateur',
                                      icon: user.role == 'admin'
                                          ? Icons.admin_panel_settings_outlined
                                          : Icons.person_outline,
                                    ),
                                    _StatusChip(
                                      label: user.isSuspended
                                          ? 'Suspendu'
                                          : 'Actif',
                                      icon: user.isSuspended
                                          ? Icons.block
                                          : Icons.check_circle_outline,
                                      isError: user.isSuspended,
                                    ),
                                    Text(
                                      'Inscrit ${dateFormat.format(user.createdAt.toLocal())}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          isThreeLine: false,
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _showDetails(user),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _showDetails(AdminUser user) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _UserDetailsSheet(
        user: user,
        onAction: (action, {role, confirmEmail, reason, durationDays}) async {
          Navigator.of(sheetContext).pop();
          try {
            await ref
                .read(adminRepositoryProvider)
                .performUserAction(
                  action: action,
                  userId: user.id,
                  role: role,
                  confirmEmail: confirmEmail,
                  reason: reason,
                  durationDays: durationDays,
                );
            ref.invalidate(adminUserListProvider);
            ref.invalidate(adminUserMetricsProvider);
            ref.invalidate(adminAuditLogProvider);
            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Action terminée.')));
            }
          } catch (error) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Action refusée : $error')),
              );
            }
          }
        },
      ),
    );
  }
}

typedef _UserAction = Future<void> Function(
  String action, {
  String? role,
  String? confirmEmail,
  String? reason,
  int? durationDays,
});

class _UserDetailsSheet extends StatelessWidget {
  const _UserDetailsSheet({required this.user, required this.onAction});
  final AdminUser user;
  final _UserAction onAction;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat.yMMMd('fr').add_Hm();
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outline,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    child: Text(
                      user.name.isNotEmpty
                          ? user.name.characters.first.toUpperCase()
                          : user.email.characters.firstOrNull?.toUpperCase() ??
                                '?',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      user.name.isEmpty ? 'Compte utilisateur' : user.name,
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      _DetailLine('E-mail', user.email),
                      _DetailLine('Identifiant', user.id),
                      _DetailLine(
                        'Inscription',
                        fmt.format(user.createdAt.toLocal()),
                      ),
                      _DetailLine(
                        'Dernière connexion',
                        _formatDate(user.lastSignInAt, fmt),
                      ),
                      _DetailLine(
                        'E-mail confirmé',
                        user.emailConfirmedAt == null ? 'Non' : 'Oui',
                      ),
                      _DetailLine(
                        'Rôle',
                        user.role == 'admin' ? 'Administrateur' : 'Utilisateur',
                      ),
                      _DetailLine(
                        'État',
                        user.isSuspended ? 'Suspendu' : 'Actif',
                      ),
                      if (user.isSuspended) ...[
                        _DetailLine(
                          'Fin de suspension',
                          _formatDate(user.bannedUntil, fmt),
                        ),
                        _DetailLine(
                          'Motif',
                          user.suspensionReason?.trim().isNotEmpty == true
                              ? user.suspensionReason!
                              : 'Non renseigné',
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Actions du compte',
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              if (user.role != 'admin') ...[
                OutlinedButton.icon(
                  onPressed: () async {
                    final role = user.role == 'admin' ? 'user' : 'admin';
                    final ok = await _confirm(
                      context,
                      'Changer le rôle',
                      'Attribuer le rôle ${role == 'admin' ? 'administrateur' : 'utilisateur'} à ${user.email} ?',
                    );
                    if (ok) await onAction('set_role', role: role);
                  },
                  icon: const Icon(Icons.manage_accounts_outlined),
                  label: const Text('Promouvoir administrateur'),
                ),
              ] else ...[
                OutlinedButton.icon(
                  onPressed: () async {
                    final ok = await _confirm(
                      context,
                      'Rôle administrateur',
                      'Retirer le rôle administrateur de ${user.email} ? Au moins un administrateur doit rester.',
                    );
                    if (ok) await onAction('set_role', role: 'user');
                  },
                  icon: const Icon(Icons.person_outline),
                  label: const Text('Rétrograder en utilisateur'),
                ),
              ],
              if (user.role != 'admin')
                OutlinedButton.icon(
                  onPressed: () async {
                    if (user.isSuspended) {
                      final ok = await _confirm(
                        context,
                        'Réactiver le compte',
                        'Réactiver le compte de ${user.email} maintenant ?',
                      );
                      if (ok) await onAction('reactivate');
                    } else {
                      final input = await _suspensionDialog(
                        context,
                        user.email,
                      );
                      if (input != null) {
                        await onAction(
                          'suspend',
                          reason: input.reason,
                          durationDays: input.days,
                        );
                      }
                    }
                  },
                  icon: Icon(
                    user.isSuspended ? Icons.check_circle_outline : Icons.block,
                  ),
                  label: Text(user.isSuspended ? 'Réactiver' : 'Suspendre'),
                ),
              if (user.role != 'admin')
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: () async {
                    final email = await _confirmDelete(context, user.email);
                    if (email != null) {
                      await onAction('delete', confirmEmail: email);
                    }
                  },
                  icon: const Icon(Icons.delete_forever_outlined),
                  label: const Text('Supprimer le compte et ses données'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuspensionInput {
  const _SuspensionInput(this.reason, this.days);
  final String reason;
  final int days;
}

Future<_SuspensionInput?> _suspensionDialog(
  BuildContext context,
  String email,
) async {
  final reasonController = TextEditingController();
  var days = 7;
  final result = await showDialog<_SuspensionInput>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Suspendre le compte'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Le compte $email ne pourra pas se connecter pendant la période choisie.',
            ),
            const SizedBox(height: 14),
            TextField(
              controller: reasonController,
              maxLength: 500,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Motif obligatoire'),
            ),
            DropdownButtonFormField<int>(
              initialValue: days,
              decoration: const InputDecoration(labelText: 'Durée'),
              items: const [
                DropdownMenuItem(value: 1, child: Text('1 jour')),
                DropdownMenuItem(value: 7, child: Text('7 jours')),
                DropdownMenuItem(value: 30, child: Text('30 jours')),
                DropdownMenuItem(value: 90, child: Text('90 jours')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => days = value);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              final reason = reasonController.text.trim();
              if (reason.length < 3) return;
              Navigator.pop(dialogContext, _SuspensionInput(reason, days));
            },
            child: const Text('Confirmer la suspension'),
          ),
        ],
      ),
    ),
  );
  reasonController.dispose();
  return result;
}

Future<bool> _confirm(
  BuildContext context,
  String title,
  String message,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    ) ??
    false;

Future<String?> _confirmDelete(BuildContext context, String email) async {
  final controller = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Suppression définitive'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Les données liées au compte seront supprimées selon les relations de la base. Cette action est irréversible. Saisissez $email pour confirmer.',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'E-mail exact du compte',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: const Text('Supprimer'),
        ),
      ],
    ),
  );
  controller.dispose();
  if (result?.toLowerCase() != email.toLowerCase()) return null;
  return result;
}

class _DetailLine extends StatelessWidget {
  const _DetailLine(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 145,
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        Expanded(child: SelectableText(value)),
      ],
    ),
  );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.icon,
    this.isError = false,
  });
  final String label;
  final IconData icon;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime? date, DateFormat format) =>
    date == null ? 'Jamais enregistrée' : format.format(date.toLocal());

String _formatDay(DateTime? date, DateFormat format, String empty) =>
    date == null ? empty : format.format(date);

class _RetryMessage extends StatelessWidget {
  const _RetryMessage({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Réessayer')),
        ],
      ),
    ),
  );
}
