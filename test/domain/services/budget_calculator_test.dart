import 'package:flutter_test/flutter_test.dart';
import 'package:serralheria_pro/domain/services/budget_calculator.dart';

void main() {
  group('BudgetCalculator', () {
    test('aplica margem, desconto e adicional', () {
      final result = BudgetCalculator.calculate(
        itemValues: [100, 50],
        profitMarginPercent: 20,
        discount: 10,
        additionalValue: 5,
      );

      expect(result.subtotal, 150);
      expect(result.profit, 30);
      expect(result.total, 175);
    });

    test('impede valores negativos', () {
      expect(
        () => BudgetCalculator.calculate(itemValues: [-1]),
        throwsArgumentError,
      );
    });

    test('total nunca fica negativo', () {
      final result = BudgetCalculator.calculate(
        itemValues: [10],
        discount: 20,
      );
      expect(result.total, 0);
    });
  });
}
