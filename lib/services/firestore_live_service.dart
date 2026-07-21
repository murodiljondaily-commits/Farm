import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/models.dart';
import 'db_service.dart';

/// Opportunistic live sync: mirrors Firestore changes for the current farm
/// into local SQLite, then calls back (FarmProvider.notifyDirty) so the UI
/// refreshes through the exact same mechanism already used for AI-confirmed
/// writes — no second, parallel state-update path. Requires the Security
/// Rules in agrivet-backend/firestore.rules (read-only, owner_uid-scoped);
/// all writes still go exclusively through the backend's admin SDK.
///
/// Fails silently (signed-out, offline, rules mismatch) — SQLite stays the
/// source of truth for reads exactly as it did before this existed, so a
/// listener error never breaks the app, it just means "not live right now."
class FirestoreLiveService {
  static StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _animalsSub;
  static StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _casesSub;
  static String? _activeFarmId;

  static void start(String farmId, void Function() onChange) {
    if (_activeFarmId == farmId && _animalsSub != null) return; // already running
    stop();
    _activeFarmId = farmId;

    final farmRef = FirebaseFirestore.instance.collection('farms').doc(farmId);

    _animalsSub = farmRef.collection('animals').snapshots().listen((snap) async {
      for (final change in snap.docChanges) {
        if (change.type == DocumentChangeType.removed) continue;
        final data = change.doc.data();
        if (data == null) continue;
        data['ear_tag'] = change.doc.id;
        data['farm_id'] = farmId;
        await DbService.saveAnimal(Animal.fromMap(data));
      }
      if (snap.docChanges.isNotEmpty) onChange();
    }, onError: (Object e) {
      // ignore: avoid_print
      print('[FirestoreLiveService] animals listener stopped: $e');
    });

    _casesSub = farmRef.collection('cases').snapshots().listen((snap) async {
      for (final change in snap.docChanges) {
        if (change.type == DocumentChangeType.removed) continue;
        final data = change.doc.data();
        if (data == null) continue;
        data['case_id'] = change.doc.id;
        await DbService.upsertCaseFromFirestore(farmId, data);
      }
      if (snap.docChanges.isNotEmpty) onChange();
    }, onError: (Object e) {
      // ignore: avoid_print
      print('[FirestoreLiveService] cases listener stopped: $e');
    });
  }

  static void stop() {
    _animalsSub?.cancel();
    _casesSub?.cancel();
    _animalsSub = null;
    _casesSub = null;
    _activeFarmId = null;
  }
}
