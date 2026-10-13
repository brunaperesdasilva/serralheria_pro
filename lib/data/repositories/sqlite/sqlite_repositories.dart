import 'package:sqflite/sqflite.dart';

import '../../../core/errors/app_exception.dart';
import '../../../models/budget.dart';
import '../../../models/client.dart';
import '../../../models/company_profile.dart';
import '../../../models/material_item.dart';
import '../../../models/schedule_item.dart';
import '../../../models/stock_movement.dart';
import '../../database_helper.dart';
import '../app_repositories.dart';

typedef FromMap<T> = T Function(Map<String, Object?> map);
typedef ToMap<T> = Map<String, Object?> Function(T value);
typedef WithId<T> = T Function(T value, int id);

class SqliteAppRepositories implements AppRepositories {
  SqliteAppRepositories(DatabaseHelper databaseHelper)
      : clients = _SqliteClientRepository(
            databaseHelper,
            'clients',
            Client.fromMap,
            (v) => v.toMap(),
            (v, id) => Client(
                id: id,
                name: v.name,
                phone: v.phone,
                address: v.address,
                email: v.email)),
        budgets = _SqliteBudgetRepository(
            databaseHelper,
            'budgets',
            Budget.fromMap,
            (v) => v.toMap(),
            (v, id) => Budget(
                id: id,
                clientId: v.clientId,
                clientName: v.clientName,
                serviceDescription: v.serviceDescription,
                baseValue: v.baseValue,
                profitMargin: v.profitMargin,
                finalValue: v.finalValue,
                items: v.items,
                discount: v.discount,
                additionalValue: v.additionalValue,
                status: v.status,
                createdAt: v.createdAt,
                validUntil: v.validUntil,
                notes: v.notes)),
        materials = _SqliteMaterialRepository(
            databaseHelper,
            'materials',
            MaterialItem.fromMap,
            (v) => v.toMap(),
            (v, id) => MaterialItem(
                id: id,
                name: v.name,
                quantity: v.quantity,
                minimumQuantity: v.minimumQuantity,
                costPrice: v.costPrice)),
        schedules = _SqliteScheduleRepository(
            databaseHelper,
            'schedules',
            ScheduleItem.fromMap,
            (v) => v.toMap(),
            (v, id) => ScheduleItem(
                id: id,
                clientId: v.clientId,
                clientName: v.clientName,
                serviceDescription: v.serviceDescription,
                date: v.date,
                time: v.time,
                status: v.status,
                address: v.address,
                notes: v.notes,
                budgetId: v.budgetId)),
        stockMovements = _SqliteStockMovementRepository(
            databaseHelper,
            'stock_movements',
            StockMovement.fromMap,
            (v) => v.toMap(),
            (v, id) => StockMovement(
                id: id,
                materialId: v.materialId,
                materialName: v.materialName,
                type: v.type,
                quantity: v.quantity,
                previousQuantity: v.previousQuantity,
                newQuantity: v.newQuantity,
                reason: v.reason,
                budgetId: v.budgetId,
                createdAt: v.createdAt)),
        profile = _SqliteProfileRepository(databaseHelper);

  @override
  final ClientRepository clients;
  @override
  final BudgetRepository budgets;
  @override
  final MaterialRepository materials;
  @override
  final ScheduleRepository schedules;
  @override
  final StockMovementRepository stockMovements;
  @override
  final ProfileRepository profile;
}

class _SqliteRepository<T> {
  _SqliteRepository(
      this._helper, this._table, this._fromMap, this._toMap, this._withId);
  final DatabaseHelper _helper;
  final String _table;
  final FromMap<T> _fromMap;
  final ToMap<T> _toMap;
  final WithId<T> _withId;

  Future<List<T>> getAll() async {
    try {
      final rows = await (await _helper.database).query(_table);
      return rows.map(_fromMap).toList(growable: false);
    } catch (error) {
      throw DataException('Nao foi possivel carregar os dados.', cause: error);
    }
  }

  Stream<List<T>> watchAll() async* {
    yield await getAll();
  }

  Future<T> save(T value) async {
    try {
      final db = await _helper.database;
      final map = Map<String, Object?>.from(_toMap(value));
      final id = map.remove('id') as int?;
      if (id == null) {
        final newId = await db.insert(_table, map,
            conflictAlgorithm: ConflictAlgorithm.abort);
        return _withId(value, newId);
      }
      await db.update(_table, map, where: 'id = ?', whereArgs: [id]);
      return value;
    } catch (error) {
      throw DataException('Nao foi possivel salvar os dados.', cause: error);
    }
  }

  Future<void> delete(int id) async {
    try {
      await (await _helper.database)
          .delete(_table, where: 'id = ?', whereArgs: [id]);
    } catch (error) {
      throw DataException('Nao foi possivel excluir o registro.', cause: error);
    }
  }
}

final class _SqliteClientRepository extends _SqliteRepository<Client>
    implements ClientRepository {
  _SqliteClientRepository(
      super.helper, super.table, super.fromMap, super.toMap, super.withId);
}

final class _SqliteBudgetRepository extends _SqliteRepository<Budget>
    implements BudgetRepository {
  _SqliteBudgetRepository(
      super.helper, super.table, super.fromMap, super.toMap, super.withId);
}

final class _SqliteMaterialRepository extends _SqliteRepository<MaterialItem>
    implements MaterialRepository {
  _SqliteMaterialRepository(
      super.helper, super.table, super.fromMap, super.toMap, super.withId);
}

final class _SqliteScheduleRepository extends _SqliteRepository<ScheduleItem>
    implements ScheduleRepository {
  _SqliteScheduleRepository(
      super.helper, super.table, super.fromMap, super.toMap, super.withId);
}

final class _SqliteStockMovementRepository
    extends _SqliteRepository<StockMovement>
    implements StockMovementRepository {
  _SqliteStockMovementRepository(
      super.helper, super.table, super.fromMap, super.toMap, super.withId);
}

class _SqliteProfileRepository implements ProfileRepository {
  _SqliteProfileRepository(this._helper);
  final DatabaseHelper _helper;

  @override
  Future<CompanyProfile?> get() async {
    try {
      final rows = await (await _helper.database).query('profile', limit: 1);
      return rows.isEmpty ? null : CompanyProfile.fromMap(rows.first);
    } catch (error) {
      throw DataException('Nao foi possivel carregar o perfil.', cause: error);
    }
  }

  @override
  Stream<CompanyProfile?> watch() async* {
    yield await get();
  }

  @override
  Future<CompanyProfile> save(CompanyProfile profile) async {
    try {
      final db = await _helper.database;
      await db.transaction((txn) async {
        await txn.delete('profile');
        await txn.insert('profile', profile.toMap());
      });
      return profile;
    } catch (error) {
      throw DataException('Nao foi possivel salvar o perfil.', cause: error);
    }
  }
}
