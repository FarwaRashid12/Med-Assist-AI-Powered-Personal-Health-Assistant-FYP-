import OpenAI from "openai";
import { OPENAI_API_KEY } from "../context/env";
import * as FileSystem from "expo-file-system/legacy";

const client = new OpenAI({ apiKey: OPENAI_API_KEY });

export const extractTextFromImage = async (imageUri) => {
  try {
    const base64 = await FileSystem.readAsStringAsync(imageUri, {
      encoding: 'base64',
    });

    const response = await client.chat.completions.create({
      model: "gpt-4o",
      messages: [
        {
          role: "user",
          content: [
            {
              type: "text",
              text: "Extract all text from this prescription image. The prescription may be in English or Urdu (اردو). Return only the raw text content in the original language without any formatting or explanations. Preserve Urdu text as-is.",
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
      max_tokens: 1000,
    });

    const extractedText = response.choices[0].message.content.trim();
    return extractedText;
  } catch (error) {
    console.error("OpenAI Vision OCR Error:", error);
    throw new Error(`Failed to extract text from image: ${error.message}`);
  }
};
