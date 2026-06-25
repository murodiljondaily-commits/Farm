import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as http_parser;
import 'package:path/path.dart' as p;
import 'package:record/record.dart';
import 'package:sqflite/sqflite.dart' show getDatabasesPath;

import 'db_service.dart';
import '../models/models.dart';

// ── Data models ───────────────────────────────────────────────────────────────

class VetIntent {
  final String intent; // INJECT | QUERY | UPDATE | EMERGENCY | REPORT | GENERAL
  final String? earTag;
  final String? animalName;
  final String? actionType; // health_case|vaccination|weight|milk|birth|status_update
  final List<String> symptoms;
  final String? bodyPart;
  final String severity; // low | medium | high | emergency
  final Map<String, dynamic> measurements;
  final String language; // uz | ru

  const VetIntent({
    required this.intent,
    this.earTag,
    this.animalName,
    this.actionType,
    this.symptoms = const [],
    this.bodyPart,
    this.severity = 'low',
    this.measurements = const {},
    this.language = 'uz',
  });

  factory VetIntent.fromJson(Map<String, dynamic> j) => VetIntent(
        intent: j['intent'] as String? ?? 'GENERAL',
        earTag: j['ear_tag'] as String?,
        animalName: j['animal_name'] as String?,
        actionType: j['action_type'] as String?,
        symptoms: (j['symptoms'] as List<dynamic>?)
                ?.map((s) => s.toString())
                .toList() ??
            [],
        bodyPart: j['body_part'] as String?,
        severity: j['severity'] as String? ?? 'low',
        measurements:
            (j['measurements'] as Map<String, dynamic>?) ?? {},
        language: j['language'] as String? ?? 'uz',
      );

  bool get isEmergency =>
      intent == 'EMERGENCY' || severity == 'emergency';
}

class VetResponse {
  final String assessment;
  final List<String> firstAid;
  final int confidence;
  final bool escalateToVet;
  final int followUpInDays;
  final String? visualFindings;

  const VetResponse({
    required this.assessment,
    this.firstAid = const [],
    required this.confidence,
    this.escalateToVet = false,
    this.followUpInDays = 0,
    this.visualFindings,
  });

  factory VetResponse.fromJson(Map<String, dynamic> j) => VetResponse(
        assessment: j['assessment'] as String? ?? '',
        firstAid: (j['first_aid'] as List<dynamic>?)
                ?.map((s) => s.toString())
                .toList() ??
            [],
        confidence: (j['confidence'] as num?)?.toInt() ?? 70,
        escalateToVet: j['escalate_to_vet'] as bool? ?? false,
        followUpInDays:
            (j['follow_up_in_days'] as num?)?.toInt() ?? 0,
        visualFindings: j['visual_findings'] as String?,
      );
}

// ── Emergency keyword sets ────────────────────────────────────────────────────

const _emergencyUz = {
  'qon oqmoqda', 'yiqilib qoldi', 'nafas olmayapti',
  'tutqanoq', 'tez yordam', 'jon bermoqda', 'o\'lmoqda',
};
const _emergencyRu = {
  'кровотечение', 'упал', 'не дышит', 'судороги',
  'срочно', 'умирает', 'не встаёт',
};

bool detectEmergencyKeywords(String text) {
  final lower = text.toLowerCase();
  return _emergencyUz.any(lower.contains) ||
      _emergencyRu.any(lower.contains);
}

// ── Service ───────────────────────────────────────────────────────────────────

class VetAiService {
  static AudioRecorder? _recorder;

  // ── 1. Recording ────────────────────────────────────────────────────────────

