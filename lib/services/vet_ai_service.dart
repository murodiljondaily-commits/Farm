import 'dart:convert';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:record/record.dart';
import 'package:sqflite/sqflite.dart' show getDatabasesPath;
import 'package:uuid/uuid.dart';

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
  static String get _anthropicKey =>
      dotenv.env['ANTHROPIC_API_KEY'] ?? '';
  static String get _muxlisaKey =>
      dotenv.env['MUXLISA_API_KEY'] ?? '';

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
        Uri.parse('https://service.muxlisa.uz/api/v2/stt'),
      );
      request.headers['x-api-key'] = _muxlisaKey;
      request.files
          .add(await http.MultipartFile.fromPath('audio', audioPath));
      final streamed = await request.send();
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

  // ── 3. Intent classification + entity extraction ─────────────────────────────

  static const _classifySystemPrompt = '''
You are an AI assistant for AgriVet, a livestock farm management app in Uzbekistan.
Classify the user input into one of these intents:
- INJECT: adding new data (health case, symptom, vaccination, weight, milk, birth)
- QUERY: asking for information about an animal or farm
- UPDATE: updating existing record (animal recovered, case closed, weight updated)
- EMERGENCY: life-threatening situation (bleeding, seizures, can't stand, not breathing)
- REPORT: daily farm report (milk production, general farm status)
- GENERAL: general vet knowledge question, no DB action needed

Also extract entities:
- ear_tag or animal_name
- action_type (health_case/vaccination/weight/milk/birth/status_update)
- symptoms (list)
- body_part (if mentioned)
- severity (low/medium/high/emergency)
- measurements (weight in kg, milk in liters, vaccine_name, timing, etc.)
- language (uz or ru — detect from input)

Return ONLY valid JSON:
{
  "intent": "INJECT",
  "ear_tag": "US44506",
  "animal_name": null,
  "action_type": "health_case",
  "symptoms": ["swollen right back leg", "wound fluid", "not bearing weight"],
  "body_part": "right_back_leg",
  "severity": "high",
  "measurements": {},
  "language": "uz"
}''';

  static Future<VetIntent> classifyIntent(String text) async {
    // Fast-path: local emergency keyword detection
    if (detectEmergencyKeywords(text)) {
      return VetIntent(
        intent: 'EMERGENCY',
        symptoms: [text],
        severity: 'emergency',
        language: text.contains(RegExp(r'[а-яёА-ЯЁ]')) ? 'ru' : 'uz',
      );
    }
    try {
      final raw = await _claudeCall(
        systemPrompt: _classifySystemPrompt,
        userMessage: text,
      );
      return VetIntent.fromJson(
          jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('[VetAI] classifyIntent: $e');
      return VetIntent(intent: 'GENERAL', language: 'uz');
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

  // ── 6. Main GPT-4o vet assessment ────────────────────────────────────────────

  static Future<VetResponse> getAssessment({
    required String userInput,
    required VetIntent intent,
    required String animalContext,
    required String ragContext,
    bool retryComplex = false,
  }) async {
    try {
      final systemPrompt = """
Siz AgriVet ilovasidagi "Sonya" — Farg'ona vodiysidan 15 yillik tajribali veterinar.
Qisqa, aniq, ishonchli javob bering:
1. Asosiy muammo
2. Ehtimoliy sabab
3. Darhol choralar (birinchi yordam)
4. Ishonch darajasi: X%

Hech qachon "men aniqlay olmayman" demang. Hech qachon "veterinarga murojaat qiling" deb tugamang. Amaliy ko'rsatmalar bering.

Javob tilini foydalanuvchi tili bilan moslashtiring (uz yoki ru).${retryComplex ? '\n\nThink step by step, this is a complex case.' : ''}

RAG ma'lumotlari (o'xshash holatlar):
$ragContext

Hayvon ma'lumotlari:
$animalContext

Return ONLY valid JSON:
{
  "assessment": "main vet response text in uz/ru",
  "first_aid": ["step 1", "step 2", "step 3"],
  "confidence": 85,
  "escalate_to_vet": false,
  "follow_up_in_days": 2
}""";

      final raw = await _claudeCall(
        systemPrompt: systemPrompt,
        userMessage: userInput,
      );
      final resp = VetResponse.fromJson(
          jsonDecode(raw) as Map<String, dynamic>);

      if (resp.confidence < 60 && !retryComplex) {
        return getAssessment(
          userInput: userInput,
          intent: intent,
          animalContext: animalContext,
          ragContext: ragContext,
          retryComplex: true,
        );
      }
      return resp;
    } catch (e) {
      debugPrint('[VetAI] getAssessment: $e');
      return VetResponse(
        assessment: intent.language == 'ru'
            ? 'Ошибка обработки запроса. Попробуйте снова.'
            : "Xatolik yuz berdi. Qayta urinib ko'ring.",
        confidence: 0,
      );
    }
  }

  // ── 7. Photo diagnosis (GPT-4o vision) ──────────────────────────────────────

  static Future<({VetResponse response, String? photoUrl})>
      diagnoseFromPhoto({
    required String imagePath,
    required String farmId,
    required String? earTag,
    required String? bodyPart,
    required String animalContext,
    required String ragContext,
  }) async {
    String? photoUrl;
    try {
      final caseId = const Uuid().v4();
      final tag = earTag ?? 'unknown';
      final ref = FirebaseStorage.instance.ref(
        'farms/$farmId/animals/$tag/health/${caseId}_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await ref.putFile(File(imagePath));
      photoUrl = await ref.getDownloadURL();
      debugPrint('[VetAI] photo uploaded: $photoUrl');
    } catch (e) {
      debugPrint('[VetAI] Firebase Storage upload failed: $e');
    }

    try {
      final systemContent =
          "You are an expert vet. Examine the image and give a concise assessment in the user's language (uz or ru).\n\n"
          "Animal data:\n$animalContext\n"
          "Body part: ${bodyPart ?? 'not specified'}\n\n"
          "Similar cases from RAG:\n$ragContext\n\n"
          "Return ONLY valid JSON:\n"
          '{"assessment":"...","first_aid":["..."],"confidence":80,"escalate_to_vet":false,'
          '"follow_up_in_days":3,"visual_findings":"what AI sees in the image"}';

      final imageBytes = await File(imagePath).readAsBytes();
      final base64Data = base64Encode(imageBytes);

      final raw = await _claudeCall(
        systemPrompt: systemContent,
        userMessage: '',
        customMessages: [
          {
            'role': 'user',
            'content': [
              {
                'type': 'image',
                'source': {
                  'type': 'base64',
                  'media_type': 'image/jpeg',
                  'data': base64Data,
                },
              },
              {
                'type': 'text',
                'text': 'Analyze this veterinary image and return the JSON assessment.',
              },
            ],
          }
        ],
      );
      final resp = VetResponse.fromJson(
          jsonDecode(raw) as Map<String, dynamic>);
      return (response: resp, photoUrl: photoUrl);
    } catch (e) {
      debugPrint('[VetAI] diagnoseFromPhoto: $e');
      return (
        response: VetResponse(
          assessment: "Rasm tahlilida xatolik. Qayta urinib ko'ring.",
          confidence: 0,
        ),
        photoUrl: photoUrl,
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
  static Future<void> saveFarmToBackend(Farm farm) async {
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
    } catch (e) {
      debugPrint('[VetAI] saveFarmToBackend error: $e');
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

  // ── Internal: Anthropic Claude call ─────────────────────────────────────────

  static Future<String> _claudeCall({
    required String systemPrompt,
    required String userMessage,
    List<Map<String, dynamic>>? customMessages,
  }) async {
    final messages = customMessages ??
        [
          if (userMessage.isNotEmpty)
            {'role': 'user', 'content': userMessage},
        ];

    final body = <String, dynamic>{
      'model': 'claude-sonnet-4-6',
      'max_tokens': 1024,
      if (systemPrompt.isNotEmpty) 'system': systemPrompt,
      'messages': messages,
    };

    final resp = await http
        .post(
          Uri.parse('https://api.anthropic.com/v1/messages'),
          headers: {
            'x-api-key': _anthropicKey,
            'anthropic-version': '2023-06-01',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 60));

    debugPrint('[VetAI] Claude status: ${resp.statusCode}');
    debugPrint('[VetAI] Claude body: ${resp.body}');
    if (resp.statusCode != 200) {
      throw Exception(
          'Anthropic API ${resp.statusCode}: ${utf8.decode(resp.bodyBytes)}');
    }
    final json =
        jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    final content = json['content'] as List?;
    if (content == null || content.isEmpty) return '';
    for (final block in content) {
      final b = block as Map<String, dynamic>;
      if (b['type'] == 'text') {
        final raw = b['text'] as String? ?? '';
        return raw.replaceAll('```json', '').replaceAll('```', '').trim();
      }
    }
    return '';
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
