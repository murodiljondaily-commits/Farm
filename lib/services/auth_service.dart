import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const _kUserId = 'userId';
  static const _kFarmId = 'farmId';
  static const _kUserName = 'userName';
  static const _kUserRole = 'userRole';
  static const _kPinHash = 'pinHash';
  static const _kPinVerified = 'pinVerified';
  static const _kLastActive = 'lastActive';

  static String hashPin(String pin) {
    final bytes = utf8.encode(pin);
    return sha256.convert(bytes).toString();
  }

  /// Full session save (requires existing pinHash).
  static Future<void> saveSession({
    required String userId,
    required String farmId,
    required String name,
    required String role,
    required String pinHash,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUserId, userId);
    await prefs.setString(_kFarmId, farmId);
    await prefs.setString(_kUserName, name);
    await prefs.setString(_kUserRole, role);
    await prefs.setString(_kPinHash, pinHash);
    await prefs.setBool(_kPinVerified, false);
    await _touch();
  }

  /// Saves everything except pinHash. Called after registration, before PIN setup.
  static Future<void> saveSessionPartial({
    required String userId,
    required String farmId,
    required String name,
    required String role,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUserId, userId);
    await prefs.setString(_kFarmId, farmId);
    await prefs.setString(_kUserName, name);
    await prefs.setString(_kUserRole, role);
    await prefs.setBool(_kPinVerified, false);
    await _touch();
  }

  /// Called from pin_setup_screen after the user creates their PIN.
  static Future<void> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPinHash, hashPin(pin));
    await prefs.setBool(_kPinVerified, true);
    await _touch();
  }

  /// Verifies current PIN then replaces it with newPin.
  static Future<bool> updatePin(String currentPin, String newPin) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_kPinHash);
    if (stored == null) return false;
    if (hashPin(currentPin) != stored) return false;
    await prefs.setString(_kPinHash, hashPin(newPin));
    return true;
  }

  static Future<Map<String, String?>> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'userId': prefs.getString(_kUserId),
      'farmId': prefs.getString(_kFarmId),
      'userName': prefs.getString(_kUserName),
      'userRole': prefs.getString(_kUserRole),
      'pinHash': prefs.getString(_kPinHash),
    };
  }

  static Future<bool> hasPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kPinHash) != null;
  }

  static Future<bool> isPinVerified() async {
    final prefs = await SharedPreferences.getInstance();
    final verified = prefs.getBool(_kPinVerified) ?? false;
    if (!verified) return false;
    final lastStr = prefs.getString(_kLastActive);
    if (lastStr == null) return false;
    final last = DateTime.tryParse(lastStr);
    if (last == null) return false;
    if (DateTime.now().difference(last).inMinutes >= 30) {
      await lock();
      return false;
    }
    return true;
  }

  static Future<bool> verifyPin(String enteredPin) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_kPinHash);
    if (stored == null) return false;
    final match = hashPin(enteredPin) == stored;
    if (match) {
      await prefs.setBool(_kPinVerified, true);
      await _touch();
    }
    return match;
  }

  static Future<void> touch() => _touch();
  static Future<void> _touch() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLastActive, DateTime.now().toIso8601String());
  }

  static Future<void> lock() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPinVerified, false);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<bool> hasSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kUserId) != null;
  }
}
