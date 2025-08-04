// server.js or routes/user.js
const express = require("express");
const router = express.Router();
const User = require("../models/user.model");

// GET user profile by ID
router.get("/:userId/profile", async (req, res) => {
  try {
    const { userId } = req.params;

    const user = await User.findById(userId).lean();

    if (!user) {
      return res.status(404).json({ error: "User not found" });
    }

    // Format data as expected by Flutter
    const profileData = {
      name: user.name,
      class: user.class || "",
      gender: user.gender || "",
      school: user.school || "",
      address: user.address || "",
      currentStreak: user.currentStreak || 0,
      currentLevel: user.currentLevel || "Basic",
      completedLessons: user.completedLessons.map((lesson) => ({
        lessonId: lesson.lessonId,
      })),
      assessmentScores: {
        ...user.assessmentScores,
        overall: user.assessmentScores?.overall || 0,
      },
    };

    res.json(profileData);
  } catch (error) {
    console.error("Error fetching user profile:", error);
    res.status(500).json({ error: "Internal Server Error" });
  }
});

router.post("/:userId/mark-complete", async (req, res) => {
  try {
    const { userId } = req.params;
    const { lessonId, score = 0 } = req.body;

    if (!lessonId) {
      return res.status(400).json({ error: "lessonId is required" });
    }

    const user = await User.findById(userId);
    if (!user) return res.status(404).json({ error: "User not found" });

    // Avoid duplicate entries
    const alreadyExists = user.completedLessons.some(
      (lesson) => lesson.lessonId === lessonId
    );

    if (!alreadyExists) {
      user.completedLessons.push({ lessonId, score });
      await user.save();
    }

    res.json({ message: "Lesson marked as completed" });
  } catch (error) {
    console.error("Error marking lesson complete:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

router.post("/:userId/submit-assessment", async (req, res) => {
  const { userId } = req.params;

  // Validate req.body exists
  if (!req.body) {
    return res.status(400).json({ message: "Missing request body" });
  }

  const { quizScore, readingScore, listeningScore, overallScore } = req.body;

  try {
    const user = await User.findById(userId);
    if (!user) return res.status(404).json({ message: "User not found" });

    // Initialize assessmentScores if undefined
    if (!user.assessmentScores) {
      user.assessmentScores = {};
    }

    // Assign scores
    user.assessmentScores.quiz = quizScore;
    user.assessmentScores.reading = readingScore;
    user.assessmentScores.listening = listeningScore;
    user.assessmentScores.overall = overallScore;

    await user.save();

    res.status(200).json({ message: "Assessment submitted successfully" });
  } catch (error) {
    console.error("Error submitting assessment:", error);
    res.status(500).json({ message: "Internal server error" });
  }
});

module.exports = router;
