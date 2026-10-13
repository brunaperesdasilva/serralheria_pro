import '../../models/budget.dart';

class MarginSuggestion {
  const MarginSuggestion({
    required this.suggestedMargin,
    required this.mean,
    required this.median,
    required this.sampleSize,
    required this.basis,
  });

  final double suggestedMargin;
  final double mean;
  final double median;
  final int sampleSize;
  final String basis;

  String get explanation => '$basis: $sampleSize orçamento(s) aprovado(s), '
      'média de ${mean.toStringAsFixed(1)}% e mediana de '
      '${median.toStringAsFixed(1)}%. A mediana foi sugerida por sofrer menos '
      'influência de valores extremos.';
}

abstract final class MarginSuggestionService {
  static MarginSuggestion? suggest(
    Iterable<Budget> history, {
    String? serviceDescription,
    int minimumGeneralSample = 2,
    int minimumSimilarSample = 3,
  }) {
    final approved = history
        .where((budget) =>
            budget.status == BudgetStatus.approved && budget.profitMargin >= 0)
        .toList();
    if (approved.length < minimumGeneralSample) return null;

    final category = _category(serviceDescription ?? '');
    final similar = category.isEmpty
        ? <Budget>[]
        : approved
            .where((budget) =>
                _category(budget.serviceDescription) == category ||
                budget.items
                    .any((item) => _category(item.description) == category))
            .toList();
    final selected =
        similar.length >= minimumSimilarSample ? similar : approved;
    final margins = selected.map((budget) => budget.profitMargin).toList()
      ..sort();
    final mean = margins.reduce((a, b) => a + b) / margins.length;
    final middle = margins.length ~/ 2;
    final median = margins.length.isOdd
        ? margins[middle]
        : (margins[middle - 1] + margins[middle]) / 2;

    return MarginSuggestion(
      suggestedMargin: median,
      mean: mean,
      median: median,
      sampleSize: margins.length,
      basis: identical(selected, similar)
          ? 'Serviços semelhantes a "$category"'
          : 'Histórico geral',
    );
  }

  static String _category(String description) {
    final normalized = description
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-záàâãéèêíïóôõöúçñ ]'), ' ')
        .trim();
    if (normalized.isEmpty) return '';
    const ignored = {
      'de',
      'da',
      'do',
      'das',
      'dos',
      'para',
      'com',
      'em',
      'um',
      'uma',
      'serviço',
      'servico',
      'fabricação',
      'fabricacao',
      'instalação',
      'instalacao'
    };
    return normalized
        .split(RegExp(r'\s+'))
        .firstWhere((word) => !ignored.contains(word), orElse: () => '');
  }
}
