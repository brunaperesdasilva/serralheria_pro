class MaterialItem {
  final int? id;
  String name;
  int quantity;
  int minimumQuantity;
  double costPrice;

  MaterialItem({
    this.id,
    required this.name,
    required this.quantity,
    required this.minimumQuantity,
    required this.costPrice,
  });

  bool get isLowStock {
    return quantity > 0 && quantity <= minimumQuantity;
  }

  bool get isOutOfStock {
    return quantity <= 0;
  }

  bool get needsAttention {
    return isLowStock || isOutOfStock;
  }

  factory MaterialItem.fromMap(Map<String, dynamic> json) => MaterialItem(
        id: json['id'],
        name: json['name'],
        quantity: json['quantity'],
        minimumQuantity: json['minimumQuantity'],
        costPrice: json['costPrice'],
      );

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'minimumQuantity': minimumQuantity,
      'costPrice': costPrice,
    };
  }
}
