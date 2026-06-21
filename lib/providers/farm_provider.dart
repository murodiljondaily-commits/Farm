import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/db_service.dart';
import '../services/auth_service.dart';
import '../services/google_auth_service.dart';

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

  Future<void> touch() => AuthService.touch();

  /// Signal all listeners (e.g. animals_screen) to reload after an AI write.
  void notifyDirty() => notifyListeners();

  Future<void> logout() async {
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
