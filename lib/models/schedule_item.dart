class ScheduleItem {
  final int id;
  int clientId;
  String clientName;
  String serviceDescription;
  String date;
  String time;
  String status;

  ScheduleItem({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.serviceDescription,
    required this.date,
    required this.time,
    required this.status,
  });

  bool get isCompleted {
    return status == 'Concluído';
  }
}