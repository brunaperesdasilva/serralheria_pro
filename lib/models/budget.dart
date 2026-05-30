class Budget {
  final int id;
  final int clientId;
  final String clientName;
  String serviceDescription;
  double baseValue;
  double profitMargin;
  double finalValue;

  Budget({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.serviceDescription,
    required this.baseValue,
    required this.profitMargin,
    required this.finalValue,
  });
}