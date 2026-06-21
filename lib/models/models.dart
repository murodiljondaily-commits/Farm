class Farm {
  final String farmId;
  final String farmName;
  final String farmCode;
  final String location;
  final String ownerName;
  final String? ownerEmail;
  final String? phone;
  final String? sheetUrl;
  final String? ownerUid;      // Firebase UID
  final String? ownerUserId;   // local session userId

  Farm({
    required this.farmId,
    required this.farmName,
    required this.farmCode,
    required this.location,
    required this.ownerName,
    this.ownerEmail,
    this.phone,
    this.sheetUrl,
    this.ownerUid,
    this.ownerUserId,
  });

  factory Farm.fromMap(Map<String, dynamic> m) => Farm(
        farmId: m['farm_id'] ?? '',
        farmName: m['farm_name'] ?? '',
        farmCode: m['farm_code'] ?? '',
        location: m['location'] ?? '',
        ownerName: m['owner_name'] ?? '',
        ownerEmail: m['owner_email'],
        phone: m['owner_phone'],
        sheetUrl: m['sheet_url'],
        ownerUid: m['owner_uid'],
        ownerUserId: m['owner_user_id'],
      );
}

class AppUser {
  final String telegramId;
  final String name;
  final String role;
  final String farmId;
  final String? email;
  final String? phone;
  final bool isApproved;
  final bool voiceMode;
  final String? pinHash;
  final bool sessionLocked;
  final String? lastActive;

  AppUser({
    required this.telegramId,
    required this.name,
    required this.role,
    required this.farmId,
    this.email,
    this.phone,
    required this.isApproved,
    required this.voiceMode,
    this.pinHash,
    required this.sessionLocked,
    this.lastActive,
  });

  factory AppUser.fromMap(Map<String, dynamic> m) => AppUser(
        telegramId: m['telegram_id']?.toString() ?? '',
        name: m['name'] ?? '',
        role: m['role'] ?? 'farmer',
        farmId: m['farm_id'] ?? '',
        email: m['email'],
        phone: m['phone'],
        isApproved: (m['is_approved'] ?? 0) == 1,
        voiceMode: (m['voice_mode'] ?? 0) == 1,
        pinHash: m['pin_hash'],
        sessionLocked: (m['session_locked'] ?? 0) == 1,
        lastActive: m['last_active'],
      );

  bool get isOwner => role == 'owner' || role == 'coowner';
  bool get isVet => role == 'vet';
}

class Animal {
  final String earTag;
  final String farmId;
  final String species;
  final String? breed;
  final String sex;
  final String? dob;
  final String? name;
  final String? color;
  final String? origin;
  final String status;
  final String? motherEarTag;
  final String? fatherEarTag;
  final String animalType;
  final String? photoFileId;
  final String pregnancyStatus;
  final String? expectedBirthDate;
  final int? pregnancyMonth;
  final String? deathReason;

  Animal({
    required this.earTag,
    required this.farmId,
    required this.species,
    this.breed,
    required this.sex,
    this.dob,
    this.name,
    this.color,
    this.origin,
    required this.status,
    this.motherEarTag,
    this.fatherEarTag,
    this.animalType = 'adult',
    this.photoFileId,
    this.pregnancyStatus = 'none',
    this.expectedBirthDate,
    this.pregnancyMonth,
    this.deathReason,
  });

  factory Animal.fromMap(Map<String, dynamic> m) => Animal(
        earTag: m['ear_tag'] ?? '',
        farmId: m['farm_id'] ?? '',
        species: m['species'] ?? 'boshqa',
        breed: m['breed'],
        sex: m['sex'] ?? 'nomalum',
        dob: m['dob'],
        name: m['name'],
        color: m['color'],
        origin: m['origin'],
        status: m['status'] ?? 'soglom',
        motherEarTag: m['mother_ear_tag'],
        fatherEarTag: m['father_ear_tag'],
        animalType: m['animal_type'] ?? 'adult',
        photoFileId: m['photo_file_id'],
        pregnancyStatus: m['pregnancy_status'] ?? 'none',
        expectedBirthDate: m['expected_birth_date'],
        pregnancyMonth: m['pregnancy_month'] as int?,
        deathReason: m['death_reason'] as String?,
      );

  String get displayName => name?.isNotEmpty == true ? name! : earTag;
}

class HealthCase {
  final String caseId;
  final String earTag;
  final String farmId;
  final String? symptomsFarmer;
  final String? diagnosis;
  final String? treatment;
  final String? medicineUsed;
  final String? aiSuggestion;
  final int? aiConfidence;
  final String severity;
  final String status;
  final int vetNotified;
  final String createdAt;

  HealthCase({
    required this.caseId,
    required this.earTag,
    required this.farmId,
    this.symptomsFarmer,
    this.diagnosis,
    this.treatment,
    this.medicineUsed,
    this.aiSuggestion,
    this.aiConfidence,
    required this.severity,
    required this.status,
    required this.vetNotified,
    required this.createdAt,
  });

