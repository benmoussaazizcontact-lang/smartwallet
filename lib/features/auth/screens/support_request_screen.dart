import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../admin/repositories/admin_repository.dart';

class SupportRequestScreen extends ConsumerStatefulWidget {
  const SupportRequestScreen({super.key});
  @override
  ConsumerState<SupportRequestScreen> createState() =>
      _SupportRequestScreenState();
}

class _SupportRequestScreenState extends ConsumerState<SupportRequestScreen> {
  final _subject = TextEditingController();
  final _message = TextEditingController();
  String _type = 'question';
  bool _busy = false;

  @override
  void dispose() {
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_subject.text.trim().length < 3 || _message.text.trim().length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ajoutez un sujet et un message plus détaillé.'),
        ),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(adminRepositoryProvider)
          .submitSupportRequest(
            subject: _subject.text,
            message: _message.text,
            requestType: _type,
          );
      if (!mounted) return;
      ref.invalidate(mySupportRequestsForUserProvider);
      _subject.clear();
      _message.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Votre demande a été envoyée.')),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.supportSendFailed)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
    appBar: AppBar(title: Text(l10n.support)),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(l10n.supportIntro),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _type,
          decoration: InputDecoration(labelText: l10n.requestType),
          items: [
            DropdownMenuItem(
              value: 'question',
              child: Text(l10n.requestQuestion),
            ),
            DropdownMenuItem(
              value: 'account_deletion',
              child: Text(l10n.requestDeletion),
            ),
          ],
          onChanged: _busy
              ? null
              : (value) {
                  if (value != null) setState(() => _type = value);
                },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _subject,
          maxLength: 160,
          decoration: InputDecoration(labelText: l10n.subject),
        ),
        TextField(
          controller: _message,
          minLines: 4,
          maxLines: 8,
          maxLength: 5000,
          decoration: InputDecoration(labelText: l10n.yourMessage),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _busy ? null : _submit,
          icon: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send),
          label: Text(l10n.sendRequest),
        ),
        const SizedBox(height: 28),
        Text(l10n.myRequests, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Consumer(
          builder: (context, ref, _) {
            final requests = ref.watch(mySupportRequestsProvider);
            return requests.when(
              loading: () => const LinearProgressIndicator(),
              error: (error, _) => Column(
                children: [
                  Text(l10n.supportLoadFailed),
                  TextButton(
                    onPressed: () => ref.invalidate(mySupportRequestsForUserProvider),
                    child: Text(l10n.retry),
                  ),
                ],
              ),
              data: (items) => items.isEmpty
                  ? Text(l10n.noSupportRequests)
                  : Column(
                      children: items
                          .map(
                            (request) => Card(
                              child: ListTile(
                                leading: Icon(
                                  request.requestType == 'account_deletion'
                                      ? Icons.delete_outline
                                      : Icons.support_agent,
                                ),
                                title: Text(request.subject),
                                subtitle: Text(
                                  'État : ${_statusLabel(request.status)}${request.response == null ? '' : '\nRéponse : ${request.response}'}',
                                ),
                                isThreeLine: request.response != null,
                              ),
                            ),
                          )
                          .toList(),
                    ),
            );
          },
        ),
      ],
    ),
  );
  }
}

String _statusLabel(String status) => switch (status) {
  'open' => 'reçue',
  'in_progress' => 'en cours',
  'resolved' => 'résolue',
  'closed' => 'fermée',
  _ => status,
};
