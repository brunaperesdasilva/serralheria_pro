enum ScheduleStatus { scheduled, inProgress, completed, cancelled }

class ScheduleItem {
  ScheduleItem({
    this.id,
    this.clientId,
    required this.clientName,
    required this.serviceDescription,
    required this.date,
    required this.time,
    this.status = ScheduleStatus.scheduled,
    this.address = '',
    this.notes = '',
    this.budgetId,
  });

  final int? id;
  int? clientId;
  String clientName;
  String serviceDescription;
  String date;
  String time;
  ScheduleStatus status;
  String address;
  String notes;
  int? budgetId;

  DateTime? get scheduledAt {
    final dateParts = date.split('/');
    final timeParts = time.split(':');
    if (dateParts.length != 3 || timeParts.length != 2) return null;
    return DateTime.tryParse(
      '${dateParts[2]}-${dateParts[1].padLeft(2, '0')}-${dateParts[0].padLeft(2, '0')}T'
      '${timeParts[0].padLeft(2, '0')}:${timeParts[1].padLeft(2, '0')}:00',
    );
  }

  factory ScheduleItem.fromMap(Map<String, dynamic> map) => ScheduleItem(
        id: (map['id'] as num?)?.toInt(),
        clientId: (map['clientId'] as num?)?.toInt(),
        clientName: map['clientName'] as String? ?? '',
        serviceDescription: map['serviceDescription'] as String? ?? '',
        date: map['date'] as String? ?? '',
        time: map['time'] as String? ?? '',
        status: _statusFrom(map['status'] as String?),
        address: map['address'] as String? ?? '',
        notes: map['notes'] as String? ?? '',
        budgetId: (map['budgetId'] as num?)?.toInt(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'clientId': clientId,
        'clientName': clientName,
        'serviceDescription': serviceDescription,
        'date': date,
        'time': time,
        'status': status.name,
        'address': address,
        'notes': notes,
        'budgetId': budgetId,
      };

  static ScheduleStatus _statusFrom(String? value) => switch (value) {
        'inProgress' || 'Em andamento' => ScheduleStatus.inProgress,
        'completed' || 'Concluído' || 'Concluido' => ScheduleStatus.completed,
        'cancelled' || 'Cancelado' => ScheduleStatus.cancelled,
        _ => ScheduleStatus.scheduled,
      };
}

extension ScheduleStatusLabel on ScheduleStatus {
  String get label => switch (this) {
        ScheduleStatus.scheduled => 'Agendado',
        ScheduleStatus.inProgress => 'Em andamento',
        ScheduleStatus.completed => 'Concluído',
        ScheduleStatus.cancelled => 'Cancelado',
      };
}
