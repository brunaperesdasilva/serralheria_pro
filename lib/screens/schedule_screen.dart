import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../data/app_data.dart';
import '../models/client.dart';
import '../models/schedule_item.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
    String twoDigits(int value) {
    return value.toString().padLeft(2, '0');
  }

  Future<void> pickDate(TextEditingController controller) async {
    final DateTime now = DateTime.now();

    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (selectedDate != null) {
      final String day = twoDigits(selectedDate.day);
      final String month = twoDigits(selectedDate.month);
      final String year = selectedDate.year.toString();

      controller.text = '$day/$month/$year';
    }
  }

  Future<void> pickTime(TextEditingController controller) async {
    final TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (selectedTime != null) {
      final String hour = twoDigits(selectedTime.hour);
      final String minute = twoDigits(selectedTime.minute);

      controller.text = '$hour:$minute';
    }
  }

  void openScheduleForm({ScheduleItem? schedule}) {
    final bool isEditing = schedule != null;

    Client? selectedClient;

    if (isEditing) {
      selectedClient = AppData.clients.firstWhere(
        (client) => client.id == schedule.clientId,
        orElse: () => AppData.clients.first,
      );
    }

    final serviceController = TextEditingController(
      text: schedule?.serviceDescription ?? '',
    );

    final dateController = TextEditingController(
      text: schedule?.date ?? '',
    );

    final timeController = TextEditingController(
      text: schedule?.time ?? '',
    );

    String selectedStatus = schedule?.status ?? 'A Fazer';

    if (AppData.clients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cadastre um cliente antes de criar um agendamento.'),
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
                      isEditing ? 'Editar Agendamento' : 'Novo Agendamento',
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
                      controller: dateController,
                      readOnly: true,
                      onTap: () {
                        pickDate(dateController);
                      },
                      decoration: const InputDecoration(
                        labelText: 'Data',
                        hintText: 'Selecione a data',
                        prefixIcon: Icon(Icons.calendar_month_outlined),
                        suffixIcon: Icon(Icons.arrow_drop_down),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                    controller: timeController,
                    readOnly: true,
                    onTap: () {
                      pickTime(timeController);
                    },
                    decoration: const InputDecoration(
                      labelText: 'Horário',
                      hintText: 'Selecione o horário',
                      prefixIcon: Icon(Icons.access_time_outlined),
                      suffixIcon: Icon(Icons.arrow_drop_down),
                    ),
                  ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        prefixIcon: Icon(Icons.task_alt_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'A Fazer',
                          child: Text('A Fazer'),
                        ),
                        DropdownMenuItem(
                          value: 'Concluído',
                          child: Text('Concluído'),
                        ),
                      ],
                      onChanged: (status) {
                        setModalState(() {
                          selectedStatus = status ?? 'A Fazer';
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        final client = selectedClient;
                        final service = serviceController.text.trim();
                        final date = dateController.text.trim();
                        final time = timeController.text.trim();

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

                        if (date.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Informe a data do serviço.'),
                            ),
                          );
                          return;
                        }

                        if (time.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Informe o horário do serviço.'),
                            ),
                          );
                          return;
                        }

                        setState(() {
                          if (isEditing) {
                            schedule.clientId = client.id;
                            schedule.clientName = client.name;
                            schedule.serviceDescription = service;
                            schedule.date = date;
                            schedule.time = time;
                            schedule.status = selectedStatus;
                          } else {
                            AppData.schedules.add(
                              ScheduleItem(
                                id: AppData.nextScheduleId,
                                clientId: client.id,
                                clientName: client.name,
                                serviceDescription: service,
                                date: date,
                                time: time,
                                status: selectedStatus,
                              ),
                            );

                            AppData.nextScheduleId++;
                          }
                        });

                        Navigator.pop(context);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isEditing
                                  ? 'Agendamento atualizado com sucesso!'
                                  : 'Agendamento cadastrado com sucesso!',
                            ),
                          ),
                        );
                      },
                      child: Text(
                        isEditing
                            ? 'Salvar Alterações'
                            : 'Cadastrar Agendamento',
                      ),
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

  void toggleStatus(ScheduleItem schedule) {
    setState(() {
      if (schedule.status == 'A Fazer') {
        schedule.status = 'Concluído';
      } else {
        schedule.status = 'A Fazer';
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          schedule.status == 'Concluído'
              ? 'Serviço marcado como concluído.'
              : 'Serviço marcado como a fazer.',
        ),
      ),
    );
  }

  void confirmDelete(ScheduleItem schedule) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir agendamento'),
          content: Text(
            'Deseja realmente excluir o agendamento "${schedule.serviceDescription}"?',
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
                  AppData.schedules.removeWhere(
                    (item) => item.id == schedule.id,
                  );
                });

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Agendamento excluído com sucesso!'),
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
    final schedules = AppData.schedules;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: schedules.isEmpty
          ? EmptyScheduleView(
              onAddSchedule: () {
                openScheduleForm();
              },
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    openScheduleForm();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Novo Agendamento'),
                ),
                const SizedBox(height: 20),
                Text(
                  'Agendamentos cadastrados',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.graphite,
                      ),
                ),
                const SizedBox(height: 12),
                ...schedules.map((schedule) {
                  return ScheduleCard(
                    schedule: schedule,
                    onEdit: () {
                      openScheduleForm(schedule: schedule);
                    },
                    onDelete: () {
                      confirmDelete(schedule);
                    },
                    onToggleStatus: () {
                      toggleStatus(schedule);
                    },
                  );
                }),
              ],
            ),
    );
  }
}

