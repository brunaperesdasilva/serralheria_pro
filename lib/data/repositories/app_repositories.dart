import '../../models/budget.dart';
import '../../models/client.dart';
import '../../models/company_profile.dart';
import '../../models/material_item.dart';
import '../../models/schedule_item.dart';
import '../../models/stock_movement.dart';
import 'repository.dart';

abstract interface class ClientRepository implements Repository<Client> {}

abstract interface class BudgetRepository implements Repository<Budget> {}

abstract interface class MaterialRepository
    implements Repository<MaterialItem> {}

abstract interface class ScheduleRepository
    implements Repository<ScheduleItem> {}

abstract interface class StockMovementRepository
    implements Repository<StockMovement> {}

abstract interface class ProfileRepository {
  Future<CompanyProfile?> get();
  Stream<CompanyProfile?> watch();
  Future<CompanyProfile> save(CompanyProfile profile);
}

abstract interface class AppRepositories {
  ClientRepository get clients;
  BudgetRepository get budgets;
  MaterialRepository get materials;
  ScheduleRepository get schedules;
  StockMovementRepository get stockMovements;
  ProfileRepository get profile;
}
