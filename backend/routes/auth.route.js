const express = require("express");
const router = express.Router();
const jwt = require("jsonwebtoken");
const User = require("../models/user.model");
const nodemailer = require("nodemailer");
const crypto = require("crypto");

const JWT_SECRET = process.env.JWT_SECRET || "your_jwt_secret";
const otpStore = new Map(); // Temporary store

function generateOTP() {
  return crypto.randomInt(100000, 999999).toString();
}

async function sendOTP(email, otp) {
  const transporter = nodemailer.createTransport({
    service: "gmail",
    auth: {
      user: "kskill2025@gmail.com",
      pass: "gaqk urkk ubxo rkvt " // Use Gmail App Password
    }
  });

  await transporter.sendMail({
    from: "kskill2025@gmail.com",
    to: email,
    subject: "OTP for K-Skill verification",
    text: `Your OTP code is ${otp}. It is valid for 5 minutes.`
  });
}

router.post("/send-otp", async (req, res) => {
  const { email } = req.body;
  const otp = generateOTP();
  otpStore.set(email, { otp, expires: Date.now() + 5 * 60 * 1000 });
  await sendOTP(email, otp);
  res.json({ message: "OTP sent successfully" });
});

router.post("/verify-otp", (req, res) => {
  const { email, otp } = req.body;
  const record = otpStore.get(email);
  if (!record || Date.now() > record.expires || record.otp !== otp) {
    return res.status(400).json({ success: false, message: "Invalid or expired OTP" });
  }
  otpStore.delete(email);
  res.json({ success: true, message: "Email verified" });
});

router.post('/reset-password', async (req, res) => {
  const { email, newPassword } = req.body;

  await User.findOneAndUpdate({ email }, {
    password: newPassword,
    otp: null,
    otpExpires: null
  });

  res.status(200).json({ message: 'Password updated successfully' });
});


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
