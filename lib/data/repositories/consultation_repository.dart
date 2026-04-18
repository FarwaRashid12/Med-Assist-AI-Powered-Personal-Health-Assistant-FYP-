import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../core/constants/api_keys.dart';
import '../models/consultation_model.dart';

class ConsultationRepository {
  final List<String> _fallbackModels = [
    'gemini-2.5-flash',
    'gemini-2.0-flash',
    'gemini-2.0-flash-lite',
  ];

  Future<ConsultationModel> extractInstructions(String transcript) async {
    if (ApiKeys.geminiApiKey == 'YOUR_GEMINI_API_KEY_HERE' || ApiKeys.geminiApiKey.isEmpty) {
      throw Exception('Please configure your Gemini API Key in api_keys.dart');
    }

    final prompt = '''
You are a medical assistant designed to extract actionable instructions from a doctor-patient conversation transcript.
Extract the medicine schedule and lifestyle/dietary instructions from the following transcript.
Return ONLY valid JSON in the exact following format, without any markdown formatting or extra text:
{
  "medicines": ["take 1 pill of Aspirin after lunch", "take 5ml of Cough Syrup before bed"],
  "lifestyle": ["drink 8 glasses of water daily", "avoid spicy food for a week"]
}

Transcript:
$transcript
''';

    for (int i = 0; i < _fallbackModels.length; i++) {
      try {
        final model = GenerativeModel(
          model: _fallbackModels[i],
          apiKey: ApiKeys.geminiApiKey,
        );
        
        final response = await model.generateContent([Content.text(prompt)]);
        String responseText = response.text ?? '{}';

        if (responseText.contains('```json')) {
          responseText = responseText.split('```json')[1];
          if (responseText.contains('```')) {
            responseText = responseText.split('```')[0];
          }
        } else if (responseText.contains('```')) {
          responseText = responseText.replaceAll('```', '');
        }
        
        responseText = responseText.trim();
        final jsonResponse = jsonDecode(responseText);
        return ConsultationModel.fromJson(jsonResponse, transcript);
        
      } catch (e) {
         final errorStr = e.toString();
         if (errorStr.contains('503') || errorStr.contains('UNAVAILABLE') || errorStr.contains('high demand') || errorStr.contains('overloaded')) {
            if (i == _fallbackModels.length - 1) {
               throw Exception("All AI servers are currently busy. Please try processing the consultation again later.");
            }
            continue; // Fallback to cheaper/older model
         }
         throw Exception('Failed to parse AI response: $e');
      }
    }
    throw Exception('Unknown error occurred during AI processing.');
  }
}
