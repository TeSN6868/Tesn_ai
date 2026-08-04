require('dotenv').config({ override: true });

const express = require('express');
const cors = require('cors');
const { GoogleGenAI } = require('@google/genai');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

if (!process.env.GEMINI_API_KEY) {
  console.error('GEMINI_API_KEY belum ditemukan di .env');
  process.exit(1);
}

const ai = new GoogleGenAI({
  apiKey: process.env.GEMINI_API_KEY,
});

app.get('/', (req, res) => {
  res.json({
    app: 'TeSN AI',
    status: 'online',
    ai: 'Gemini',
  });
});

app.post('/chat', async (req, res) => {
  const message = req.body?.message?.trim();

  if (!message) {
    return res.status(400).json({
      error: 'Pesan tidak boleh kosong',
    });
  }

  try {
    const response = await ai.models.generateContent({
      model: 'gemini-3.5-flash',
      contents: message,
    });

    res.json({
      reply: response.text || 'Gemini tidak memberikan jawaban.',
    });
  } catch (error) {
    console.error('GEMINI ERROR:', error);

    res.status(500).json({
      error: error.message || 'Gagal mendapatkan jawaban dari Gemini.',
    });
  }
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`TeSN AI backend berjalan di port ${PORT}`);
});
