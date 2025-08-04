const express = require("express");
const router = express.Router();
const { GoogleGenerativeAI } = require("@google/generative-ai");
require("dotenv").config();

if (!process.env.GEMINI_API_KEY) {
  console.error("❌ GEMINI_API_KEY is not set");
}

let genAI, model;
try {
  genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
  model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });
  console.log("✅ Gemini AI initialized successfully");
} catch (error) {
  console.error("❌ Failed to initialize Gemini AI:", error.message);
}

function buildPrompt(userInput) {
  return `
You are a friendly and helpful English tutor chatbot for students in classes 4 to 8. 
Your role is to assist students with English language learning only.
...
Student Question: ${userInput}
Provide a student-friendly answer:
`;
}

async function generateResponse(prompt) {
  try {
    const result = await model.generateContent(prompt);
    const text = result.response.candidates[0].content.parts[0].text || "";
    if (!text.trim()) throw new Error("Empty response from Gemini AI");
    return text;
  } catch (err) {
    console.error("❌ AI error:", err);
    throw new Error("AI model error: " + err.message);
  }
}

router.post("/chat", async (req, res) => {
  try {
    const { message } = req.body;
    if (!message || typeof message !== "string") {
      return res.status(400).json({ error: "Invalid message" });
    }
    const prompt = buildPrompt(message.trim());
    const aiResponse = await generateResponse(prompt);
    return res.json({ response: aiResponse });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

module.exports = router;
