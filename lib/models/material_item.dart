class MaterialItem {
  final int id;
  String name;
  int quantity;
  int minimumQuantity;
  double costPrice;
  double salePrice;

  MaterialItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.minimumQuantity,
    required this.costPrice,
    required this.salePrice,
  });

  bool get isLowStock {
    return quantity <= minimumQuantity;
  }
}