class ScheduleCard extends StatelessWidget {
  final ScheduleItem schedule;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleStatus;

  const ScheduleCard({
    super.key,
    required this.schedule,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    final bool concluido = schedule.status == 'Concluído';

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
              CircleAvatar(
                backgroundColor:
                    concluido ? AppColors.success : AppColors.primary,
                child: Icon(
                  concluido
                      ? Icons.check_circle_outline
                      : Icons.calendar_month_outlined,
                  color: AppColors.white,
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
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'editar') {
                    onEdit();
                  }

                  if (value == 'excluir') {
                    onDelete();
                  }
                },
                itemBuilder: (context) {
                  return const [
                    PopupMenuItem(
                      value: 'editar',
                      child: Text('Editar'),
                    ),
                    PopupMenuItem(
                      value: 'excluir',
                      child: Text('Excluir'),
                    ),
                  ];
                },
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
                ScheduleInfoLine(
                  icon: Icons.calendar_month_outlined,
                  label: 'Data',
                  value: schedule.date,
                ),
                const SizedBox(height: 8),
                ScheduleInfoLine(
                  icon: Icons.access_time_outlined,
                  label: 'Horário',
                  value: schedule.time,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: concluido
                      ? AppColors.success.withOpacity(0.12)
                      : AppColors.warning.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  schedule.status,
                  style: TextStyle(
                    color: concluido ? AppColors.success : AppColors.warning,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onToggleStatus,
                icon: Icon(
                  concluido ? Icons.undo_outlined : Icons.check_circle_outline,
                  size: 18,
                ),
                label: Text(
                  concluido ? 'Reabrir' : 'Concluir',
                ),
                style: TextButton.styleFrom(
                  foregroundColor:
                      concluido ? AppColors.darkGray : AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ScheduleInfoLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const ScheduleInfoLine({
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

class EmptyScheduleView extends StatelessWidget {
  final VoidCallback onAddSchedule;

  const EmptyScheduleView({
    super.key,
    required this.onAddSchedule,
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
                Icons.calendar_month_outlined,
                size: 56,
                color: AppColors.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Nenhum agendamento cadastrado',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.graphite,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Cadastre serviços para organizar sua agenda de trabalho.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.darkGray,
                    ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onAddSchedule,
                icon: const Icon(Icons.add),
                label: const Text('Cadastrar Agendamento'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
