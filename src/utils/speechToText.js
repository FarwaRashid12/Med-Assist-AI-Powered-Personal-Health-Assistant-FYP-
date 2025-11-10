import { OPENAI_API_KEY } from "../context/env";
import * as FileSystem from "expo-file-system/legacy";

export const transcribeAudio = async (audioUri, options = {}) => {
  try {
    console.log("🎤 Starting transcription for:", audioUri);
    console.log("🌐 Language mode:", options.language || "auto-detect");
    
    const fileInfo = await FileSystem.getInfoAsync(audioUri);
    if (!fileInfo.exists) {
      throw new Error("Audio file not found");
    }

    const fileExtension = audioUri.split('.').pop()?.toLowerCase() || 'm4a';
    const fileName = `recording.${fileExtension}`;
    
    const mimeTypeMap = {
      'm4a': 'audio/m4a',
      'mp3': 'audio/mpeg',
      'mp4': 'audio/mp4',
      'wav': 'audio/wav',
      'webm': 'audio/webm',
      'ogg': 'audio/ogg',
      'mpeg': 'audio/mpeg',
      'mpga': 'audio/mpeg',
    };
    const mimeType = mimeTypeMap[fileExtension] || 'audio/m4a';

    const formData = new FormData();
    formData.append('file', {
      uri: audioUri,
      type: mimeType,
      name: fileName,
    });
    formData.append('model', 'whisper-1');
    
    if (options.language && options.language !== 'auto') {
      formData.append('language', options.language);
      console.log("📌 Using specified language:", options.language);
    } else {
      console.log("🔍 Auto-detecting language (supports Urdu/English mixed)");
    }
    
    const defaultPrompt = options.language === 'ur' 
      ? "This is a medical consultation in Urdu. Focus on accurate transcription of Urdu medical terms and phrases."
      : options.language === 'en'
      ? "This is a medical consultation in English. Focus on accurate transcription of English medical terms."
      : "This is a medical consultation that may contain Urdu and English. Transcribe accurately in both languages, preserving the original language of each word or phrase. Medical terms should be transcribed precisely.";
    
    const prompt = options.prompt || defaultPrompt;
    formData.append('prompt', prompt);
    
    formData.append('response_format', 'text');

    const response = await fetch('https://api.openai.com/v1/audio/transcriptions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${OPENAI_API_KEY}`,
      },
      body: formData,
    });

    if (!response.ok) {
      const errorData = await response.json().catch(() => ({ error: 'Unknown error' }));
      console.error("OpenAI API Error:", errorData);
      throw new Error(`OpenAI API error: ${errorData.error?.message || JSON.stringify(errorData)}`);
    }

    const transcription = await response.text();
    console.log("✅ Transcription completed:", transcription.substring(0, 100) + "...");
    
    return transcription.trim();
  } catch (error) {
    console.error("Speech-to-text error:", error);
    throw new Error(`Failed to transcribe audio: ${error.message}`);
  }
};

