import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/db_service.dart';
import '../services/auth_service.dart';
import '../services/google_auth_service.dart';
import '../services/vet_ai_service.dart';
import '../services/firestore_live_service.dart';

class FarmProvider extends ChangeNotifier {
  String? _farmId;
  String? _userId;
  String? _userName;
  String? _userRole;
  Farm? _farm;
  bool _pinVerified = false;
  bool _hasPin = false;
  bool _loading = false;
  bool _googleSignedIn = false;
  String? _error;
  List<Farm> _availableFarms = [];
  int? _identityId;
  int _aiWriteCount = 0;

  String? get farmId => _farmId;
  String? get userId => _userId;
  String? get userName => _userName;
  String? get userRole => _userRole;
  Farm? get farm => _farm;
  bool get pinVerified => _pinVerified;
  bool get hasPin => _hasPin;
  bool get loading => _loading;
  bool get googleSignedIn => _googleSignedIn;
  String? get error => _error;
  List<Farm> get availableFarms => _availableFarms;
  bool get needsFarmPicker => _googleSignedIn && _userId == null && _availableFarms.isNotEmpty;
  bool get isOwner => _userRole == 'owner' || _userRole == 'coowner';
  bool get isVet => _userRole == 'vet';
  int get aiWriteCount => _aiWriteCount;

