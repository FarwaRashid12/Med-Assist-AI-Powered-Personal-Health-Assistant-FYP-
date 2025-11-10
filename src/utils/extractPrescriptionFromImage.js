import OpenAI from "openai";
import { OPENAI_API_KEY } from "../context/env";
import * as FileSystem from "expo-file-system/legacy";

const client = new OpenAI({ apiKey: OPENAI_API_KEY });

const normalizeMedicineData = (medicine) => {
  return {
    name: medicine.name || null,
    dosage: medicine.dosage || null,
    timing: medicine.timing || null,
    frequency: medicine.frequency || medicine.timing || null,
    duration: medicine.duration || null,
    instructions: medicine.instructions || medicine.instruction || null,
    time: medicine.time || medicine.timing || null,
  };
};

export const extractPrescriptionFromImage = async (imageUri) => {
  try {
    const base64 = await FileSystem.readAsStringAsync(imageUri, {
      encoding: 'base64',
    });

    const prompt = `
You are a medical text extractor for prescriptions written in English or Urdu (اردو).
Analyze this prescription image and extract key details.

IMPORTANT RULES:
1. Return ONLY valid JSON (no markdown, no code blocks, no extra text)
2. If a field is missing or cannot be found, use null (not empty string, not undefined)
3. Extract all medicines mentioned in the prescription
4. Support both English and Urdu text - extract text in the original language
5. For timing: extract specific times (e.g., "8 AM", "9 PM", "after breakfast", "before sleep", "صبح", "شام")
6. For frequency: extract how often (e.g., "twice daily", "once a day", "every 8 hours", "دن میں دو بار", "روزانہ")
7. For duration: extract how long to take (e.g., "7 days", "2 weeks", "until finished", "سات دن", "دو ہفتے")
8. Preserve Urdu text as-is when extracting medicine names and instructions

Return this EXACT structure:
{
  "doctor_name": "string or null",
  "medicines": [
    {
      "name": "string or null",
      "dosage": "string or null",
      "timing": "string or null",
      "frequency": "string or null",
      "duration": "string or null",
      "instructions": "string or null",
      "time": "string or null"
    }
  ]
}
`;

    const response = await client.chat.completions.create({
      model: "gpt-4o",
      messages: [
        {
          role: "user",
          content: [
            {
              type: "text",
              text: prompt,
            },
            {
              type: "image_url",
              image_url: {
                url: `data:image/jpeg;base64,${base64}`,
              },
            },
          ],
        },
      ],
      temperature: 0.2,
      response_format: { type: "json_object" },
      max_tokens: 2000,
    });

    const raw = response.choices[0].message.content.trim();
    
    const cleanedRaw = raw.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim();
    
    const parsed = JSON.parse(cleanedRaw);
    
    const normalized = {
      doctor_name: parsed.doctor_name || null,
      medicines: (parsed.medicines || []).map(normalizeMedicineData),
    };
    
    return normalized;
  } catch (error) {
    console.error("OpenAI Vision extraction error:", error);
    throw new Error(`Failed to extract prescription from image: ${error.message}`);
  }
};
