import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../providers/farm_provider.dart';
import '../providers/locale_provider.dart';
import '../services/db_service.dart';
import '../services/vet_ai_service.dart';
import '../theme.dart';

// ── Chat message model ────────────────────────────────────────────────────────

class ChatMessage {
  final String id;
  final bool isUser;
  final String? text;
  final VetResponse? vetResponse;
  final VetIntent? intent;
  final bool isLoading;
  final String? photoPath;
  final Map<String, String>? emergencyContact;

  const ChatMessage({
    required this.id,
    required this.isUser,
    this.text,
    this.vetResponse,
    this.intent,
    this.isLoading = false,
    this.photoPath,
    this.emergencyContact,
  });

  ChatMessage copyWith({
    VetResponse? vetResponse,
    VetIntent? intent,
    bool? isLoading,
    Map<String, String>? emergencyContact,
  }) =>
      ChatMessage(
        id: id,
        isUser: isUser,
        text: text,
        vetResponse: vetResponse ?? this.vetResponse,
        intent: intent ?? this.intent,
        isLoading: isLoading ?? this.isLoading,
        photoPath: photoPath,
        emergencyContact: emergencyContact ?? this.emergencyContact,
      );
}

// ── Screen ────────────────────────────────────────────────────────────────────

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen>
    with SingleTickerProviderStateMixin {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textCtrl = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final AudioPlayer _player = AudioPlayer();
  final ImagePicker _picker = ImagePicker();

  bool _isRecording = false;
  bool _recordingLocked = false;
  bool _processing = false;
  bool _hasText = false;
  bool _sttProcessing = false;
  String _isPlayingId = '';
  int _recordSeconds = 0;
  Timer? _recordTimer;
  late AnimationController _pulseCtrl;

  // Railway backend session state
  String? _conversationId;
  bool _vetMode = false;
  bool _historyLoading = true;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _textCtrl.addListener(() {
      final has = _textCtrl.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
    _loadHistoryThenWelcome();
    _syncAnimals();
  }

  /// Loads conversation history from backend; shows welcome if no history exists.
  /// Replaces the old pattern of welcome-then-async-replace to eliminate pop-in.
  Future<void> _loadHistoryThenWelcome() async {
    final farmId = context.read<FarmProvider>().farmId;
    if (farmId == null) {
      if (mounted) setState(() => _historyLoading = false);
      _addWelcome();
      return;
    }
    try {
      final data = await VetAiService.loadLatestConversation(farmId);
      if (!mounted) return;

      final hasHistory = data != null &&
          data['conversation_id'] != null &&
          ((data['messages'] as List<dynamic>?) ?? []).isNotEmpty;

      if (hasHistory) {
        final convId = data['conversation_id'] as String;
        final msgs = (data['messages'] as List<dynamic>?) ?? [];
        setState(() {
          _historyLoading = false;
          _conversationId = convId;
          for (final m in msgs) {
            final role = m['role'] as String? ?? '';
            final content = m['content'] as String? ?? '';
            if (role == 'user') {
              _messages.add(ChatMessage(
                id: const Uuid().v4(),
                isUser: true,
                text: content,
              ));
            } else if (role == 'assistant') {
              _messages.add(ChatMessage(
                id: const Uuid().v4(),
                isUser: false,
                vetResponse:
                    VetResponse(assessment: content, firstAid: [], confidence: 0),
                intent: const VetIntent(intent: 'GENERAL'),
              ));
            }
          }
        });
        _scrollToBottom();
      } else {
        setState(() => _historyLoading = false);
        _addWelcome();
      }
    } catch (e) {
      debugPrint('[AI] loadHistory error: $e');
      if (mounted) {
        setState(() => _historyLoading = false);
        _addWelcome();
      }
    }
  }

  Future<void> _deleteConversation() async {
    final farmId = context.read<FarmProvider>().farmId;
    if (farmId != null && _conversationId != null) {
      await VetAiService.deleteConversation(farmId, _conversationId!);
    }
    if (!mounted) return;
    setState(() {
      _conversationId = null;
      _vetMode = false;
      _messages.clear();
    });
    _addWelcome();
  }

  Future<void> _syncAnimals() async {
    final farmId = context.read<FarmProvider>().farmId;
    if (farmId == null) return;
    await VetAiService.syncAnimalsToBackend(farmId);
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _pulseCtrl.dispose();
    _player.dispose();
    _textCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // ── Recording timer ───────────────────────────────────────────────────────

  void _startRecordTimer() {
    _recordSeconds = 0;
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _recordSeconds++);
    });
  }

  void _stopRecordTimer() {
    _recordTimer?.cancel();
    _recordTimer = null;
  }

  void _lockRecording() {
    if (_recordingLocked) return;
    HapticFeedback.mediumImpact();
    setState(() => _recordingLocked = true);
  }

  // ── Welcome ───────────────────────────────────────────────────────────────

  void _addWelcome() {
    final isRu =
        context.read<LocaleProvider>().locale.languageCode == 'ru';
    setState(() {
      _messages.add(ChatMessage(
        id: const Uuid().v4(),
        isUser: false,
        vetResponse: VetResponse(
          assessment: isRu
              ? 'Ассалому алайкум! Я Соня — ваш ИИ-ветеринар. '
                  'Расскажите о состоянии животного, симптомах, вакцинации '
                  'или весе. Пишите текст или говорите голосом.'
              : 'Salom! Men Sonya — sizning AI veterinar yordamchingizman. '
                  'Hayvon holati, kasallik belgilari, emlash yoki vazn haqida '
                  'menga xabar bering. Ovoz yoki matn bilan murojaat qiling.',
          firstAid: [],
          confidence: 100,
        ),
        intent: const VetIntent(intent: 'GENERAL'),
      ));
    });
  }

  // ── Sync AI writes back to local SQLite ──────────────────────────────────

  Future<void> _applyDataSavedToSQLite(
      String farmId, Map<String, dynamic> dataSaved) async {
    try {
      final statusWrite = dataSaved['update_animal_status'] as Map<String, dynamic>?;
      if (statusWrite != null && statusWrite['success'] == true) {
        final earTag = statusWrite['ear_tag'] as String?;
        final newStatus = statusWrite['new_status'] as String?;
        if (earTag != null && newStatus != null) {
          await DbService.updateAnimalStatus(farmId, earTag, newStatus);
          debugPrint('[AI] Synced status update → $earTag: $newStatus');
        }
      }
      // Pull fresh Firestore state into SQLite for any AI write
      await VetAiService.syncAnimalsFromBackend(farmId);
    } catch (e) {
      debugPrint('[AI] _applyDataSavedToSQLite error: $e');
    }
  }

  // ── Send pipeline ─────────────────────────────────────────────────────────

  Future<void> _send(String text, {String? imagePath}) async {
    if (text.trim().isEmpty && imagePath == null) return;
    if (_processing) return;

    final farmId = context.read<FarmProvider>().farmId;
    if (farmId == null) return;
    final isRu =
        context.read<LocaleProvider>().locale.languageCode == 'ru';

    final userMsgId = const Uuid().v4();
    final aiMsgId = const Uuid().v4();
    setState(() {
      _processing = true;
      _messages.add(ChatMessage(
        id: userMsgId,
        isUser: true,
        text: text.trim().isEmpty ? null : text.trim(),
        photoPath: imagePath,
      ));
      _messages.add(ChatMessage(
        id: aiMsgId,
        isUser: false,
        isLoading: true,
      ));
    });
    _textCtrl.clear();
    _scrollToBottom();

    try {
      VetResponse aiResp;
      VetIntent? intent;
      Map<String, String>? emergencyContact;
      String? uploadedPhotoUrl;

      if (imagePath != null) {
        intent = const VetIntent(
          intent: 'INJECT',
          actionType: 'health_case',
          severity: 'medium',
        );
        final ctx = await VetAiService.getAnimalContext(farmId);
        final rag = await VetAiService.getRagContext(null, []);
        final result = await VetAiService.diagnoseFromPhoto(
          imagePath: imagePath,
          farmId: farmId,
          earTag: null,
          bodyPart: null,
          animalContext: ctx ?? '',
          ragContext: rag,
        );
        aiResp = result.response;
        uploadedPhotoUrl = result.photoUrl;

        // Keep local SQLite save for photo diagnoses
        final savedType = await VetAiService.autoSave(
          farmId: farmId,
          intent: intent,
          response: aiResp,
          photoUrl: uploadedPhotoUrl,
        );
        if (savedType != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Saqlandi'),
              duration: Duration(seconds: 2),
              backgroundColor: Color(0xFF22DD66),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        // Route all text messages through Railway backend
        final fp = context.read<FarmProvider>();
        final isEmergency = detectEmergencyKeywords(text);
        intent = VetIntent(
          intent: isEmergency ? 'EMERGENCY' : 'GENERAL',
          severity: isEmergency ? 'emergency' : 'low',
        );

        try {
          final result = await VetAiService.chatWithBackend(
            farmId: farmId,
            userId: fp.userId ?? 'unknown',
            userRole: fp.userRole ?? 'owner',
            message: text,
            conversationId: _conversationId,
            vetMode: _vetMode,
          );
          aiResp = result.response;
          if (mounted) {
            setState(() {
              _conversationId = result.conversationId;
              _vetMode = result.vetMode;
            });
          }
          if (result.dataSaved.isNotEmpty && mounted) {
            // Sync confirmed AI writes back to local SQLite so the UI refreshes
            await _applyDataSavedToSQLite(farmId, result.dataSaved);
            if (mounted) context.read<FarmProvider>().notifyDirty();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Saqlandi'),
                  duration: Duration(seconds: 2),
                  backgroundColor: Color(0xFF22DD66),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        } catch (e) {
          debugPrint('[AI] backend error: $e');
          aiResp = VetResponse(
            assessment:
                "⚠️ Server bilan bog'lanib bo'lmadi, qayta urinib ko'ring",
            confidence: 0,
          );
        }
      }

      if (intent.isEmergency) {
        emergencyContact = await VetAiService.getVetContact(farmId);
      }

      if (mounted) {
        setState(() {
          final idx = _messages.indexWhere((m) => m.id == aiMsgId);
          if (idx != -1) {
            _messages[idx] = _messages[idx].copyWith(
              vetResponse: aiResp,
              intent: intent,
              isLoading: false,
              emergencyContact: emergencyContact,
            );
          }
          _processing = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('[AI] send error: $e');
      if (mounted) {
        setState(() {
          final idx = _messages.indexWhere((m) => m.id == aiMsgId);
          if (idx != -1) {
            _messages[idx] = _messages[idx].copyWith(
              vetResponse: VetResponse(
                assessment: isRu
                    ? 'Произошла ошибка. Попробуйте снова.'
                    : "Xatolik yuz berdi. Qayta urinib ko'ring.",
                confidence: 0,
              ),
              isLoading: false,
            );
          }
          _processing = false;
        });
      }
    }
  }

  // ── Recording ─────────────────────────────────────────────────────────────

  Future<void> _startRecording() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mikrofon ruxsati kerak')),
        );
      }
      return;
    }
    final ok = await VetAiService.startRecording();
    if (ok && mounted) {
      setState(() => _isRecording = true);
      _startRecordTimer();
    }
  }

  Future<void> _stopRecordingAndSend() async {
    _stopRecordTimer();
    final path = await VetAiService.stopRecording();
    if (mounted) {
      setState(() {
        _isRecording = false;
        _recordingLocked = false;
        _recordSeconds = 0;
        if (path != null) _sttProcessing = true;
      });
    }
    if (path == null) return;
    try {
      final transcript = await VetAiService.transcribeAudio(path);
      if (transcript.isNotEmpty && mounted) {
        _textCtrl.text = transcript;
        setState(() => _sttProcessing = false);
        await Future.delayed(const Duration(milliseconds: 500));
        await _send(transcript);
      } else if (mounted) {
        setState(() => _sttProcessing = false);
      }
    } catch (e) {
      debugPrint('[AI] transcription error: $e');
      if (mounted) {
        setState(() => _sttProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("🎤 Ovoz tanilmadi, qayta urinib ko'ring"),
            backgroundColor: Color(0xFFC23B2A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ── Photo picker (camera + gallery) ──────────────────────────────────────

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: kOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.camera_alt_rounded,
                    color: kOrange),
              ),
              title: const Text(
                '📷 Kamera',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Yangi rasm olish',
                  style: TextStyle(fontSize: 11)),
              onTap: () =>
                  Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF2E9EF4).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.photo_library_rounded,
                    color: Color(0xFF2E9EF4)),
              ),
              title: const Text(
                '🖼️ Galereya',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Telefondan tanlash',
                  style: TextStyle(fontSize: 11)),
              onTap: () =>
                  Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    final xfile =
        await _picker.pickImage(source: source, imageQuality: 80);
    if (xfile == null || !mounted) return;
    await _send('', imagePath: xfile.path);
  }

  // ── TTS ───────────────────────────────────────────────────────────────────

  Future<void> _playTts(String msgId, String text) async {
    if (_isPlayingId == msgId) {
      await _player.stop();
      if (mounted) setState(() => _isPlayingId = '');
      return;
    }
    setState(() => _isPlayingId = msgId);
    try {
      final bytes = await VetAiService.textToSpeech(text);
      if (bytes != null && bytes.isNotEmpty && mounted) {
        await _player.play(BytesSource(bytes));
        _player.onPlayerComplete.first.then((_) {
          if (mounted) setState(() => _isPlayingId = '');
        });
      } else {
        if (mounted) setState(() => _isPlayingId = '');
      }
    } catch (e) {
      debugPrint('[AI] TTS playback error: $e');
      if (mounted) setState(() => _isPlayingId = '');
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF0A0806),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F3EF),
        body: Column(
          children: [
            _AppBar(
              onBack: () =>
                  context.canPop() ? context.pop() : context.go('/'),
              onDelete: _deleteConversation,
            ),
            Expanded(
              child: _historyLoading
                  ? const _HistorySkeleton()
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                      itemCount: _messages.length,
                      itemBuilder: (_, i) {
                        final msg = _messages[i];
                        if (msg.isUser) return _UserBubble(msg: msg);
                        return _AiCard(
                          msg: msg,
                          isPlaying: _isPlayingId == msg.id,
                          onTts: () {
                            final text = msg.vetResponse?.assessment ?? '';
                            if (text.isNotEmpty) _playTts(msg.id, text);
                          },
                        );
                      },
                    ),
            ),
            _InputBar(
              controller: _textCtrl,
              hasText: _hasText,
              isRecording: _isRecording,
              recordingLocked: _recordingLocked,
              recordSeconds: _recordSeconds,
              processing: _processing,
              sttProcessing: _sttProcessing,
              pulseCtrl: _pulseCtrl,
              onSend: () => _send(_textCtrl.text),
              onMicStart: _startRecording,
              onMicStop: _stopRecordingAndSend,
              onMicLock: _lockRecording,
              onSendLocked: _stopRecordingAndSend,
              onCamera: _pickPhoto,
            ),
          ],
        ),
      ),
    );
  }
}

