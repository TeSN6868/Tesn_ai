const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
};

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (request.method === "OPTIONS") {
      return new Response(null, {
        status: 204,
        headers: corsHeaders,
      });
    }

    try {
      // HEALTH CHECK
      if (url.pathname === "/" && request.method === "GET") {
        return json({
          success: true,
          app: "M8 Messenger",
          status: "online",
          database: "M8 D1",
        });
      }

      // REGISTER
      if (url.pathname === "/api/register" && request.method === "POST") {
        const body = await request.json();

        const name = String(body.name || "").trim();
        const email = String(body.email || "").trim().toLowerCase();
        const phone = String(body.phone || "").trim();
        const identifier = String(
          body.identifier || body.email_or_phone || ""
        ).trim();

        const finalEmail = email || (identifier.includes("@") ? identifier.toLowerCase() : "");
        const finalPhone = phone || (identifier && !identifier.includes("@") ? identifier : "");

        const password = String(body.password || "");
        const confirmPassword = String(body.confirm_password || "");
        const m8Pin = String(body.m8_pin || body.pin || "").trim();

        if (!name || (!finalEmail && !finalPhone) || !password || !confirmPassword || !m8Pin) {
          return json({
            success: false,
            error: "Nama, email/nomor HP, password, konfirmasi password, dan PIN M8 wajib diisi.",
          }, 400);
        }

        if (password !== confirmPassword) {
          return json({
            success: false,
            error: "Konfirmasi password tidak cocok.",
          }, 400);
        }

        if (m8Pin.length < 4) {
          return json({
            success: false,
            error: "PIN M8 minimal 4 karakter.",
          }, 400);
        }

        if (!env.DB) {
          return json({
            success: false,
            error: "Binding D1 DB belum tersedia.",
          }, 500);
        }

        const existing = await env.DB.prepare(
          "SELECT id FROM users WHERE (email IS NOT NULL AND email = ?) OR (phone IS NOT NULL AND phone = ?) OR m8_pin = ? LIMIT 1"
        )
          .bind(finalEmail || "", finalPhone || "", m8Pin)
          .first();

        if (existing) {
          return json({
            success: false,
            error: "Email/nomor HP atau PIN M8 sudah terdaftar.",
          }, 409);
        }

        const passwordHash = await hashPassword(password);

        const result = await env.DB.prepare(
          `INSERT INTO users
           (m8_pin, name, email, phone, password_hash, created_at)
           VALUES (?, ?, ?, ?, ?, unixepoch())`
        )
          .bind(
            m8Pin,
            name,
            finalEmail || null,
            finalPhone || null,
            passwordHash
          )
          .run();

        if (!result.success) {
          throw new Error("Gagal menyimpan akun M8.");
        }

        return json({
          success: true,
          message: "Akun M8 berhasil dibuat.",
        }, 201);
      }

      // ============================================================
      // CHATS
      // ============================================================

      if (url.pathname === "/api/chats" && request.method === "GET") {
        const myPin = url.searchParams.get("m8_pin")?.trim();

        if (!myPin) {
          return json({
            success: false,
            error: "m8_pin wajib diisi."
          }, 400);
        }

        const result = await env.DB.prepare(`
          SELECT
            id,
            participant_1_pin,
            participant_2_pin,
            created_at
          FROM chats
          WHERE participant_1_pin = ? OR participant_2_pin = ?
          ORDER BY id DESC
        `)
          .bind(myPin, myPin)
          .all();

        return json({
          success: true,
          chats: result.results || []
        });
      }

      // ============================================================
      // CREATE CHAT
      // ============================================================

      if (url.pathname === "/api/chats" && request.method === "POST") {
        const body = await request.json();

        const myPin = String(body.my_pin || "").trim();
        const otherPin = String(body.other_pin || "").trim();

        if (!myPin || !otherPin) {
          return json({
            success: false,
            error: "my_pin dan other_pin wajib diisi."
          }, 400);
        }

        if (myPin === otherPin) {
          return json({
            success: false,
            error: "Tidak bisa membuat chat dengan PIN sendiri."
          }, 400);
        }

        const existing = await env.DB.prepare(`
          SELECT id, participant_1_pin, participant_2_pin, created_at
          FROM chats
          WHERE
            (participant_1_pin = ? AND participant_2_pin = ?)
            OR
            (participant_1_pin = ? AND participant_2_pin = ?)
          LIMIT 1
        `)
          .bind(myPin, otherPin, otherPin, myPin)
          .first();

        if (existing) {
          return json({
            success: true,
            chat: existing,
            existing: true
          });
        }

        const createdAt = Date.now();

        const result = await env.DB.prepare(`
          INSERT INTO chats
          (participant_1_pin, participant_2_pin, created_at)
          VALUES (?, ?, ?)
        `)
          .bind(myPin, otherPin, createdAt)
          .run();

        if (!result.success) {
          throw new Error("Gagal membuat chat.");
        }

        const chat = await env.DB.prepare(`
          SELECT id, participant_1_pin, participant_2_pin, created_at
          FROM chats
          WHERE id = ?
        `)
          .bind(result.meta.last_row_id)
          .first();

        return json({
          success: true,
          chat,
          existing: false
        }, 201);
      }

      // ============================================================
      // MESSAGES - GET
      // ============================================================

      if (url.pathname === "/api/messages" && request.method === "GET") {
        const chatId = Number(url.searchParams.get("chat_id"));

        if (!chatId) {
          return json({
            success: false,
            error: "chat_id wajib diisi."
          }, 400);
        }

        const result = await env.DB.prepare(`
          SELECT
            id,
            chat_id,
            sender_pin,
            message,
            timestamp,
            status
          FROM messages
          WHERE chat_id = ?
          ORDER BY id ASC
        `)
          .bind(chatId)
          .all();

        return json({
          success: true,
          messages: result.results || []
        });
      }

      // ============================================================
      // MESSAGES - SEND
      // ============================================================

      if (url.pathname === "/api/messages" && request.method === "POST") {
        const body = await request.json();

        const chatId = Number(body.chat_id);
        const senderPin = String(body.sender_pin || "").trim();
        const message = String(body.message || "").trim();

        if (!chatId || !senderPin || !message) {
          return json({
            success: false,
            error: "chat_id, sender_pin dan message wajib diisi."
          }, 400);
        }

        const chat = await env.DB.prepare(`
          SELECT
            id,
            participant_1_pin,
            participant_2_pin
          FROM chats
          WHERE id = ?
          LIMIT 1
        `)
          .bind(chatId)
          .first();

        if (!chat) {
          return json({
            success: false,
            error: "Chat tidak ditemukan."
          }, 404);
        }

        if (
          chat.participant_1_pin !== senderPin &&
          chat.participant_2_pin !== senderPin
        ) {
          return json({
            success: false,
            error: "Pengirim bukan anggota chat."
          }, 403);
        }

        const timestamp = Date.now();

        const result = await env.DB.prepare(`
          INSERT INTO messages
          (chat_id, sender_pin, message, timestamp, status)
          VALUES (?, ?, ?, ?, 'sent')
        `)
          .bind(chatId, senderPin, message, timestamp)
          .run();

        if (!result.success) {
          throw new Error("Gagal menyimpan pesan.");
        }

        const saved = await env.DB.prepare(`
          SELECT
            id,
            chat_id,
            sender_pin,
            message,
            timestamp,
            status
          FROM messages
          WHERE id = ?
        `)
          .bind(result.meta.last_row_id)
          .first();

        return json({
          success: true,
          message: saved
        }, 201);
      }

      // LOGIN
if (url.pathname === "/api/login" && request.method === "POST") {
      const body = await request.json();

      const identifier = String(
        body.identifier || body.email_or_phone || ""
      ).trim();

      const m8Pin = String(
        body.m8_pin || body.pin || ""
      ).trim();

      const password = String(body.password || "");

      if ((!identifier && !m8Pin) || !password) {
        return json({
          success: false,
          error: "Identitas/PIN dan password wajib diisi.",
        }, 400);
      }

      if (!env.DB) {
        return json({
          success: false,
          error: "Binding D1 DB belum tersedia.",
        }, 500);
      }

      let user;

      if (identifier) {
        user = await env.DB.prepare(`
          SELECT id, name, email, phone, m8_pin, password_hash
          FROM users
          WHERE email = ? OR phone = ?
          LIMIT 1
        `)
          .bind(identifier, identifier)
          .first();
      } else {
        user = await env.DB.prepare(`
          SELECT id, name, email, phone, m8_pin, password_hash
          FROM users
          WHERE m8_pin = ?
          LIMIT 1
        `)
          .bind(m8Pin)
          .first();
      }

      if (!user) {
        return json({
          success: false,
          error: "Identitas/PIN atau password salah.",
        }, 401);
      }

      const validPassword = await verifyPassword(
        password,
        user.password_hash
      );

      if (!validPassword) {
        return json({
          success: false,
          error: "Identitas/PIN atau password salah.",
        }, 401);
      }

      const token = await createToken();

      return json({
        success: true,
        token,
        user: {
          id: user.id,
          name: user.name,
          email: user.email,
          phone: user.phone,
          m8_pin: user.m8_pin,
        },
      });
    }

      return json({
        success: false,
        error: "Endpoint M8 tidak ditemukan.",
      }, 404);

    } catch (error) {
      return json({
        success: false,
        error: "M8 server error.",
        message: error instanceof Error
          ? error.message
          : String(error),
      }, 500);
    }
  },
};

