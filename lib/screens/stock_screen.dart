import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_card.dart';
import '../core/app_colors.dart';
import '../core/widgets/app_state_view.dart';
import '../core/widgets/app_dialogs.dart';
import '../data/app_data.dart';
import '../models/budget.dart';
import '../models/material_item.dart';
import '../models/stock_movement.dart';

enum _StockFilter { all, low, out }

class StockScreen extends StatefulWidget {
  const StockScreen({super.key, this.onBack});
  final VoidCallback? onBack;

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  final _searchController = TextEditingController();
  _StockFilter _filter = _StockFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  double _number(String value) =>
      double.tryParse(value.replaceAll(',', '.')) ?? 0;
  String _currency(double value) =>
      'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  String _dateTime(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year} '
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  Future<void> _openMaterialForm({MaterialItem? material}) async {
    final editing = material != null;
    final name = TextEditingController(text: material?.name ?? '');
    final initialQuantity = TextEditingController();
    final minimum =
        TextEditingController(text: material?.minimumQuantity.toString() ?? '');
    final cost = TextEditingController(
        text:
            material?.costPrice.toStringAsFixed(2).replaceAll('.', ',') ?? '');

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 24, 20, MediaQuery.viewInsetsOf(sheetContext).bottom + 24),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(editing ? 'Editar material' : 'Novo material',
                style: Theme.of(sheetContext).textTheme.titleLarge),
            const SizedBox(height: 18),
            TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Nome')),
            if (!editing) ...[
              const SizedBox(height: 12),
              TextField(
                  controller: initialQuantity,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Quantidade inicial', hintText: '0')),
            ],
            const SizedBox(height: 12),
            TextField(
                controller: minimum,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Estoque mínimo', hintText: '0')),
            const SizedBox(height: 12),
            TextField(
                controller: cost,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                    labelText: 'Preço de custo',
                    hintText: '0,00',
                    prefixText: 'R\$ '),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                ]),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final materialName = name.text.trim();
                  final min = int.tryParse(minimum.text) ?? -1;
                  final initial = int.tryParse(initialQuantity.text) ?? 0;
                  final costValue = _number(cost.text);
                  if (materialName.isEmpty ||
                      min < 0 ||
                      initial < 0 ||
                      costValue < 0) {
                    _message(
                        'Revise os campos. Valores negativos não são permitidos.');
                    return;
                  }
                  if (editing) {
                    await AppData.updateMaterial(MaterialItem(
                      id: material.id,
                      name: materialName,
                      quantity: material.quantity,
                      minimumQuantity: min,
                      costPrice: costValue,
                    ));
                  } else {
                    final created = await AppData.addMaterial(MaterialItem(
                      name: materialName,
                      quantity: 0,
                      minimumQuantity: min,
                      costPrice: costValue,
                    ));
                    if (initial > 0) {
                      await AppData.moveStock(
                        material: created,
                        type: StockMovementType.entry,
                        quantity: initial,
                        reason: 'Estoque inicial',
                      );
                    }
                  }
                  if (!sheetContext.mounted) return;
                  Navigator.pop(sheetContext);
                },
                child: const Text('Salvar material'),
              ),
            ),
          ]),
        ),
      ),
    );
    name.dispose();
    initialQuantity.dispose();
    minimum.dispose();
    cost.dispose();
  }

  Future<void> _openMovement(MaterialItem material) async {
    var type = StockMovementType.entry;
    var processing = false;
    Budget? selectedBudget;
    final quantity = TextEditingController();
    final reason = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 24, 20, MediaQuery.viewInsetsOf(context).bottom + 24),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('Movimentar ${material.name}',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 18),
              SegmentedButton<StockMovementType>(
                segments: const [
                  ButtonSegment(
                      value: StockMovementType.entry,
                      label: Text('Entrada'),
                      icon: Icon(Icons.add)),
                  ButtonSegment(
                      value: StockMovementType.exit,
                      label: Text('Saída'),
                      icon: Icon(Icons.remove)),
                ],
                selected: {type},
                onSelectionChanged: processing
                    ? null
                    : (value) => setModalState(() => type = value.first),
              ),
              const SizedBox(height: 14),
              TextField(
                  controller: quantity,
                  enabled: !processing,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                      labelText: 'Quantidade',
                      helperText: 'Saldo atual: ${material.quantity}')),
              const SizedBox(height: 12),
              TextField(
                  controller: reason,
                  enabled: !processing,
                  decoration:
                      const InputDecoration(labelText: 'Motivo / observação')),
              if (type == StockMovementType.exit &&
                  AppData.budgets.isNotEmpty) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<Budget?>(
                  initialValue: selectedBudget,
                  decoration: const InputDecoration(
                      labelText: 'Relacionar ao orçamento (opcional)'),
                  items: [
                    const DropdownMenuItem<Budget?>(
                        value: null, child: Text('Sem orçamento')),
                    ...AppData.budgets.map((budget) =>
                        DropdownMenuItem<Budget?>(
                            value: budget,
                            child:
                                Text('#${budget.id} - ${budget.clientName}'))),
                  ],
                  onChanged:
                      processing ? null : (value) => selectedBudget = value,
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: processing
                      ? null
                      : () async {
                          final amount = int.tryParse(quantity.text) ?? 0;
                          if (amount <= 0) {
                            _message('Informe uma quantidade positiva.');
                            return;
                          }
                          if (type == StockMovementType.exit &&
                              amount > material.quantity) {
                            _message('Saída maior que o saldo disponível.');
                            return;
                          }
                          setModalState(() => processing = true);
                          try {
                            await AppData.moveStock(
                              material: material,
                              type: type,
                              quantity: amount,
                              reason: reason.text.trim().isEmpty
                                  ? (type == StockMovementType.entry
                                      ? 'Entrada de material'
                                      : 'Saída de material')
                                  : reason.text.trim(),
                              budgetId: selectedBudget?.id,
                            );
                            if (sheetContext.mounted) {
                              Navigator.pop(sheetContext);
                            }
                          } catch (error) {
                            if (mounted) _message('$error');
                            if (sheetContext.mounted) {
                              setModalState(() => processing = false);
                            }
                          }
                        },
                  child: processing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Confirmar movimentação'),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
    quantity.dispose();
    reason.dispose();
  }

  void _showHistory({MaterialItem? material}) {
    final movements = AppData.stockMovements
        .where((value) => material == null || value.materialId == material.id)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .75,
        builder: (context, controller) => Column(children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
                material == null
                    ? 'Histórico de movimentações'
                    : 'Histórico - ${material.name}',
                style: Theme.of(context).textTheme.titleLarge),
          ),
          Expanded(
            child: movements.isEmpty
                ? const Center(child: Text('Nenhuma movimentação registrada.'))
                : ListView.builder(
                    controller: controller,
                    itemCount: movements.length,
                    itemBuilder: (context, index) {
                      final movement = movements[index];
                      final entry = movement.type == StockMovementType.entry;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: (entry ? Colors.green : Colors.red)
                              .withValues(alpha: .12),
                          child: Icon(entry ? Icons.add : Icons.remove,
                              color: entry ? Colors.green : Colors.red),
                        ),
                        title: Text(
                            '${entry ? 'Entrada' : 'Saída'} de ${movement.quantity} - ${movement.materialName}'),
                        subtitle: Text(
                            '${movement.reason}\n${_dateTime(movement.createdAt)} • ${movement.previousQuantity} → ${movement.newQuantity}${movement.budgetId == null ? '' : ' • Orçamento #${movement.budgetId}'}'),
                        isThreeLine: true,
                      );
                    },
                  ),
          ),
        ]),
      ),
    );
  }

  Future<void> _confirmDelete(MaterialItem item) async {
    final confirmed = await AppDialogs.confirmDelete(
      context,
      title: 'Excluir material',
      message: 'Excluir ${item.name}? O histórico será preservado.',
    );
    if (confirmed) await AppData.deleteMaterial(item.id!);
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final materials = AppData.materials.where((item) {
      final matchesSearch = item.name.toLowerCase().contains(query);
      final matchesFilter = switch (_filter) {
        _StockFilter.all => true,
        _StockFilter.low => item.isLowStock,
        _StockFilter.out => item.isOutOfStock,
      };
      return matchesSearch && matchesFilter;
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    final totalValue = AppData.materials
        .fold<double>(0, (sum, item) => sum + item.quantity * item.costPrice);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: widget.onBack == null
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back), onPressed: widget.onBack),
        title: const Text('Estoque'),
        actions: [
          IconButton(
              tooltip: 'Histórico',
              onPressed: _showHistory,
              icon: const Icon(Icons.history)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openMaterialForm,
        icon: const Icon(Icons.add),
        label: const Text('Material'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
        children: [
          AppCard(
            child: Row(children: [
              const Icon(Icons.inventory_2_outlined, color: AppColors.primary),
              const SizedBox(width: 12),
              const Expanded(child: Text('Valor total do estoque')),
              Text(_currency(totalValue),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: AppColors.primary)),
            ]),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
                hintText: 'Buscar material', prefixIcon: Icon(Icons.search)),
          ),
          const SizedBox(height: 10),
          SegmentedButton<_StockFilter>(
            segments: const [
              ButtonSegment(value: _StockFilter.all, label: Text('Todos')),
              ButtonSegment(value: _StockFilter.low, label: Text('Baixo')),
              ButtonSegment(value: _StockFilter.out, label: Text('Em falta')),
            ],
            selected: {_filter},
            onSelectionChanged: (value) =>
                setState(() => _filter = value.first),
          ),
          const SizedBox(height: 18),
          if (materials.isEmpty)
            SizedBox(
              height: 300,
              child: AppStateView.empty(
                title: 'Nenhum material encontrado',
                message: _searchController.text.isEmpty
                    ? 'Adicione materiais para controlar o estoque.'
                    : 'Tente alterar a busca ou os filtros.',
                actionLabel: _searchController.text.isEmpty
                    ? 'Adicionar material'
                    : null,
                onAction:
                    _searchController.text.isEmpty ? _openMaterialForm : null,
              ),
            )
          else
            ...materials.map((item) => StockCard(
                  item: item,
                  currency: _currency,
                  onMove: () => _openMovement(item),
                  onHistory: () => _showHistory(material: item),
                  onEdit: () => _openMaterialForm(material: item),
                  onDelete: () => _confirmDelete(item),
                )),
        ],
      ),
    );
  }
}

