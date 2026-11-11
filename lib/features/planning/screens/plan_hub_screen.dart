import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/i18n/l10n_ext.dart';
import '../../../core/theme/app_radius.dart';
import '../../../shared/widgets/pressable.dart';

class PlanHubScreen extends StatelessWidget {
  const PlanHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final manage = [
      _PlanDest(l10n.planBudget, l10n.planBudgetBody, Icons.pie_chart_outline, '/plan/budgets'),
      _PlanDest(l10n.planGoals, l10n.planGoalsBody, Icons.flag_outlined, '/plan/goals'),
      _PlanDest(l10n.planInvest, l10n.planInvestBody, Icons.candlestick_chart_outlined, '/plan/portfolio'),
    ];
    final intelligence = [
      _PlanDest(l10n.planAssistant, l10n.planAssistantBody, Icons.auto_awesome_outlined, '/plan/assistant'),
      _PlanDest(l10n.planInsights, l10n.planInsightsBody, Icons.insights_outlined, '/plan/insights'),
      _PlanDest(l10n.whatIf, l10n.planWhatIfBody, Icons.tune, '/plan/what-if'),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.planTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text(l10n.planSubtitle, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 18),
          _Section(title: l10n.planManage, items: manage),
          const SizedBox(height: 8),
          _Section(title: l10n.planIntelligence, items: intelligence),
        ],
      ),
    );
  }
}

class _PlanDest {
  const _PlanDest(this.title, this.body, this.icon, this.route);
  final String title;
  final String body;
  final IconData icon;
  final String route;
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.items});
  final String title;
  final List<_PlanDest> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        for (final item in items) ...[
          _PlanCard(item: item),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.item});
  final _PlanDest item;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Pressable(
      haptic: true,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: () => context.push(item.route),
      child: Material(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Icon(item.icon, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      item.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(Directionality.of(context) == ui.TextDirection.rtl ? Icons.chevron_left : Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
