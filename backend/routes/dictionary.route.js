const express = require("express");
const cors = require("cors");
const router = express.Router();
const { GoogleGenerativeAI } = require("@google/generative-ai");
require("dotenv").config();

// Initialize Google AI
const genAI = new GoogleGenerativeAI(process.env.GOOGLE_API_KEY);

// Utility to extract clean JSON from Gemini response
function extractJsonFromMarkdown(text) {
  const match = text.match(/```json\s*([\s\S]*?)\s*```/i);
  return match ? match[1].trim() : text.trim();
}

// Dictionary lookup endpoint
router.post("/api/dictionary", async (req, res) => {
  try {
    const { word } = req.body;

    if (!word) {
      return res.status(400).json({ error: "Word is required" });
    }

    const prompt = `You are a dictionary assistant. When I give you a word, you must respond ONLY in this exact JSON format:

{
  "word": "<word>",
  "phonetic": "<phonetic representation of the word, e.g., /ˈwɜːd/>",
  "definition": "<short definition in English>",
  "example": "<example sentence>",
  "telugu": "<telugu translation>",
  "hindi": "<hindi translation>",
  "type": "<part of speech>",
  "example_sentence_usage": "<example sentence usage>",
  "example_sentence_translation": "<example sentence translation in Telugu>"
}


Don't add any extra explanation or text. If the word is not found or invalid, respond with: {"error": "Word not found"}

Now, give me the dictionary entry for the word: "${word}"`;

    const model = genAI.getGenerativeModel({ model: "gemini-2.5-flash" });
    const result = await model.generateContent(prompt);
    const response = result.response;
    const rawText = response.text();

    const cleanJsonText = extractJsonFromMarkdown(rawText);

    try {
      const dictionaryData = JSON.parse(cleanJsonText);
      res.json(dictionaryData);
    } catch (parseError) {
      console.error("JSON parsing error:", parseError);
      console.error("Gemini raw response:\n", rawText);
      res.status(500).json({ error: "Failed to parse dictionary response" });
    }
  } catch (error) {
    console.error("Error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

module.exports = router;
