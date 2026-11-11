import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../repositories/admin_repository.dart';
import 'admin_audit_screen.dart';
import 'admin_support_screen.dart';
import 'admin_users_screen.dart';

class AdminUsersDashboardScreen extends ConsumerWidget {
  const AdminUsersDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return DefaultTabController(
    length: 4,
    child: Scaffold(
      appBar: AppBar(
        title: Text(l10n.userManagement),
        actions: [
          IconButton(
            tooltip: l10n.refresh,
            onPressed: () {
              ref.invalidate(adminUserMetricsProvider);
              ref.invalidate(adminUserListProvider);
              ref.invalidate(adminSupportRequestsProvider);
              ref.invalidate(adminAuditLogProvider);
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
        bottom: TabBar(
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          dividerHeight: 0,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: [
            Tab(icon: const Icon(Icons.insights_outlined), text: l10n.adminOverview),
            Tab(icon: const Icon(Icons.people_outline), text: l10n.adminAccounts),
            Tab(icon: const Icon(Icons.support_agent), text: l10n.adminSupport),
            Tab(icon: const Icon(Icons.history), text: l10n.adminAudit),
          ],
        ),
      ),
      body: const TabBarView(
        children: [
          _OverviewTab(),
          AdminUsersScreen(),
          AdminSupportScreen(),
          AdminAuditScreen(),
        ],
      ),
    ),
  );
  }
}

class _OverviewTab extends ConsumerWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = ref.watch(adminUserMetricsProvider);
    return metrics.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 42),
              const SizedBox(height: 12),
              const Text(
                'Statistiques indisponibles. Vérifiez le rôle administrateur et les migrations Supabase.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(error.toString(), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => ref.invalidate(adminUserMetricsProvider),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
      data: (data) => LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 900 ? 3 : 2;
          final metrics = [
            _MetricData(
              'Comptes au total',
              data.totalAccounts,
              Icons.people_alt_outlined,
              const Color(0xFF5B8CFF),
            ),
            _MetricData(
              'Inscriptions · 30 jours',
              data.recentSignups,
              Icons.person_add_alt_1_outlined,
              const Color(0xFF35C99A),
            ),
            _MetricData(
              'Actifs · 30 jours',
              data.activeAccounts,
              Icons.online_prediction_outlined,
              const Color(0xFF9B7BFF),
            ),
            _MetricData(
              'Comptes suspendus',
              data.suspendedAccounts,
              Icons.block_outlined,
              const Color(0xFFFF7188),
            ),
            _MetricData(
              'Demandes à traiter',
              data.openSupportRequests,
              Icons.support_agent,
              const Color(0xFFFFB74D),
            ),
          ];
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Vue d’ensemble',
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Suivez l’activité et les demandes des utilisateurs.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary
                      .withValues(alpha: .09),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, size: 19),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Les comptes actifs et les inscriptions récentes couvrent les 30 derniers jours.',
                          style: TextStyle(height: 1.35),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: metrics.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: 136,
                ),
                itemBuilder: (context, index) =>
                    _MetricCard(metric: metrics[index]),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MetricData {
  const _MetricData(this.title, this.value, this.icon, this.color);
  final String title;
  final int value;
  final IconData icon;
  final Color color;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});
  final _MetricData metric;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: metric.color.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(metric.icon, color: metric.color, size: 21),
          ),
          const Spacer(),
          Text(
            metric.value.toString(),
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            metric.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    ),
  );
}
