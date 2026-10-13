import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../data/app_data.dart';
import 'budgets_screen.dart';
import 'clients_screen.dart';
import 'dashboard_screen.dart';
import 'schedule_screen.dart';
import 'stock_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        return Scaffold(
          body: Row(children: [
            if (wide) ...[
              NavigationRail(
                extended: constraints.maxWidth >= 1200,
                selectedIndex: _currentIndex,
                onDestinationSelected: (index) =>
                    setState(() => _currentIndex = index),
                labelType: constraints.maxWidth >= 1200
                    ? NavigationRailLabelType.none
                    : NavigationRailLabelType.all,
                destinations: _railDestinations,
              ),
              const VerticalDivider(width: 1),
            ],
            Expanded(
              child: ValueListenableBuilder<int>(
                valueListenable: AppData.revision,
                builder: (context, revision, child) => [
                  DashboardScreen(
                    revision: revision,
                    onNavigate: (index) =>
                        setState(() => _currentIndex = index),
                  ),
                  ClientsScreen(onBack: _goHome),
                  BudgetsScreen(onBack: _goHome),
                  StockScreen(onBack: _goHome),
                  ScheduleScreen(onBack: _goHome),
                ][_currentIndex],
              ),
            ),
          ]),
          bottomNavigationBar: wide
              ? null
              : _ModernBottomNavigation(
                  selectedIndex: _currentIndex,
                  onSelected: (index) => setState(() => _currentIndex = index),
                ),
        );
      },
    );
  }

  static const _railDestinations = [
    NavigationRailDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard),
        label: Text('Início')),
    NavigationRailDestination(
        icon: Icon(Icons.people_outline),
        selectedIcon: Icon(Icons.people),
        label: Text('Clientes')),
    NavigationRailDestination(
        icon: Icon(Icons.request_quote_outlined),
        selectedIcon: Icon(Icons.request_quote),
        label: Text('Orçamentos')),
    NavigationRailDestination(
        icon: Icon(Icons.inventory_2_outlined),
        selectedIcon: Icon(Icons.inventory_2),
        label: Text('Estoque')),
    NavigationRailDestination(
        icon: Icon(Icons.calendar_month_outlined),
        selectedIcon: Icon(Icons.calendar_month),
        label: Text('Agenda')),
  ];

  void _goHome() {
    setState(() {
      _currentIndex = 0;
    });
  }
}

class _ModernBottomNavigation extends StatelessWidget {
  const _ModernBottomNavigation({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _items = [
    (Icons.home_outlined, Icons.home_rounded, 'Início'),
    (Icons.people_outline_rounded, Icons.people_rounded, 'Clientes'),
    (Icons.receipt_long_outlined, Icons.receipt_long_rounded, 'Orçamentos'),
    (Icons.inventory_2_outlined, Icons.inventory_2_rounded, 'Estoque'),
    (Icons.calendar_today_outlined, Icons.calendar_month_rounded, 'Agenda'),
  ];

  @override
  Widget build(BuildContext context) => SafeArea(
        minimum: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        child: Container(
          height: 68,
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE9E9EC)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: List.generate(_items.length, (index) {
              final item = _items[index];
              final selected = index == selectedIndex;
              return Expanded(
                child: Semantics(
                  selected: selected,
                  button: true,
                  label: item.$3,
                  child: InkWell(
                    onTap: () => onSelected(index),
                    borderRadius: BorderRadius.circular(17),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary.withValues(alpha: 0.08)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(selected ? item.$2 : item.$1,
                              size: 22,
                              color: selected
                                  ? AppColors.primary
                                  : const Color(0xFF71717A)),
                          const SizedBox(height: 3),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              item.$3,
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 9.5,
                                height: 1,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: selected
                                    ? AppColors.primary
                                    : const Color(0xFF71717A),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      );
}
