import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';

import '../core/app_card.dart';
import '../core/app_colors.dart';
import '../core/errors/error_message.dart';
import '../core/widgets/app_state_view.dart';
import '../core/widgets/app_dialogs.dart';
import '../data/app_data.dart';
import '../domain/services/budget_calculator.dart';
import '../domain/services/budget_pdf_service.dart';
import '../domain/services/budget_share_service.dart';
import '../domain/services/margin_suggestion_service.dart';
import '../models/budget.dart';
import '../models/client.dart';
import '../models/material_item.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key, this.onBack});
  final VoidCallback? onBack;

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  String _currency(double value) =>
      'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';

  double _number(String value) =>
      double.tryParse(value.replaceAll(',', '.').trim()) ?? 0;

  String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

  Future<void> _openForm({Budget? budget}) async {
    if (AppData.clients.isEmpty) {
      _message('Cadastre um cliente antes de criar um orçamento.');
      return;
    }
    final editing = budget != null;
    Client selectedClient = AppData.clients.firstWhere(
      (client) =>
          client.id == budget?.clientId || client.name == budget?.clientName,
      orElse: () => AppData.clients.first,
    );
    final margin = TextEditingController(
        text: editing ? budget.profitMargin.toStringAsFixed(0) : '');
    final discount = TextEditingController(
        text: editing && budget.discount > 0
            ? budget.discount.toStringAsFixed(2).replaceAll('.', ',')
            : '');
    final additional = TextEditingController(
        text: editing && budget.additionalValue > 0
            ? budget.additionalValue.toStringAsFixed(2).replaceAll('.', ',')
            : '');
    final notes = TextEditingController(text: budget?.notes ?? '');
    final drafts = (budget?.items ??
            [BudgetItem(description: '', quantity: 1, unitValue: 0)])
        .map(_BudgetItemDraft.fromItem)
        .toList();
    var status = budget?.status ?? BudgetStatus.draft;
    var saving = false;
    var validUntil =
        budget?.validUntil ?? DateTime.now().add(const Duration(days: 15));
    var calculation = _calculate(drafts, margin, discount, additional);
    var suggestion = MarginSuggestionService.suggest(
      AppData.budgets,
      serviceDescription: drafts.isEmpty ? null : drafts.first.description.text,
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setModalState) {
          void recalculate() => setModalState(() {
                calculation = _calculate(drafts, margin, discount, additional);
                suggestion = MarginSuggestionService.suggest(
                  AppData.budgets,
                  serviceDescription:
                      drafts.isEmpty ? null : drafts.first.description.text,
                );
              });

          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.92,
            maxChildSize: 0.96,
            builder: (context, scrollController) => ListView(
              controller: scrollController,
              padding: EdgeInsets.fromLTRB(
                  20, 20, 20, MediaQuery.viewInsetsOf(context).bottom + 24),
              children: [
                Text(editing ? 'Editar orçamento' : 'Novo orçamento',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.graphite)),
                const SizedBox(height: 18),
                DropdownButtonFormField<Client>(
                  initialValue: selectedClient,
                  decoration: const InputDecoration(labelText: 'Cliente'),
                  items: AppData.clients
                      .map((client) => DropdownMenuItem(
                          value: client, child: Text(client.name)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) selectedClient = value;
                  },
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Text('Itens',
                        style: Theme.of(context).textTheme.titleMedium),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => setModalState(() => drafts.add(
                          _BudgetItemDraft.fromItem(BudgetItem(
                              description: '', quantity: 1, unitValue: 0)))),
                      icon: const Icon(Icons.add),
                      label: const Text('Adicionar'),
                    ),
                  ],
                ),
                ...List.generate(drafts.length, (index) {
                  final draft = drafts[index];
                  return AppCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      children: [
                        Row(children: [
                          Expanded(
                            child: DropdownButtonFormField<BudgetItemType>(
                              initialValue: draft.type,
                              decoration:
                                  const InputDecoration(labelText: 'Tipo'),
                              items: const [
                                DropdownMenuItem(
                                    value: BudgetItemType.service,
                                    child: Text('Serviço')),
                                DropdownMenuItem(
                                    value: BudgetItemType.material,
                                    child: Text('Material')),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setModalState(() => draft.type = value);
                                }
                              },
                            ),
                          ),
                          IconButton(
                            tooltip: 'Remover item',
                            onPressed: drafts.length == 1
                                ? null
                                : () {
                                    draft.dispose();
                                    setModalState(() => drafts.removeAt(index));
                                    recalculate();
                                  },
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ]),
                        if (draft.type == BudgetItemType.material &&
                            AppData.materials.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          DropdownButtonFormField<MaterialItem>(
                            initialValue: AppData.materials
                                .where((item) => item.id == draft.materialId)
                                .firstOrNull,
                            decoration: const InputDecoration(
                                labelText: 'Material do estoque'),
                            items: AppData.materials
                                .map((item) => DropdownMenuItem(
                                    value: item, child: Text(item.name)))
                                .toList(),
                            onChanged: (item) {
                              if (item == null) return;
                              draft.materialId = item.id;
                              draft.description.text = item.name;
                              draft.unitValue.text = item.costPrice
                                  .toStringAsFixed(2)
                                  .replaceAll('.', ',');
                              recalculate();
                            },
                          ),
                        ],
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: draft.description,
                          decoration:
                              const InputDecoration(labelText: 'Descrição'),
                          onChanged: (_) => recalculate(),
                        ),
                        const SizedBox(height: 10),
                        Row(children: [
                          Expanded(
                            child: TextFormField(
                              controller: draft.quantity,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: const InputDecoration(
                                  labelText: 'Quantidade', hintText: '0'),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9,.]')),
                              ],
                              onChanged: (_) => recalculate(),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: draft.unitValue,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Valor unitário',
                                hintText: '0,00',
                                prefixText: 'R\$ ',
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9,.]')),
                              ],
                              onChanged: (_) => recalculate(),
                            ),
                          ),
                        ]),
                      ],
                    ),
                  );
                }),
                if (suggestion != null) ...[
                  _MarginSuggestionCard(
                    suggestion: suggestion!,
                    onApply: () {
                      margin.text =
                          suggestion!.suggestedMargin.toStringAsFixed(1);
                      recalculate();
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                Row(children: [
                  Expanded(
                    child: TextFormField(
                      controller: margin,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Margem (%)', hintText: '0'),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                      ],
                      onChanged: (_) => recalculate(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: discount,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Desconto',
                        hintText: '0,00',
                        prefixText: 'R\$ ',
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                      ],
                      onChanged: (_) => recalculate(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: additional,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Adicional',
                        hintText: '0,00',
                        prefixText: 'R\$ ',
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                      ],
                      onChanged: (_) => recalculate(),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                DropdownButtonFormField<BudgetStatus>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'Estado'),
                  items: BudgetStatus.values
                      .map((value) => DropdownMenuItem(
                          value: value, child: Text(value.label)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) status = value;
                  },
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Validade'),
                  subtitle: Text(_date(validUntil)),
                  trailing: const Icon(Icons.calendar_month_outlined),
                  onTap: () async {
                    final selected = await showDatePicker(
                      context: context,
                      initialDate: validUntil,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 730)),
                    );
                    if (selected != null) {
                      setModalState(() => validUntil = selected);
                    }
                  },
                ),
                TextFormField(
                  controller: notes,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Observações'),
                ),
                const SizedBox(height: 16),
                _TotalsCard(calculation: calculation, currency: _currency),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          final items =
                              drafts.map((value) => value.toItem()).toList();
                          if (items.any((item) =>
                              item.description.trim().isEmpty ||
                              item.quantity <= 0 ||
                              item.unitValue < 0)) {
                            _message(
                                'Revise descrição, quantidade e valor dos itens.');
                            return;
                          }
                          if (_number(margin.text) < 0 ||
                              _number(discount.text) < 0 ||
                              _number(additional.text) < 0) {
                            _message(
                                'Margem, desconto e adicional não podem ser negativos.');
                            return;
                          }
                          final description =
                              items.map((e) => e.description).join(', ');
                          final value = Budget(
                            id: budget?.id,
                            clientId: selectedClient.id,
                            clientName: selectedClient.name,
                            serviceDescription: description,
                            baseValue: calculation.subtotal,
                            profitMargin: _number(margin.text),
                            finalValue: calculation.total,
                            items: items,
                            discount: _number(discount.text),
                            additionalValue: _number(additional.text),
                            status: status,
                            createdAt: budget?.createdAt,
                            validUntil: validUntil,
                            notes: notes.text.trim(),
                          );
                          setModalState(() => saving = true);
                          try {
                            if (editing) {
                              await AppData.updateBudget(value);
                            } else {
                              await AppData.addBudget(value);
                            }
                            if (!mounted || !sheetContext.mounted) return;
                            Navigator.pop(sheetContext);
                            _message(editing
                                ? 'Orçamento atualizado com sucesso!'
                                : 'Orçamento criado com sucesso!');
                          } catch (error) {
                            if (mounted) _message(ErrorMessage.from(error));
                            if (sheetContext.mounted) {
                              setModalState(() => saving = false);
                            }
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4),
                        )
                      : const Text('Salvar orçamento'),
                ),
              ],
            ),
          );
        },
      ),
    );

    margin.dispose();
    discount.dispose();
    additional.dispose();
    notes.dispose();
    for (final draft in drafts) {
      draft.dispose();
    }
  }

  BudgetCalculation _calculate(
          List<_BudgetItemDraft> drafts,
          TextEditingController margin,
          TextEditingController discount,
          TextEditingController additional) =>
      BudgetCalculator.calculate(
        itemValues: drafts.map((item) =>
            _positive(item.quantity.text) * _positive(item.unitValue.text)),
        profitMarginPercent: _positive(margin.text),
        discount: _positive(discount.text),
        additionalValue: _positive(additional.text),
      );

  double _positive(String value) {
    final parsed = _number(value);
    return parsed < 0 ? 0 : parsed;
  }

  Future<void> _duplicate(Budget source) async {
    await AppData.addBudget(Budget(
      clientId: source.clientId,
      clientName: source.clientName,
      serviceDescription: source.serviceDescription,
      baseValue: source.baseValue,
      profitMargin: source.profitMargin,
      finalValue: source.finalValue,
      items:
          source.items.map((item) => BudgetItem.fromMap(item.toMap())).toList(),
      discount: source.discount,
      additionalValue: source.additionalValue,
      status: BudgetStatus.draft,
      validUntil: DateTime.now().add(const Duration(days: 15)),
      notes: source.notes,
    ));
    if (mounted) _message('Orçamento duplicado como rascunho.');
  }

  Future<void> _previewPdf(Budget budget) async {
    try {
      final client = AppData.clients
          .where((value) => value.id == budget.clientId)
          .firstOrNull;
      final bytes = await BudgetPdfService.generate(
        budget: budget,
        company: AppData.companyProfile,
        client: client,
      );
      await Printing.layoutPdf(
        name: 'Orçamento.pdf',
        onLayout: (_) async => bytes,
      );
    } catch (_) {
      if (mounted) _message('Não foi possível gerar o PDF. Tente novamente.');
    }
  }

  void _openShareOptions(Budget budget) {
    final client = AppData.clients
        .where((value) => value.id == budget.clientId)
        .firstOrNull;
    if (client == null) {
      _message('Cliente do orçamento não foi encontrado.');
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.chat_outlined, color: Colors.green),
                title: const Text('Enviar PDF pelo WhatsApp'),
                subtitle: Text(client.phone.isEmpty
                    ? 'O PDF será anexado; escolha a conversa no WhatsApp.'
                    : 'PDF anexado • cliente: ${client.phone}'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  final box = context.findRenderObject() as RenderBox?;
                  try {
                    await BudgetShareService.sharePdf(
                      budget: budget,
                      company: AppData.companyProfile,
                      client: client,
                      sharePositionOrigin: box == null
                          ? null
                          : box.localToGlobal(Offset.zero) & box.size,
                    );
                  } catch (_) {
                    if (mounted) {
                      _message('Não foi possível compartilhar o PDF.');
                    }
                  }
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.share_outlined, color: AppColors.primary),
                title: const Text('Compartilhar em outro aplicativo'),
                subtitle:
                    const Text('Enviar o PDF por e-mail, Drive ou outro app.'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  final box = context.findRenderObject() as RenderBox?;
                  try {
                    await BudgetShareService.sharePdf(
                      budget: budget,
                      company: AppData.companyProfile,
                      client: client,
                      sharePositionOrigin: box == null
                          ? null
                          : box.localToGlobal(Offset.zero) & box.size,
                    );
                  } catch (_) {
                    if (mounted) {
                      _message('Não foi possível compartilhar o PDF.');
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(Budget budget) async {
    final confirmed = await AppDialogs.confirmDelete(
      context,
      title: 'Excluir orçamento',
      message: 'Deseja excluir o orçamento de ${budget.clientName}?',
    );
    if (confirmed) await AppData.deleteBudget(budget.id!);
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) {
    final budgets = [...AppData.budgets]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: widget.onBack == null
            ? null
            : IconButton(
                onPressed: widget.onBack, icon: const Icon(Icons.arrow_back)),
        title: const Text('Orçamentos'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openForm,
        icon: const Icon(Icons.add),
        label: const Text('Novo orçamento'),
      ),
      body: budgets.isEmpty
          ? AppStateView.empty(
              title: 'Nenhum orçamento cadastrado',
              message: 'Crie o primeiro orçamento para começar.',
              actionLabel: 'Novo orçamento',
              onAction: _openForm,
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
              itemCount: budgets.length,
              itemBuilder: (context, index) {
                final budget = budgets[index];
                return BudgetCard(
                  budget: budget,
                  currency: _currency,
                  date: _date,
                  onEdit: () => _openForm(budget: budget),
                  onDuplicate: () => _duplicate(budget),
                  onPdf: () => _previewPdf(budget),
                  onShare: () => _openShareOptions(budget),
                  onDelete: () => _confirmDelete(budget),
                );
              },
            ),
    );
  }
}

class _BudgetItemDraft {
  _BudgetItemDraft.fromItem(BudgetItem item)
      : description = TextEditingController(text: item.description),
        quantity = TextEditingController(
            text: item.description.isEmpty ? '' : item.quantity.toString()),
        unitValue = TextEditingController(
            text: item.description.isEmpty
                ? ''
                : item.unitValue.toStringAsFixed(2).replaceAll('.', ',')),
        type = item.type,
        materialId = item.materialId;

  final TextEditingController description;
  final TextEditingController quantity;
  final TextEditingController unitValue;
  BudgetItemType type;
  int? materialId;

  BudgetItem toItem() => BudgetItem(
        description: description.text.trim(),
        quantity: double.tryParse(quantity.text.replaceAll(',', '.')) ?? 0,
        unitValue: double.tryParse(unitValue.text.replaceAll(',', '.')) ?? 0,
        type: type,
        materialId: materialId,
      );

  void dispose() {
    description.dispose();
    quantity.dispose();
    unitValue.dispose();
  }
}

class _MarginSuggestionCard extends StatelessWidget {
  const _MarginSuggestionCard({
    required this.suggestion,
    required this.onApply,
  });

  final MarginSuggestion suggestion;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) => AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.auto_graph, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Sugestão: ${suggestion.suggestedMargin.toStringAsFixed(1)}%',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              TextButton(onPressed: onApply, child: const Text('Aplicar')),
            ]),
            Text(
              suggestion.explanation,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.darkGray),
            ),
            const SizedBox(height: 4),
            const Text(
              'É apenas uma referência; você pode informar qualquer margem.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      );
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.calculation, required this.currency});
  final BudgetCalculation calculation;
  final String Function(double) currency;

  @override
  Widget build(BuildContext context) => AppCard(
        child: Column(children: [
          _line('Subtotal', calculation.subtotal),
          _line('Lucro', calculation.profit),
          _line('Desconto', -calculation.discount),
          _line('Adicional', calculation.additionalValue),
          const Divider(),
          _line('Total', calculation.total, strong: true),
        ]),
      );

  Widget _line(String label, double value, {bool strong = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          Expanded(child: Text(label)),
          Text(currency(value),
              style: TextStyle(
                  fontWeight: strong ? FontWeight.bold : FontWeight.normal,
                  color: strong ? AppColors.primary : null)),
        ]),
      );
}

