import 'package:flutter_test/flutter_test.dart';
import 'package:serralheria_pro/models/budget.dart';

void main() {
  test('orcamento antigo recebe item de compatibilidade', () {
    final budget = Budget.fromMap({
      'id': 1,
      'clientId': 2,
      'clientName': 'Cliente',
      'serviceDescription': 'Portao',
      'baseValue': 100.0,
      'profitMargin': 20.0,
      'finalValue': 120.0,
    });

    expect(budget.items, hasLength(1));
    expect(budget.items.single.description, 'Portao');
    expect(budget.status, BudgetStatus.draft);
  });

  test('serializacao local preserva os itens', () {
    final original = Budget(
      clientName: 'Cliente',
      serviceDescription: 'Servico',
      baseValue: 50,
      profitMargin: 10,
      finalValue: 55,
      items: [
        BudgetItem(description: 'Material', quantity: 2, unitValue: 25),
      ],
    );

    final restored = Budget.fromMap(original.toMap());
    expect(restored.items.single.total, 50);
  });

  test('json antigo invalido nao impede abrir o orcamento', () {
    final budget = Budget.fromMap({
      'clientName': 'Cliente',
      'serviceDescription': 'Grade antiga',
      'baseValue': 250.0,
      'itemsJson': 'conteudo antigo fora do formato json',
    });

    expect(budget.items, hasLength(1));
    expect(budget.items.single.description, 'Grade antiga');
    expect(budget.items.single.unitValue, 250);
  });
}
