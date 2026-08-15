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
      // ============================================================
      // M8 R2 MEDIA UPLOAD
      // ============================================================
      if (url.pathname === "/api/upload" && request.method === "POST") {
        if (!env.MEDIA) {
          return json({
            success: false,
            error: "Binding R2 MEDIA belum tersedia.",
          }, 500);
        }

        const contentType =
          request.headers.get("content-type") || "";

        if (!contentType.startsWith("image/")) {
          return json({
            success: false,
            error: "File harus berupa gambar.",
          }, 400);
        }

        const contentLength =
          Number(request.headers.get("content-length") || 0);

        if (contentLength > 5 * 1024 * 1024) {
          return json({
            success: false,
            error: "Ukuran foto maksimal 5 MB.",
          }, 413);
        }

        const body = await request.arrayBuffer();

        if (!body || body.byteLength === 0) {
          return json({
            success: false,
            error: "File gambar kosong.",
          }, 400);
        }

        if (body.byteLength > 5 * 1024 * 1024) {
          return json({
            success: false,
            error: "Ukuran foto maksimal 5 MB.",
          }, 413);
        }

        const ext = contentType === "image/png"
          ? "png"
          : contentType === "image/webp"
              ? "webp"
              : contentType === "image/gif"
                  ? "gif"
                  : "jpg";

        const key =
          `messages/${Date.now()}-${crypto.randomUUID()}.${ext}`;

        await env.MEDIA.put(key, body, {
          httpMetadata: {
            contentType,
            cacheControl: "public, max-age=31536000, immutable",
          },
        });

        return json({
          success: true,
          key,
          url: `${url.origin}/api/media/${key}`,
        }, 201);
      }

      // ============================================================
      // M8 R2 MEDIA GET
      // ============================================================
      if (
        url.pathname.startsWith("/api/media/") &&
        request.method === "GET"
      ) {
        if (!env.MEDIA) {
          return json({
            success: false,
            error: "Binding R2 MEDIA belum tersedia.",
          }, 500);
        }

        const key = decodeURIComponent(
          url.pathname.substring("/api/media/".length)
        );

        if (!key || key.includes("..")) {
          return json({
            success: false,
            error: "Media tidak valid.",
          }, 400);
        }

        const object = await env.MEDIA.get(key);

        if (!object) {
          return json({
            success: false,
            error: "Foto tidak ditemukan.",
          }, 404);
        }

        const headers = new Headers(corsHeaders);
        object.writeHttpMetadata(headers);
        headers.set("etag", object.httpEtag);
        headers.set(
          "Cache-Control",
          "public, max-age=31536000, immutable"
        );

        return new Response(object.body, {
          headers,
        });
      }

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

        // ============================================================
        // M8 PIN RULES
        // Owner PIN khusus: M8000001
        // User PIN: tepat 8 karakter, huruf kecil + angka
        // ============================================================

        const OWNER_PIN = "M8000001";

        if (m8Pin === OWNER_PIN) {
          return json({
            success: false,
            error: "PIN Owner M8 adalah PIN khusus dan tidak dapat digunakan untuk registrasi pengguna.",
          }, 403);
        }

        if (!/^(?=.*[a-z])(?=.*[0-9])[a-z0-9]{8}$/.test(m8Pin)) {
          return json({
            success: false,
            error: "PIN M8 harus tepat 8 karakter dan terdiri dari huruf kecil serta angka.",
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

      // ============================================================
      // ============================================================
      // MESSAGES - EDIT
      // ============================================================

      if (
        url.pathname === "/api/messages/edit" &&
        request.method === "POST"
      ) {
        const body = await request.json();

        const messageId = Number(body.message_id);
        const senderPin = String(body.sender_pin || "").trim();
        const message = String(body.message || "").trim();

        if (!messageId || !senderPin || !message) {
          return json({
            success: false,
            error: "message_id, sender_pin dan message wajib diisi."
          }, 400);
        }

        const existing = await env.DB.prepare(`
          SELECT
            id,
            chat_id,
            sender_pin,
            message,
            timestamp,
            status
          FROM messages
          WHERE id = ?
          LIMIT 1
        `)
          .bind(messageId)
          .first();

        if (!existing) {
          return json({
            success: false,
            error: "Pesan tidak ditemukan."
          }, 404);
        }

        if (existing.sender_pin !== senderPin) {
          return json({
            success: false,
            error: "Kamu hanya dapat mengedit pesan milik sendiri."
          }, 403);
        }

        await env.DB.prepare(`
          UPDATE messages
          SET message = ?
          WHERE id = ?
            AND sender_pin = ?
        `)
          .bind(message, messageId, senderPin)
          .run();

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
          LIMIT 1
        `)
          .bind(messageId)
          .first();

        return json({
          success: true,
          message: saved
        });
      }

      // ============================================================
      // MESSAGES - DELIVERED
      // ============================================================
      if (url.pathname === "/api/messages/delivered" && request.method === "POST") {
        const body = await request.json();

        const chatId = Number(body.chat_id);
        const receiverPin = String(body.receiver_pin || "").trim();

        if (!chatId || !receiverPin) {
          return json({
            success: false,
            error: "chat_id dan receiver_pin wajib diisi."
          }, 400);
        }

        const chat = await env.DB.prepare(`
          SELECT id, participant_1_pin, participant_2_pin
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
          chat.participant_1_pin !== receiverPin &&
          chat.participant_2_pin !== receiverPin
        ) {
          return json({
            success: false,
            error: "Penerima bukan anggota chat."
          }, 403);
        }

        const result = await env.DB.prepare(`
          UPDATE messages
          SET status = 'delivered'
          WHERE chat_id = ?
            AND sender_pin != ?
            AND status = 'sent'
        `)
          .bind(chatId, receiverPin)
          .run();

        return json({
          success: true,
          updated: result.meta?.changes || 0
        });
      }

      // MESSAGES - READ
      // ============================================================
      if (url.pathname === "/api/messages/read" && request.method === "POST") {
        const body = await request.json();

        const chatId = Number(body.chat_id);
        const readerPin = String(body.reader_pin || "").trim();

        if (!chatId || !readerPin) {
          return json({
            success: false,
            error: "chat_id dan reader_pin wajib diisi."
          }, 400);
        }

        const chat = await env.DB.prepare(`
          SELECT id, participant_1_pin, participant_2_pin
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
          chat.participant_1_pin !== readerPin &&
          chat.participant_2_pin !== readerPin
        ) {
          return json({
            success: false,
            error: "Pembaca bukan anggota chat."
          }, 403);
        }

        const result = await env.DB.prepare(`
          UPDATE messages
          SET status = 'read'
          WHERE chat_id = ?
            AND sender_pin != ?
            AND status != 'read'
        `)
          .bind(chatId, readerPin)
          .run();

        return json({
          success: true,
          updated: result.meta?.changes || 0
        });
      }

  
    // ============================================================

    // ============================================================
    // TYPING INDICATOR
    // ============================================================

    await env.DB.prepare(`
      CREATE TABLE IF NOT EXISTS typing_states (
        chat_id INTEGER NOT NULL,
        user_pin TEXT NOT NULL,
        updated_at INTEGER NOT NULL,
        PRIMARY KEY (chat_id, user_pin)
      )
    `).run();

    // SET TYPING
    if (
      url.pathname === "/api/typing" &&
      request.method === "POST"
    ) {
      const body = await request.json();

      const chatId = Number(body.chat_id);
      const userPin = String(body.user_pin || "").trim();
      const typing = body.typing === true;

      if (!chatId || !userPin) {
        return json({
          success: false,
          error: "chat_id dan user_pin wajib diisi."
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
        chat.participant_1_pin !== userPin &&
        chat.participant_2_pin !== userPin
      ) {
        return json({
          success: false,
          error: "Pengguna bukan anggota chat."
        }, 403);
      }

      if (!typing) {
        await env.DB.prepare(`
          DELETE FROM typing_states
          WHERE chat_id = ?
            AND user_pin = ?
        `)
          .bind(chatId, userPin)
          .run();

        return json({
          success: true,
          typing: false
        });
      }

      await env.DB.prepare(`
        INSERT INTO typing_states
        (chat_id, user_pin, updated_at)
        VALUES (?, ?, ?)
        ON CONFLICT(chat_id, user_pin)
        DO UPDATE SET updated_at = excluded.updated_at
      `)
        .bind(chatId, userPin, Date.now())
        .run();

      return json({
        success: true,
        typing: true
      });
    }

    // GET TYPING STATUS
    if (
      url.pathname === "/api/typing" &&
      request.method === "GET"
    ) {
      const chatId = Number(url.searchParams.get("chat_id"));
      const userPin = url.searchParams.get("user_pin")?.trim();

      if (!chatId || !userPin) {
        return json({
          success: false,
          error: "chat_id dan user_pin wajib diisi."
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
        chat.participant_1_pin !== userPin &&
        chat.participant_2_pin !== userPin
      ) {
        return json({
          success: false,
          error: "Pengguna bukan anggota chat."
        }, 403);
      }

      const otherPin =
        chat.participant_1_pin === userPin
          ? chat.participant_2_pin
          : chat.participant_1_pin;

      const state = await env.DB.prepare(`
        SELECT updated_at
        FROM typing_states
        WHERE chat_id = ?
          AND user_pin = ?
        LIMIT 1
      `)
        .bind(chatId, otherPin)
        .first();

      const now = Date.now();

      const isTyping =
        state &&
        Number(state.updated_at) > now - 4000;

      return json({
        success: true,
        typing: !!isTyping,
        user_pin: otherPin
      });
    }

    // VOICE CALL / WEBRTC SIGNALING
    // ============================================================

    await env.DB.prepare(`
      CREATE TABLE IF NOT EXISTS call_sessions (
        id TEXT PRIMARY KEY,
        caller_pin TEXT NOT NULL,
        callee_pin TEXT NOT NULL,
        call_type TEXT NOT NULL DEFAULT 'voice',
        status TEXT NOT NULL DEFAULT 'ringing',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    `).run();

    await env.DB.prepare(`
      CREATE TABLE IF NOT EXISTS call_signals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        call_id TEXT NOT NULL,
        sender_pin TEXT NOT NULL,
        type TEXT NOT NULL,
        payload TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    `).run();

    // MIGRATE CALL TYPE FOR EXISTING DATABASE
    try {
      await env.DB.prepare(
        "ALTER TABLE call_sessions ADD COLUMN call_type TEXT NOT NULL DEFAULT 'voice'"
      ).run();
    } catch (_) {
      // Kolom call_type sudah ada.
    }

    // CREATE CALL
    if (url.pathname === "/api/calls" && request.method === "POST") {
      const body = await request.json();

      const callerPin = String(body.caller_pin || "").trim();
      const calleePin = String(body.callee_pin || "").trim();
    const callType = String(body.call_type || "voice").trim().toLowerCase();

    if (callType !== "voice" && callType !== "video") {
      return json({
        success: false,
        error: "call_type harus voice atau video.",
      }, 400);
    }

      if (!callerPin || !calleePin) {
        return json({
          success: false,
          error: "caller_pin dan callee_pin wajib diisi.",
        }, 400);
      }

      if (callerPin === calleePin) {
        return json({
          success: false,
          error: "Tidak dapat menelepon PIN sendiri.",
        }, 400);
      }

      const callee = await env.DB.prepare(
        "SELECT m8_pin FROM users WHERE m8_pin = ? LIMIT 1"
      ).bind(calleePin).first();

      if (!callee) {
        return json({
          success: false,
          error: "Pengguna tujuan tidak ditemukan.",
        }, 404);
      }

      const activeTimeout = Date.now() - 60000;

      const active = await env.DB.prepare(`
        SELECT id
        FROM call_sessions
        WHERE
          status IN ('ringing', 'accepted')
          AND updated_at > ?
          AND (
            caller_pin = ?
            OR callee_pin = ?
          )
        LIMIT 1
      `).bind(activeTimeout, callerPin, callerPin).first();

      if (active) {
        return json({
          success: false,
          error: "Masih ada panggilan aktif.",
        }, 409);
      }

      const callId = crypto.randomUUID();
      const now = Date.now();

      await env.DB.prepare(`
        INSERT INTO call_sessions
        (id, caller_pin, callee_pin, call_type, status, created_at, updated_at)
        VALUES (?, ?, ?, ?, 'ringing', ?, ?)
      `).bind(
        callId,
        callerPin,
        calleePin,
        callType,
        now,
        now
      ).run();

      return json({
        success: true,
        call_id: callId,
        call_type: callType,
        status: "ringing",
      }, 201);
    }

    // INCOMING CALLS
    if (url.pathname === "/api/calls/incoming" && request.method === "GET") {
      const pin = url.searchParams.get("m8_pin")?.trim();

      if (!pin) {
        return json({
          success: false,
          error: "m8_pin wajib diisi.",
        }, 400);
      }

      const result = await env.DB.prepare(`
        SELECT
          id,
          caller_pin,
          callee_pin,
          call_type,
          status,
          created_at,
          updated_at
        FROM call_sessions
        WHERE callee_pin = ?
          AND status = 'ringing'
        ORDER BY created_at DESC
        LIMIT 5
      `).bind(pin).all();

      return json({
        success: true,
        calls: result.results || [],
      });
    }

    // ACCEPT / REJECT / END
    if (
      url.pathname === "/api/calls/accept" &&
      request.method === "POST"
    ) {
      const body = await request.json();
      const callId = String(body.call_id || "").trim();
      const pin = String(body.m8_pin || "").trim();

      if (!callId || !pin) {
        return json({
          success: false,
          error: "call_id dan m8_pin wajib diisi.",
        }, 400);
      }

      const call = await env.DB.prepare(`
        SELECT *
        FROM call_sessions
        WHERE id = ?
        LIMIT 1
      `).bind(callId).first();

      if (!call || call.callee_pin !== pin) {
        return json({
          success: false,
          error: "Panggilan tidak ditemukan.",
        }, 404);
      }

      await env.DB.prepare(`
        UPDATE call_sessions
        SET status = 'accepted', updated_at = ?
        WHERE id = ?
      `).bind(Date.now(), callId).run();

      return json({
        success: true,
        status: "accepted",
      });
    }

    if (
      url.pathname === "/api/calls/reject" &&
      request.method === "POST"
    ) {
      const body = await request.json();
      const callId = String(body.call_id || "").trim();
      const pin = String(body.m8_pin || "").trim();

      if (!callId || !pin) {
        return json({
          success: false,
          error: "call_id dan m8_pin wajib diisi.",
        }, 400);
      }

      const result = await env.DB.prepare(`
        UPDATE call_sessions
        SET status = 'rejected', updated_at = ?
        WHERE id = ?
          AND callee_pin = ?
          AND status = 'ringing'
      `).bind(
        Date.now(),
        callId,
        pin
      ).run();

      return json({
        success: true,
        changed: result.meta?.changes > 0,
        status: "rejected",
      });
    }

    if (
      url.pathname === "/api/calls/end" &&
      request.method === "POST"
    ) {
      const body = await request.json();
      const callId = String(body.call_id || "").trim();
      const pin = String(body.m8_pin || "").trim();

      if (!callId || !pin) {
        return json({
          success: false,
          error: "call_id dan m8_pin wajib diisi.",
        }, 400);
      }

      const result = await env.DB.prepare(`
        UPDATE call_sessions
        SET status = 'ended', updated_at = ?
        WHERE id = ?
          AND (caller_pin = ? OR callee_pin = ?)
          AND status IN ('ringing', 'accepted')
      `).bind(
        Date.now(),
        callId,
        pin,
        pin
      ).run();

      return json({
        success: true,
        changed: result.meta?.changes > 0,
        status: "ended",
      });
    }

    // WEBRTC SIGNAL
    if (
      url.pathname === "/api/calls/signal" &&
      request.method === "POST"
    ) {
      const body = await request.json();

      const callId = String(body.call_id || "").trim();
      const senderPin = String(body.sender_pin || "").trim();
      const type = String(body.type || "").trim();
      const payload = body.payload;

      const allowedTypes = [
        "offer",
        "answer",
        "ice",
      ];

      if (
        !callId ||
        !senderPin ||
        !allowedTypes.includes(type) ||
        payload == null
      ) {
        return json({
          success: false,
          error: "Data signaling tidak lengkap.",
        }, 400);
      }

      const call = await env.DB.prepare(`
        SELECT *
        FROM call_sessions
        WHERE id = ?
        LIMIT 1
      `).bind(callId).first();

      if (!call) {
        return json({
          success: false,
          error: "Panggilan tidak ditemukan.",
        }, 404);
      }

      if (
        call.caller_pin !== senderPin &&
        call.callee_pin !== senderPin
      ) {
        return json({
          success: false,
          error: "Pengirim bukan peserta panggilan.",
        }, 403);
      }

      await env.DB.prepare(`
        INSERT INTO call_signals
        (call_id, sender_pin, type, payload, created_at)
        VALUES (?, ?, ?, ?, ?)
      `).bind(
        callId,
        senderPin,
        type,
        JSON.stringify(payload),
        Date.now()
      ).run();

      return json({
        success: true,
      }, 201);
    }

    // GET WEBRTC SIGNALS
    if (
      url.pathname === "/api/calls/signals" &&
      request.method === "GET"
    ) {
      const callId = url.searchParams.get("call_id")?.trim();
      const pin = url.searchParams.get("m8_pin")?.trim();

      if (!callId || !pin) {
        return json({
          success: false,
          error: "call_id dan m8_pin wajib diisi.",
        }, 400);
      }

      const call = await env.DB.prepare(`
        SELECT *
        FROM call_sessions
        WHERE id = ?
        LIMIT 1
      `).bind(callId).first();

      if (!call) {
        return json({
          success: false,
          error: "Panggilan tidak ditemukan.",
        }, 404);
      }

      if (
        call.caller_pin !== pin &&
        call.callee_pin !== pin
      ) {
        return json({
          success: false,
          error: "Bukan peserta panggilan.",
        }, 403);
      }

      const result = await env.DB.prepare(`
        SELECT
          id,
          sender_pin,
          type,
          payload,
          created_at
        FROM call_signals
        WHERE call_id = ?
          AND sender_pin != ?
        ORDER BY id ASC
        LIMIT 100
      `).bind(callId, pin).all();

      return json({
        success: true,
        status: call.status,
        signals: (result.results || []).map((row) => ({
          id: row.id,
          sender_pin: row.sender_pin,
          type: row.type,
          payload: JSON.parse(row.payload),
          created_at: row.created_at,
        })),
      });
    }


    // ============================================================
    // UPDATE PROFILE NAME
    // ============================================================
    if (url.pathname === "/api/profile/name" && request.method === "POST") {
      const body = await request.json();

      const m8Pin = String(body.m8_pin || "").trim();
      const name = String(body.name || "").trim();

      if (!m8Pin || !name) {
        return json({
          success: false,
          error: "M8 PIN dan nama wajib diisi.",
        }, 400);
      }

      if (name.length < 2) {
        return json({
          success: false,
          error: "Nama minimal 2 karakter.",
        }, 400);
      }

      if (name.length > 50) {
        return json({
          success: false,
          error: "Nama maksimal 50 karakter.",
        }, 400);
      }

      if (!env.DB) {
        return json({
          success: false,
          error: "Binding D1 DB belum tersedia.",
        }, 500);
      }

      const user = await env.DB.prepare(`
        SELECT id, name, email, phone, m8_pin
        FROM users
        WHERE m8_pin = ?
        LIMIT 1
      `)
        .bind(m8Pin)
        .first();

      if (!user) {
        return json({
          success: false,
          error: "Akun M8 tidak ditemukan.",
        }, 404);
      }

      const result = await env.DB.prepare(`
        UPDATE users
        SET name = ?
        WHERE id = ?
      `)
        .bind(name, user.id)
        .run();

      if (!result.success) {
        throw new Error("Gagal memperbarui nama akun M8.");
      }

      const updated = await env.DB.prepare(`
        SELECT id, name, email, phone, m8_pin
        FROM users
        WHERE id = ?
        LIMIT 1
      `)
        .bind(user.id)
        .first();

      return json({
        success: true,
        message: "Nama M8 berhasil diperbarui.",
        user: updated,
      });
    }

    // ============================================================
    // UPDATE PROFILE PHOTO
    // ============================================================
    if (url.pathname === "/api/profile/photo" && request.method === "POST") {
      const body = await request.json();
      const m8Pin = String(body.m8_pin || "").trim();
      const photoUrl = String(body.photo_url || "").trim();

      if (!m8Pin || !photoUrl) {
        return json({
          success: false,
          error: "M8 PIN dan URL foto wajib diisi.",
        }, 400);
      }

      if (photoUrl.length > 2000) {
        return json({
          success: false,
          error: "URL foto terlalu panjang.",
        }, 400);
      }

      if (!env.DB) {
        return json({
          success: false,
          error: "Binding D1 DB belum tersedia.",
        }, 500);
      }

      const user = await env.DB.prepare(`
        SELECT id, name, email, phone, m8_pin, profile_photo_url
        FROM users
        WHERE m8_pin = ?
        LIMIT 1
      `).bind(m8Pin).first();

      if (!user) {
        return json({
          success: false,
          error: "Akun M8 tidak ditemukan.",
        }, 404);
      }

      const result = await env.DB.prepare(`
        UPDATE users
        SET profile_photo_url = ?
        WHERE id = ?
      `).bind(photoUrl, user.id).run();

      if (!result.success) {
        throw new Error("Gagal memperbarui foto profil akun M8.");
      }

      const updated = await env.DB.prepare(`
        SELECT id, name, email, phone, m8_pin, profile_photo_url
        FROM users
        WHERE id = ?
        LIMIT 1
      `).bind(user.id).first();

      return json({
        success: true,
        message: "Foto profil M8 berhasil diperbarui.",
        user: updated,
      });
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
          SELECT id, name, email, phone, m8_pin, password_hash, profile_photo_url, profile_photo_url
          FROM users
          WHERE (email = ? OR phone = ?) AND active = 1
          LIMIT 1
        `)
          .bind(identifier, identifier)
          .first();
      } else {
        user = await env.DB.prepare(`
          SELECT id, name, email, phone, m8_pin, password_hash, profile_photo_url, profile_photo_url
          FROM users
          WHERE m8_pin = ? AND active = 1
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

      let validPassword = await verifyPassword(
        password,
        user.password_hash
      );

      // Upgrade akun lama dari SHA-256 ke PBKDF2
      if (
        !validPassword &&
        user.password_hash &&
        !user.password_hash.startsWith("pbkdf2$")
      ) {
        const legacyHash = await sha256(password);

        if (legacyHash === user.password_hash) {
          const upgradedHash = await hashPassword(password);

          await env.DB.prepare(`
            UPDATE users
            SET password_hash = ?
            WHERE id = ?
          `)
            .bind(upgradedHash, user.id)
            .run();

          validPassword = true;
        }
      }

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
          profile_photo_url: user.profile_photo_url,
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
