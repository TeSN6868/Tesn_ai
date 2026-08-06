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
      // =========================
      // HEALTH CHECK
      // =========================
      if (url.pathname === "/" && request.method === "GET") {
        return json({
          success: true,
          app: "M8 Messenger",
          status: "online",
        });
      }

      // =========================
      // REGISTER
      // =========================
      if (url.pathname === "/api/register" && request.method === "POST") {
        const body = await request.json();

        const name = String(body.name || "").trim();
        const email = String(body.email || "").trim().toLowerCase();
        const phone = String(body.phone || "").trim();
        const password = String(body.password || "");
        const confirmPassword = String(
          body.confirm_password || body.confirmPassword || ""
        );
        const m8Pin = String(body.m8_pin || "").trim();

        if (!name || !email || !phone || !password || !m8Pin) {
          return json({
            success: false,
            error: "Nama, email, nomor HP, password, dan PIN M8 wajib diisi.",
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
            error: "Database M8 belum terhubung.",
          }, 500);
        }

        const existing = await env.DB.prepare(
          `SELECT id
           FROM users
           WHERE email = ? OR phone = ? OR m8_pin = ?
           LIMIT 1`
        )
          .bind(email, phone, m8Pin)
          .first();

        if (existing) {
          return json({
            success: false,
            error: "Email, nomor HP, atau PIN M8 sudah terdaftar.",
          }, 409);
        }

        const passwordHash = await hashPassword(password);

        const result = await env.DB.prepare(
          `INSERT INTO users
           (m8_pin, name, email, phone, password_hash, created_at)
           VALUES (?, ?, ?, ?, ?, ?)`
        )
          .bind(
            m8Pin,
            name,
            email,
            phone,
            passwordHash,
            Date.now()
          )
          .run();

        if (!result.success) {
          throw new Error("Gagal membuat akun M8.");
        }

        return json({
          success: true,
          message: "Akun M8 berhasil dibuat.",
        }, 201);
      }

      // =========================
      // LOGIN
      // =========================
      if (url.pathname === "/api/login" && request.method === "POST") {
        const body = await request.json();

        const login = String(
          body.email || body.phone || body.identifier || ""
        ).trim().toLowerCase();

        const m8Pin = String(body.m8_pin || "").trim();
        const password = String(body.password || "");

        if (!login || !password) {
          return json({
            success: false,
            error: "Email/nomor HP dan password wajib diisi.",
          }, 400);
        }

        const user = await env.DB.prepare(
          `SELECT id, m8_pin, name, email, phone, password_hash
           FROM users
           WHERE (LOWER(email) = ? OR phone = ?)
           LIMIT 1`
        )
          .bind(login, login)
          .first();

        if (!user) {
          return json({
            success: false,
            error: "Akun M8 tidak ditemukan.",
          }, 401);
        }

        // Jika PIN diberikan, pastikan cocok.
        if (m8Pin && user.m8_pin !== m8Pin) {
          return json({
            success: false,
            error: "PIN M8 salah.",
          }, 401);
        }

        const valid = await verifyPassword(
          password,
          user.password_hash
        );

        if (!valid) {
          return json({
            success: false,
            error: "Password salah.",
          }, 401);
        }

        const token = await createToken();

        return json({
          success: true,
          token,
          user: {
            id: user.id,
            m8_pin: user.m8_pin,
            name: user.name,
            email: user.email,
            phone: user.phone,
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


// ============================================================
// PASSWORD
// ============================================================

async function hashPassword(password) {
  const salt = crypto.randomUUID();

  const iterations = 100000;

  const keyMaterial = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(password),
    "PBKDF2",
    false,
    ["deriveBits"]
  );

  const bits = await crypto.subtle.deriveBits(
    {
      name: "PBKDF2",
      salt: new TextEncoder().encode(salt),
      iterations,
      hash: "SHA-256",
    },
    keyMaterial,
    256
  );

  const hash = bytesToBase64(new Uint8Array(bits));

  return `pbkdf2$${iterations}$${salt}$${hash}`;
}

async function verifyPassword(password, stored) {
  if (!stored) return false;

  // Akun lama TEST0001.
  // Jangan izinkan TEST_HASH sebagai password nyata.
  if (stored === "TEST_HASH") {
    return false;
  }

  const parts = stored.split("$");

  if (parts.length !== 4 || parts[0] !== "pbkdf2") {
    return false;
  }

  const iterations = Number(parts[1]);
  const salt = parts[2];
  const expected = parts[3];

  if (!iterations || !salt || !expected) {
    return false;
  }

  const keyMaterial = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(password),
    "PBKDF2",
    false,
    ["deriveBits"]
  );

  const bits = await crypto.subtle.deriveBits(
    {
      name: "PBKDF2",
      salt: new TextEncoder().encode(salt),
      iterations,
      hash: "SHA-256",
    },
    keyMaterial,
    256
  );

  const actual = bytesToBase64(new Uint8Array(bits));

  return actual === expected;
}


// ============================================================
// TOKEN
// ============================================================

async function createToken() {
  const bytes = new Uint8Array(32);
  crypto.getRandomValues(bytes);

  return bytesToHex(bytes);
}


// ============================================================
// HELPERS
// ============================================================

function bytesToBase64(bytes) {
  let binary = "";

  for (const byte of bytes) {
    binary += String.fromCharCode(byte);
  }

  return btoa(binary);
}

function bytesToHex(bytes) {
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
