import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/budget.dart';
import '../models/client.dart';
import '../models/company_profile.dart';
import '../models/material_item.dart';
import '../models/schedule_item.dart';
import '../models/stock_movement.dart';
import '../domain/services/stock_movement_service.dart';
import 'database_helper.dart';
import 'repositories/app_repositories.dart';
import 'repositories/sqlite/sqlite_repositories.dart';

/// Fachada temporaria para manter as telas existentes compativeis.
/// O armazenamento real fica isolado nos repositorios.
abstract final class AppData {
  static AppRepositories repositories =
      SqliteAppRepositories(DatabaseHelper.instance);

  static List<Client> clients = [];
  static List<Budget> budgets = [];
  static List<MaterialItem> materials = [];
  static List<ScheduleItem> schedules = [];
  static List<StockMovement> stockMovements = [];
  static CompanyProfile companyProfile = _defaultProfile;
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);
  static final List<StreamSubscription<Object?>> _subscriptions = [];

  static CompanyProfile get _defaultProfile => CompanyProfile(
        companyName: 'Serralheria Pro',
        responsibleName: 'Administrador',
        phone: '(51) 99999-0000',
        email: 'contato@email.com',
      );

  static Future<void> init({AppRepositories? withRepositories}) async {
    if (withRepositories != null) repositories = withRepositories;
    final results = await Future.wait<Object?>([
      repositories.clients.getAll(),
      repositories.budgets.getAll(),
      repositories.materials.getAll(),
      repositories.schedules.getAll(),
      repositories.stockMovements.getAll(),
      repositories.profile.get(),
    ]);
    clients = List<Client>.of(results[0] as List<Client>);
    budgets = List<Budget>.of(results[1] as List<Budget>);
    materials = List<MaterialItem>.of(results[2] as List<MaterialItem>);
    schedules = List<ScheduleItem>.of(results[3] as List<ScheduleItem>);
    stockMovements = List<StockMovement>.of(results[4] as List<StockMovement>);
    companyProfile = results[5] as CompanyProfile? ?? _defaultProfile;
  }

  static Future<void> addClient(Client value) async =>
      clients.add(await repositories.clients.save(value));

  static Future<void> updateClient(Client value) async {
    _replaceById(clients, await repositories.clients.save(value), (v) => v.id);
  }

  static Future<void> deleteClient(int id) async {
    await repositories.clients.delete(id);
    clients.removeWhere((value) => value.id == id);
    _notify();
  }

  static Future<void> addBudget(Budget value) async {
    budgets.add(await repositories.budgets.save(value));
    _notify();
  }

  static Future<void> updateBudget(Budget value) async {
    _replaceById(budgets, await repositories.budgets.save(value), (v) => v.id);
    _notify();
  }

  static Future<void> deleteBudget(int id) async {
    await repositories.budgets.delete(id);
    budgets.removeWhere((value) => value.id == id);
  }

  static Future<MaterialItem> addMaterial(MaterialItem value) async {
    final saved = await repositories.materials.save(value);
    materials.add(saved);
    _notify();
    return saved;
  }

  static Future<void> updateMaterial(MaterialItem value) async {
    _replaceById(
        materials, await repositories.materials.save(value), (v) => v.id);
  }

  static Future<void> deleteMaterial(int id) async {
    await repositories.materials.delete(id);
    materials.removeWhere((value) => value.id == id);
  }

  static Future<void> addSchedule(ScheduleItem value) async {
    value.clientId ??= 0;
    schedules.add(await repositories.schedules.save(value));
  }

  static Future<void> updateSchedule(ScheduleItem value) async {
    value.clientId ??= 0;
    _replaceById(
        schedules, await repositories.schedules.save(value), (v) => v.id);
  }

  static Future<void> deleteSchedule(int id) async {
    await repositories.schedules.delete(id);
    schedules.removeWhere((value) => value.id == id);
  }

  static Future<void> saveProfile(CompanyProfile value) async {
    companyProfile = await repositories.profile.save(value);
    _notify();
  }

  static void watchRealtime() {
    stopWatching();
    _subscriptions.addAll([
      repositories.clients.watchAll().listen((value) {
        clients = List<Client>.of(value);
        _notify();
      }),
      repositories.budgets.watchAll().listen((value) {
        budgets = List<Budget>.of(value);
        _notify();
      }),
      repositories.materials.watchAll().listen((value) {
        materials = List<MaterialItem>.of(value);
        _notify();
      }),
      repositories.schedules.watchAll().listen((value) {
        schedules = List<ScheduleItem>.of(value);
        _notify();
      }),
      repositories.stockMovements.watchAll().listen((value) {
        stockMovements = List<StockMovement>.of(value);
        _notify();
      }),
      repositories.profile.watch().listen((value) {
        if (value != null) companyProfile = value;
        _notify();
      }),
    ]);
  }

  static void stopWatching() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _subscriptions.clear();
  }

  static void _notify() => revision.value++;

  static int get lowStockCount =>
      materials.where((value) => value.needsAttention).length;
  static int get pendingSchedulesCount => schedules
      .where((value) => value.status == ScheduleStatus.scheduled)
      .length;

  static Future<void> moveStock({
    required MaterialItem material,
    required StockMovementType type,
    required int quantity,
    required String reason,
    int? budgetId,
  }) async {
    if (material.id == null) throw ArgumentError('Material sem identificador.');
    if (quantity <= 0) throw ArgumentError('A quantidade deve ser positiva.');
    final previous = material.quantity;
    final next = StockMovementService.calculateNewQuantity(
      currentQuantity: previous,
      type: type,
      quantity: quantity,
    );

    final updated = MaterialItem(
      id: material.id,
      name: material.name,
      quantity: next,
      minimumQuantity: material.minimumQuantity,
      costPrice: material.costPrice,
    );
    final movement = StockMovement(
      materialId: material.id!,
      materialName: material.name,
      type: type,
      quantity: quantity,
      previousQuantity: previous,
      newQuantity: next,
      reason: reason,
      budgetId: budgetId,
    );
    await repositories.materials.save(updated);
    try {
      final savedMovement = await repositories.stockMovements.save(movement);
      _replaceById(materials, updated, (value) => value.id);
      stockMovements.add(savedMovement);
      _notify();
    } catch (error) {
      await repositories.materials.save(material);
      rethrow;
    }
  }

  static void _replaceById<T>(
      List<T> values, T replacement, int? Function(T) idOf) {
    final index =
        values.indexWhere((value) => idOf(value) == idOf(replacement));
    if (index >= 0) values[index] = replacement;
  }
}
