import 'package:flutter_test/flutter_test.dart';
import 'package:serralheria_pro/domain/services/budget_share_service.dart';

void main() {
  test('adiciona o codigo do Brasil ao telefone local', () {
    expect(
        BudgetShareService.normalizedPhone('(51) 99999-0000'), '5551999990000');
  });

  test('preserva telefone com codigo do pais', () {
    expect(BudgetShareService.normalizedPhone('+55 51 99999-0000'),
        '5551999990000');
  });

  test('rejeita telefone incompleto', () {
    expect(BudgetShareService.normalizedPhone('9999-0000'), isNull);
  });
}
