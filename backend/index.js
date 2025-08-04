require("dotenv").config({ path: "./.env" });
const express = require("express");
const mongoose = require("mongoose");
const cors = require("cors");
const app = express();
const PORT = process.env.PORT || 8080;

// Middlewares
const corsOptions = {
  origin: ['http://localhost:52606','https://k-skill-5agsv8g2i-gsrivanis-projects.vercel.app'],
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true
};
app.use(cors());
app.use(express.json());

// Define routes BEFORE starting server
const authRoutes = require("./routes/auth.route");
app.use("/api/auth", authRoutes);

const profileRoutes = require("./routes/profile.route");
app.use("/", profileRoutes);

const dictionaryRoutes = require("./routes/dictionary.route");
app.use("/", dictionaryRoutes);

const chatbotRouter = require("./routes/chat.route");
app.use("/", chatbotRouter);

// Example Route
app.get("/", (req, res) => {
  res.send("API is working");
});

// Start Server
console.log("MongoDB URI:", process.env.MONGO_URI); // Fixed variable name
mongoose
  .connect(process.env.MONGO_URI)
  .then(() => {
    console.log("MongoDB connected");
    app.listen(PORT, '0.0.0.0', () => {
      console.log(`Server is running on port ${PORT}`);
    });
  })
  .catch((err) => console.error(err));