class BudgetCard extends StatelessWidget {
  const BudgetCard({
    super.key,
    required this.budget,
    required this.currency,
    required this.date,
    required this.onEdit,
    required this.onDuplicate,
    required this.onPdf,
    required this.onShare,
    required this.onDelete,
  });

  final Budget budget;
  final String Function(double) currency;
  final String Function(DateTime) date;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onPdf;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => AppCard(
        margin: const EdgeInsets.only(bottom: 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(budget.clientName,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ),
            Chip(label: Text(budget.status.label)),
          ]),
          Text(
              '${budget.items.length} item(ns) • válido até ${date(budget.validUntil)}'),
          const SizedBox(height: 8),
          Text(currency(budget.finalValue),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.primary, fontWeight: FontWeight.bold)),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            IconButton(
                onPressed: onPdf,
                tooltip: 'Visualizar PDF',
                icon: const Icon(Icons.picture_as_pdf_outlined,
                    color: AppColors.primary)),
            IconButton(
                onPressed: onShare,
                tooltip: 'Compartilhar',
                icon: const Icon(Icons.share_outlined)),
            IconButton(
                onPressed: onEdit,
                tooltip: 'Editar',
                icon: const Icon(Icons.edit_outlined)),
            IconButton(
                onPressed: onDuplicate,
                tooltip: 'Duplicar',
                icon: const Icon(Icons.copy_outlined)),
            IconButton(
                onPressed: onDelete,
                tooltip: 'Excluir',
                icon:
                    const Icon(Icons.delete_outline, color: AppColors.danger)),
          ]),
        ]),
      );
}
