import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/sync_status.dart';
import '../../../models/budget.dart';
import '../../../models/client.dart';
import '../../../models/company_profile.dart';
import '../../../models/material_item.dart';
import '../../../models/schedule_item.dart';
import '../../../models/stock_movement.dart';
import '../app_repositories.dart';

typedef _FromMap<T> = T Function(Map<String, dynamic> map);
typedef _ToMap<T> = Map<String, dynamic> Function(T value);
typedef _WithId<T> = T Function(T value, int id);

class FirestoreAppRepositories implements AppRepositories {
  FirestoreAppRepositories(FirebaseFirestore firestore, String userId)
      : clients = _FirestoreClientRepository(
          firestore,
          userId,
          'clients',
          Client.fromMap,
          (value) => value.toMap(),
          (value, id) => Client(
            id: id,
            name: value.name,
            phone: value.phone,
            address: value.address,
            email: value.email,
          ),
        ),
        budgets = _FirestoreBudgetRepository(
          firestore,
          userId,
          'budgets',
          Budget.fromMap,
          (value) => value.toCloudMap(),
          (value, id) => Budget(
            id: id,
            clientId: value.clientId,
            clientName: value.clientName,
            serviceDescription: value.serviceDescription,
            baseValue: value.baseValue,
            profitMargin: value.profitMargin,
            finalValue: value.finalValue,
            items: value.items,
            discount: value.discount,
            additionalValue: value.additionalValue,
            status: value.status,
            createdAt: value.createdAt,
            validUntil: value.validUntil,
            notes: value.notes,
          ),
        ),
        materials = _FirestoreMaterialRepository(
          firestore,
          userId,
          'materials',
          MaterialItem.fromMap,
          (value) => value.toMap(),
          (value, id) => MaterialItem(
            id: id,
            name: value.name,
            quantity: value.quantity,
            minimumQuantity: value.minimumQuantity,
            costPrice: value.costPrice,
          ),
        ),
        schedules = _FirestoreScheduleRepository(
          firestore,
          userId,
          'schedules',
          ScheduleItem.fromMap,
          (value) => value.toMap(),
          (value, id) => ScheduleItem(
            id: id,
            clientId: value.clientId,
            clientName: value.clientName,
            serviceDescription: value.serviceDescription,
            date: value.date,
            time: value.time,
            status: value.status,
            address: value.address,
            notes: value.notes,
            budgetId: value.budgetId,
          ),
        ),
        stockMovements = _FirestoreStockMovementRepository(
          firestore,
          userId,
          'stockMovements',
          StockMovement.fromMap,
          (value) => value.toMap(),
          (value, id) => StockMovement(
            id: id,
            materialId: value.materialId,
            materialName: value.materialName,
            type: value.type,
            quantity: value.quantity,
            previousQuantity: value.previousQuantity,
            newQuantity: value.newQuantity,
            reason: value.reason,
            budgetId: value.budgetId,
            createdAt: value.createdAt,
          ),
        ),
        profile = _FirestoreProfileRepository(firestore, userId);

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

class _FirestoreRepository<T> {
  _FirestoreRepository(this._firestore, this._userId, this._collectionName,
      this._fromMap, this._toMap, this._withId);

  final FirebaseFirestore _firestore;
  final String _userId;
  final String _collectionName;
  final _FromMap<T> _fromMap;
  final _ToMap<T> _toMap;
  final _WithId<T> _withId;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('users').doc(_userId).collection(_collectionName);

  Future<List<T>> getAll() async {
    try {
      final snapshot = await _collection.get();
      return snapshot.docs.map((document) {
        final map = document.data();
        map['id'] = int.parse(document.id);
        return _fromMap(map);
      }).toList(growable: false);
    } catch (error) {
      throw DataException('Nao foi possivel carregar os dados da nuvem.',
          cause: error);
    }
  }

