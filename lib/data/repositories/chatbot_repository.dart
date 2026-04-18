import 'package:google_generative_ai/google_generative_ai.dart';
import '../../core/constants/api_keys.dart';

class ChatbotRepository {
  late GenerativeModel _model;
  ChatSession? _chatSession;
  
  final List<String> _fallbackModels = [
    'gemini-2.5-flash',
    'gemini-2.0-flash',
    'gemini-2.0-flash-lite',
  ];

  ChatbotRepository() {
    _model = GenerativeModel(
      model: _fallbackModels[0],
      apiKey: ApiKeys.geminiApiKey,
    );
  }

  void initializeSession(String systemContext) {
    _chatSession = _model.startChat(
      history: [
        Content.text(
          "You are MedAssist, a highly intelligent and polite medical AI assistant app.\n"
          "Your job is to answer the user's health queries based on their personal records.\n"
          "If the user asks about their vitals, doctor visits, medicines, interpret the data for them.\n"
          "If they ask something outside of medication/health context, gently steer them back to their health.\n"
          "Do not format your responses in raw JSON or code blocks unless necessary.\n"
          "IMPORTANT CONTEXT ABOT THE USER:\n$systemContext\n\n"
          "Reply conversationally, concisely, and warmly. If requested, provide answers in Urdu.",
        ),
        Content.model([TextPart("Understood. I am ready to assist based on the provided context.")]),
      ],
    );
  }

  Future<String> sendMessage(String text) async {
    if (_chatSession == null) {
      throw Exception("Chat session not initialized with user context yet.");
    }
    
    for (int i = 0; i < _fallbackModels.length; i++) {
      try {
        if (i > 0) {
           // Swap to fallback model implicitly but keep conversation history
           final fallbackModel = GenerativeModel(
             model: _fallbackModels[i],
             apiKey: ApiKeys.geminiApiKey,
           );
           _chatSession = fallbackModel.startChat(history: _chatSession!.history.toList());
        }
        
        final response = await _chatSession!.sendMessage(Content.text(text));
        return response.text ?? 'I apologize, I could not process that request.';
      } catch (e) {
         final errorStr = e.toString();
         if (errorStr.contains('503') || errorStr.contains('UNAVAILABLE') || errorStr.contains('high demand') || errorStr.contains('overloaded')) {
            if (i == _fallbackModels.length - 1) {
               throw Exception("All AI models are currently overwhelmed by global traffic. Please try again later.");
            }
            // High demand on current model, cascade to the next fallback model (i.e. lite)
            continue;
         }
         
         if (errorStr.contains('apiKey')) {
            throw Exception("Invalid Gemini API Key. Please configure it properly in api_keys.dart.");
         }
         throw Exception("Failed to generate response: $e");
      }
    }
    return '';
  }
}
