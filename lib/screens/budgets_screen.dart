import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../data/app_data.dart';
import '../models/budget.dart';
import '../models/client.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  String formatCurrency(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  double parseCurrency(String value) {
    String cleanValue = value.replaceAll(',', '.').trim();
    return double.tryParse(cleanValue) ?? 0.0;
  }

  void openBudgetForm() {
    Client? selectedClient;

    final serviceController = TextEditingController();
    final baseValueController = TextEditingController();
    final marginController = TextEditingController(text: '20');

    double calculatedFinalValue = 0.0;

    void calculateFinalValue(StateSetter setModalState) {
      final baseValue = parseCurrency(baseValueController.text);
      final margin = parseCurrency(marginController.text);

      setModalState(() {
        calculatedFinalValue = baseValue + (baseValue * margin / 100);
      });
    }

    if (AppData.clients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cadastre um cliente antes de criar um orçamento.'),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Novo Orçamento',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.graphite,
                          ),
                    ),

                    const SizedBox(height: 20),

                    DropdownButtonFormField<Client>(
                      value: selectedClient,
                      decoration: const InputDecoration(
                        labelText: 'Cliente',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      items: AppData.clients.map((client) {
                        return DropdownMenuItem<Client>(
                          value: client,
                          child: Text(client.name),
                        );
                      }).toList(),
                      onChanged: (client) {
                        setModalState(() {
                          selectedClient = client;
                        });
                      },
                    ),

                    const SizedBox(height: 14),

                    TextField(
                      controller: serviceController,
                      decoration: const InputDecoration(
                        labelText: 'Descrição do serviço',
                        prefixIcon: Icon(Icons.build_outlined),
                      ),
                    ),

                    const SizedBox(height: 14),

                    TextField(
                      controller: baseValueController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Valor base',
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      onChanged: (_) {
                        calculateFinalValue(setModalState);
                      },
                    ),

                    const SizedBox(height: 14),

                    TextField(
                      controller: marginController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Margem de lucro (%)',
                        prefixIcon: Icon(Icons.percent),
                      ),
                      onChanged: (_) {
                        calculateFinalValue(setModalState);
                      },
                    ),

                    const SizedBox(height: 20),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.20),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Valor final calculado',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.darkGray,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formatCurrency(calculatedFinalValue),
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    ElevatedButton(
                      onPressed: () {
                        final client = selectedClient;
                        final service = serviceController.text.trim();
                        final baseValue = parseCurrency(baseValueController.text);
                        final margin = parseCurrency(marginController.text);
                        final finalValue = baseValue + (baseValue * margin / 100);

                        if (client == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Selecione um cliente.'),
                            ),
                          );
                          return;
                        }

                        if (service.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Informe a descrição do serviço.'),
                            ),
                          );
                          return;
                        }

                        if (baseValue <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Informe um valor base válido.'),
                            ),
                          );
                          return;
                        }

                        setState(() {
                          AppData.budgets.add(
                            Budget(
                              id: AppData.nextBudgetId,
                              clientId: client.id,
                              clientName: client.name,
                              serviceDescription: service,
                              baseValue: baseValue,
                              profitMargin: margin,
                              finalValue: finalValue,
                            ),
                          );

                          AppData.nextBudgetId++;
                        });

                        Navigator.pop(context);

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Orçamento cadastrado com sucesso!'),
                          ),
                        );
                      },
                      child: const Text('Salvar Orçamento'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void confirmDelete(Budget budget) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir orçamento'),
          content: Text(
            'Deseja realmente excluir o orçamento "${budget.serviceDescription}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  AppData.budgets.removeWhere((item) => item.id == budget.id);
                });

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Orçamento excluído com sucesso!'),
                  ),
                );
              },
              child: const Text(
                'Excluir',
                style: TextStyle(
                  color: AppColors.danger,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final budgets = AppData.budgets;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: budgets.isEmpty
          ? EmptyBudgetsView(
              onAddBudget: openBudgetForm,
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                ElevatedButton.icon(
                  onPressed: openBudgetForm,
                  icon: const Icon(Icons.add),
                  label: const Text('Novo Orçamento'),
                ),

                const SizedBox(height: 20),

                Text(
                  'Orçamentos cadastrados',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.graphite,
                      ),
                ),

                const SizedBox(height: 12),

                ...budgets.map((budget) {
                  return BudgetCard(
                    budget: budget,
                    formattedBaseValue: formatCurrency(budget.baseValue),
                    formattedFinalValue: formatCurrency(budget.finalValue),
                    onDelete: () {
                      confirmDelete(budget);
                    },
                  );
                }),
              ],
            ),
    );
  }
}

class BudgetCard extends StatelessWidget {
  final Budget budget;
  final String formattedBaseValue;
  final String formattedFinalValue;
  final VoidCallback onDelete;

  const BudgetCard({
    super.key,
    required this.budget,
    required this.formattedBaseValue,
    required this.formattedFinalValue,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: AppColors.primary,
                child: Icon(
                  Icons.request_quote,
                  color: AppColors.white,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      budget.serviceDescription,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.graphite,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Cliente: ${budget.clientName}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.darkGray,
                          ),
                    ),
                  ],
                ),
              ),

              IconButton(
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppColors.danger,
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
                BudgetInfoLine(
                  label: 'Valor base',
                  value: formattedBaseValue,
                ),
                const SizedBox(height: 8),
                BudgetInfoLine(
                  label: 'Margem de lucro',
                  value: '${budget.profitMargin.toStringAsFixed(0)}%',
                ),
                const Divider(height: 22),
                BudgetInfoLine(
                  label: 'Valor final',
                  value: formattedFinalValue,
                  isHighlight: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BudgetInfoLine extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlight;

  const BudgetInfoLine({
    super.key,
    required this.label,
    required this.value,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.darkGray,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isHighlight ? AppColors.primary : AppColors.graphite,
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class EmptyBudgetsView extends StatelessWidget {
  final VoidCallback onAddBudget;

  const EmptyBudgetsView({
    super.key,
    required this.onAddBudget,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.request_quote_outlined,
                size: 56,
                color: AppColors.primary,
              ),

              const SizedBox(height: 16),

              Text(
                'Nenhum orçamento cadastrado',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.graphite,
                    ),
              ),

              const SizedBox(height: 8),

              Text(
                'Crie orçamentos vinculados aos clientes cadastrados.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.darkGray,
                    ),
              ),

              const SizedBox(height: 20),

              ElevatedButton.icon(
                onPressed: onAddBudget,
                icon: const Icon(Icons.add),
                label: const Text('Criar Orçamento'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}