  factory HealthCase.fromMap(Map<String, dynamic> m) => HealthCase(
        caseId: m['case_id']?.toString() ?? '',
        earTag: m['ear_tag'] ?? '',
        farmId: m['farm_id'] ?? '',
        symptomsFarmer: m['symptoms_farmer'],
        diagnosis: m['diagnosis'],
        treatment: m['treatment'],
        medicineUsed: m['medicine_used'],
        aiSuggestion: m['ai_suggestion'],
        aiConfidence: m['ai_confidence'] as int?,
        severity: m['severity'] ?? 'routine',
        status: m['status'] ?? 'open',
        vetNotified: m['vet_notified'] as int? ?? 0,
        createdAt: m['created_at'] ?? '',
      );

  bool get isOpen => status == 'open';
  bool get isEmergency => severity == 'emergency';
}

class Vaccination {
  final String id;
  final String earTag;
  final String farmId;
  final String vaccineName;
  final String date;
  final String? nextDue;

  Vaccination({
    required this.id,
    required this.earTag,
    required this.farmId,
    required this.vaccineName,
    required this.date,
    this.nextDue,
  });

  factory Vaccination.fromMap(Map<String, dynamic> m) => Vaccination(
        id: m['id']?.toString() ?? '',
        earTag: m['ear_tag'] ?? '',
        farmId: m['farm_id'] ?? '',
        vaccineName: m['vaccine_name'] ?? '',
        date: m['date'] ?? '',
        nextDue: m['next_due'],
      );

  bool get isDueSoon {
    if (nextDue == null) return false;
    try {
      final due = DateTime.parse(nextDue!);
      return due.difference(DateTime.now()).inDays <= 3;
    } catch (_) {
      return false;
    }
  }
}

class WeightEntry {
  final String id;
  final String earTag;
  final String farmId;
  final double weight;
  final String measuredAt;
  final String? recordedBy;

  WeightEntry({
    required this.id,
    required this.earTag,
    required this.farmId,
    required this.weight,
    required this.measuredAt,
    this.recordedBy,
  });

  factory WeightEntry.fromMap(Map<String, dynamic> m) => WeightEntry(
        id: m['id']?.toString() ?? '',
        earTag: m['ear_tag'] ?? '',
        farmId: m['farm_id'] ?? '',
        weight: (m['weight'] as num?)?.toDouble() ?? 0.0,
        measuredAt: m['measured_at'] ?? '',
        recordedBy: m['recorded_by'],
      );
}

class MilkEntry {
  final String id;
  final String farmId;
  final double amountLiters;
  final String timing;
  final String? recordedBy;
  final String recordedAt;
  final String? notes;

  MilkEntry({
    required this.id,
    required this.farmId,
    required this.amountLiters,
    required this.timing,
    this.recordedBy,
    required this.recordedAt,
    this.notes,
  });

  factory MilkEntry.fromMap(Map<String, dynamic> m) => MilkEntry(
        id: m['id']?.toString() ?? '',
        farmId: m['farm_id'] ?? '',
        amountLiters: (m['amount_liters'] as num?)?.toDouble() ?? 0.0,
        timing: m['timing'] ?? '',
        recordedBy: m['recorded_by'],
        recordedAt: m['recorded_at'] ?? '',
        notes: m['notes'],
      );
}

class Birth {
  final String id;
  final String farmId;
  final String offspringEarTag;
  final String? offspringName;
  final String motherEarTag;
  final String? fatherEarTag;
  final String birthDate;
  final double? birthWeight;
  final String sex;
  final String? breed;

  Birth({
    required this.id,
    required this.farmId,
    required this.offspringEarTag,
    this.offspringName,
    required this.motherEarTag,
    this.fatherEarTag,
    required this.birthDate,
    this.birthWeight,
    required this.sex,
    this.breed,
  });

  factory Birth.fromMap(Map<String, dynamic> m) => Birth(
        id: m['id']?.toString() ?? '',
        farmId: m['farm_id'] ?? '',
        offspringEarTag: m['offspring_ear_tag'] ?? '',
        offspringName: m['offspring_name'],
        motherEarTag: m['mother_ear_tag'] ?? '',
        fatherEarTag: m['father_ear_tag'],
        birthDate: m['birth_date'] ?? '',
        birthWeight: (m['birth_weight'] as num?)?.toDouble(),
        sex: m['sex'] ?? 'nomalum',
        breed: m['breed'],
      );
}

class FarmReport {
  final int totalAnimals;
  final int soglom;
  final int davolanmoqda;
  final int kritik;
  final int openCases;
  final int closedCases;
  final double totalMilk;
  final double avgMilkPerDay;
  final int vaccinationsDue;
  final int births;
  final int teamCount;

  FarmReport({
    required this.totalAnimals,
    required this.soglom,
    required this.davolanmoqda,
    required this.kritik,
    required this.openCases,
    required this.closedCases,
    required this.totalMilk,
    required this.avgMilkPerDay,
    required this.vaccinationsDue,
    required this.births,
    required this.teamCount,
  });
}
