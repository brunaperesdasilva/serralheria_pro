import '../../models/stock_movement.dart';

abstract final class StockMovementService {
  static int calculateNewQuantity({
    required int currentQuantity,
    required StockMovementType type,
    required int quantity,
  }) {
    if (currentQuantity < 0) {
      throw ArgumentError('O saldo atual não pode ser negativo.');
    }
    if (quantity <= 0) {
      throw ArgumentError('A quantidade deve ser positiva.');
    }
    final result = type == StockMovementType.entry
        ? currentQuantity + quantity
        : currentQuantity - quantity;
    if (result < 0) {
      throw ArgumentError('A saída não pode deixar o estoque negativo.');
    }
    return result;
  }
}
