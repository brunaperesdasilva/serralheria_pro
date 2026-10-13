import 'package:flutter/material.dart';

import '../core/app_card.dart';
import '../core/app_colors.dart';
import '../core/widgets/app_state_view.dart';
import '../core/widgets/app_dialogs.dart';
import '../data/app_data.dart';
import '../models/budget.dart';
import '../models/client.dart';
import '../models/schedule_item.dart';

enum _PeriodFilter { all, today, week }

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key, this.onBack});
  final VoidCallback? onBack;

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  _PeriodFilter _period = _PeriodFilter.all;
  ScheduleStatus? _status;

  String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  String _time(TimeOfDay value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  Future<void> _openForm({ScheduleItem? item}) async {
    if (AppData.clients.isEmpty) {
      _message('Cadastre um cliente antes de criar um agendamento.');
      return;
    }
    final editing = item != null;
    Client selectedClient = AppData.clients.firstWhere(
      (value) => value.id == item?.clientId || value.name == item?.clientName,
      orElse: () => AppData.clients.first,
    );
    Budget? selectedBudget = AppData.budgets
        .where((value) => value.id == item?.budgetId)
        .firstOrNull;
    var selectedDate = item?.scheduledAt ?? DateTime.now();
    var selectedTime = TimeOfDay.fromDateTime(selectedDate);
    var status = item?.status ?? ScheduleStatus.scheduled;
    final service = TextEditingController(text: item?.serviceDescription ?? '');
    final address = TextEditingController(
        text: item?.address.isNotEmpty == true
            ? item!.address
            : selectedClient.address);
    final notes = TextEditingController(text: item?.notes ?? '');

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 24, 20, MediaQuery.viewInsetsOf(context).bottom + 24),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(editing ? 'Editar / reagendar' : 'Novo agendamento',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 18),
              DropdownButtonFormField<Client>(
                initialValue: selectedClient,
                decoration: const InputDecoration(labelText: 'Cliente'),
                items: AppData.clients
                    .map((client) => DropdownMenuItem(
                        value: client, child: Text(client.name)))
                    .toList(),
                onChanged: (client) {
                  if (client == null) return;
                  setModalState(() {
                    selectedClient = client;
                    selectedBudget = null;
                    if (address.text.trim().isEmpty) {
                      address.text = client.address;
                    }
                  });
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<Budget?>(
                initialValue: selectedBudget,
                decoration:
                    const InputDecoration(labelText: 'Orçamento (opcional)'),
                items: [
                  const DropdownMenuItem<Budget?>(
                      value: null, child: Text('Sem orçamento')),
                  ...AppData.budgets
                      .where((budget) =>
                          budget.clientId == selectedClient.id ||
                          budget.clientName == selectedClient.name)
                      .map((budget) => DropdownMenuItem<Budget?>(
                          value: budget,
                          child:
                              Text('#${budget.id} - ${budget.status.label}'))),
                ],
                onChanged: (budget) {
                  selectedBudget = budget;
                  if (budget != null) {
                    service.text = budget.serviceDescription;
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                  controller: service,
                  decoration: const InputDecoration(
                      labelText: 'Serviço / compromisso')),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Data'),
                    subtitle: Text(_date(selectedDate)),
                    trailing: const Icon(Icons.calendar_month),
                    onTap: () async {
                      final value = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate:
                            DateTime.now().add(const Duration(days: 1825)),
                      );
                      if (value != null) {
                        setModalState(() => selectedDate = value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Horário'),
                    subtitle: Text(_time(selectedTime)),
                    trailing: const Icon(Icons.schedule),
                    onTap: () async {
                      final value = await showTimePicker(
                          context: context, initialTime: selectedTime);
                      if (value != null) {
                        setModalState(() => selectedTime = value);
                      }
                    },
                  ),
                ),
              ]),
              DropdownButtonFormField<ScheduleStatus>(
                initialValue: status,
                decoration: const InputDecoration(labelText: 'Estado'),
                items: ScheduleStatus.values
                    .map((value) => DropdownMenuItem(
                        value: value, child: Text(value.label)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) status = value;
                },
              ),
              const SizedBox(height: 12),
              TextField(
                  controller: address,
                  decoration: const InputDecoration(
                      labelText: 'Endereço do serviço',
                      prefixIcon: Icon(Icons.location_on_outlined))),
              const SizedBox(height: 12),
              TextField(
                  controller: notes,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Observações')),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (service.text.trim().isEmpty) {
                      _message('Informe o serviço ou compromisso.');
                      return;
                    }
                    final value = ScheduleItem(
                      id: item?.id,
                      clientId: selectedClient.id,
                      clientName: selectedClient.name,
                      serviceDescription: service.text.trim(),
                      date: _date(selectedDate),
                      time: _time(selectedTime),
                      status: status,
                      address: address.text.trim(),
                      notes: notes.text.trim(),
                      budgetId: selectedBudget?.id,
                    );
                    if (editing) {
                      await AppData.updateSchedule(value);
                    } else {
                      await AppData.addSchedule(value);
                    }
                    if (sheetContext.mounted) Navigator.pop(sheetContext);
                  },
                  child: Text(editing ? 'Salvar alterações' : 'Agendar'),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
    service.dispose();
    address.dispose();
    notes.dispose();
  }

  Future<void> _changeStatus(ScheduleItem item, ScheduleStatus status) async {
    await AppData.updateSchedule(ScheduleItem(
      id: item.id,
      clientId: item.clientId,
      clientName: item.clientName,
      serviceDescription: item.serviceDescription,
      date: item.date,
      time: item.time,
      status: status,
      address: item.address,
      notes: item.notes,
      budgetId: item.budgetId,
    ));
  }

  Future<void> _confirmDelete(ScheduleItem item) async {
    final confirmed = await AppDialogs.confirmDelete(
      context,
      title: 'Excluir agendamento',
      message: 'Excluir o compromisso de ${item.clientName}?',
    );
    if (confirmed) await AppData.deleteSchedule(item.id!);
  }

  bool _matchesPeriod(ScheduleItem item) {
    final scheduledAt = item.scheduledAt;
    if (scheduledAt == null || _period == _PeriodFilter.all) return true;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(scheduledAt.year, scheduledAt.month, scheduledAt.day);
    if (_period == _PeriodFilter.today) return day == today;
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    return !day.isBefore(weekStart) &&
        day.isBefore(weekStart.add(const Duration(days: 7)));
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) {
    final items = AppData.schedules
        .where((item) =>
            _matchesPeriod(item) && (_status == null || item.status == _status))
        .toList()
      ..sort((a, b) {
        final aDate = a.scheduledAt ?? DateTime(2100);
        final bDate = b.scheduledAt ?? DateTime(2100);
        return aDate.compareTo(bDate);
      });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: widget.onBack == null
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back), onPressed: widget.onBack),
        title: const Text('Agenda'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openForm,
        icon: const Icon(Icons.add),
        label: const Text('Agendar'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
        children: [
          SegmentedButton<_PeriodFilter>(
            segments: const [
              ButtonSegment(value: _PeriodFilter.all, label: Text('Todos')),
              ButtonSegment(value: _PeriodFilter.today, label: Text('Hoje')),
              ButtonSegment(value: _PeriodFilter.week, label: Text('Semana')),
            ],
            selected: {_period},
            onSelectionChanged: (value) =>
                setState(() => _period = value.first),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<ScheduleStatus?>(
            initialValue: _status,
            decoration: const InputDecoration(labelText: 'Filtrar por estado'),
            items: [
              const DropdownMenuItem<ScheduleStatus?>(
                  value: null, child: Text('Todos os estados')),
              ...ScheduleStatus.values.map((value) =>
                  DropdownMenuItem<ScheduleStatus?>(
                      value: value, child: Text(value.label))),
            ],
            onChanged: (value) => setState(() => _status = value),
          ),
          const SizedBox(height: 18),
          if (items.isEmpty)
            SizedBox(
              height: 320,
              child: AppStateView.empty(
                title: 'Nenhum compromisso encontrado',
                message: 'Altere os filtros ou crie um novo agendamento.',
                actionLabel: 'Novo agendamento',
                onAction: _openForm,
              ),
            )
          else
            ...items.map((item) => ScheduleCard(
                  item: item,
                  onEdit: () => _openForm(item: item),
                  onDelete: () => _confirmDelete(item),
                  onStatusChanged: (status) => _changeStatus(item, status),
                )),
        ],
      ),
    );
  }
}

