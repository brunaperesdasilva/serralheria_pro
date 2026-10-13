import 'dart:convert';

enum BudgetStatus { draft, sent, approved, declined }

enum BudgetItemType { service, material }

class BudgetItem {
  BudgetItem({
    required this.description,
    required this.quantity,
    required this.unitValue,
    this.type = BudgetItemType.service,
    this.materialId,
  });

  final String description;
  final double quantity;
  final double unitValue;
  final BudgetItemType type;
  final int? materialId;

  double get total => quantity * unitValue;

  factory BudgetItem.fromMap(Map<String, dynamic> map) => BudgetItem(
        description: map['description'] as String? ?? '',
        quantity: (map['quantity'] as num?)?.toDouble() ?? 1,
        unitValue: (map['unitValue'] as num?)?.toDouble() ?? 0,
        type: BudgetItemType.values.firstWhere(
          (value) => value.name == map['type'],
          orElse: () => BudgetItemType.service,
        ),
        materialId: (map['materialId'] as num?)?.toInt(),
      );

  Map<String, dynamic> toMap() => {
        'description': description,
        'quantity': quantity,
        'unitValue': unitValue,
        'type': type.name,
        'materialId': materialId,
      };
}

class Budget {
  Budget({
    this.id,
    this.clientId,
    required this.clientName,
    required this.serviceDescription,
    required this.baseValue,
    required this.profitMargin,
    required this.finalValue,
    List<BudgetItem>? items,
    this.discount = 0,
    this.additionalValue = 0,
    this.status = BudgetStatus.draft,
    DateTime? createdAt,
    DateTime? validUntil,
    this.notes = '',
  })  : items = items ??
            [
              BudgetItem(
                description: serviceDescription,
                quantity: 1,
                unitValue: baseValue,
              ),
            ],
        createdAt = createdAt ?? DateTime.now(),
        validUntil = validUntil ?? DateTime.now().add(const Duration(days: 15));

  final int? id;
  int? clientId;
  String clientName;
  String serviceDescription;
  double baseValue;
  double profitMargin;
  double finalValue;
  List<BudgetItem> items;
  double discount;
  double additionalValue;
  BudgetStatus status;
  DateTime createdAt;
  DateTime validUntil;
  String notes;

  factory Budget.fromMap(Map<String, dynamic> map) {
    final baseValue = (map['baseValue'] as num?)?.toDouble() ?? 0;
    final description = map['serviceDescription'] as String? ?? '';
    final items = _readItems(map, description, baseValue);
    return Budget(
      id: (map['id'] as num?)?.toInt(),
      clientId: (map['clientId'] as num?)?.toInt(),
      clientName: map['clientName'] as String? ?? '',
      serviceDescription: description,
      baseValue: baseValue,
      profitMargin: (map['profitMargin'] as num?)?.toDouble() ?? 0,
      finalValue: (map['finalValue'] as num?)?.toDouble() ?? baseValue,
      items: items,
      discount: (map['discount'] as num?)?.toDouble() ?? 0,
      additionalValue: (map['additionalValue'] as num?)?.toDouble() ?? 0,
      status: BudgetStatus.values.firstWhere(
        (value) => value.name == map['status'],
        orElse: () => BudgetStatus.draft,
      ),
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
      validUntil: DateTime.tryParse(map['validUntil'] as String? ?? '') ??
          DateTime.now().add(const Duration(days: 15)),
      notes: map['notes'] as String? ?? '',
    );
  }

  static List<BudgetItem> _readItems(
      Map<String, dynamic> map, String description, double baseValue) {
    final cloudItems = map['items'];
    if (cloudItems is List) {
      return cloudItems
          .whereType<Map>()
          .map((value) => BudgetItem.fromMap(Map<String, dynamic>.from(value)))
          .toList();
    }
    final encoded = map['itemsJson'] as String?;
    if (encoded != null && encoded.isNotEmpty) {
      try {
        final decoded = jsonDecode(encoded);
        if (decoded is List) {
          final values = decoded
              .whereType<Map>()
              .map((value) =>
                  BudgetItem.fromMap(Map<String, dynamic>.from(value)))
              .toList();
          if (values.isNotEmpty) return values;
        }
      } on FormatException {
        // Registros de versoes antigas podem conter texto em vez de JSON.
        // Nesse caso, o orçamento continua acessivel usando os campos legados.
      }
    }
    return [
      BudgetItem(description: description, quantity: 1, unitValue: baseValue),
    ];
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'clientId': clientId,
        'clientName': clientName,
        'serviceDescription': serviceDescription,
        'baseValue': baseValue,
        'profitMargin': profitMargin,
        'finalValue': finalValue,
        'itemsJson': jsonEncode(items.map((value) => value.toMap()).toList()),
        'discount': discount,
        'additionalValue': additionalValue,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'validUntil': validUntil.toIso8601String(),
        'notes': notes,
      };

  Map<String, dynamic> toCloudMap() {
    final map = toMap()..remove('itemsJson');
    map['items'] = items.map((value) => value.toMap()).toList();
    return map;
  }
}

extension BudgetStatusLabel on BudgetStatus {
  String get label => switch (this) {
        BudgetStatus.draft => 'Rascunho',
        BudgetStatus.sent => 'Enviado',
        BudgetStatus.approved => 'Aprovado',
        BudgetStatus.declined => 'Recusado',
      };
}
