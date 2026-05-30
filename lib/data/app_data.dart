import '../models/budget.dart';
import '../models/client.dart';
import '../models/company_profile.dart';
import '../models/material_item.dart';
import '../models/schedule_item.dart';

class AppData {
  static int nextClientId = 3;
  static int nextBudgetId = 2;
  static int nextMaterialId = 4;
  static int nextScheduleId = 3;

  static CompanyProfile companyProfile = CompanyProfile(
    companyName: 'Serralheria Pro',
    responsibleName: 'Administrador',
    phone: '(51) 99999-0000',
    email: 'contato@serralheriapro.com',
  );

  static List<Client> clients = [
    Client(
      id: 1,
      name: 'João Silva',
      phone: '(51) 99999-1111',
      address: 'Rua das Flores, 120',
      email: 'joao@email.com',
    ),
    Client(
      id: 2,
      name: 'Maria Oliveira',
      phone: '(51) 98888-2222',
      address: 'Av. Central, 450',
      email: 'maria@email.com',
    ),
  ];

  static List<Budget> budgets = [
    Budget(
      id: 1,
      clientId: 1,
      clientName: 'João Silva',
      serviceDescription: 'Portão de correr',
      baseValue: 1000.00,
      profitMargin: 20.00,
      finalValue: 1200.00,
    ),
  ];

  static List<MaterialItem> materials = [
    MaterialItem(
      id: 1,
      name: 'Tubo metalon',
      quantity: 5,
      minimumQuantity: 10,
      costPrice: 35.00,
      salePrice: 50.00,
    ),
    MaterialItem(
      id: 2,
      name: 'Chapa de aço',
      quantity: 18,
      minimumQuantity: 8,
      costPrice: 90.00,
      salePrice: 130.00,
    ),
    MaterialItem(
      id: 3,
      name: 'Eletrodo',
      quantity: 30,
      minimumQuantity: 15,
      costPrice: 25.00,
      salePrice: 40.00,
    ),
  ];

  static List<ScheduleItem> schedules = [
    ScheduleItem(
      id: 1,
      clientId: 1,
      clientName: 'João Silva',
      serviceDescription: 'Instalação de portão',
      date: '29/05/2026',
      time: '14:00',
      status: 'A Fazer',
    ),
    ScheduleItem(
      id: 2,
      clientId: 2,
      clientName: 'Maria Oliveira',
      serviceDescription: 'Manutenção de grade',
      date: '30/05/2026',
      time: '09:00',
      status: 'Concluído',
    ),
  ];

  static int get lowStockCount {
    return materials.where((material) => material.isLowStock).length;
  }

  static int get pendingSchedulesCount {
    return schedules.where((schedule) => schedule.status == 'A Fazer').length;
  }
}
