abstract final class FormValidators {
  static String? required(String? value, {String field = 'Campo'}) {
    if (value == null || value.trim().isEmpty) return '$field e obrigatorio.';
    return null;
  }

  static String? email(String? value, {bool optional = false}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return optional ? null : 'E-mail e obrigatorio.';
    final pattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return pattern.hasMatch(text) ? null : 'Informe um e-mail valido.';
  }

  static String? password(String? value) {
    final text = value ?? '';
    if (text.length < 6) return 'A senha deve ter pelo menos 6 caracteres.';
    return null;
  }

  static String? nonNegativeNumber(String? value, {String field = 'Valor'}) {
    final parsed = double.tryParse((value ?? '').replaceAll(',', '.'));
    if (parsed == null) return 'Informe um numero valido.';
    if (parsed < 0) return '$field nao pode ser negativo.';
    return null;
  }
}
