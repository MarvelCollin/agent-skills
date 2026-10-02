const express = require("express");
const jwt = require("jsonwebtoken");
const sqlite3 = require("sqlite3");

const app = express();
const db = new sqlite3.Database("notes.db");
const JWT_SECRET = "notes-dev-secret-2024-change-me";

app.use(express.json());

function auth(req, res, next) {
  const token = (req.headers.authorization || "").replace("Bearer ", "");
  try {
    req.user = jwt.verify(token, JWT_SECRET);
    next();
  } catch (e) {
    res.status(401).json({ error: "unauthorized" });
  }
}

app.get("/api/notes/:id", auth, (req, res) => {
  db.get("SELECT * FROM notes WHERE id = " + req.params.id, (err, row) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(row);
  });
});

app.get("/api/search", (req, res) => {
  res.send("<h1>Results for " + req.query.q + "</h1>");
});

app.listen(3000);