async function hashPassword(password) {
  const iterations = 100000;
  const saltBytes = new Uint8Array(16);
  crypto.getRandomValues(saltBytes);

  let saltBinary = "";
  for (const byte of saltBytes) {
    saltBinary += String.fromCharCode(byte);
  }
  const salt = btoa(saltBinary);

  const passwordBytes = new TextEncoder().encode(password);
  const saltData = new TextEncoder().encode(salt);

  const keyMaterial = await crypto.subtle.importKey(
    "raw",
    passwordBytes,
    "PBKDF2",
    false,
    ["deriveBits"]
  );

  const derivedBits = await crypto.subtle.deriveBits(
    {
      name: "PBKDF2",
      salt: saltData,
      iterations: iterations,
      hash: "SHA-256",
    },
    keyMaterial,
    256
  );

  const derivedBytes = new Uint8Array(derivedBits);

  let binary = "";
  for (const byte of derivedBytes) {
    binary += String.fromCharCode(byte);
  }

  return `pbkdf2$${iterations}$${salt}$${btoa(binary)}`;
}

async function verifyPassword(password, stored) {
  if (!stored || !stored.startsWith("pbkdf2$")) {
    return false;
  }

  const parts = stored.split("$");

  if (parts.length !== 4) {
    return false;
  }

  const iterations = Number(parts[1]);
  const salt = parts[2];
  const expectedBase64 = parts[3];

  if (!Number.isInteger(iterations) || !salt || !expectedBase64) {
    return false;
  }

  const passwordBytes = new TextEncoder().encode(password);
  const saltBytes = new TextEncoder().encode(salt);

  const keyMaterial = await crypto.subtle.importKey(
    "raw",
    passwordBytes,
    "PBKDF2",
    false,
    ["deriveBits"]
  );

  const derivedBits = await crypto.subtle.deriveBits(
    {
      name: "PBKDF2",
      salt: saltBytes,
      iterations: iterations,
      hash: "SHA-256",
    },
    keyMaterial,
    256
  );

  const derivedBytes = new Uint8Array(derivedBits);

  let binary = "";

  for (const byte of derivedBytes) {
    binary += String.fromCharCode(byte);
  }

  return btoa(binary) === expectedBase64;
}

async function sha256(text) {
  const data = new TextEncoder().encode(text);
  const hash = await crypto.subtle.digest("SHA-256", data);

  return [...new Uint8Array(hash)]
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

async function createToken() {
  const bytes = new Uint8Array(32);
  crypto.getRandomValues(bytes);

  return [...bytes]
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

function json(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json; charset=UTF-8",
    },
  });
}
