import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../data/app_data.dart';
import '../models/schedule_item.dart';
import 'budgets_screen.dart';
import 'clients_screen.dart';
import 'schedule_screen.dart';
import 'stock_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int currentIndex = 0;

  final List<String> titles = const [
    'Dashboard',
    'Clientes',
    'Orçamentos',
    'Estoque',
    'Agenda',
  ];

  void changePage(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      DashboardHomeContent(
        onNovoOrcamento: () {
          changePage(2);
        },
        onAbrirAgenda: () {
          changePage(4);
        },
      ),
      const ClientsScreen(),
      const BudgetsScreen(),
      const StockScreen(),
      const ScheduleScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(titles[currentIndex]),
        actions: [
          IconButton(
            tooltip: 'Perfil',
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
            icon: const Icon(Icons.person_outline),
          ),
          IconButton(
            tooltip: 'Sair',
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: pages[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.mediumGray,
        backgroundColor: AppColors.white,
        onTap: changePage,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Início',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Clientes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.request_quote_outlined),
            activeIcon: Icon(Icons.request_quote),
            label: 'Orçamentos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: 'Estoque',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Icon(Icons.calendar_month),
            label: 'Agenda',
          ),
        ],
      ),
    );
  }
}

class DashboardHomeContent extends StatelessWidget {
  final VoidCallback onNovoOrcamento;
  final VoidCallback onAbrirAgenda;

  const DashboardHomeContent({
    super.key,
    required this.onNovoOrcamento,
    required this.onAbrirAgenda,
  });

  ScheduleItem? getNextPendingSchedule() {
    final pendingSchedules = AppData.schedules
        .where((schedule) => schedule.status == 'A Fazer')
        .toList();

    if (pendingSchedules.isEmpty) {
      return null;
    }

    return pendingSchedules.first;
  }

  @override
  Widget build(BuildContext context) {
    final ScheduleItem? nextSchedule = getNextPendingSchedule();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Olá, serralheiro!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.graphite,
                ),
          ),

          const SizedBox(height: 6),

          Text(
            'Resumo das atividades da sua serralheria.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.darkGray,
                ),
          ),

          const SizedBox(height: 24),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.25,
            children: [
              SummaryCard(
                title: 'Clientes',
                value: AppData.clients.length.toString(),
                icon: Icons.people_outline,
              ),
              SummaryCard(
                title: 'Orçamentos',
                value: AppData.budgets.length.toString(),
                icon: Icons.request_quote_outlined,
              ),
              SummaryCard(
                title: 'Itens',
                value: AppData.materials.length.toString(),
                icon: Icons.inventory_2_outlined,
              ),
              SummaryCard(
                title: 'Alertas',
                value: AppData.lowStockCount.toString(),
                icon: Icons.warning_amber_outlined,
                isAlert: true,
              ),
            ],
          ),

          const SizedBox(height: 24),

          ElevatedButton.icon(
            onPressed: onNovoOrcamento,
            icon: const Icon(Icons.add),
            label: const Text('Novo Orçamento'),
          ),

          const SizedBox(height: 24),

          Text(
            'Próximo serviço',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.graphite,
                ),
          ),

          const SizedBox(height: 12),

          if (nextSchedule == null)
            EmptyNextScheduleCard(
              onAbrirAgenda: onAbrirAgenda,
            )
          else
            NextScheduleCard(
              schedule: nextSchedule,
              onAbrirAgenda: onAbrirAgenda,
            ),
        ],
      ),
    );
  }
}

class SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final bool isAlert;

  const SummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.isAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = isAlert ? AppColors.danger : AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
            size: 30,
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.graphite,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.darkGray,
                ),
          ),
        ],
      ),
    );
  }
}

class NextScheduleCard extends StatelessWidget {
  final ScheduleItem schedule;
  final VoidCallback onAbrirAgenda;

  const NextScheduleCard({
    super.key,
    required this.schedule,
    required this.onAbrirAgenda,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.calendar_month_outlined,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      schedule.serviceDescription,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.graphite,
                          ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      'Cliente: ${schedule.clientName}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.darkGray,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                DashboardInfoLine(
                  icon: Icons.calendar_today_outlined,
                  label: 'Data',
                  value: schedule.date,
                ),
                const SizedBox(height: 8),
                DashboardInfoLine(
                  icon: Icons.access_time_outlined,
                  label: 'Horário',
                  value: schedule.time,
                ),
                const SizedBox(height: 8),
                DashboardInfoLine(
                  icon: Icons.task_alt_outlined,
                  label: 'Status',
                  value: schedule.status,
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onAbrirAgenda,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Ver agenda'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyNextScheduleCard extends StatelessWidget {
  final VoidCallback onAbrirAgenda;

  const EmptyNextScheduleCard({
    super.key,
    required this.onAbrirAgenda,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.event_available_outlined,
            color: AppColors.primary,
            size: 42,
          ),

          const SizedBox(height: 12),

          Text(
            'Nenhum serviço pendente',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.graphite,
                ),
          ),

          const SizedBox(height: 6),

          Text(
            'Quando houver serviços com status "A Fazer", eles aparecerão aqui.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.darkGray,
                ),
          ),

          const SizedBox(height: 12),

          TextButton.icon(
            onPressed: onAbrirAgenda,
            icon: const Icon(Icons.add),
            label: const Text('Abrir Agenda'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardInfoLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const DashboardInfoLine({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: AppColors.primary,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.darkGray,
                fontWeight: FontWeight.w600,
              ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.graphite,
                ),
          ),
        ),
      ],
    );
  }
}