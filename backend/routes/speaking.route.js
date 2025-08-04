const express = require("express");
const fileUpload = require("express-fileupload");
const Groq = require("groq-sdk");

const router = express.Router();
const groq = new Groq({ apiKey: process.env.GROQ_API_KEY });

let conversationHistory = [
  { role: "system", content: "You are a friendly English speaking tutor." }
];

const asyncHandler = (fn) => (req, res, next) =>
  Promise.resolve(fn(req, res, next)).catch(next);

// ---- Helper: TTS ----
async function generateTTS(text) {
  const audio = await groq.audio.speech.create({
    model: "playai-tts",
    input: text,
    voice: "Fritz-PlayAI",
    response_format: "wav"
  });
  const buffer = Buffer.from(await audio.arrayBuffer());
  return `data:audio/wav;base64,${buffer.toString("base64")}`;
}

// ---- Helper: Pronunciation Feedback ----
function getPronunciationFeedback(userText, referenceText) {
  // naive comparison: look for word mismatches
  const userWords = userText.toLowerCase().split(/\s+/);
  const refWords = referenceText.toLowerCase().split(/\s+/);
  const mistakes = [];

  refWords.forEach((word, idx) => {
    if (userWords[idx] && userWords[idx] !== word) {
      mistakes.push({ expected: word, said: userWords[idx] });
    }
  });

  if (mistakes.length === 0) {
    return "Good pronunciation!";
  }

  const feedbackParts = mistakes.map(
    (m) => `You pronounced "${m.said}" instead of "${m.expected}".`
  );
  return feedbackParts.join(" ") + " Let's say it again correctly.";
}

// ---- Start Conversation ----
router.get("/start", asyncHandler(async (req, res) => {
  const initPrompt = [
    ...conversationHistory,
    { role: "user", content: "Please greet me and ask me a question." }
  ];

  const llmResponse = await groq.chat.completions.create({
    model: "llama-3.3-70b-versatile",
    messages: initPrompt,
    temperature: 0.7,
    max_tokens: 100
  });

  const botText = llmResponse.choices[0].message.content;
  conversationHistory.push({ role: "assistant", content: botText });

  const audioBase64 = await generateTTS(botText);
  res.json({ text: botText, audioBase64, success: true });
}));

// ---- Process User Speech ----
router.post("/process-speech", fileUpload(), asyncHandler(async (req, res) => {
  if (!req.files || !req.files.audio) {
    return res.status(400).json({ error: "No audio uploaded", success: false });
  }

  const audioFile = req.files.audio;
  const transcription = await groq.audio.transcriptions.create({
    file: audioFile.data,
    model: "whisper-large-v3",
    language: "en"
  });

  const userText = transcription.text || "";
  conversationHistory.push({ role: "user", content: userText });

  // Pronunciation feedback based on previous question (last assistant text)
  const lastQuestion = conversationHistory
    .slice()
    .reverse()
    .find((msg) => msg.role === "assistant")?.content || "";

  const feedback = getPronunciationFeedback(userText, lastQuestion);
  const feedbackAudio = await generateTTS(feedback);

  // Get next question from LLM
  const llmResponse = await groq.chat.completions.create({
    model: "llama-3.3-70b-versatile",
    messages: conversationHistory,
    temperature: 0.7,
    max_tokens: 150
  });

  const nextQuestion = llmResponse.choices[0].message.content;
  conversationHistory.push({ role: "assistant", content: nextQuestion });
  const nextAudio = await generateTTS(nextQuestion);

  res.json({
    userText,
    feedback,
    feedbackAudio,
    nextQuestion,
    nextAudio,
    success: true
  });
}));

router.post("/end", (req, res) => {
  conversationHistory = [
    { role: "system", content: "You are a friendly English speaking tutor." }
  ];
  res.json({ success: true, message: "Conversation ended" });
});

module.exports = router;
