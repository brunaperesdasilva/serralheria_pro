enum StockMovementType { entry, exit }

class StockMovement {
  StockMovement({
    this.id,
    required this.materialId,
    required this.materialName,
    required this.type,
    required this.quantity,
    required this.previousQuantity,
    required this.newQuantity,
    required this.reason,
    this.budgetId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final int? id;
  final int materialId;
  final String materialName;
  final StockMovementType type;
  final int quantity;
  final int previousQuantity;
  final int newQuantity;
  final String reason;
  final int? budgetId;
  final DateTime createdAt;

  factory StockMovement.fromMap(Map<String, dynamic> map) => StockMovement(
        id: (map['id'] as num?)?.toInt(),
        materialId: (map['materialId'] as num).toInt(),
        materialName: map['materialName'] as String? ?? '',
        type: StockMovementType.values.firstWhere(
          (value) => value.name == map['type'],
          orElse: () => StockMovementType.entry,
        ),
        quantity: (map['quantity'] as num).toInt(),
        previousQuantity: (map['previousQuantity'] as num).toInt(),
        newQuantity: (map['newQuantity'] as num).toInt(),
        reason: map['reason'] as String? ?? '',
        budgetId: (map['budgetId'] as num?)?.toInt(),
        createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'materialId': materialId,
        'materialName': materialName,
        'type': type.name,
        'quantity': quantity,
        'previousQuantity': previousQuantity,
        'newQuantity': newQuantity,
        'reason': reason,
        'budgetId': budgetId,
        'createdAt': createdAt.toIso8601String(),
      };
}