class ScheduleCard extends StatelessWidget {
  const ScheduleCard({
    super.key,
    required this.item,
    required this.onEdit,
    required this.onDelete,
    required this.onStatusChanged,
  });

  final ScheduleItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<ScheduleStatus> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final color = switch (item.status) {
      ScheduleStatus.scheduled => Colors.blue,
      ScheduleStatus.inProgress => Colors.orange,
      ScheduleStatus.completed => Colors.green,
      ScheduleStatus.cancelled => Colors.grey,
    };
    return AppCard(
      margin: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: .12),
            child: Icon(Icons.calendar_month_outlined, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.clientName,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(item.serviceDescription,
                  maxLines: 2, overflow: TextOverflow.ellipsis),
            ]),
          ),
          PopupMenuButton<ScheduleStatus>(
            initialValue: item.status,
            onSelected: onStatusChanged,
            itemBuilder: (context) => ScheduleStatus.values
                .map((value) =>
                    PopupMenuItem(value: value, child: Text(value.label)))
                .toList(),
            child: Chip(
                label: Text(item.status.label),
                backgroundColor: color.withValues(alpha: .12)),
          ),
        ]),
        const SizedBox(height: 10),
        _line(Icons.schedule, '${item.date} às ${item.time}'),
        if (item.address.isNotEmpty)
          _line(Icons.location_on_outlined, item.address),
        if (item.notes.isNotEmpty) _line(Icons.notes, item.notes),
        if (item.budgetId != null)
          _line(Icons.request_quote_outlined, 'Orçamento #${item.budgetId}'),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          TextButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.event_repeat),
              label: const Text('Editar / reagendar')),
          IconButton(
              onPressed: onDelete,
              tooltip: 'Excluir',
              icon: const Icon(Icons.delete_outline, color: AppColors.danger)),
        ]),
      ]),
    );
  }

  Widget _line(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 17, color: AppColors.darkGray),
          const SizedBox(width: 7),
          Expanded(child: Text(text)),
        ]),
      );
}