  Stream<List<T>> watchAll() =>
      _collection.snapshots(includeMetadataChanges: true).map((snapshot) {
        AppSync.controller.update(
          _collectionName,
          pending: snapshot.metadata.hasPendingWrites,
          fromCache: snapshot.metadata.isFromCache,
        );
        return snapshot.docs.map((document) {
          final map = document.data();
          map['id'] = int.parse(document.id);
          return _fromMap(map);
        }).toList(growable: false);
      }).handleError((Object error) {
        AppSync.controller.reportError();
        throw error;
      });

  Future<T> save(T value) async {
    try {
      final map = Map<String, dynamic>.from(_toMap(value));
      final currentId = map.remove('id') as int?;
      final id = currentId ?? DateTime.now().microsecondsSinceEpoch;
      map['updatedAt'] = FieldValue.serverTimestamp();
      await _collection.doc('$id').set(map, SetOptions(merge: true));
      return currentId == null ? _withId(value, id) : value;
    } catch (error) {
      throw DataException('Nao foi possivel salvar os dados na nuvem.',
          cause: error);
    }
  }

  Future<void> delete(int id) async {
    try {
      await _collection.doc('$id').delete();
    } catch (error) {
      throw DataException('Nao foi possivel excluir o registro da nuvem.',
          cause: error);
    }
  }
}

final class _FirestoreClientRepository extends _FirestoreRepository<Client>
    implements ClientRepository {
  _FirestoreClientRepository(super.firestore, super.userId,
      super.collectionName, super.fromMap, super.toMap, super.withId);
}

final class _FirestoreBudgetRepository extends _FirestoreRepository<Budget>
    implements BudgetRepository {
  _FirestoreBudgetRepository(super.firestore, super.userId,
      super.collectionName, super.fromMap, super.toMap, super.withId);
}

final class _FirestoreMaterialRepository
    extends _FirestoreRepository<MaterialItem> implements MaterialRepository {
  _FirestoreMaterialRepository(super.firestore, super.userId,
      super.collectionName, super.fromMap, super.toMap, super.withId);
}

final class _FirestoreScheduleRepository
    extends _FirestoreRepository<ScheduleItem> implements ScheduleRepository {
  _FirestoreScheduleRepository(super.firestore, super.userId,
      super.collectionName, super.fromMap, super.toMap, super.withId);
}

final class _FirestoreStockMovementRepository
    extends _FirestoreRepository<StockMovement>
    implements StockMovementRepository {
  _FirestoreStockMovementRepository(super.firestore, super.userId,
      super.collectionName, super.fromMap, super.toMap, super.withId);
}

class _FirestoreProfileRepository implements ProfileRepository {
  _FirestoreProfileRepository(this._firestore, this._userId);
  final FirebaseFirestore _firestore;
  final String _userId;

  DocumentReference<Map<String, dynamic>> get _document => _firestore
      .collection('users')
      .doc(_userId)
      .collection('settings')
      .doc('profile');

  @override
  Future<CompanyProfile?> get() async {
    try {
      final snapshot = await _document.get();
      return snapshot.exists ? CompanyProfile.fromMap(snapshot.data()!) : null;
    } catch (error) {
      throw DataException('Nao foi possivel carregar o perfil da nuvem.',
          cause: error);
    }
  }

  @override
  Stream<CompanyProfile?> watch() =>
      _document.snapshots(includeMetadataChanges: true).map((snapshot) {
        AppSync.controller.update(
          'profile',
          pending: snapshot.metadata.hasPendingWrites,
          fromCache: snapshot.metadata.isFromCache,
        );
        return snapshot.exists
            ? CompanyProfile.fromMap(snapshot.data()!)
            : null;
      }).handleError((Object error) {
        AppSync.controller.reportError();
        throw error;
      });

  @override
  Future<CompanyProfile> save(CompanyProfile profile) async {
    try {
      final map = profile.toMap()..remove('id');
      map['updatedAt'] = FieldValue.serverTimestamp();
      await _document.set(map, SetOptions(merge: true));
      return profile;
    } catch (error) {
      throw DataException('Nao foi possivel salvar o perfil na nuvem.',
          cause: error);
    }
  }
}