  Future<void> init() async {
    debugPrint('[FarmProvider] init() started');
    _loading = true;
    notifyListeners();
    try {
      debugPrint('[FarmProvider] step 0 — GoogleAuthService.isSignedIn');
      _googleSignedIn = GoogleAuthService.isSignedIn;
      debugPrint('[FarmProvider] googleSignedIn=$_googleSignedIn');

      debugPrint('[FarmProvider] step 1 — AuthService.getSession()');
      final session = await AuthService.getSession();
      debugPrint('[FarmProvider] session result: userId=${session['userId']} '
          'farmId=${session['farmId']} role=${session['userRole']} '
          'hasPinHash=${session['pinHash'] != null}');
      _userId = session['userId'];
      _farmId = session['farmId'];
      _userName = session['userName'];
      _userRole = session['userRole'];
      _hasPin = session['pinHash'] != null;

      // If signed in but no local session, load all farms via unified identity.
      if (_googleSignedIn && _userId == null) {
        await _loadIdentityFarms();
        debugPrint('[FarmProvider] availableFarms=${_availableFarms.length}');
      } else {
        _availableFarms = [];
      }

      debugPrint('[FarmProvider] step 2 — AuthService.isPinVerified()');
      _pinVerified = await AuthService.isPinVerified();
      debugPrint('[FarmProvider] pinVerified=$_pinVerified');

      if (_farmId != null) {
        debugPrint('[FarmProvider] step 3 — DbService.getFarm($_farmId)');
        _farm = await DbService.getFarm(_farmId!);
        debugPrint('[FarmProvider] farm loaded: ${_farm?.farmName}');
        // Opportunistic live sync: only meaningful with a real Firebase Auth
        // session (Security Rules require request.auth.uid == owner_uid).
        // Silently does nothing signed-out/offline — SQLite + notifyDirty()
        // remain the source of truth exactly as before this existed.
        if (FirebaseAuth.instance.currentUser != null) {
          FirestoreLiveService.start(_farmId!, notifyDirty);
        }
      } else {
        debugPrint('[FarmProvider] step 3 — skipped (no farmId)');
      }
    } catch (e, st) {
      debugPrint('[FarmProvider] init() ERROR: $e');
      debugPrint('[FarmProvider] stackTrace: $st');
      _error = e.toString();
    } finally {
      debugPrint('[FarmProvider] init() done — '
          'userId=$_userId farmId=$_farmId hasPin=$_hasPin '
          'pinVerified=$_pinVerified loading→false');
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refreshFarm() async {
    if (_farmId != null) {
      _farm = await DbService.getFarm(_farmId!);
      notifyListeners();
    }
  }

  void updateUserName(String name) {
    _userName = name;
    notifyListeners();
  }

  Future<bool> verifyPin(String pin) async {
    final ok = await AuthService.verifyPin(pin);
    if (ok) {
      _pinVerified = true;
      notifyListeners();
    }
    return ok;
  }

  Future<void> lock() async {
    await AuthService.lock();
    _pinVerified = false;
    notifyListeners();
  }

  // ── Trusted background tasks (image_picker, share sheets, etc.) ───────────
  // Backgrounding the app to launch a system picker can legitimately take
  // longer than the 60s auto-lock threshold (permission dialogs, browsing a
  // large gallery). Screens wrap such calls in begin/end so the security
  // lock in main.dart doesn't misfire mid-workflow. Counter-based so nested
  // or overlapping trusted calls are safe.
  int _suppressLockDepth = 0;
  bool get suppressAutoLock => _suppressLockDepth > 0;

  void beginTrustedBackgroundTask() => _suppressLockDepth++;
  void endTrustedBackgroundTask() {
    if (_suppressLockDepth > 0) _suppressLockDepth--;
  }

  Future<void> touch() => AuthService.touch();

  /// Signal all listeners (e.g. animals_screen) to reload after an AI write.
  void notifyDirty() {
    _aiWriteCount++;
    notifyListeners();
  }

  Future<void> logout() async {
    FirestoreLiveService.stop();
    await GoogleAuthService.signOut();
    await AuthService.logout();
    _farmId = null;
    _userId = null;
    _userName = null;
    _userRole = null;
    _farm = null;
    _pinVerified = false;
    _hasPin = false;
    _googleSignedIn = false;
    notifyListeners();
  }

  /// Upserts the unified_identity for the currently signed-in Firebase user,
  /// merges farms from the identity table with legacy farms stored by owner_uid,
  /// and links any legacy farms into the identity for future lookups.
  Future<void> _loadIdentityFarms() async {
    final uid = GoogleAuthService.uid;
    if (uid == null) return;
    final phone = FirebaseAuth.instance.currentUser?.phoneNumber;
    _identityId = await DbService.upsertIdentity(uid, phoneNumber: phone);
    final identityFarms = await DbService.getFarmsByIdentity(_identityId!);
    final uidFarms = await DbService.getFarmsByUid(uid);
    final allMap = <String, Farm>{};
    for (final f in identityFarms) {
      allMap[f.farmId] = f;
    }
    for (final f in uidFarms) {
      allMap[f.farmId] = f;
      // Link legacy farms (created before identity system) into identity.
      await DbService.linkFarmToIdentity(_identityId!, f.farmId);
    }

    // Cross-device restore: fetch farms this Google account owns from the backend
    // (Firestore), since a fresh install has no local SQLite record of them.
    try {
      final email = FirebaseAuth.instance.currentUser?.email;
      final remote = await VetAiService.lookupFarmsByOwner(uid: uid, email: email);
      for (final r in remote) {
        final farmId = r['farm_id'] as String?;
        if (farmId == null || allMap.containsKey(farmId)) continue;
        final farm = Farm(
          farmId: farmId,
          farmName: r['farm_name'] as String? ?? '',
          farmCode: r['farm_code'] as String? ?? '',
          location: r['location'] as String? ?? '',
          ownerName: r['owner_name'] as String? ?? '',
          ownerEmail: r['owner_email'] as String?,
          ownerUid: r['owner_uid'] as String? ?? uid,
        );
        await DbService.saveFarm(farm); // persist locally so selectFarm() works
        await DbService.linkFarmToIdentity(_identityId!, farmId);
        allMap[farmId] = farm;
      }
    } catch (e) {
      debugPrint('[FarmProvider] remote farm restore failed: $e');
    }

    _availableFarms = allMap.values.toList();
  }

  Future<void> setGoogleSignedIn() async {
    _googleSignedIn = true;
    if (_userId == null) {
      await _loadIdentityFarms();
      debugPrint('[FarmProvider] setGoogleSignedIn: availableFarms=${_availableFarms.length}');
    }
    notifyListeners();
  }

  /// Links [farmId] to the currently signed-in user's unified identity.
  /// No-op when the user is not signed in (e.g. fresh install, no auth yet).
  Future<void> linkCurrentIdentityToFarm(String farmId) async {
    if (_identityId == null) return;
    await DbService.linkFarmToIdentity(_identityId!, farmId);
    debugPrint('[FarmProvider] linked farm $farmId to identity $_identityId');
  }

  Future<void> selectFarm(Farm farm) async {
    final userId = farm.ownerUserId ?? DateTime.now().millisecondsSinceEpoch.toString();
    await AuthService.saveSessionPartial(
      userId: userId,
      farmId: farm.farmId,
      name: farm.ownerName,
      role: 'owner',
    );
    _availableFarms = [];
    await init();
  }

  Future<void> reloadFarm() async {
    if (_farmId == null) return;
    _farm = await DbService.getFarm(_farmId!);
    notifyListeners();
  }
}
