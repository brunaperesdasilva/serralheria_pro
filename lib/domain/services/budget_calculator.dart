class BudgetCalculation {
  const BudgetCalculation({
    required this.subtotal,
    required this.profit,
    required this.discount,
    required this.additionalValue,
    required this.total,
  });

  final double subtotal;
  final double profit;
  final double discount;
  final double additionalValue;
  final double total;
}

abstract final class BudgetCalculator {
  static BudgetCalculation calculate({
    required Iterable<double> itemValues,
    double profitMarginPercent = 0,
    double discount = 0,
    double additionalValue = 0,
  }) {
    if (profitMarginPercent < 0 || discount < 0 || additionalValue < 0) {
      throw ArgumentError('Valores do orcamento nao podem ser negativos.');
    }
    if (itemValues.any((value) => value < 0)) {
      throw ArgumentError('Itens do orcamento nao podem ter valor negativo.');
    }

    final subtotal = itemValues.fold<double>(0, (sum, value) => sum + value);
    final profit = subtotal * profitMarginPercent / 100;
    final total = subtotal + profit - discount + additionalValue;

    return BudgetCalculation(
      subtotal: subtotal,
      profit: profit,
      discount: discount,
      additionalValue: additionalValue,
      total: total < 0 ? 0 : total,
    );
  }
}
