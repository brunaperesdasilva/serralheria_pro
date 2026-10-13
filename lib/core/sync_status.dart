import 'package:flutter/foundation.dart';

enum SyncStatus { synced, syncing, offline, error }

class SyncStatusController {
  final ValueNotifier<SyncStatus> status =
      ValueNotifier<SyncStatus>(SyncStatus.synced);
  final Map<String, ({bool pending, bool fromCache})> _sources = {};

  void update(String source, {required bool pending, required bool fromCache}) {
    _sources[source] = (pending: pending, fromCache: fromCache);
    final hasPending = _sources.values.any((value) => value.pending);
    final hasCachedSource = _sources.values.any((value) => value.fromCache);
    status.value = hasCachedSource
        ? SyncStatus.offline
        : hasPending
            ? SyncStatus.syncing
            : SyncStatus.synced;
  }

  void reportError() => status.value = SyncStatus.error;

  void reset() {
    _sources.clear();
    status.value = SyncStatus.synced;
  }
}

abstract final class AppSync {
  static final SyncStatusController controller = SyncStatusController();
}
