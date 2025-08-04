const express = require("express");
const router = express.Router();
const jwt = require("jsonwebtoken");
const User = require("../models/user.model");

const JWT_SECRET = process.env.JWT_SECRET || "your_jwt_secret";

// ✅ Signup Route (no hashing)
router.post("/signup", async (req, res) => {
  try {
    const {
      name,
      email,
      password,
      class: userClass,
      gender,
      school,
      address,
    } = req.body;

    const existingUser = await User.findOne({ email });
    if (existingUser)
      return res.status(400).json({ message: "Email already registered." });

    const user = new User({
      name,
      email,
      password,
      class: userClass,
      gender,
      school,
      address,
      assessmentScores: {
        quiz: 0,
        reading: 0,
        listening: 0,
        overall: 0,
      },
    });

    await user.save();
    res
      .status(201)
      .json({ message: "User registered successfully.", userId: user._id });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Login route
router.post("/login", async (req, res) => {
  try {
    const { email, password } = req.body;

    // Find user
    const user = await User.findOne({ email });
    if (!user || user.password !== password) {
      return res.status(400).json({ message: "Invalid email or password." });
    }

    // Streak calculation
    const today = new Date();
    const lastLogin = user.lastLogin;

    if (lastLogin) {
      const last = new Date(lastLogin);
      const diffTime = today.setHours(0, 0, 0, 0) - last.setHours(0, 0, 0, 0);
      const diffDays = diffTime / (1000 * 60 * 60 * 24);

      if (diffDays === 1) {
        user.currentStreak += 1; // ✅ yesterday
      } else if (diffDays > 1) {
        user.currentStreak = 1; // ✅ missed a day
      } // else: same day → do nothing
    } else {
      user.currentStreak = 1; // ✅ first login
    }

    // Update lastLogin
    user.lastLogin = new Date();
    await user.save();

    // Generate JWT token
    const token = jwt.sign(
      { userId: user._id, email: user.email },
      JWT_SECRET,
      { expiresIn: "7d" }
    );

    res.status(200).json({
      token,
      user: {
        userId: user._id,
        name: user.name,
        email: user.email,
        currentLevel: user.currentLevel,
        currentStreak: user.currentStreak,
      },
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;

module.exports = router;
