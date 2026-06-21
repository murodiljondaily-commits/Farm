// Fill these before running. Never commit real keys.
class AppConfig {
  static const geminiApiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
  static const muxlisaApiKey = String.fromEnvironment('MUXLISA_API_KEY', defaultValue: '');

  // Gemini REST endpoint
  static const geminiModel = 'gemini-2.5-flash';
  static const geminiBase =
      'https://generativelanguage.googleapis.com/v1beta/models/$geminiModel:generateContent';

  // Muxlisa API (STT only — TTS is now handled by backend via Yandex SpeechKit)
  static const muxlisaBase = 'https://api.muxlisa.ai/v1';
}