class StockCard extends StatelessWidget {
  const StockCard({
    super.key,
    required this.item,
    required this.currency,
    required this.onMove,
    required this.onHistory,
    required this.onEdit,
    required this.onDelete,
  });
  final MaterialItem item;
  final String Function(double) currency;
  final VoidCallback onMove;
  final VoidCallback onHistory;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = item.isOutOfStock
        ? AppColors.danger
        : item.isLowStock
            ? AppColors.warning
            : AppColors.success;
    final label = item.isOutOfStock
        ? 'Em falta'
        : item.isLowStock
            ? 'Estoque baixo'
            : 'Estoque ok';
    return AppCard(
      margin: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
              backgroundColor: color.withValues(alpha: .12),
              child: Icon(Icons.category_outlined, color: color)),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.name,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('Saldo: ${item.quantity} • Mínimo: ${item.minimumQuantity}'),
              Text(
                  'Custo em estoque: ${currency(item.quantity * item.costPrice)}'),
            ]),
          ),
          Chip(
              label: Text(label),
              backgroundColor: color.withValues(alpha: .12)),
        ]),
        const SizedBox(height: 8),
        Wrap(alignment: WrapAlignment.end, children: [
          TextButton.icon(
              onPressed: onMove,
              icon: const Icon(Icons.swap_vert),
              label: const Text('Movimentar')),
          IconButton(
              onPressed: onHistory,
              tooltip: 'Histórico',
              icon: const Icon(Icons.history)),
          IconButton(
              onPressed: onEdit,
              tooltip: 'Editar',
              icon: const Icon(Icons.edit_outlined)),
          IconButton(
              onPressed: onDelete,
              tooltip: 'Excluir',
              icon: const Icon(Icons.delete_outline, color: AppColors.danger)),
        ]),
      ]),
    );
  }
}
