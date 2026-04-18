import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../core/constants/api_keys.dart';
import '../models/prescription_model.dart';

class PrescriptionRepository {
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';
  static const String _audioUrl = 'https://api.openai.com/v1/audio/transcriptions';

  Future<String?> _transcribeAudio(File audioFile) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(_audioUrl));
      request.headers['Authorization'] = 'Bearer ${ApiKeys.openAiApiKey}';
      request.fields['model'] = 'whisper-1';
      request.files.add(await http.MultipartFile.fromPath('file', audioFile.path));

      final response = await request.send();
      if (response.statusCode != 200) return null;

      final respStr = await response.stream.bytesToString();
      final json = jsonDecode(respStr);
      return json['text'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<PrescriptionModel> analyzePrescription(File imageFile, {File? audioFile}) async {
    if (ApiKeys.openAiApiKey.isEmpty) {
      throw Exception('Please configure your OpenAI API Key in api_keys.dart');
    }

    // Convert image to base64
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    // Determine mime type
    final extension = imageFile.path.split('.').last.toLowerCase();
    String mimeType = 'image/jpeg';
    if (extension == 'png') {
      mimeType = 'image/png';
    } else if (extension == 'webp') {
      mimeType = 'image/webp';
    }

    // System message to bypass content policy for document OCR
    const systemMessage = '''You are a medical document extraction and visit summation assistant. Your job is to read text from photographed documents, optionally combine it with transcribed doctor audio, and return accurate structured data in JSON format. You are NOT providing medical advice — you are simply structuring OCR and summarizing text. This is a legitimate accessibility tool.''';

    String transcription = '';
    if (audioFile != null) {
      final t = await _transcribeAudio(audioFile);
      if (t != null && t.isNotEmpty) {
        transcription = t;
      }
    }

    String userPrompt = '''Read all the text visible in this document image and extract the following structured information as JSON.

This is a document from Pakistan. Pakistani documents use specific shorthand notations for scheduling:
- "1+1" means one in the morning and one in the evening (2 times a day)
- "1+1+1" means one morning, one afternoon, one evening (3 times a day)
- "1+0+1" means one morning, skip afternoon, one evening
- "0+0+1" means only one at night
- "1+2" means one in the morning, two in the evening
- "BD" means twice daily
- "TDS" means three times daily
- "OD" means once daily
- "SOS" means take only when needed
- "HS" means at bedtime
- "AC" means before meals
- "PC" means after meals

Look for and extract:
1. Any organization or institution name at the top of the document (return as "clinic_name"). If not found, return empty string "".
2. Any person's name that appears to be the author/writer (return as "doctor_name"). If not found, return empty string "".
3. For each item listed in the document, extract:
   - "name": the item name as written
   - "dosage": any quantity or strength (like "500mg", "5ml", "1 tablet")
   - "frequency": the schedule pattern. Convert shorthand: "1+1" → "1+1 (Morning + Evening)", "BD" → "1+1 (Twice Daily)", "TDS" → "1+1+1 (Three Times Daily)", "OD" → "1+0+0 (Once Daily)". If NO frequency is found at all, return empty string ""
   - "duration_days": the course length written near the medicine (e.g. "5 days", "1 week", "2 hafta", "10 din", "1 month"). Convert Urdu to English: "din" → "days", "hafta" → "week(s)". If not specified, return empty string ""
   - "when_to_take": any timing instructions (like "After meals", "Before bed", "Empty stomach"). If not specified, return ""
   - "confidence": a score from 1 to 100 showing how clearly you could read that specific line. Unclear handwriting = lower score.
4. Any vitals or clinical measurements (e.g., Blood Pressure, Heart Rate, Blood Sugar, Temperature, Weight) mentioned anywhere in the document or audio transcription. Return these as a key-value mapping object named "vitals" (e.g., {"Blood Pressure": "120/80", "Blood Sugar": "95"}). Do NOT return this as a list, return it as a JSON Object. If none are found, return {}.
''';

    if (transcription.isNotEmpty) {
      userPrompt += '''

Additionally, here is the raw audio transcription from the doctor's visit:
"$transcription"

CRITICAL AUDIO INSTRUCTION:
1. Cross-check the image OCR against this audio transcript. If any medicine names, dosages, frequency, or durations are missing, vague, or illegible on the image, use the transcription to correct and fill them in accurately.
2. Summarize key advice, warnings, diagnosis thoughts, tests advised, or next steps from the audio transcription into the "notes" field. Keep it concise, clear, and professional.
''';
    } else {
      userPrompt += '''

Ensure the "notes" field is an empty string "" since no audio transcription was provided.
''';
    }

    userPrompt += '''

Return ONLY valid JSON, no markdown, no explanation, no extra text:
{
  "clinic_name": "Example Clinic",
  "doctor_name": "Dr. Name",
  "notes": "Synthesized advice from doctor's audio...",
  "medicines": [
    {
      "name": "Medicine Name",
      "dosage": "500mg",
      "frequency": "1+1 (Morning + Evening)",
      "duration_days": "7 days",
      "when_to_take": "After meals",
      "confidence": 85
    }
  ]
}

If you cannot read the document at all, return:
{"clinic_name": "", "doctor_name": "", "notes": "", "medicines": []}''';

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer ${ApiKeys.openAiApiKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'gpt-4o',
          'messages': [
            {
              'role': 'system',
              'content': systemMessage,
            },
            {
              'role': 'user',
              'content': [
                {'type': 'text', 'text': userPrompt},
                {
                  'type': 'image_url',
                  'image_url': {
                    'url': 'data:$mimeType;base64,$base64Image',
                    'detail': 'high',
                  },
                },
              ],
            }
          ],
          'max_tokens': 2000,
          'temperature': 0.1,
        }),
      );

      if (response.statusCode != 200) {
        final errorBody = jsonDecode(response.body);
        final errorMsg = errorBody['error']?['message'] ?? response.body;
        throw Exception('API Error (${response.statusCode}): $errorMsg');
      }

      final responseJson = jsonDecode(response.body);
      String content = responseJson['choices'][0]['message']['content'] ?? '{}';

      // Check if the response is a refusal instead of JSON
      if (!content.trimLeft().startsWith('{') && !content.contains('"medicines"')) {
        throw Exception('The AI could not read this image. Please try with a clearer photo.');
      }

      // Clean up markdown if the AI wraps it
      if (content.contains('```json')) {
        content = content.split('```json')[1];
        if (content.contains('```')) {
          content = content.split('```')[0];
        }
      } else if (content.contains('```')) {
        content = content.replaceAll('```', '');
      }
      content = content.trim();

      final parsedJson = jsonDecode(content);
      return PrescriptionModel.fromJson(parsedJson);
    } on FormatException {
      throw Exception('Could not parse the AI response. Please try again with a clearer image.');
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Failed to analyze: $e');
    }
  }
}