export const transcribeAudioDetailed = async (audioUri, options = {}) => {
  try {
    console.log("🎤 Starting detailed transcription for:", audioUri);
    console.log("🌐 Language mode:", options.language || "auto-detect");
    
    const fileInfo = await FileSystem.getInfoAsync(audioUri);
    if (!fileInfo.exists) {
      throw new Error("Audio file not found");
    }

    const fileExtension = audioUri.split('.').pop()?.toLowerCase() || 'm4a';
    const fileName = `recording.${fileExtension}`;
    
    const mimeTypeMap = {
      'm4a': 'audio/m4a',
      'mp3': 'audio/mpeg',
      'mp4': 'audio/mp4',
      'wav': 'audio/wav',
      'webm': 'audio/webm',
      'ogg': 'audio/ogg',
      'mpeg': 'audio/mpeg',
      'mpga': 'audio/mpeg',
    };
    const mimeType = mimeTypeMap[fileExtension] || 'audio/m4a';

    const formData = new FormData();
    formData.append('file', {
      uri: audioUri,
      type: mimeType,
      name: fileName,
    });
    formData.append('model', 'whisper-1');
    formData.append('response_format', 'verbose_json');
    
    if (options.language && options.language !== 'auto') {
      formData.append('language', options.language);
      console.log("📌 Using specified language:", options.language);
    } else {
      console.log("🔍 Auto-detecting language (supports Urdu/English mixed)");
    }
    
    const defaultPrompt = options.language === 'ur' 
      ? "This is a medical consultation in Urdu. Focus on accurate transcription of Urdu medical terms and phrases with timestamps."
      : options.language === 'en'
      ? "This is a medical consultation in English. Focus on accurate transcription of English medical terms with timestamps."
      : "This is a medical consultation that may contain Urdu and English. Transcribe accurately in both languages, preserving the original language of each word or phrase. Medical terms should be transcribed precisely with timestamps.";
    
    formData.append('prompt', options.prompt || defaultPrompt);

    const response = await fetch('https://api.openai.com/v1/audio/transcriptions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${OPENAI_API_KEY}`,
      },
      body: formData,
    });

    if (!response.ok) {
      const errorData = await response.json().catch(() => ({ error: 'Unknown error' }));
      throw new Error(`OpenAI API error: ${errorData.error?.message || JSON.stringify(errorData)}`);
    }

    const transcription = await response.json();
    console.log("✅ Detailed transcription completed");
    console.log("📊 Detected language:", transcription.language);
    
    return transcription;
  } catch (error) {
    console.error("Speech-to-text error:", error);
    throw new Error(`Failed to transcribe audio: ${error.message}`);
  }
};

export const transcribeAndExtractMedicalInfo = async (audioUri, options = {}) => {
  try {
    console.log("🏥 Starting medical transcription and extraction");
    console.log("🌐 Language mode:", options.language || "auto-detect");
    
    const transcriptionPrompt = options.language === 'ur'
      ? "This is a medical consultation in Urdu. Focus on accurate transcription of Urdu medical terms, symptoms, diagnoses, and treatment plans."
      : options.language === 'en'
      ? "This is a medical consultation in English. Focus on accurate transcription of English medical terms, symptoms, diagnoses, and treatment plans."
      : "This is a medical consultation that may contain Urdu and English. Transcribe accurately in both languages, preserving medical terms, symptoms, diagnoses, and treatment plans in their original language.";
    
    const transcription = await transcribeAudio(audioUri, {
      language: options.language || 'auto',
      prompt: transcriptionPrompt,
    });

    console.log("📝 Transcription completed, extracting medical info...");

    const systemPrompt = options.language === 'ur'
      ? 'You are a medical assistant that extracts key information from doctor-patient consultations in Urdu. Extract symptoms, diagnoses, prescriptions, and recommendations. Respond in Urdu or English as appropriate.'
      : options.language === 'en'
      ? 'You are a medical assistant that extracts key information from doctor-patient consultations in English. Extract symptoms, diagnoses, prescriptions, and recommendations.'
      : 'You are a medical assistant that extracts key information from doctor-patient consultations. The consultation may be in Urdu, English, or a mix of both languages. Extract symptoms, diagnoses, prescriptions, and recommendations. Preserve the original language when extracting terms, but provide structured data in English for consistency.';

    const response = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${OPENAI_API_KEY}`,
      },
      body: JSON.stringify({
        model: 'gpt-4o-mini',
        messages: [
          {
            role: 'system',
            content: systemPrompt,
          },
          {
            role: 'user',
            content: `Extract key medical information from this consultation transcript (may contain Urdu and/or English):\n\n${transcription}\n\nReturn a JSON object with: symptoms (array), diagnosis (string), prescriptions (array), recommendations (array), and follow_up (string). If the transcript contains Urdu terms, include them in the extracted information while providing English translations where helpful.`,
          },
        ],
        response_format: { type: 'json_object' },
        temperature: 0.2,
      }),
    });

    if (!response.ok) {
      const errorData = await response.json().catch(() => ({ error: 'Unknown error' }));
      throw new Error(`GPT API error: ${errorData.error?.message || JSON.stringify(errorData)}`);
    }

    const result = await response.json();
    const extractedInfo = JSON.parse(result.choices[0].message.content);

    console.log("✅ Medical information extracted successfully");

    return {
      transcription,
      medicalInfo: extractedInfo,
    };
  } catch (error) {
    console.error("Medical transcription error:", error);
    throw new Error(`Failed to process medical consultation: ${error.message}`);
  }
};
