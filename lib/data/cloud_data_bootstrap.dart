import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/sync_status.dart';
import 'app_data.dart';
import 'database_helper.dart';
import 'migration/local_to_firestore_migrator.dart';
import 'repositories/firebase/firestore_repositories.dart';
import 'repositories/sqlite/sqlite_repositories.dart';

abstract final class CloudDataBootstrap {
  static String? _activeUserId;

  static Future<void> initialize(String userId) async {
    if (_activeUserId == userId) return;
    final firestore = FirebaseFirestore.instance;
    final local = SqliteAppRepositories(DatabaseHelper.instance);
    final cloud = FirestoreAppRepositories(firestore, userId);
    await LocalToFirestoreMigrator(firestore, userId)
        .migrate(local: local, cloud: cloud);
    await AppData.init(withRepositories: cloud);
    AppData.watchRealtime();
    _activeUserId = userId;
  }

  static void reset() {
    AppData.stopWatching();
    AppSync.controller.reset();
    _activeUserId = null;
  }
}
