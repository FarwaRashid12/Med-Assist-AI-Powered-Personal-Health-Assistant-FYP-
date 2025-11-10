import OpenAI from "openai";
import { OPENAI_API_KEY } from "../context/env";
import * as FileSystem from "expo-file-system/legacy";

const client = new OpenAI({ apiKey: OPENAI_API_KEY });

export const validatePrescription = async (imageUri) => {
  try {
    const base64 = await FileSystem.readAsStringAsync(imageUri, {
      encoding: 'base64',
    });

    const validationPrompt = `
You are a medical document validator. Analyze this image and determine if it is a valid medical prescription.

A valid prescription should contain:
- Doctor's name, signature, or clinic/hospital name
- Patient information (name, age, or patient ID)
- Medicine names with dosages
- Instructions for taking medicines (timing, frequency, duration)
- Date of prescription
- Medical terminology related to medications

The image can be in English or Urdu language.

Return ONLY a valid JSON object with this EXACT structure:
{
  "isPrescription": true or false,
  "confidence": "high" or "medium" or "low",
  "reason": "brief explanation why it is or isn't a prescription"
}

If the image is NOT a prescription (e.g., random photo, document, text, or unrelated image), set isPrescription to false.
If the image IS a prescription, set isPrescription to true.
`;

    const response = await client.chat.completions.create({
      model: "gpt-4o",
      messages: [
        {
          role: "user",
          content: [
            {
              type: "text",
              text: validationPrompt,
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
      temperature: 0.1,
      response_format: { type: "json_object" },
      max_tokens: 500,
    });

    const raw = response.choices[0].message.content.trim();
    
    const cleanedRaw = raw.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim();
    
    const parsed = JSON.parse(cleanedRaw);
    
    return {
      isPrescription: parsed.isPrescription === true,
      confidence: parsed.confidence || "medium",
      reason: parsed.reason || "Validation completed",
    };
  } catch (error) {
    console.error("Prescription validation error:", error);
    return {
      isPrescription: false,
      confidence: "low",
      reason: "Unable to validate image. Please ensure it's a clear prescription image.",
    };
  }
};
