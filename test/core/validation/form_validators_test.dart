import 'package:flutter_test/flutter_test.dart';
import 'package:serralheria_pro/core/validation/form_validators.dart';

void main() {
  group('FormValidators', () {
    test('valida campos obrigatorios', () {
      expect(FormValidators.required('  ', field: 'Nome'), isNotNull);
      expect(FormValidators.required('Cliente'), isNull);
    });

    test('valida e-mail', () {
      expect(FormValidators.email('invalido'), isNotNull);
      expect(FormValidators.email('cliente@empresa.com.br'), isNull);
    });

    test('nao aceita numeros negativos', () {
      expect(FormValidators.nonNegativeNumber('-1'), isNotNull);
      expect(FormValidators.nonNegativeNumber('10,50'), isNull);
    });
  });
}
