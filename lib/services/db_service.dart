import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/models.dart';

class DbService {
  static Database? _db;
  static const _dbName = 'agrivet.db';
  static const _version = 7;

  static Future<Database> get db async {
    _db ??= await _open();
    return _db!;
  }

  static Future<Database> _open() async {
    final dir = await getDatabasesPath();
    final path = p.join(dir, _dbName);
    return openDatabase(
      path,
      version: _version,
      onCreate: _create,
      onUpgrade: _upgrade,
    );
  }

  static Future<void> _upgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE farms ADD COLUMN owner_phone TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE farms ADD COLUMN owner_uid TEXT');
      await db.execute('ALTER TABLE farms ADD COLUMN owner_user_id TEXT');
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS unified_identity (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          firebase_uid TEXT UNIQUE,
          phone_number TEXT UNIQUE,
          linked_farm_ids TEXT NOT NULL DEFAULT '[]',
          created_at TEXT NOT NULL,
          last_login TEXT
        )
      ''');
    }
    if (oldVersion < 5) {
      // New columns on cases table for AI diagnostics
      try { await db.execute('ALTER TABLE cases ADD COLUMN body_part TEXT'); } catch(_) {}
      try { await db.execute('ALTER TABLE cases ADD COLUMN first_aid_json TEXT'); } catch(_) {}
      try { await db.execute('ALTER TABLE cases ADD COLUMN photo_url TEXT'); } catch(_) {}
      try { await db.execute('ALTER TABLE cases ADD COLUMN ai_model TEXT'); } catch(_) {}
      // Anonymised knowledge base for RAG
      await db.execute('''
        CREATE TABLE IF NOT EXISTS rag_knowledge (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          species TEXT,
          breed TEXT,
          animal_age_months INTEGER,
          body_part TEXT,
          symptoms TEXT,
          visual_findings TEXT,
          diagnosis TEXT,
          treatment TEXT,
          medicine TEXT,
          outcome TEXT,
          recovery_days INTEGER,
          region TEXT,
          season TEXT,
          confidence_score REAL,
          confirmed_by_vet INTEGER DEFAULT 0,
          created_at TEXT
        )
      ''');
    }
    if (oldVersion < 6) {
      try { await db.execute('ALTER TABLE animals ADD COLUMN pregnancy_month INTEGER'); } catch(_) {}
    }
    if (oldVersion < 7) {
      try { await db.execute('ALTER TABLE animals ADD COLUMN death_reason TEXT'); } catch(_) {}
    }
  }

  static Future<void> _create(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS farms (
        farm_id TEXT PRIMARY KEY,
        farm_name TEXT NOT NULL,
        farm_code TEXT UNIQUE,
        location TEXT,
        owner_telegram_id TEXT,
        owner_name TEXT,
        owner_email TEXT,
        owner_phone TEXT,
        owner_uid TEXT,
        owner_user_id TEXT,
        sheet_url TEXT,
        drive_folder_id TEXT,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        telegram_id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        role TEXT DEFAULT 'farmer',
        farm_id TEXT,
        email TEXT,
        phone TEXT,
        pin_hash TEXT,
        session_locked INTEGER DEFAULT 0,
        last_active TEXT,
        is_approved INTEGER DEFAULT 0,
        approved INTEGER DEFAULT 0,
        voice_mode INTEGER DEFAULT 0,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS animals (
        ear_tag TEXT NOT NULL,
        farm_id TEXT NOT NULL,
        species TEXT,
        breed TEXT,
        sex TEXT DEFAULT 'nomalum',
        dob TEXT,
        name TEXT,
        color TEXT,
        origin TEXT,
        status TEXT DEFAULT 'soglom',
        mother_ear_tag TEXT,
        father_ear_tag TEXT,
        animal_type TEXT DEFAULT 'adult',
        photo_file_id TEXT,
        photo_drive_url TEXT,
        pregnancy_status TEXT DEFAULT 'none',
        pregnancy_month INTEGER,
        expected_birth_date TEXT,
        mating_date TEXT,
        death_reason TEXT,
        created_at TEXT,
        PRIMARY KEY (ear_tag, farm_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS cases (
        case_id INTEGER PRIMARY KEY AUTOINCREMENT,
        ear_tag TEXT,
        farm_id TEXT,
        symptoms_farmer TEXT,
        diagnosis TEXT,
        treatment TEXT,
        medicine_used TEXT,
        ai_suggestion TEXT,
        ai_confidence INTEGER,
        severity TEXT DEFAULT 'routine',
        status TEXT DEFAULT 'open',
        vet_notified INTEGER DEFAULT 0,
        reported_by TEXT,
        reported_by_role TEXT,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS vaccinations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ear_tag TEXT,
        farm_id TEXT,
        vaccine_name TEXT,
        date TEXT,
        next_due TEXT,
        administered_by TEXT,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS weight_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ear_tag TEXT,
        farm_id TEXT,
        weight REAL,
        measured_at TEXT,
        recorded_by TEXT,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS milk_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        farm_id TEXT,
        amount_liters REAL,
        timing TEXT,
        recorded_by TEXT,
        recorded_at TEXT,
        notes TEXT,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS births (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        farm_id TEXT,
        offspring_ear_tag TEXT,
        offspring_name TEXT,
        mother_ear_tag TEXT,
        father_ear_tag TEXT,
        birth_date TEXT,
        birth_weight REAL,
        sex TEXT,
        breed TEXT,
        notes TEXT,
        recorded_by TEXT,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_session (
        id INTEGER PRIMARY KEY,
        user_id TEXT,
        farm_id TEXT,
        pin_verified INTEGER DEFAULT 0,
        last_active TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS rag_knowledge (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        species TEXT,
        breed TEXT,
        animal_age_months INTEGER,
        body_part TEXT,
        symptoms TEXT,
        visual_findings TEXT,
        diagnosis TEXT,
        treatment TEXT,
        medicine TEXT,
        outcome TEXT,
        recovery_days INTEGER,
        region TEXT,
        season TEXT,
        confidence_score REAL,
        confirmed_by_vet INTEGER DEFAULT 0,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS unified_identity (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        firebase_uid TEXT UNIQUE,
        phone_number TEXT UNIQUE,
        linked_farm_ids TEXT NOT NULL DEFAULT '[]',
        created_at TEXT NOT NULL,
        last_login TEXT
      )
    ''');
  }

  // ─── Animals ────────────────────────────────────────────────────────────────

  static Future<List<Animal>> getAnimals(String farmId, {String? species, bool youngOnly = false}) async {
    final database = await db;
    String where = 'farm_id = ? AND status NOT IN (\'sotildi\', \'oldi\')';
    final args = <dynamic>[farmId];
    final cutoff = DateTime(DateTime.now().year - 2, DateTime.now().month, DateTime.now().day)
        .toIso8601String()
        .substring(0, 10);
    if (species != null) {
      where += ' AND species = ?';
      args.add(species);
      if (!youngOnly) {
        // Exclude animals < 24 months old — they appear in the young-animals tab
        where += ' AND (dob IS NULL OR dob < ?)';
        args.add(cutoff);
      }
    }
    if (youngOnly) {
      where += ' AND dob >= ?';
      args.add(cutoff);
    }
    final rows = await database.query('animals',
        where: where, whereArgs: args, orderBy: 'name ASC, ear_tag ASC');
    return rows.map(Animal.fromMap).toList();
  }

  static Future<Animal?> getAnimal(String farmId, String earTag) async {
    final database = await db;
    final rows = await database.rawQuery(
      'SELECT * FROM animals WHERE farm_id = ? AND UPPER(ear_tag) = UPPER(?)',
      [farmId, earTag],
    );
    return rows.isEmpty ? null : Animal.fromMap(rows.first);
  }

  static Future<Map<String, int>> getSpeciesCounts(String farmId) async {
    final database = await db;
    final rows = await database.rawQuery(
        '''SELECT species, COUNT(*) as cnt FROM animals
           WHERE farm_id = ? AND status NOT IN ('sotildi', 'oldi')
           GROUP BY species''',
        [farmId]);
    return {for (var r in rows) r['species'] as String: r['cnt'] as int};
  }

  /// Returns { species → { status → count } } for the 4 health stages.
  static Future<Map<String, Map<String, int>>> getHealthBySpecies(String farmId) async {
    final database = await db;
    final rows = await database.rawQuery(
      '''SELECT species, status, COUNT(*) as cnt
         FROM animals
         WHERE farm_id = ? AND status IN ('soglom','davolanmoqda','kuzatuvda','kritik')
         GROUP BY species, status''',
      [farmId],
    );
    final result = <String, Map<String, int>>{};
    for (final row in rows) {
      final sp = row['species'] as String;
      final st = row['status'] as String;
      final cnt = (row['cnt'] as int?) ?? 0;
      result.putIfAbsent(sp, () => {});
      result[sp]![st] = cnt;
    }
    return result;
  }

  /// Returns { status → count } for animals younger than 2 years.
  static Future<Map<String, int>> getHealthByYoungAnimals(String farmId) async {
    final database = await db;
    final cutoff = DateTime(DateTime.now().year - 2, DateTime.now().month, DateTime.now().day)
        .toIso8601String()
        .substring(0, 10);
    final rows = await database.rawQuery(
      '''SELECT status, COUNT(*) as cnt
         FROM animals
         WHERE farm_id = ? AND dob >= ? AND status IN ('soglom','davolanmoqda','kuzatuvda','kritik')
         GROUP BY status''',
      [farmId, cutoff],
    );
    return {for (final r in rows) r['status'] as String: (r['cnt'] as int?) ?? 0};
  }

  /// Returns { species → { status → count } } for animals younger than 2 years.
  static Future<Map<String, Map<String, int>>> getHealthBySpeciesYoungAnimals(String farmId) async {
    final database = await db;
    final cutoff = DateTime(DateTime.now().year - 2, DateTime.now().month, DateTime.now().day)
        .toIso8601String()
        .substring(0, 10);
    final rows = await database.rawQuery(
      '''SELECT species, status, COUNT(*) as cnt
         FROM animals
         WHERE farm_id = ? AND dob >= ? AND status IN ('soglom','davolanmoqda','kuzatuvda','kritik')
         GROUP BY species, status''',
      [farmId, cutoff],
    );
    final result = <String, Map<String, int>>{};
    for (final row in rows) {
      final sp = row['species'] as String;
      final st = row['status'] as String;
      final cnt = (row['cnt'] as int?) ?? 0;
      result.putIfAbsent(sp, () => {});
      result[sp]![st] = cnt;
    }
    return result;
  }

  static Future<void> saveAnimal(Animal a) async {
    final database = await db;
    await database.insert(
      'animals',
      {
        'ear_tag': a.earTag,
        'farm_id': a.farmId,
        'species': a.species,
        'breed': a.breed,
        'sex': a.sex,
        'dob': a.dob,
        'name': a.name,
        'color': a.color,
        'origin': a.origin,
        'status': a.status,
        'mother_ear_tag': a.motherEarTag,
        'father_ear_tag': a.fatherEarTag,
        'animal_type': a.animalType,
        'pregnancy_status': a.pregnancyStatus,
        'pregnancy_month': a.pregnancyMonth,
        'expected_birth_date': a.expectedBirthDate,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> updateAnimalStatus(
      String farmId, String earTag, String status, {String? deathReason}) async {
    final database = await db;
    final data = {'status': status};
    if (deathReason != null) data['death_reason'] = deathReason;
    await database.update('animals', data,
        where: 'farm_id = ? AND ear_tag = ?', whereArgs: [farmId, earTag]);
  }

  static Future<void> deleteAnimal(String farmId, String earTag) async {
    final database = await db;
    await database.delete('animals',
        where: 'farm_id = ? AND ear_tag = ?', whereArgs: [farmId, earTag]);
  }

  static Future<List<Animal>> getArchivedAnimals(String farmId) async {
    final database = await db;
    final rows = await database.query(
      'animals',
      where: "farm_id = ? AND status IN ('sotildi', 'oldi')",
      whereArgs: [farmId],
      orderBy: 'name ASC, ear_tag ASC',
    );
    return rows.map(Animal.fromMap).toList();
  }

  static Future<void> updateAnimalPregnancy(
      String farmId, String earTag, String status, int? month) async {
    final database = await db;
    await database.update(
      'animals',
      {'pregnancy_status': status, 'pregnancy_month': month},
      where: 'farm_id = ? AND UPPER(ear_tag) = UPPER(?)',
      whereArgs: [farmId, earTag],
    );
  }

  // ─── Health Cases ────────────────────────────────────────────────────────────

  static Future<List<HealthCase>> getCases(String farmId,
      {String? earTag, String? status}) async {
    final database = await db;
    var where = 'farm_id = ?';
    final args = <dynamic>[farmId];
    if (earTag != null) {
      where += ' AND ear_tag = ?';
      args.add(earTag);
    }
    if (status != null) {
      where += ' AND status = ?';
      args.add(status);
    }
    final rows = await database.query('cases',
        where: where, whereArgs: args, orderBy: 'created_at DESC', limit: 20);
    return rows.map(HealthCase.fromMap).toList();
  }

  static Future<int> saveCase(Map<String, dynamic> data) async {
    final database = await db;
    return database.insert('cases', data);
  }

  static Future<void> updateCaseStatus(String caseId, String status) async {
    final database = await db;
    await database.update('cases', {'status': status},
        where: 'case_id = ?', whereArgs: [caseId]);
  }

  static Future<void> closeCaseWithOutcome(
    String caseId,
    String outcome, {
    int? recoveryDays,
    bool vetConfirmed = false,
  }) async {
    final database = await db;
    await database.update(
      'cases',
      {
        'status': 'closed',
        'outcome': outcome,
        'recovery_days': recoveryDays,
      },
      where: 'case_id = ?',
      whereArgs: [caseId],
    );
  }

  /// Deletes a case record and auto-reverts animal to 'soglom' if no open cases remain.
  static Future<void> deleteHealthCase(
      String caseId, String farmId, String earTag) async {
    final database = await db;
    await database.delete('cases', where: 'case_id = ?', whereArgs: [caseId]);
    final remaining = await database.query(
      'cases',
      where: "farm_id = ? AND ear_tag = ? AND status = 'open'",
      whereArgs: [farmId, earTag],
    );
    if (remaining.isEmpty) {
      await database.update('animals', {'status': 'soglom'},
          where: 'farm_id = ? AND ear_tag = ?', whereArgs: [farmId, earTag]);
    }
  }

  // ─── Vaccinations ────────────────────────────────────────────────────────────

  static Future<List<Vaccination>> getVaccinations(String farmId,
      {String? earTag}) async {
    final database = await db;
    final rows = await database.query(
      'vaccinations',
      where: earTag != null ? 'farm_id = ? AND ear_tag = ?' : 'farm_id = ?',
      whereArgs: earTag != null ? [farmId, earTag] : [farmId],
      orderBy: 'date DESC',
      limit: 20,
    );
    return rows.map(Vaccination.fromMap).toList();
  }

  static Future<List<Vaccination>> getDueVaccinations(String farmId) async {
    final database = await db;
    final threeDaysFromNow =
        DateTime.now().add(const Duration(days: 3)).toIso8601String().substring(0, 10);
    final rows = await database.query(
      'vaccinations',
      where: 'farm_id = ? AND next_due <= ?',
      whereArgs: [farmId, threeDaysFromNow],
      orderBy: 'next_due ASC',
    );
    return rows.map(Vaccination.fromMap).toList();
  }

  static Future<void> saveVaccination(Map<String, dynamic> data) async {
    final database = await db;
    await database.insert('vaccinations', data);
  }

  static Future<void> deleteVaccination(String id) async {
    final database = await db;
    await database.delete('vaccinations', where: 'id = ?', whereArgs: [id]);
  }

  // ─── Weight ──────────────────────────────────────────────────────────────────

  static Future<List<WeightEntry>> getWeights(String farmId,
      {String? earTag}) async {
    final database = await db;
    final rows = await database.query(
      'weight_log',
      where: earTag != null ? 'farm_id = ? AND ear_tag = ?' : 'farm_id = ?',
      whereArgs: earTag != null ? [farmId, earTag] : [farmId],
      orderBy: 'measured_at DESC, id DESC',
      limit: 20,
    );
    return rows.map(WeightEntry.fromMap).toList();
  }

  static Future<void> saveWeight(Map<String, dynamic> data) async {
    final database = await db;
    await database.insert('weight_log', data);
  }

  static Future<void> deleteWeight(String id) async {
    final database = await db;
    await database.delete('weight_log', where: 'id = ?', whereArgs: [id]);
  }

  // ─── Milk ────────────────────────────────────────────────────────────────────

  static Future<List<MilkEntry>> getMilkLog(String farmId) async {
    final database = await db;
    final rows = await database.query(
      'milk_log',
      where: 'farm_id = ?',
      whereArgs: [farmId],
      orderBy: 'recorded_at DESC, created_at DESC',
    );
    return rows.map(MilkEntry.fromMap).toList();
  }

  static Future<double> getTodayMilk(String farmId) async {
    final database = await db;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final rows = await database.rawQuery(
        'SELECT SUM(amount_liters) as total FROM milk_log WHERE farm_id = ? AND recorded_at = ?',
        [farmId, today]);
    return (rows.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  static Future<double> getTotalMilk(String farmId) async {
    final database = await db;
    final rows = await database.rawQuery(
        'SELECT SUM(amount_liters) as total FROM milk_log WHERE farm_id = ?',
        [farmId]);
    return (rows.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  static Future<int> countMilkEntries(
      String farmId, String date, String timing) async {
    final database = await db;
    final rows = await database.rawQuery(
        'SELECT COUNT(*) c FROM milk_log WHERE farm_id = ? AND recorded_at = ? AND timing = ?',
        [farmId, date, timing]);
    return (rows.first['c'] as int?) ?? 0;
  }

  static Future<void> saveMilk(Map<String, dynamic> data) async {
    final database = await db;
    await database.insert('milk_log', data);
  }

  static Future<void> deleteMilk(String id) async {
    final database = await db;
    await database.delete('milk_log', where: 'id = ?', whereArgs: [id]);
  }

  // ─── Births ──────────────────────────────────────────────────────────────────

  static Future<List<Birth>> getBirths(String farmId) async {
    final database = await db;
    final rows = await database.query('births',
        where: 'farm_id = ?',
        whereArgs: [farmId],
        orderBy: 'birth_date DESC',
        limit: 20);
    return rows.map(Birth.fromMap).toList();
  }

  static Future<void> saveBirth(Map<String, dynamic> data) async {
    final database = await db;
    await database.insert('births', data);
  }

  // ─── Farm ────────────────────────────────────────────────────────────────────

  static Future<Farm?> getFarm(String farmId) async {
    final database = await db;
    final rows = await database.query('farms',
        where: 'farm_id = ?', whereArgs: [farmId]);
    return rows.isEmpty ? null : Farm.fromMap(rows.first);
  }

  static Future<Farm?> getFarmByCode(String farmCode) async {
    final database = await db;
    final rows = await database.query('farms',
        where: 'farm_code = ?', whereArgs: [farmCode]);
    return rows.isEmpty ? null : Farm.fromMap(rows.first);
  }

  static Future<void> saveUser(Map<String, dynamic> data) async {
    final database = await db;
    await database.insert('users', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Map<String, dynamic>>> getPendingUsers(String farmId) async {
    final database = await db;
    return database.query('users',
        where: 'farm_id = ? AND is_approved = 0', whereArgs: [farmId]);
  }

  static Future<void> approveUser(String telegramId) async {
    final database = await db;
    await database.update('users', {'is_approved': 1, 'approved': 1},
        where: 'telegram_id = ?', whereArgs: [telegramId]);
  }

  static Future<void> saveFarm(Farm farm) async {
    final database = await db;
    await database.insert(
      'farms',
      {
        'farm_id': farm.farmId,
        'farm_name': farm.farmName,
        'farm_code': farm.farmCode,
        'location': farm.location,
        'owner_name': farm.ownerName,
        'owner_email': farm.ownerEmail,
        'owner_phone': farm.phone,
        'owner_uid': farm.ownerUid,
        'owner_user_id': farm.ownerUserId,
        'sheet_url': farm.sheetUrl,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> updateFarmInfo(String farmId, String name, String location) async {
    final database = await db;
    await database.update('farms', {'farm_name': name, 'location': location},
        where: 'farm_id = ?', whereArgs: [farmId]);
  }

  static Future<void> updateFarmSheetUrl(String farmId, String sheetUrl) async {
    final database = await db;
    await database.update('farms', {'sheet_url': sheetUrl},
        where: 'farm_id = ?', whereArgs: [farmId]);
  }

  static Future<void> updateUserInfo(String userId, {String? name, String? phone}) async {
    final database = await db;
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (phone != null) data['phone'] = phone;
    if (data.isEmpty) return;
    await database.update('users', data,
        where: 'telegram_id = ?', whereArgs: [userId]);
  }

  static Future<List<Farm>> getFarmsByUid(String uid) async {
    final database = await db;
    final rows = await database.query('farms',
        where: 'owner_uid = ?', whereArgs: [uid], orderBy: 'created_at DESC');
    return rows.map(Farm.fromMap).toList();
  }

  // ─── RAG Knowledge ───────────────────────────────────────────────────────────

  static Future<void> saveRagKnowledge(Map<String, dynamic> data) async {
    final database = await db;
    await database.insert('rag_knowledge', data,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Simple text-contains match: returns up to [limit] rows whose symptoms
  /// overlap with the given [symptoms] list, optionally filtered by species.
  static Future<List<Map<String, dynamic>>> searchRagKnowledge({
    String? species,
    List<String> symptoms = const [],
    int limit = 5,
  }) async {
    final database = await db;
    if (symptoms.isEmpty) return [];
    // Build OR conditions for each symptom keyword
    final conditions = symptoms
        .where((s) => s.isNotEmpty)
        .map((s) => "symptoms LIKE '%${s.replaceAll("'", "''")}%'")
        .join(' OR ');
    final where = species != null
        ? 'species = ? AND ($conditions)'
        : conditions;
    final args = species != null ? [species] : <dynamic>[];
    final rows = await database.query(
      'rag_knowledge',
      where: where.isEmpty ? null : where,
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'confirmed_by_vet DESC, confidence_score DESC',
      limit: limit,
    );
    return rows;
  }

  // ─── Users / Vet contact ─────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getVetUsers(String farmId) async {
    final database = await db;
    return database.query(
      'users',
      where: "farm_id = ? AND role = 'vet' AND is_approved = 1",
      whereArgs: [farmId],
    );
  }

  // ─── Unified Identity ────────────────────────────────────────────────────────

  /// Creates or updates an identity record for [firebaseUid].
  /// If [phoneNumber] is provided and a separate identity exists for that phone,
  /// the two are merged into one (cross-auth linking).
  /// Returns the integer primary key of the identity row.
  static Future<int> upsertIdentity(String firebaseUid,
      {String? phoneNumber}) async {
    final database = await db;
    final now = DateTime.now().toIso8601String();

    // 1. Existing identity by UID?
    var rows = await database.query('unified_identity',
        where: 'firebase_uid = ?', whereArgs: [firebaseUid]);
    if (rows.isNotEmpty) {
      final id = rows.first['id'] as int;
      final updates = <String, dynamic>{'last_login': now};
      if (phoneNumber != null && rows.first['phone_number'] == null) {
        updates['phone_number'] = phoneNumber;
      }
      await database.update('unified_identity', updates,
          where: 'id = ?', whereArgs: [id]);
      return id;
    }

    // 2. Cross-auth: existing identity by phone?
    if (phoneNumber != null) {
      rows = await database.query('unified_identity',
          where: 'phone_number = ?', whereArgs: [phoneNumber]);
      if (rows.isNotEmpty) {
        final id = rows.first['id'] as int;
        await database.update('unified_identity',
            {'firebase_uid': firebaseUid, 'last_login': now},
            where: 'id = ?', whereArgs: [id]);
        return id;
      }
    }

    // 3. New identity
    return database.insert('unified_identity', {
      'firebase_uid': firebaseUid,
      'phone_number': phoneNumber,
      'linked_farm_ids': '[]',
      'created_at': now,
      'last_login': now,
    });
  }

  /// Adds [farmId] to the identity's linked_farm_ids list (idempotent).
  static Future<void> linkFarmToIdentity(int identityId, String farmId) async {
    final database = await db;
    final rows = await database.query('unified_identity',
        columns: ['linked_farm_ids'],
        where: 'id = ?',
        whereArgs: [identityId]);
    if (rows.isEmpty) return;
    final List<dynamic> ids =
        jsonDecode(rows.first['linked_farm_ids'] as String? ?? '[]');
    if (ids.contains(farmId)) return;
    ids.add(farmId);
    await database.update('unified_identity',
        {'linked_farm_ids': jsonEncode(ids)},
        where: 'id = ?', whereArgs: [identityId]);
  }

  /// Returns all farms whose IDs are stored in the identity's linked_farm_ids.
  static Future<List<Farm>> getFarmsByIdentity(int identityId) async {
    final database = await db;
    final rows = await database.query('unified_identity',
        columns: ['linked_farm_ids'],
        where: 'id = ?',
        whereArgs: [identityId]);
    if (rows.isEmpty) return [];
    final List<dynamic> ids =
        jsonDecode(rows.first['linked_farm_ids'] as String? ?? '[]');
    if (ids.isEmpty) return [];
    final result = <Farm>[];
    for (final fid in ids) {
      final farmRows = await database
          .query('farms', where: 'farm_id = ?', whereArgs: [fid as String]);
      if (farmRows.isNotEmpty) result.add(Farm.fromMap(farmRows.first));
    }
    return result;
  }

  // ─── Report ──────────────────────────────────────────────────────────────────

  static Future<FarmReport> buildReport(String farmId, {int days = 30}) async {
    final database = await db;
    final since = DateTime.now()
        .subtract(Duration(days: days))
        .toIso8601String()
        .substring(0, 10);

    final animalCountRow = await database.rawQuery(
        'SELECT COUNT(*) c FROM animals WHERE farm_id=? AND status NOT IN (\'sotildi\',\'oldi\')',
        [farmId]);
    final soglomRow = await database.rawQuery(
        'SELECT COUNT(*) c FROM animals WHERE farm_id=? AND status=\'soglom\'',
        [farmId]);
    final davolanmoqdaRow = await database.rawQuery(
        'SELECT COUNT(*) c FROM animals WHERE farm_id=? AND status=\'davolanmoqda\'',
        [farmId]);
    final kritikRow = await database.rawQuery(
        'SELECT COUNT(*) c FROM animals WHERE farm_id=? AND status=\'kritik\'',
        [farmId]);
    final openCasesRow = await database.rawQuery(
        'SELECT COUNT(*) c FROM cases WHERE farm_id=? AND status=\'open\'',
        [farmId]);
    final closedCasesRow = await database.rawQuery(
        'SELECT COUNT(*) c FROM cases WHERE farm_id=? AND status=\'closed\' AND created_at>=?',
        [farmId, since]);
    final milkRow = await database.rawQuery(
        'SELECT SUM(amount_liters) total FROM milk_log WHERE farm_id=? AND recorded_at>=?',
        [farmId, since]);
    final birthRow = await database.rawQuery(
        'SELECT COUNT(*) c FROM births WHERE farm_id=? AND birth_date>=?',
        [farmId, since]);
    final teamRow = await database.rawQuery(
        'SELECT COUNT(*) c FROM users WHERE farm_id=? AND is_approved=1',
        [farmId]);

    final threeDays =
        DateTime.now().add(const Duration(days: 3)).toIso8601String().substring(0, 10);
    final vacDueRow = await database.rawQuery(
        'SELECT COUNT(*) c FROM vaccinations WHERE farm_id=? AND next_due<=?',
        [farmId, threeDays]);

    final totalMilk = (milkRow.first['total'] as num?)?.toDouble() ?? 0;

    return FarmReport(
      totalAnimals: (animalCountRow.first['c'] as int?) ?? 0,
      soglom: (soglomRow.first['c'] as int?) ?? 0,
      davolanmoqda: (davolanmoqdaRow.first['c'] as int?) ?? 0,
      kritik: (kritikRow.first['c'] as int?) ?? 0,
      openCases: (openCasesRow.first['c'] as int?) ?? 0,
      closedCases: (closedCasesRow.first['c'] as int?) ?? 0,
      totalMilk: totalMilk,
      avgMilkPerDay: days > 0 ? totalMilk / days : 0,
      vaccinationsDue: (vacDueRow.first['c'] as int?) ?? 0,
      births: (birthRow.first['c'] as int?) ?? 0,
      teamCount: (teamRow.first['c'] as int?) ?? 0,
    );
  }
}