  static Future<bool> startRecording() async {
    try {
      _recorder ??= AudioRecorder();
      if (!await _recorder!.hasPermission()) {
        debugPrint('[VetAI] mic permission denied');
        return false;
      }
      final dir = await getDatabasesPath();
      final path = p.join(dir, 'agrivet_rec.wav');
      await _recorder!.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: path,
      );
      debugPrint('[VetAI] recording started → $path');
      return true;
    } catch (e) {
      debugPrint('[VetAI] startRecording: $e');
      return false;
    }
  }

  static Future<String?> stopRecording() async {
    try {
      final path = await _recorder?.stop();
      _recorder?.dispose();
      _recorder = null;
      debugPrint('[VetAI] recording stopped → $path');
      return path;
    } catch (e) {
      debugPrint('[VetAI] stopRecording: $e');
      _recorder?.dispose();
      _recorder = null;
      return null;
    }
  }

  // ── 2. Muxlisa STT ──────────────────────────────────────────────────────────

  static Future<String> transcribeAudio(String audioPath) async {
    try {
      final file = File(audioPath);
      if (!file.existsSync()) {
        throw Exception('Audio file not found: $audioPath');
      }
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_backendUrl/transcribe'),
      );
      request.files
          .add(await http.MultipartFile.fromPath('audio', audioPath));
      final streamed = await request.send()
          .timeout(const Duration(seconds: 30));
      final body = await streamed.stream.bytesToString();
      debugPrint('[VetAI] STT (${streamed.statusCode}): $body');
      if (streamed.statusCode != 200) {
        throw Exception('STT HTTP ${streamed.statusCode}: $body');
      }
      final json = jsonDecode(body) as Map<String, dynamic>;
      return json['text'] as String? ??
          json['result'] as String? ??
          json['transcript'] as String? ??
          '';
    } catch (e) {
      debugPrint('[VetAI] transcribeAudio: $e');
      rethrow;
    }
  }

  // ── 4. Animal context retrieval ──────────────────────────────────────────────

  static Future<String?> getAnimalContext(
    String farmId, {
    String? earTag,
    String? animalName,
  }) async {
    // No identifier provided — no specific animal requested
    if (earTag == null && animalName == null) return '';
    try {
      final animal = earTag != null
          ? (await DbService.getAnimal(farmId, earTag) ??
              await _fuzzyFindAnimal(farmId, earTag))
          : await _fuzzyFindAnimal(farmId, animalName!);

      if (animal == null) return null; // signal: not found

      int? ageMonths;
      if (animal.dob != null) {
        try {
          final dob = DateTime.parse(animal.dob!);
          ageMonths =
              DateTime.now().difference(dob).inDays ~/ 30;
        } catch (_) {}
      }

      final weights =
          await DbService.getWeights(farmId, earTag: animal.earTag);
      final weightStr = weights
          .take(3)
          .map((w) => '${w.weight}kg (${w.measuredAt})')
          .join(', ');

      final cases =
          await DbService.getCases(farmId, earTag: animal.earTag);
      final lastCase = cases.isNotEmpty ? cases.first : null;

      final vaccs = await DbService.getVaccinations(farmId,
          earTag: animal.earTag);
      final lastVacc = vaccs.isNotEmpty ? vaccs.first : null;

      return '''
Animal: ${animal.displayName} (${animal.earTag})
Species: ${animal.species}, Breed: ${animal.breed ?? 'unknown'}
Sex: ${animal.sex}, Age: ${ageMonths != null ? '$ageMonths months' : 'unknown'}
Status: ${animal.status}
Weight (last 3): ${weightStr.isEmpty ? 'none' : weightStr}
Last case: ${lastCase != null ? '${lastCase.diagnosis ?? lastCase.symptomsFarmer ?? 'n/a'} (${lastCase.createdAt.substring(0, 10)})' : 'none'}
Last vaccination: ${lastVacc != null ? '${lastVacc.vaccineName} on ${lastVacc.date}' : 'none'}
''';
    } catch (e) {
      debugPrint('[VetAI] getAnimalContext: $e');
      return 'Could not load animal data.';
    }
  }

  static Future<dynamic> _fuzzyFindAnimal(
      String farmId, String name) async {
    final all = await DbService.getAnimals(farmId);
    final lower = name.toLowerCase();
    try {
      return all.firstWhere(
        (a) =>
            (a.name?.toLowerCase().contains(lower) ?? false) ||
            a.earTag.toLowerCase().contains(lower),
      );
    } catch (_) {
      return null;
    }
  }

  // ── 5. RAG knowledge retrieval ───────────────────────────────────────────────

  static Future<String> getRagContext(
      String? species, List<String> symptoms) async {
    try {
      if (symptoms.isEmpty) return '';
      final rows = await DbService.searchRagKnowledge(
          species: species, symptoms: symptoms, limit: 5);
      if (rows.isEmpty) return '';
      return rows.map((r) {
        final confirmed = (r['confirmed_by_vet'] as int?) == 1;
        return '• [${r['species']}] ${r['symptoms']} → ${r['diagnosis']} '
            '(confidence: ${r['confidence_score']}%, vet-confirmed: $confirmed)';
      }).join('\n');
    } catch (e) {
      debugPrint('[VetAI] getRagContext: $e');
      return '';
    }
  }

  // ── 7. Photo diagnosis ──────────────────────────────────────────────────────

  static Future<({VetResponse response, String? photoUrl})>
      diagnoseFromPhoto({
    required String imagePath,
    required String farmId,
    required String? earTag,
    required String? bodyPart,
    required String animalContext,
    required String ragContext,
  }) async {
    try {
      final file = File(imagePath);
      if (!file.existsSync()) throw Exception('Image not found: $imagePath');

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_backendUrl/diagnose-photo'),
      );
      request.fields['farm_id'] = farmId;
      if (earTag != null) request.fields['ear_tag'] = earTag;
      if (bodyPart != null) request.fields['body_part'] = bodyPart;
      // Explicitly set image/jpeg so the backend always gets a known media type
      request.files.add(await http.MultipartFile.fromPath(
        'image',
        imagePath,
        contentType: http_parser.MediaType('image', 'jpeg'),
      ));

      final streamed =
          await request.send().timeout(const Duration(seconds: 60));
      final body = await streamed.stream.bytesToString();
      debugPrint(
          '[VetAI] diagnose-photo (${streamed.statusCode}): ${body.substring(0, body.length.clamp(0, 300))}');

      if (streamed.statusCode != 200) {
        // Surface the actual backend error so it shows in the chat
        String detail = body;
        try {
          detail = (jsonDecode(body) as Map)['detail']?.toString() ?? body;
        } catch (_) {}
        return (
          response: VetResponse(
            assessment:
                "Rasm tahlilida xatolik: $detail",
            confidence: 0,
          ),
          photoUrl: null,
        );
      }
      final json = jsonDecode(body) as Map<String, dynamic>;
      return (
        response: VetResponse.fromJson(json),
        photoUrl: json['photo_url'] as String?,
      );
    } catch (e) {
      debugPrint('[VetAI] diagnoseFromPhoto: $e');
      return (
        response: VetResponse(
          assessment: "Rasm tahlilida xatolik: $e",
          confidence: 0,
        ),
        photoUrl: null,
      );
    }
  }

  // ── 8. Auto-save ─────────────────────────────────────────────────────────────

  static Future<String?> autoSave({
    required String farmId,
    required VetIntent intent,
    required VetResponse response,
    String? photoUrl,
  }) async {
    if (intent.intent == 'QUERY' ||
        intent.intent == 'GENERAL' ||
        intent.intent == 'REPORT') return null;
    try {
      final now = DateTime.now().toIso8601String();
      final actionType = intent.actionType ?? 'health_case';
      bool saved = false;

      switch (actionType) {
        case 'health_case':
        case 'health':
          if (intent.earTag == null) break;
          await DbService.saveCase({
            'ear_tag': intent.earTag,
            'farm_id': farmId,
            'symptoms_farmer': intent.symptoms.join(', '),
            'diagnosis': response.assessment,
            'ai_suggestion': response.assessment,
            'ai_confidence': response.confidence,
            'severity': intent.severity,
            'body_part': intent.bodyPart,
            'first_aid_json': jsonEncode(response.firstAid),
            'photo_url': photoUrl,
            'ai_model': 'claude-sonnet-4-6',
            'status': 'open',
            'vet_notified': 0,
            'created_at': now,
          });
          final newStatus = switch (intent.severity) {
            'emergency' || 'high' => 'kritik',
            'medium' => 'davolanmoqda',
            _ => 'kuzatuvda',
          };
          await DbService.updateAnimalStatus(
              farmId, intent.earTag!, newStatus);
          final animal =
              await DbService.getAnimal(farmId, intent.earTag!);
          if (animal != null) {
            await DbService.saveRagKnowledge({
              'species': animal.species,
              'breed': animal.breed,
              'animal_age_months': _ageMonths(animal.dob),
              'body_part': intent.bodyPart,
              'symptoms': jsonEncode(intent.symptoms),
              'visual_findings': response.visualFindings,
              'diagnosis': response.assessment,
              'confidence_score': response.confidence.toDouble(),
              'season': _currentSeason(),
              'confirmed_by_vet': 0,
              'created_at': now,
            });
          }
          saved = true;
          break;

        case 'vaccination':
          if (intent.earTag == null) break;
          await DbService.saveVaccination({
            'ear_tag': intent.earTag,
            'farm_id': farmId,
            'vaccine_name': intent.measurements['vaccine_name']
                    ?.toString() ??
                "Noma'lum vaksina",
            'date': now.substring(0, 10),
            'next_due': null,
            'administered_by': null,
            'created_at': now,
          });
          saved = true;
          break;

        case 'weight':
          if (intent.earTag == null) break;
          final kg =
              (intent.measurements['weight_kg'] as num?)?.toDouble();
          if (kg != null) {
            final prev = await DbService.getWeights(farmId,
                earTag: intent.earTag!);
            if (prev.isNotEmpty) {
              final drop = (prev.first.weight - kg) / prev.first.weight;
              if (drop > 0.10) {
                debugPrint(
                    '[VetAI] ⚠️ Weight drop >10% for ${intent.earTag}');
              }
            }
            await DbService.saveWeight({
              'ear_tag': intent.earTag,
              'farm_id': farmId,
              'weight': kg,
              'measured_at': now.substring(0, 10),
              'recorded_by': 'AI',
              'created_at': now,
            });
            saved = true;
          }
          break;

        case 'milk':
          final liters =
              (intent.measurements['milk_liters'] as num?)?.toDouble();
          if (liters != null) {
            await DbService.saveMilk({
              'farm_id': farmId,
              'amount_liters': liters,
              'timing':
                  intent.measurements['timing']?.toString() ?? 'morning',
              'recorded_by': 'AI',
              'recorded_at': now.substring(0, 10),
              'created_at': now,
            });
            saved = true;
          }
          break;
      }
      if (saved) debugPrint('[VetAI] autoSave done for action=$actionType');
      return saved ? actionType : null;
    } catch (e) {
      debugPrint('[VetAI] autoSave: $e');
      return null;
    }
  }

  // ── 9. Yandex SpeechKit TTS (via backend proxy) ─────────────────────────────

  static Future<Uint8List?> textToSpeech(String text) async {
    final truncated = text.length > 5000 ? text.substring(0, 5000) : text;
    debugPrint('[VetAI] TTS text (first 80): '
        '${truncated.length > 80 ? truncated.substring(0, 80) : truncated}');
    try {
      final resp = await http.post(
        Uri.parse('$_backendUrl/tts'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': truncated}),
      ).timeout(const Duration(seconds: 35));
      debugPrint('[VetAI] TTS status: ${resp.statusCode}');
      debugPrint('[VetAI] TTS content-type: ${resp.headers['content-type']}');
      debugPrint('[VetAI] TTS body bytes: ${resp.bodyBytes.length}');
      if (resp.statusCode != 200) {
        debugPrint('[VetAI] TTS error body: ${resp.body}');
        return null;
      }
      return resp.bodyBytes.isNotEmpty ? resp.bodyBytes : null;
    } catch (e) {
      debugPrint('[VetAI] textToSpeech exception: $e');
      return null;
    }
  }

  // ── 10. Emergency vet contact ────────────────────────────────────────────────

  static Future<Map<String, String>?> getVetContact(
      String farmId) async {
    try {
      final rows = await DbService.getVetUsers(farmId);
      if (rows.isEmpty) return null;
      final v = rows.first;
      return {
        'name': v['name'] as String? ?? 'Veterinar',
        'phone': v['phone'] as String? ?? '',
      };
    } catch (e) {
      debugPrint('[VetAI] getVetContact: $e');
      return null;
    }
  }

  // ── 11. Railway backend chat ─────────────────────────────────────────────────

  static const _backendUrl =
      'https://farm-production-3ea5.up.railway.app';

  /// Push all local SQLite animals to Firestore so the AI backend can see them.
  static Future<void> syncAnimalsToBackend(String farmId) async {
    try {
      final animals = await DbService.getAnimals(farmId);
      if (animals.isEmpty) return;

      final payload = animals.map((a) {
        int? ageMonths;
        if (a.dob != null && a.dob!.isNotEmpty) {
          try {
            final dob = DateTime.parse(a.dob!);
            final now = DateTime.now();
            ageMonths =
                (now.year - dob.year) * 12 + (now.month - dob.month);
          } catch (_) {}
        }
        return {
          'ear_tag': a.earTag,
          'farm_id': farmId,
          'name': a.name ?? a.earTag,
          'species': a.species,
          'breed': a.breed ?? '',
          'sex': a.sex,
          'dob': a.dob ?? '',
          'status': a.status,
          'animal_type': a.animalType,
          'pregnancy_status': a.pregnancyStatus,
          if (ageMonths != null) 'age_months': ageMonths,
          if (a.color != null) 'color': a.color,
          if (a.motherEarTag != null) 'mother_ear_tag': a.motherEarTag,
          if (a.fatherEarTag != null) 'father_ear_tag': a.fatherEarTag,
        };
      }).toList();

      final resp = await http
          .post(
            Uri.parse('$_backendUrl/farm/$farmId/sync-animals'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'animals': payload}),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint(
          '[VetAI] sync-animals status=${resp.statusCode} count=${animals.length}');
    } catch (e) {
      debugPrint('[VetAI] sync-animals error: $e');
    }
  }

  /// Pull all Firestore animals for this farm and upsert them into local SQLite.
  static Future<void> syncAnimalsFromBackend(String farmId) async {
    try {
      final resp = await http
          .get(Uri.parse('$_backendUrl/farm/$farmId/animals'))
          .timeout(const Duration(seconds: 20));
      if (resp.statusCode != 200) {
        debugPrint('[VetAI] syncAnimalsFromBackend: HTTP ${resp.statusCode}');
        return;
      }
      final json = jsonDecode(utf8.decode(resp.bodyBytes));
      final List<dynamic> rawList = json is List
          ? json
          : (json['animals'] as List<dynamic>? ?? []);
      int count = 0;
      for (final raw in rawList) {
        final map = Map<String, dynamic>.from(raw as Map);
        map['farm_id'] = farmId;
        final animal = Animal.fromMap(map);
        await DbService.saveAnimal(animal);
        count++;
      }
      debugPrint('[VetAI] syncAnimalsFromBackend: upserted $count animals');
    } catch (e) {
      debugPrint('[VetAI] syncAnimalsFromBackend error: $e');
    }
  }

  /// Close a health case from the UI with outcome data. Updates Firestore via backend.
  static Future<bool> closeCaseViaApi({
    required String farmId,
    required String caseId,
    required String outcome,
    int? recoveryDays,
    bool vetConfirmed = false,
    String? vetNotes,
  }) async {
    try {
      final resp = await http
          .post(
            Uri.parse('$_backendUrl/farm/$farmId/close-case'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'case_id': caseId,
              'outcome': outcome,
              'recovery_days': recoveryDays,
              'vet_confirmed': vetConfirmed,
              'vet_notes': vetNotes,
            }),
          )
          .timeout(const Duration(seconds: 20));
      debugPrint('[VetAI] closeCaseViaApi: HTTP ${resp.statusCode} $caseId');
      return resp.statusCode == 200;
    } catch (e) {
      debugPrint('[VetAI] closeCaseViaApi error: $e');
      return false;
    }
  }

  static Future<
      ({
        VetResponse response,
        String conversationId,
        bool vetMode,
        Map<String, dynamic> dataSaved,
      })> chatWithBackend({
    required String farmId,
    required String userId,
    required String userRole,
    required String message,
    String? conversationId,
    bool vetMode = false,
  }) async {
    try {
      final resp = await http
          .post(
            Uri.parse('$_backendUrl/chat'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'farm_id': farmId,
              'user_id': userId,
              'user_role': userRole,
              'message': message,
              if (conversationId != null)
                'conversation_id': conversationId,
              'vet_mode': vetMode,
            }),
          )
          .timeout(const Duration(seconds: 45));

      debugPrint('[VetAI] backend status: ${resp.statusCode}');
      if (resp.statusCode != 200) {
        throw Exception(
            'Backend ${resp.statusCode}: ${utf8.decode(resp.bodyBytes)}');
      }

      final json = jsonDecode(utf8.decode(resp.bodyBytes))
          as Map<String, dynamic>;
      final text = json['response'] as String? ?? '';
      final newConvId =
          json['conversation_id'] as String? ?? conversationId ?? '';
      final newVetMode = json['vet_mode'] as bool? ?? vetMode;
      final dataSaved =
          (json['data_saved'] as Map<String, dynamic>?) ?? {};

      return (
        response: VetResponse(
          assessment: text,
          firstAid: [],
          confidence: 0,
        ),
        conversationId: newConvId,
        vetMode: newVetMode,
        dataSaved: dataSaved,
      );
    } on Exception {
      rethrow;
    }
  }

  // ── 12b. Create Google Sheet for a farm ─────────────────────────────────────

  static Future<String?> createSheet(String farmId, String ownerEmail) async {
    try {
      final resp = await http
          .post(
            Uri.parse('$_backendUrl/farm/$farmId/create-sheet'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'owner_email': ownerEmail}),
          )
          .timeout(const Duration(seconds: 30));
      debugPrint('[VetAI] createSheet status=${resp.statusCode}');
      if (resp.statusCode != 200) return null;
      final json = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
      return json['sheet_url'] as String?;
    } catch (e) {
      debugPrint('[VetAI] createSheet error: $e');
      return null;
    }
  }

  // ── Farm registry (cross-device join) ───────────────────────────────────────

  /// Save the newly created farm to Firestore so other devices can find it by code.
  static Future<bool> saveFarmToBackend(Farm farm) async {
    try {
      final resp = await http
          .post(
            Uri.parse('$_backendUrl/farm'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'farm_id': farm.farmId,
              'farm_name': farm.farmName,
              'farm_code': farm.farmCode,
              'location': farm.location,
              'owner_name': farm.ownerName,
              if (farm.ownerEmail != null) 'owner_email': farm.ownerEmail,
              if (farm.phone != null) 'phone': farm.phone,
            }),
          )
          .timeout(const Duration(seconds: 20));
      debugPrint('[VetAI] saveFarmToBackend status=${resp.statusCode}');
      return resp.statusCode == 200 || resp.statusCode == 201;
    } catch (e) {
      debugPrint('[VetAI] saveFarmToBackend error: $e');
      return false;
    }
  }

  /// Look up a farm by its join code via the backend (queries Firestore, not local SQLite).
  /// Returns a map with farm_id, farm_name, farm_code, location, owner_name on success, or null.
  static Future<Map<String, dynamic>?> lookupFarmByCode(String code) async {
    try {
      final resp = await http
          .get(
            Uri.parse(
                '$_backendUrl/farm-by-code/${Uri.encodeComponent(code.toUpperCase())}'),
          )
          .timeout(const Duration(seconds: 15));
      debugPrint('[VetAI] lookupFarmByCode status=${resp.statusCode}');
      if (resp.statusCode != 200) return null;
      final json =
          jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
      if (json['found'] != true) return null;
      return json;
    } catch (e) {
      debugPrint('[VetAI] lookupFarmByCode error: $e');
      return null;
    }
  }

  // ── 12. Conversation history ─────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> loadLatestConversation(
      String farmId) async {
    try {
      final resp = await http
          .get(Uri.parse('$_backendUrl/farm/$farmId/conversation/latest'))
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        return jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('[VetAI] loadLatestConversation error: $e');
    }
    return null;
  }

  static Future<void> deleteConversation(
      String farmId, String convId) async {
    try {
      await http
          .delete(
            Uri.parse('$_backendUrl/farm/$farmId/conversation/$convId'),
          )
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('[VetAI] deleteConversation error: $e');
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  static int? _ageMonths(String? dob) {
    if (dob == null) return null;
    try {
      return DateTime.now().difference(DateTime.parse(dob)).inDays ~/
          30;
    } catch (_) {
      return null;
    }
  }

  static String _currentSeason() {
    final m = DateTime.now().month;
    if (m >= 3 && m <= 5) return 'spring';
    if (m >= 6 && m <= 8) return 'summer';
    if (m >= 9 && m <= 11) return 'autumn';
    return 'winter';
  }
}