// ── History loading skeleton ──────────────────────────────────────────────────

class _HistorySkeleton extends StatelessWidget {
  const _HistorySkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _SkeletonBubble(width: 220, isUser: false),
        const SizedBox(height: 10),
        _SkeletonBubble(width: 160, isUser: true),
        const SizedBox(height: 10),
        _SkeletonBubble(width: 260, isUser: false),
        const SizedBox(height: 10),
        _SkeletonBubble(width: 140, isUser: true),
        const SizedBox(height: 10),
        _SkeletonBubble(width: 200, isUser: false),
      ],
    );
  }
}

class _SkeletonBubble extends StatelessWidget {
  final double width;
  final bool isUser;
  const _SkeletonBubble({required this.width, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        width: width,
        height: 44,
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: isUser
              ? const Color(0xFFE8E4DE)
              : const Color(0xFFDDD9D2),
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }
}

// ── App bar ───────────────────────────────────────────────────────────────────

class _AppBar extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onDelete;
  const _AppBar({required this.onBack, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0A0806),
        borderRadius:
            BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 16,
        left: 8,
        right: 4,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 22),
            onPressed: onBack,
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: kOrange.withValues(alpha: 0.22),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('🩺', style: TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Sonya',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'AI Veterinar · 15 yil tajriba',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            width: 9,
            height: 9,
            decoration: const BoxDecoration(
              color: Color(0xFF22DD66),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text('Online',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 10)),
          const SizedBox(width: 4),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded,
                color: Colors.white.withValues(alpha: 0.7), size: 22),
            color: const Color(0xFF1A1814),
            onSelected: (v) {
              if (v == 'delete') onDelete();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded,
                        color: Colors.redAccent, size: 20),
                    SizedBox(width: 10),
                    Text("Suhbatni o'chirish",
                        style: TextStyle(color: Colors.white, fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── User bubble ───────────────────────────────────────────────────────────────

class _UserBubble extends StatelessWidget {
  final ChatMessage msg;
  const _UserBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 60),
      child: Align(
        alignment: Alignment.centerRight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (msg.photoPath != null)
              Container(
                margin: const EdgeInsets.only(bottom: 4),
                width: 220,
                height: 165,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: DecorationImage(
                    image: FileImage(File(msg.photoPath!)),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            if (msg.text != null && msg.text!.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: kOrange,
                  borderRadius: BorderRadius.circular(20).copyWith(
                      bottomRight: const Radius.circular(4)),
                  boxShadow: [
                    BoxShadow(
                        color: kOrange.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: Text(
                  msg.text!,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.4),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── AI response card ──────────────────────────────────────────────────────────

class _AiCard extends StatelessWidget {
  final ChatMessage msg;
  final bool isPlaying;
  final VoidCallback onTts;
  const _AiCard(
      {required this.msg,
      required this.isPlaying,
      required this.onTts});

  @override
  Widget build(BuildContext context) {
    if (msg.isLoading) return const _LoadingBubble();

    final resp = msg.vetResponse;
    final intent = msg.intent;
    final isEmerg = intent?.isEmergency ?? false;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 60),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(right: 8, top: 2),
            decoration: BoxDecoration(
              color: kOrange.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Center(
                child: Text('🩺', style: TextStyle(fontSize: 22))),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + confidence
                Row(children: [
                  const Text('Sonya',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: kDark)),
                  const SizedBox(width: 8),
                  if (resp != null && resp.confidence > 0)
                    _ConfidenceBadge(pct: resp.confidence),
                ]),
                const SizedBox(height: 4),
                // Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20).copyWith(
                        topLeft: const Radius.circular(4)),
                    boxShadow: [
                      BoxShadow(
                          color:
                              Colors.black.withValues(alpha: 0.07),
                          blurRadius: 12,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isEmerg) ...[
                        _EmergencyBanner(
                            contact: msg.emergencyContact),
                        const SizedBox(height: 10),
                      ],
                      if (resp != null)
                        Text(
                          resp.assessment,
                          style: const TextStyle(
                              fontSize: 16,
                              color: kDark,
                              height: 1.5),
                        ),
                      if (resp != null &&
                          resp.firstAid.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        const Text(
                          '🩺 Darhol choralar:',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: kDark),
                        ),
                        const SizedBox(height: 8),
                        ...resp.firstAid.asMap().entries.map(
                              (e) => Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      margin: const EdgeInsets.only(
                                          right: 8, top: 1),
                                      decoration: BoxDecoration(
                                        color: kOrange,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${e.key + 1}',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight:
                                                  FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(e.value,
                                          style: const TextStyle(
                                              fontSize: 16,
                                              color: kDark,
                                              height: 1.4)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                      ],
                      if (resp != null && resp.followUpInDays > 0) ...[
                        const SizedBox(height: 10),
                        Row(children: [
                          Icon(Icons.calendar_today_outlined,
                              size: 14, color: kGrey),
                          const SizedBox(width: 5),
                          Text(
                            '${resp.followUpInDays} kundan so\'ng tekshirish',
                            style: const TextStyle(
                                fontSize: 11, color: kGrey),
                          ),
                        ]),
                      ],
                    ],
                  ),
                ),
                // TTS button
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: onTts,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPlaying
                            ? Icons.stop_circle_outlined
                            : Icons.volume_up_outlined,
                        size: 15,
                        color: kOrange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isPlaying ? 'To\'xtatish' : '🔊 Eshitish',
                        style: const TextStyle(
                            fontSize: 11, color: kOrange),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfidenceBadge extends StatelessWidget {
  final int pct;
  const _ConfidenceBadge({required this.pct});

  Color get _color {
    if (pct >= 80) return const Color(0xFF22DD66);
    if (pct >= 60) return kOrange;
    return kError;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$pct%',
        style: TextStyle(
            fontSize: 10,
            color: _color,
            fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _EmergencyBanner extends StatelessWidget {
  final Map<String, String>? contact;
  const _EmergencyBanner({this.contact});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kError.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kError.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.emergency_rounded, color: kError, size: 18),
            SizedBox(width: 6),
            Text(
              '🚨 FAVQULODDA HOLAT',
              style: TextStyle(
                  color: kError,
                  fontWeight: FontWeight.w800,
                  fontSize: 13),
            ),
          ]),
          if (contact != null &&
              (contact!['phone'] ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Veterinar: ${contact!['name']}',
              style: const TextStyle(
                  fontSize: 13,
                  color: kDark,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () =>
                  launchUrl(Uri.parse('tel:${contact!['phone']}')),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: kError,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.phone_rounded,
                        color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '📞 ${contact!['phone']}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),
            const Text(
              'Darhol veterinar chaqiring!',
              style: TextStyle(
                  fontSize: 13,
                  color: kError,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }
}

class _LoadingBubble extends StatelessWidget {
  const _LoadingBubble();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 60),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: kOrange.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Center(
                child: Text('💬', style: TextStyle(fontSize: 22))),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20).copyWith(
                  topLeft: const Radius.circular(4)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 3))
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Dot(delay: 0),
                const SizedBox(width: 5),
                _Dot(delay: 200),
                const SizedBox(width: 5),
                _Dot(delay: 400),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600));
    _a = Tween<double>(begin: 0.3, end: 1.0).animate(_c);
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _c.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _a,
        child: Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
                color: kOrange, shape: BoxShape.circle)),
      );
}

// ── Input bar ─────────────────────────────────────────────────────────────────

class _InputBar extends StatefulWidget {
  final TextEditingController controller;
  final bool hasText;
  final bool isRecording;
  final bool recordingLocked;
  final int recordSeconds;
  final bool processing;
  final bool sttProcessing;
  final AnimationController pulseCtrl;
  final VoidCallback onSend;
  final VoidCallback onMicStart;
  final VoidCallback onMicStop;
  final VoidCallback onMicLock;
  final VoidCallback onSendLocked;
  final VoidCallback onCamera;

  const _InputBar({
    required this.controller,
    required this.hasText,
    required this.isRecording,
    required this.recordingLocked,
    required this.recordSeconds,
    required this.processing,
    required this.sttProcessing,
    required this.pulseCtrl,
    required this.onSend,
    required this.onMicStart,
    required this.onMicStop,
    required this.onMicLock,
    required this.onSendLocked,
    required this.onCamera,
  });

  @override
  State<_InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<_InputBar> {
  double _initialPressY = 0;

  String _formatTime(int s) =>
      '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
            top: BorderSide(
                color: Colors.black.withValues(alpha: 0.06))),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, -4))
        ],
      ),
      child: Row(
        children: [
          // Camera button (hidden while recording or STT processing)
          if (!widget.isRecording && !widget.sttProcessing)
            _BarButton(
              icon: Icons.photo_camera_outlined,
              onTap: widget.processing ? null : widget.onCamera,
            )
          else
            const SizedBox(width: 46),
          const SizedBox(width: 6),

          // Centre: text field OR recording indicator OR STT spinner
          Expanded(
            child: widget.isRecording
                ? _RecordingIndicator(
                    pulseCtrl: widget.pulseCtrl,
                    locked: widget.recordingLocked,
                    timeLabel: _formatTime(widget.recordSeconds),
                  )
                : widget.sttProcessing
                    ? Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: kOrange.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                              color: kOrange.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: kOrange,
                              ),
                            ),
                            SizedBox(width: 10),
                            Text(
                              '🎤 Tahlil qilinmoqda...',
                              style: TextStyle(
                                  color: kOrange,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F3EF),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                              color:
                                  Colors.black.withValues(alpha: 0.08)),
                        ),
                        child: TextField(
                          controller: widget.controller,
                          minLines: 1,
                          maxLines: 4,
                          textInputAction: TextInputAction.send,
                          onSubmitted: widget.processing
                              ? null
                              : (_) => widget.onSend(),
                          style: const TextStyle(
                              fontSize: 14, color: kDark),
                          decoration: const InputDecoration(
                            hintText: 'Hayvon haqida yozing...',
                            hintStyle:
                                TextStyle(color: kGrey, fontSize: 14),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            filled: false,
                          ),
                        ),
                      ),
          ),
          const SizedBox(width: 6),

          // Right button
          if (widget.isRecording && widget.recordingLocked)
            _BarButton(
              icon: Icons.send_rounded,
              color: kOrange,
              iconColor: Colors.white,
              onTap: widget.onSendLocked,
            )
          else if (!widget.isRecording && widget.hasText)
            _BarButton(
              icon: Icons.send_rounded,
              color: kOrange,
              iconColor: Colors.white,
              onTap: widget.processing ? null : widget.onSend,
            )
          else if (widget.sttProcessing)
            const SizedBox(width: 50)
          else
            GestureDetector(
              onTapDown: (d) {
                _initialPressY = d.globalPosition.dy;
                if (!widget.processing && !widget.isRecording) {
                  widget.onMicStart();
                }
              },
              onTapUp: (_) {
                if (widget.isRecording && !widget.recordingLocked) {
                  widget.onMicStop();
                }
              },
              onTapCancel: () {
                // Drag began — vertical drag handler takes over
              },
              onVerticalDragUpdate: (d) {
                if (widget.isRecording && !widget.recordingLocked) {
                  final dy = _initialPressY - d.globalPosition.dy;
                  if (dy > 60) widget.onMicLock();
                }
              },
              onVerticalDragEnd: (_) {
                if (widget.isRecording && !widget.recordingLocked) {
                  widget.onMicStop();
                }
              },
              child: AnimatedBuilder(
                animation: widget.pulseCtrl,
                builder: (_, __) => Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: widget.isRecording
                        ? kError.withValues(
                            alpha:
                                0.75 + 0.25 * widget.pulseCtrl.value)
                        : kDark,
                    shape: BoxShape.circle,
                    boxShadow: widget.isRecording
                        ? [
                            BoxShadow(
                                color: kError.withValues(alpha: 0.4),
                                blurRadius:
                                    16 * widget.pulseCtrl.value,
                                spreadRadius:
                                    4 * widget.pulseCtrl.value)
                          ]
                        : [],
                  ),
                  child: Icon(
                    widget.isRecording
                        ? Icons.stop_rounded
                        : Icons.mic_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Recording indicator ───────────────────────────────────────────────────────

class _RecordingIndicator extends StatelessWidget {
  final AnimationController pulseCtrl;
  final bool locked;
  final String timeLabel;

  const _RecordingIndicator({
    required this.pulseCtrl,
    required this.locked,
    required this.timeLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: kError.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: kError.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          if (locked)
            const Icon(Icons.lock_rounded, color: kError, size: 14)
          else
            AnimatedBuilder(
              animation: pulseCtrl,
              builder: (_, __) => Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: kError.withValues(
                      alpha: 0.7 + 0.3 * pulseCtrl.value),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          const SizedBox(width: 8),
          Text(
            timeLabel,
            style: const TextStyle(
                color: kError,
                fontSize: 13,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 6),
          if (!locked)
            Expanded(
              child: Text(
                '↑ yuqoriga → qulflash',
                style: TextStyle(
                    color: kError.withValues(alpha: 0.7),
                    fontSize: 10),
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}

// ── Bar button ────────────────────────────────────────────────────────────────

class _BarButton extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final Color? iconColor;
  final VoidCallback? onTap;

  const _BarButton(
      {required this.icon,
      this.color,
      this.iconColor,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: color ?? const Color(0xFFF0EDE8),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor ?? kGrey, size: 20),
      ),
    );
  }
}
