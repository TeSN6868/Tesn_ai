const express = require('express');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

app.get('/', (req, res) => {
  res.json({
    app: 'TeSN AI',
    status: 'online',
    message: 'Backend TeSN AI aktif'
  });
});

app.post('/chat', (req, res) => {
  const message = req.body?.message?.trim();

  if (!message) {
    return res.status(400).json({
      error: 'Pesan tidak boleh kosong'
    });
  }

  res.json({
    reply: `TeSN AI menerima pesan: ${message}`
  });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`TeSN AI backend berjalan di port ${PORT}`);
});
