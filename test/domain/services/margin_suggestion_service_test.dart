import 'package:flutter_test/flutter_test.dart';
import 'package:serralheria_pro/domain/services/margin_suggestion_service.dart';
import 'package:serralheria_pro/models/budget.dart';

void main() {
  Budget approved(String description, double margin) => Budget(
        clientName: 'Cliente',
        serviceDescription: description,
        baseValue: 100,
        profitMargin: margin,
        finalValue: 100 + margin,
        status: BudgetStatus.approved,
      );

  test('calcula media e mediana somente dos aprovados', () {
    final history = [
      approved('Portão', 10),
      approved('Grade', 20),
      approved('Corrimão', 90),
      Budget(
        clientName: 'Cliente',
        serviceDescription: 'Recusado',
        baseValue: 100,
        profitMargin: 200,
        finalValue: 300,
        status: BudgetStatus.declined,
      ),
    ];

    final suggestion = MarginSuggestionService.suggest(history)!;
    expect(suggestion.mean, 40);
    expect(suggestion.median, 20);
    expect(suggestion.suggestedMargin, 20);
    expect(suggestion.sampleSize, 3);
  });

  test('prioriza servicos semelhantes com tres registros', () {
    final suggestion = MarginSuggestionService.suggest([
      approved('Portão deslizante', 20),
      approved('Portão social', 30),
      approved('Portão basculante', 40),
      approved('Grade', 80),
    ], serviceDescription: 'Portão de ferro')!;

    expect(suggestion.median, 30);
    expect(suggestion.sampleSize, 3);
    expect(suggestion.basis, contains('portão'));
  });

  test('nao sugere com historico insuficiente', () {
    expect(MarginSuggestionService.suggest([approved('Portão', 20)]), isNull);
  });
}
