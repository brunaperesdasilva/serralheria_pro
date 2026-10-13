import 'package:flutter_test/flutter_test.dart';
import 'package:serralheria_pro/domain/services/stock_movement_service.dart';
import 'package:serralheria_pro/models/stock_movement.dart';

void main() {
  test('calcula entrada e saída', () {
    expect(
      StockMovementService.calculateNewQuantity(
          currentQuantity: 10, type: StockMovementType.entry, quantity: 5),
      15,
    );
    expect(
      StockMovementService.calculateNewQuantity(
          currentQuantity: 10, type: StockMovementType.exit, quantity: 4),
      6,
    );
  });

  test('impede estoque negativo', () {
    expect(
      () => StockMovementService.calculateNewQuantity(
          currentQuantity: 2, type: StockMovementType.exit, quantity: 3),
      throwsArgumentError,
    );
  });

  test('impede quantidade zero', () {
    expect(
      () => StockMovementService.calculateNewQuantity(
          currentQuantity: 2, type: StockMovementType.entry, quantity: 0),
      throwsArgumentError,
    );
  });
}
