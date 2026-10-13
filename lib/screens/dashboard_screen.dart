import 'package:flutter/material.dart';

import '../core/app_card.dart';
import '../core/app_colors.dart';
import '../core/widgets/company_avatar.dart';
import '../data/app_data.dart';
import '../models/budget.dart';
import '../models/material_item.dart';
import '../models/schedule_item.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    this.revision = 0,
    required this.onNavigate,
  });

  final int revision;
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = AppData.schedules.where((item) {
      final date = item.scheduledAt;
      return date != null &&
          date.year == now.year &&
          date.month == now.month &&
          date.day == now.day &&
          item.status != ScheduleStatus.cancelled;
    }).toList()
      ..sort((a, b) => (a.scheduledAt ?? now).compareTo(b.scheduledAt ?? now));
    final pending = AppData.budgets
        .where((item) =>
            item.status == BudgetStatus.draft ||
            item.status == BudgetStatus.sent)
        .length;
    final approved = AppData.budgets
        .where((item) =>
            item.status == BudgetStatus.approved &&
            item.createdAt.year == now.year &&
            item.createdAt.month == now.month)
        .fold<double>(0, (total, item) => total + item.finalValue);
    final expiring = AppData.budgets.where((item) {
      final days = item.validUntil.difference(now).inDays;
      return item.status != BudgetStatus.approved &&
          item.status != BudgetStatus.declined &&
          days >= 0 &&
          days <= 7;
    }).length;
    final lowStock = AppData.materials
        .where((item) => item.needsAttention)
        .toList()
      ..sort((a, b) => a.quantity.compareTo(b.quantity));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        centerTitle: false,
        titleSpacing: 20,
        title: Text(AppData.companyProfile.companyName.isEmpty
            ? 'Serralheria Pro'
            : AppData.companyProfile.companyName),
        actions: [_profileButton(context), const SizedBox(width: 8)],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) => ListView(
          padding: EdgeInsets.all(constraints.maxWidth >= 700 ? 28 : 18),
          children: [
            _sectionHeader(context, 'Acesso rápido'),
            const SizedBox(height: 10),
            _quickActions(),
            const SizedBox(height: 24),
            _metrics(context, constraints.maxWidth, pending, approved,
                today.length, lowStock.length),
            const SizedBox(height: 26),
            _sectionHeader(context, 'Agenda de hoje',
                action: 'Ver agenda', onTap: () => onNavigate(4)),
            const SizedBox(height: 10),
            _todaySchedule(today),
            const SizedBox(height: 26),
            _sectionHeader(context, 'Atenção necessária',
                action: lowStock.isEmpty ? null : 'Ver estoque',
                onTap: lowStock.isEmpty ? null : () => onNavigate(3)),
            const SizedBox(height: 10),
            _attentionCard(lowStock, expiring),
          ],
        ),
      ),
    );
  }

  Widget _profileButton(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ProfileScreen())),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.graphite.withValues(alpha: 0.045),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.lightGray),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              CompanyAvatar(
                radius: 15,
                logoBase64: AppData.companyProfile.logoBase64,
                fallback: _initials(AppData.companyProfile.companyName),
              ),
              const SizedBox(width: 7),
              const Text('Perfil',
                  style: TextStyle(
                      color: AppColors.graphite,
                      fontWeight: FontWeight.w700,
                      fontSize: 12)),
            ]),
          ),
        ),
      );

  Widget _quickActions() => Row(children: [
        _quickAction(Icons.request_quote_outlined, 'Orçamento', 2),
        const SizedBox(width: 9),
        _quickAction(Icons.person_add_alt_outlined, 'Cliente', 1),
        const SizedBox(width: 9),
        _quickAction(Icons.event_available_outlined, 'Agenda', 4),
        const SizedBox(width: 9),
        _quickAction(Icons.inventory_2_outlined, 'Estoque', 3),
      ]);

  Widget _quickAction(IconData icon, String label, int index) => Expanded(
        child: InkWell(
          onTap: () => onNavigate(index),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 3),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.lightGray),
            ),
            child: Column(children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.09),
                    shape: BoxShape.circle),
                child: Icon(icon, color: AppColors.primary, size: 21),
              ),
              const SizedBox(height: 7),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  style: const TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
      );

  Widget _metrics(BuildContext context, double width, int pending,
      double approved, int today, int lowStock) {
    final metrics = [
      _Metric('Pendentes', '$pending', Icons.pending_actions_outlined,
          AppColors.warning, () => onNavigate(2)),
      _Metric('Aprovado no mês', _currency(approved), Icons.trending_up,
          AppColors.success, () => onNavigate(2)),
      _Metric('Serviços hoje', '$today', Icons.today_outlined,
          const Color(0xFF3568A8), () => onNavigate(4)),
      _Metric('Estoque baixo', '$lowStock', Icons.warning_amber_outlined,
          AppColors.danger, () => onNavigate(3)),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: metrics.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: width >= 900 ? 4 : 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: width >= 900 ? 1.65 : 1.3,
      ),
      itemBuilder: (context, index) => _metricCard(context, metrics[index]),
    );
  }

  Widget _metricCard(BuildContext context, _Metric item) => InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(16),
        child: AppCard(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(item.icon, color: item.color, size: 25),
            const Spacer(),
            FittedBox(
              child: Text(item.value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800, color: AppColors.graphite)),
            ),
            Text(item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 11.5, color: AppColors.darkGray)),
          ]),
        ),
      );

  Widget _todaySchedule(List<ScheduleItem> items) {
    if (items.isEmpty) {
      return _emptyCard(
          Icons.event_available_outlined, 'Nenhum serviço agendado para hoje.');
    }
    final visible = items.take(3).toList();
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      child: Column(
        children: visible.asMap().entries.map((entry) {
          final item = entry.value;
          return Column(children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              onTap: () => onNavigate(4),
              leading: Container(
                width: 52,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12)),
                child: Text(item.time,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12)),
              ),
              title: Text(item.clientName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(item.serviceDescription,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: const Icon(Icons.chevron_right),
            ),
            if (entry.key < visible.length - 1) const Divider(height: 1),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _attentionCard(List<MaterialItem> lowStock, int expiring) {
    if (lowStock.isEmpty && expiring == 0) {
      return _emptyCard(Icons.check_circle_outline,
          'Tudo certo. Nenhuma pendência importante agora.',
          color: AppColors.success);
    }
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        if (expiring > 0)
          _alertRow(
              Icons.schedule_outlined,
              '$expiring orçamento${expiring == 1 ? '' : 's'} perto da validade',
              AppColors.warning,
              () => onNavigate(2)),
        if (expiring > 0 && lowStock.isNotEmpty) const Divider(height: 20),
        if (lowStock.isNotEmpty)
          _alertRow(
              Icons.inventory_2_outlined,
              lowStock.length == 1
                  ? '${lowStock.first.name} precisa de reposição'
                  : '${lowStock.length} materiais precisam de reposição',
              AppColors.danger,
              () => onNavigate(3)),
      ]),
    );
  }

  Widget _alertRow(
          IconData icon, String text, Color color, VoidCallback onTap) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
            const Icon(Icons.chevron_right, color: AppColors.mediumGray),
          ]),
        ),
      );

  Widget _emptyCard(IconData icon, String text,
          {Color color = AppColors.mediumGray}) =>
      AppCard(
        padding: const EdgeInsets.all(18),
        child: Row(children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
              child: Text(text,
                  style: const TextStyle(color: AppColors.darkGray))),
        ]),
      );

  Widget _sectionHeader(BuildContext context, String title,
          {String? action, VoidCallback? onTap}) =>
      Row(children: [
        Expanded(
            child: Text(title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700, color: AppColors.graphite))),
        if (action != null) TextButton(onPressed: onTap, child: Text(action)),
      ]);

  String _currency(double value) =>
      'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    return parts.length > 1
        ? '${parts.first[0]}${parts[1][0]}'.toUpperCase()
        : parts.first[0].toUpperCase();
  }
}

class _Metric {
  const _Metric(this.label, this.value, this.icon, this.color, this.onTap);
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}
