import 'package:flutter_test/flutter_test.dart';
import 'package:serralheria_pro/models/schedule_item.dart';

void main() {
  test('converte data e horário padronizados', () {
    final item = ScheduleItem(
      clientName: 'Cliente',
      serviceDescription: 'Instalação',
      date: '27/08/2026',
      time: '14:30',
    );

    expect(item.scheduledAt, DateTime(2026, 8, 27, 14, 30));
  });

  test('converte estados antigos', () {
    final item = ScheduleItem.fromMap({
      'id': 1,
      'clientId': 2,
      'clientName': 'Cliente',
      'serviceDescription': 'Serviço',
      'date': '27/08/2026',
      'time': '14:30',
      'status': 'Concluído',
    });

    expect(item.status, ScheduleStatus.completed);
    expect(item.address, isEmpty);
  });

  test('data inválida não causa exceção', () {
    final item = ScheduleItem(
      clientName: 'Cliente',
      serviceDescription: 'Serviço',
      date: 'inválida',
      time: '14:30',
    );

    expect(item.scheduledAt, isNull);
  });
}
