import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/company_profile.dart';
import '../repositories/app_repositories.dart';

class LocalToFirestoreMigrator {
  LocalToFirestoreMigrator(this._firestore, this._userId);

  final FirebaseFirestore _firestore;
  final String _userId;

  DocumentReference<Map<String, dynamic>> get _marker => _firestore
      .collection('users')
      .doc(_userId)
      .collection('settings')
      .doc('migration');

  Future<bool> migrate({
    required AppRepositories local,
    required AppRepositories cloud,
  }) async {
    final marker = await _marker.get();
    if ((marker.data()?['version'] as num? ?? 0) >= 2) return false;

    for (final value in await local.clients.getAll()) {
      await cloud.clients.save(value);
    }
    for (final value in await local.budgets.getAll()) {
      await cloud.budgets.save(value);
    }
    for (final value in await local.materials.getAll()) {
      await cloud.materials.save(value);
    }
    for (final value in await local.schedules.getAll()) {
      await cloud.schedules.save(value);
    }
    for (final value in await local.stockMovements.getAll()) {
      await cloud.stockMovements.save(value);
    }
    final CompanyProfile? profile = await local.profile.get();
    if (profile != null) await cloud.profile.save(profile);

    await _marker.set({
      'completed': true,
      'completedAt': FieldValue.serverTimestamp(),
      'version': 2,
    });
    return true;
  }
}
