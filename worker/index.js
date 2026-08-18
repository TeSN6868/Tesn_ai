async function ensureStoryTables(db) {
  await db.prepare(`
    CREATE TABLE IF NOT EXISTS stories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      story_id TEXT NOT NULL UNIQUE,
      user_pin TEXT NOT NULL,
      media_url TEXT NOT NULL,
      media_type TEXT NOT NULL DEFAULT 'image',
      caption TEXT,
      created_at INTEGER NOT NULL,
      expires_at INTEGER NOT NULL,
      is_active INTEGER NOT NULL DEFAULT 1,
      view_count INTEGER NOT NULL DEFAULT 0
    )
  `).run();

  try {
    await db.prepare(
      `ALTER TABLE stories ADD COLUMN latitude REAL`
    ).run();
  } catch (_) {}

  try {
    await db.prepare(
      `ALTER TABLE stories ADD COLUMN longitude REAL`
    ).run();
  } catch (_) {}

  await db.prepare(`
    CREATE TABLE IF NOT EXISTS story_viewers (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      story_id TEXT NOT NULL,
      viewer_pin TEXT NOT NULL,
      created_at INTEGER NOT NULL,
      UNIQUE(story_id, viewer_pin)
    )
  `).run();

  await db.prepare(`
    CREATE TABLE IF NOT EXISTS story_likes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      story_id TEXT NOT NULL,
      user_pin TEXT NOT NULL,
      created_at INTEGER NOT NULL,
      UNIQUE(story_id, user_pin)
    )
  `).run();
}

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
          (request.headers.get("content-type") || "")
            .split(";")[0]
            .trim()
            .toLowerCase();

        const allowedTypes = new Set([
          "image/jpeg",
          "image/png",
          "image/webp",
          "image/gif",
          "video/mp4",
          "video/webm",
          "video/quicktime",
        ]);

        if (!allowedTypes.has(contentType)) {
          return json({
            success: false,
            error: "Format media tidak didukung. Gunakan JPG, PNG, WEBP, GIF, MP4, WEBM, atau MOV.",
          }, 400);
        }

        const maxSize = 25 * 1024 * 1024;

        const contentLength =
          Number(request.headers.get("content-length") || 0);

        if (contentLength > maxSize) {
          return json({
            success: false,
            error: "Ukuran media maksimal 25 MB.",
          }, 413);
        }

        const body = await request.arrayBuffer();

        if (!body || body.byteLength === 0) {
          return json({
            success: false,
            error: "File media kosong.",
          }, 400);
        }

        if (body.byteLength > maxSize) {
          return json({
            success: false,
            error: "Ukuran media maksimal 25 MB.",
          }, 413);
        }

        const ext = {
          "image/jpeg": "jpg",
          "image/png": "png",
          "image/webp": "webp",
          "image/gif": "gif",
          "video/mp4": "mp4",
          "video/webm": "webm",
          "video/quicktime": "mov",
        }[contentType] || "bin";

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
      // ============================================================
      // M8 R2 MEDIA GET - RANGE SUPPORT FOR VIDEO
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
            error: "Media tidak ditemukan.",
          }, 404);
        }

        const headers = new Headers(corsHeaders);

        object.writeHttpMetadata(headers);

        headers.set("ETag", object.httpEtag);
        headers.set(
          "Cache-Control",
          "public, max-age=31536000, immutable"
        );
        headers.set("Accept-Ranges", "bytes");

        const range = request.headers.get("Range");

        // ==========================================================
        // RANGE REQUEST
        // ==========================================================
        if (range) {
          const match = range.match(/^bytes=(\d*)-(\d*)$/);

          if (!match) {
            return new Response("Invalid Range", {
              status: 416,
              headers,
            });
          }

          const startText = match[1];
          const endText = match[2];

          const size = object.size;

          let startByte;
          let endByte;

          if (startText === "") {
            const suffixLength = Number(endText);

            if (!Number.isFinite(suffixLength) || suffixLength <= 0) {
              return new Response("Invalid Range", {
                status: 416,
                headers,
              });
            }

            startByte = Math.max(0, size - suffixLength);
            endByte = size - 1;
          } else {
            startByte = Number(startText);

            if (!Number.isFinite(startByte) || startByte < 0 || startByte >= size) {
              return new Response("Range Not Satisfiable", {
                status: 416,
                headers,
              });
            }

            if (endText === "") {
              endByte = size - 1;
            } else {
              endByte = Number(endText);

              if (!Number.isFinite(endByte)) {
                return new Response("Invalid Range", {
                  status: 416,
                  headers,
                });
              }

              endByte = Math.min(endByte, size - 1);
            }
          }

          if (endByte < startByte) {
            return new Response("Range Not Satisfiable", {
              status: 416,
              headers,
            });
          }

          const length = endByte - startByte + 1;

          const rangedObject = await env.MEDIA.get(key, {
            range: {
              offset: startByte,
              length,
            },
          });

          if (!rangedObject) {
            return new Response("Media tidak ditemukan.", {
              status: 404,
              headers,
            });
          }

          headers.set(
            "Content-Range",
            `bytes ${startByte}-${endByte}/${size}`
          );

          headers.set("Content-Length", String(length));

          return new Response(rangedObject.body, {
            status: 206,
            headers,
          });
        }

        // ==========================================================
        // NORMAL FULL MEDIA REQUEST
        // ==========================================================
        headers.set("Content-Length", String(object.size));

        return new Response(object.body, {
          status: 200,
          headers,
        });
      }

      // M8 STORY FEED - CREATE
      // ============================================================
      if (url.pathname === "/api/stories" && request.method === "POST") {
        if (!env.DB) {
          return json({
            success: false,
            error: "Binding D1 DB belum tersedia.",
          }, 500);
        }

        await ensureStoryTables(env.DB);

        const body = await request.json();

        const userPin = String(
          body.m8_pin || body.user_pin || ""
        ).trim();

        const mediaUrl = String(body.media_url || "").trim();

        const mediaType = String(
          body.media_type || "text"
        ).trim().toLowerCase();

        const caption = String(
          body.caption || body.text || ""
        ).trim();
        const latitude =
          body.latitude == null || body.latitude === ""
            ? null
            : Number(body.latitude);

        const longitude =
          body.longitude == null || body.longitude === ""
            ? null
            : Number(body.longitude);

        if (
          (latitude !== null && !Number.isFinite(latitude)) ||
          (longitude !== null && !Number.isFinite(longitude))
        ) {
          return json({
            success: false,
            error: "Koordinat lokasi tidak valid.",
          }, 400);
        }



        if (!userPin) {
          return json({
            success: false,
            error: "m8_pin wajib diisi.",
          }, 400);
        }

        if (!["text", "image", "video"].includes(mediaType)) {
          return json({
            success: false,
            error: "media_type harus text, image, atau video.",
          }, 400);
        }

        if (mediaType === "text" && !caption) {
          return json({
            success: false,
            error: "Tulisan tidak boleh kosong.",
          }, 400);
        }

        if (
          (mediaType === "image" || mediaType === "video") &&
          !mediaUrl
        ) {
          return json({
            success: false,
            error: "media_url wajib diisi untuk foto atau video.",
          }, 400);
        }

        const user = await env.DB.prepare(`
          SELECT m8_pin, name
          FROM users
          WHERE m8_pin = ?
          LIMIT 1
        `).bind(userPin).first();

        if (!user) {
          return json({
            success: false,
            error: "Pengguna B'Jo tidak ditemukan.",
          }, 404);
        }

        const now = Math.floor(Date.now() / 1000);

        /*
         * Story Feed tidak lagi menggunakan masa berlaku 24 jam.
         * expires_at tetap diisi jauh ke depan agar database lama
         * tetap kompatibel tanpa migrasi berbahaya.
         */
        const expiresAt = now + (10 * 365 * 24 * 60 * 60);

        const storyId = crypto.randomUUID();

        const result = await env.DB.prepare(`
          INSERT INTO stories
            (
              story_id,
              user_pin,
              media_url,
              media_type,
              caption,
              latitude,
              longitude,
              created_at,
              expires_at,
              is_active,
              view_count
            )
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 1, 0)
        `).bind(
          storyId,
          userPin,
          mediaUrl,
          mediaType,
          caption,
          latitude,
          longitude,
          now,
          expiresAt
        ).run();

        if (!result.success) {
          throw new Error("Gagal menyimpan posting B'Jo.");
        }

        return json({
          success: true,
          message: "Posting B'Jo berhasil dibuat.",
          story: {
            story_id: storyId,
            user_pin: userPin,
            user_name: user.name,
            media_url: mediaUrl,
            media_type: mediaType,
            caption,
            latitude,
            longitude,
            created_at: now,
            expires_at: expiresAt,
            is_active: true,
            view_count: 0,
          },
        }, 201);
      }

      // ============================================================
      // B'JO STORY - LOVE / UNLOVE
      // ============================================================
      if (url.pathname === "/api/stories/love" && request.method === "POST") {
        if (!env.DB) {
          return json({
            success: false,
            error: "Binding D1 DB belum tersedia.",
          }, 500);
        }

        await ensureStoryTables(env.DB);

        const body = await request.json();

        const storyId = String(body.story_id || "").trim();
        const userPin = String(
          body.m8_pin || body.user_pin || ""
        ).trim();

        if (!storyId || !userPin) {
          return json({
            success: false,
            error: "story_id dan m8_pin wajib diisi.",
          }, 400);
        }

        const story = await env.DB.prepare(`
          SELECT story_id, user_pin
          FROM stories
          WHERE story_id = ?
            AND is_active = 1
          LIMIT 1
        `).bind(storyId).first();

        if (!story) {
          return json({
            success: false,
            error: "Moment tidak ditemukan.",
          }, 404);
        }

        const existing = await env.DB.prepare(`
          SELECT id
          FROM story_likes
          WHERE story_id = ?
            AND user_pin = ?
          LIMIT 1
        `).bind(storyId, userPin).first();

        let liked;

        if (existing) {
          await env.DB.prepare(`
            DELETE FROM story_likes
            WHERE story_id = ?
              AND user_pin = ?
          `).bind(storyId, userPin).run();

          liked = false;
        } else {
          await env.DB.prepare(`
            INSERT INTO story_likes
              (story_id, user_pin, created_at)
            VALUES (?, ?, ?)
          `).bind(
            storyId,
            userPin,
            Math.floor(Date.now() / 1000)
          ).run();

          liked = true;
        }

        const count = await env.DB.prepare(`
          SELECT COUNT(*) AS total
          FROM story_likes
          WHERE story_id = ?
        `).bind(storyId).first();

        return json({
          success: true,
          liked,
          like_count: Number(count?.total || 0),
        });
      }

      // ============================================================
      // B'JO STORY - RECORD VIEW
      // ============================================================
      if (url.pathname === "/api/stories/view" && request.method === "POST") {
        if (!env.DB) {
          return json({
            success: false,
            error: "Binding D1 DB belum tersedia.",
          }, 500);
        }

        await ensureStoryTables(env.DB);

        const body = await request.json();

        const storyId = String(body.story_id || "").trim();
        const viewerPin = String(
          body.m8_pin || body.viewer_pin || ""
        ).trim();

        if (!storyId || !viewerPin) {
          return json({
            success: false,
            error: "story_id dan m8_pin wajib diisi.",
          }, 400);
        }

        const story = await env.DB.prepare(`
          SELECT story_id
          FROM stories
          WHERE story_id = ?
            AND is_active = 1
          LIMIT 1
        `).bind(storyId).first();

        if (!story) {
          return json({
            success: false,
            error: "Moment tidak ditemukan.",
          }, 404);
        }

        const existing = await env.DB.prepare(`
          SELECT id
          FROM story_viewers
          WHERE story_id = ?
            AND viewer_pin = ?
          LIMIT 1
        `).bind(storyId, viewerPin).first();

        if (!existing) {
          await env.DB.prepare(`
            INSERT INTO story_viewers
              (story_id, viewer_pin, created_at)
            VALUES (?, ?, ?)
          `).bind(
            storyId,
            viewerPin,
            Math.floor(Date.now() / 1000)
          ).run();

          await env.DB.prepare(`
            UPDATE stories
            SET view_count = view_count + 1
            WHERE story_id = ?
          `).bind(storyId).run();
        }

        const count = await env.DB.prepare(`
          SELECT COUNT(*) AS total
          FROM story_viewers
          WHERE story_id = ?
        `).bind(storyId).first();

        return json({
          success: true,
          view_count: Number(count?.total || 0),
        });
      }

      // ============================================================
      // B'JO STORY - GET VIEWERS
      // ============================================================
      if (url.pathname === "/api/stories/viewers" && request.method === "GET") {
        if (!env.DB) {
          return json({
            success: false,
            error: "Binding D1 DB belum tersedia.",
          }, 500);
        }

        await ensureStoryTables(env.DB);

        const storyId = url.searchParams.get("story_id")?.trim();
        const ownerPin = url.searchParams.get("m8_pin")?.trim();

        if (!storyId || !ownerPin) {
          return json({
            success: false,
            error: "story_id dan m8_pin wajib diisi.",
          }, 400);
        }

        const story = await env.DB.prepare(`
          SELECT story_id, user_pin
          FROM stories
          WHERE story_id = ?
            AND is_active = 1
          LIMIT 1
        `).bind(storyId).first();

        if (!story) {
          return json({
            success: false,
            error: "Moment tidak ditemukan.",
          }, 404);
        }

        if (String(story.user_pin) !== ownerPin) {
          return json({
            success: false,
            error: "Hanya pemilik Moment yang dapat melihat daftar penonton.",
          }, 403);
        }

        const result = await env.DB.prepare(`
          SELECT
            sv.viewer_pin,
            u.name AS viewer_name,
            sv.created_at
          FROM story_viewers sv
          LEFT JOIN users u
            ON u.m8_pin = sv.viewer_pin
          WHERE sv.story_id = ?
          ORDER BY sv.created_at DESC
        `).bind(storyId).all();

        return json({
          success: true,
          viewers: result.results || [],
        });
      }

      // ============================================================
      // B'JO STORY - DELETE
      // ============================================================
      if (url.pathname === "/api/stories/delete" && request.method === "POST") {
        if (!env.DB) {
          return json({
            success: false,
            error: "Binding D1 DB belum tersedia.",
          }, 500);
        }

        await ensureStoryTables(env.DB);

        const body = await request.json();

        const storyId = String(body.story_id || "").trim();
        const ownerPin = String(
          body.m8_pin || body.user_pin || ""
        ).trim();

        if (!storyId || !ownerPin) {
          return json({
            success: false,
            error: "story_id dan m8_pin wajib diisi.",
          }, 400);
        }

        const story = await env.DB.prepare(`
          SELECT
            story_id,
            user_pin,
            media_url
          FROM stories
          WHERE story_id = ?
            AND is_active = 1
          LIMIT 1
        `).bind(storyId).first();

        if (!story) {
          return json({
            success: false,
            error: "Moment tidak ditemukan.",
          }, 404);
        }

        if (String(story.user_pin) !== ownerPin) {
          return json({
            success: false,
            error: "Hanya pemilik Moment yang dapat menghapusnya.",
          }, 403);
        }

        await env.DB.batch([
          env.DB.prepare(`
            UPDATE stories
            SET is_active = 0
            WHERE story_id = ?
          `).bind(storyId),

          env.DB.prepare(`
            DELETE FROM story_viewers
            WHERE story_id = ?
          `).bind(storyId),

          env.DB.prepare(`
            DELETE FROM story_likes
            WHERE story_id = ?
          `).bind(storyId),
        ]);

        return json({
          success: true,
          message: "Moment berhasil dihapus.",
          story_id: storyId,
        });
      }

      // ============================================================
      // B'JO STORY FEED - GET
      // ============================================================
      if (url.pathname === "/api/stories" && request.method === "GET") {
        if (!env.DB) {
          return json({
            success: false,
            error: "Binding D1 DB belum tersedia.",
          }, 500);
        }

        await ensureStoryTables(env.DB);

        const myPin = url.searchParams.get("m8_pin")?.trim();

        if (!myPin) {
          return json({
            success: false,
            error: "m8_pin wajib diisi.",
          }, 400);
        }

        const result = await env.DB.prepare(`
          SELECT
            s.story_id,
            s.user_pin,
            u.name AS user_name,
            u.profile_photo_url AS user_photo_url,
            s.media_url,
            s.media_type,
            s.caption,
            s.latitude,
            s.longitude,
            s.created_at,
            s.expires_at,
            s.is_active,
            s.view_count,
            (
              SELECT COUNT(*)
              FROM story_likes sl
              WHERE sl.story_id = s.story_id
            ) AS like_count,
            CASE
              WHEN EXISTS (
                SELECT 1
                FROM story_likes sl2
                WHERE sl2.story_id = s.story_id
                  AND sl2.user_pin = ?
              )
              THEN 1
              ELSE 0
            END AS liked
          FROM stories s
          INNER JOIN users u
            ON u.m8_pin = s.user_pin
          WHERE s.is_active = 1
          ORDER BY s.created_at DESC
          LIMIT 100
        `).bind(myPin).all();

        return json({
          success: true,
          stories: result.results || [],
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
      // M8 GROUPS
      // ============================================================

      async function ensureGroupTables() {
        await env.DB.batch([
          env.DB.prepare(`
            CREATE TABLE IF NOT EXISTS groups (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              description TEXT,
              owner_pin TEXT NOT NULL,
              photo_url TEXT,
              created_at INTEGER NOT NULL
            )
          `),
          env.DB.prepare(`
            CREATE TABLE IF NOT EXISTS group_members (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              group_id INTEGER NOT NULL,
              member_pin TEXT NOT NULL,
              role TEXT NOT NULL DEFAULT 'member',
              joined_at INTEGER NOT NULL,
              UNIQUE(group_id, member_pin)
            )
          `),
          env.DB.prepare(`
            CREATE TABLE IF NOT EXISTS group_messages (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              group_id INTEGER NOT NULL,
              sender_pin TEXT NOT NULL,
              message TEXT NOT NULL,
              timestamp INTEGER NOT NULL,
              status TEXT NOT NULL DEFAULT 'sent'
            )
          `),
        ]);
      }

      // ============================================================
      // GET GROUPS
      // ============================================================

      if (url.pathname === "/api/groups" && request.method === "GET") {
        await ensureGroupTables();

        const myPin = url.searchParams.get("m8_pin")?.trim();

        if (!myPin) {
          return json({
            success: false,
            error: "m8_pin wajib diisi.",
          }, 400);
        }

        const result = await env.DB.prepare(`
          SELECT
            g.id,
            g.name,
            g.description,
            g.owner_pin,
            g.photo_url,
            g.created_at,
            COUNT(gm.id) AS member_count
          FROM groups g
          INNER JOIN group_members gm
            ON gm.group_id = g.id
          WHERE EXISTS (
            SELECT 1
            FROM group_members mine
            WHERE mine.group_id = g.id
              AND mine.member_pin = ?
          )
          GROUP BY
            g.id,
            g.name,
            g.description,
            g.owner_pin,
            g.photo_url,
            g.created_at
          ORDER BY g.id DESC
        `)
          .bind(myPin)
          .all();

        return json({
          success: true,
          groups: result.results || [],
        });
      }

      // ============================================================
      // UPDATE GROUP NAME
      // ============================================================

      if (url.pathname === "/api/groups" && request.method === "PUT") {
        await ensureGroupTables();

        const body = await request.json();

        const groupId = Number(body.group_id || 0);
        const requesterPin = String(body.requester_pin || "").trim();
        const name = String(body.name || "").trim();

        if (!groupId || !requesterPin || !name) {
          return json({
            success: false,
            error: "group_id, requester_pin, dan nama grup wajib diisi.",
          }, 400);
        }

        if (name.length > 80) {
          return json({
            success: false,
            error: "Nama grup maksimal 80 karakter.",
          }, 400);
        }

        const groupResult = await env.DB.prepare(`
          SELECT id, owner_pin
          FROM groups
          WHERE id = ?
          LIMIT 1
        `)
          .bind(groupId)
          .first();

        if (!groupResult) {
          return json({
            success: false,
            error: "Grup tidak ditemukan.",
          }, 404);
        }

        if (String(groupResult.owner_pin) !== requesterPin) {
          return json({
            success: false,
            error: "Hanya pemilik grup yang dapat mengubah nama grup.",
          }, 403);
        }

        await env.DB.prepare(`
          UPDATE groups
          SET name = ?
          WHERE id = ?
        `)
          .bind(name, groupId)
          .run();

        return json({
          success: true,
          message: "Nama grup berhasil diperbarui.",
          group_id: groupId,
          name,
        });
      }


      // ============================================================
      // CREATE GROUP
      // ============================================================

      if (url.pathname === "/api/groups" && request.method === "POST") {
        await ensureGroupTables();

        const body = await request.json();

        const ownerPin = String(body.owner_pin || "").trim();
        const name = String(body.name || "").trim();
        const description = String(body.description || "").trim();
        const photoUrl = String(body.photo_url || "").trim();

        let members = Array.isArray(body.members)
          ? body.members.map((x) => String(x).trim()).filter(Boolean)
          : [];

        if (!ownerPin || !name) {
          return json({
            success: false,
            error: "owner_pin dan nama grup wajib diisi.",
          }, 400);
        }

        if (name.length > 80) {
          return json({
            success: false,
            error: "Nama grup maksimal 80 karakter.",
          }, 400);
        }

        // Pemilik selalu menjadi anggota grup.
        members = [...new Set([ownerPin, ...members])];

        if (members.length > 100) {
          return json({
            success: false,
            error: "Maksimal 100 anggota dalam satu grup.",
          }, 400);
        }

        // Pastikan semua PIN anggota benar-benar terdaftar.
        const placeholders = members.map(() => "?").join(",");

        const usersResult = await env.DB.prepare(`
          SELECT m8_pin
          FROM users
          WHERE m8_pin IN (${placeholders})
        `)
          .bind(...members)
          .all();

        const registeredPins = new Set(
          (usersResult.results || [])
            .map((row) => String(row.m8_pin))
        );

        const missingPins = members.filter(
          (pin) => !registeredPins.has(pin)
        );

        if (missingPins.length > 0) {
          return json({
            success: false,
            error: "Ada PIN M8 yang tidak ditemukan.",
            missing_pins: missingPins,
          }, 404);
        }

        const createdAt = Date.now();

        const groupResult = await env.DB.prepare(`
          INSERT INTO groups
            (name, description, owner_pin, photo_url, created_at)
          VALUES (?, ?, ?, ?, ?)
        `)
          .bind(
            name,
            description || null,
            ownerPin,
            photoUrl || null,
            createdAt,
          )
          .run();

        if (!groupResult.success) {
          throw new Error("Gagal membuat grup.");
        }

        const groupId = groupResult.meta.last_row_id;

        const statements = members.map((pin) =>
          env.DB.prepare(`
            INSERT INTO group_members
              (group_id, member_pin, role, joined_at)
            VALUES (?, ?, ?, ?)
          `).bind(
            groupId,
            pin,
            pin === ownerPin ? "owner" : "member",
            createdAt,
          )
        );

        await env.DB.batch(statements);

        const group = await env.DB.prepare(`
          SELECT
            id,
            name,
            description,
            owner_pin,
            photo_url,
            created_at
          FROM groups
          WHERE id = ?
        `)
          .bind(groupId)
          .first();

        return json({
          success: true,
          group,
          member_count: members.length,
        }, 201);
      }

      // ============================================================
      // GET GROUP MEMBERS
      // ============================================================

      if (
        url.pathname === "/api/groups/members" &&
        request.method === "GET"
      ) {
        await ensureGroupTables();

        const groupId = Number(
          url.searchParams.get("group_id")
        );

        const myPin = url.searchParams.get("m8_pin")?.trim();

        if (!groupId || !myPin) {
          return json({
            success: false,
            error: "group_id dan m8_pin wajib diisi.",
          }, 400);
        }

        const access = await env.DB.prepare(`
          SELECT id
          FROM group_members
          WHERE group_id = ?
            AND member_pin = ?
          LIMIT 1
        `)
          .bind(groupId, myPin)
          .first();

        if (!access) {
          return json({
            success: false,
            error: "Kamu bukan anggota grup ini.",
          }, 403);
        }

        const result = await env.DB.prepare(`
          SELECT
            gm.id,
            gm.group_id,
            gm.member_pin,
            gm.role,
            gm.joined_at,
            u.name,
            u.profile_photo_url
          FROM group_members gm
          LEFT JOIN users u
            ON u.m8_pin = gm.member_pin
          WHERE gm.group_id = ?
          ORDER BY
            CASE WHEN gm.role = 'owner' THEN 0 ELSE 1 END,
            gm.id ASC
        `)
          .bind(groupId)
          .all();

        return json({
          success: true,
          members: result.results || [],
        });
      }

      // ============================================================
      // ADD GROUP MEMBER
      // ============================================================

      if (
        url.pathname === "/api/groups/members" &&
        request.method === "POST"
      ) {
        await ensureGroupTables();

        const body = await request.json();

        const groupId = Number(body.group_id);
        const requesterPin = String(
          body.requester_pin || ""
        ).trim();
        const memberPin = String(
          body.member_pin || ""
        ).trim();

        if (!groupId || !requesterPin || !memberPin) {
          return json({
            success: false,
            error: "group_id, requester_pin dan member_pin wajib diisi.",
          }, 400);
        }

        const requester = await env.DB.prepare(`
          SELECT role
          FROM group_members
          WHERE group_id = ?
            AND member_pin = ?
          LIMIT 1
        `)
          .bind(groupId, requesterPin)
          .first();

        if (!requester) {
          return json({
            success: false,
            error: "Kamu bukan anggota grup.",
          }, 403);
        }

        if (
          requester.role !== "owner" &&
          requester.role !== "admin"
        ) {
          return json({
            success: false,
            error: "Hanya pemilik atau admin yang dapat menambah anggota.",
          }, 403);
        }

        const user = await env.DB.prepare(`
          SELECT m8_pin
          FROM users
          WHERE m8_pin = ?
          LIMIT 1
        `)
          .bind(memberPin)
          .first();

        if (!user) {
          return json({
            success: false,
            error: "PIN M8 anggota tidak ditemukan.",
          }, 404);
        }

        const existing = await env.DB.prepare(`
          SELECT id
          FROM group_members
          WHERE group_id = ?
            AND member_pin = ?
          LIMIT 1
        `)
          .bind(groupId, memberPin)
          .first();

        if (existing) {
          return json({
            success: true,
            message: "Anggota sudah berada di grup.",
            existing: true,
          });
        }

        const count = await env.DB.prepare(`
          SELECT COUNT(*) AS total
          FROM group_members
          WHERE group_id = ?
        `)
          .bind(groupId)
          .first();

        if (Number(count?.total || 0) >= 100) {
          return json({
            success: false,
            error: "Grup sudah mencapai 100 anggota.",
          }, 409);
        }

        await env.DB.prepare(`
          INSERT INTO group_members
            (group_id, member_pin, role, joined_at)
          VALUES (?, ?, 'member', ?)
        `)
          .bind(groupId, memberPin, Date.now())
          .run();

        return json({
          success: true,
          message: "Anggota berhasil ditambahkan.",
        }, 201);
      }

      // ============================================================
      // GET GROUP MESSAGES
      // ============================================================

      if (
        url.pathname === "/api/group-messages" &&
        request.method === "GET"
      ) {
        await ensureGroupTables();

        const groupId = Number(
          url.searchParams.get("group_id")
        );

        const myPin = url.searchParams.get("m8_pin")?.trim();

        if (!groupId || !myPin) {
          return json({
            success: false,
            error: "group_id dan m8_pin wajib diisi.",
          }, 400);
        }

        const access = await env.DB.prepare(`
          SELECT id
          FROM group_members
          WHERE group_id = ?
            AND member_pin = ?
          LIMIT 1
        `)
          .bind(groupId, myPin)
          .first();

        if (!access) {
          return json({
            success: false,
            error: "Kamu bukan anggota grup ini.",
          }, 403);
        }

        const result = await env.DB.prepare(`
          SELECT
            id,
            group_id,
            sender_pin,
            message,
            timestamp,
            status
          FROM group_messages
          WHERE group_id = ?
          ORDER BY id ASC
        `)
          .bind(groupId)
          .all();

        return json({
          success: true,
          messages: result.results || [],
        });
      }

      // ============================================================
      // SEND GROUP MESSAGE
      // ============================================================

      if (
        url.pathname === "/api/group-messages" &&
        request.method === "POST"
      ) {
        await ensureGroupTables();

        const body = await request.json();

        const groupId = Number(body.group_id);
        const senderPin = String(
          body.sender_pin || ""
        ).trim();
        const message = String(
          body.message || ""
        ).trim();

        if (!groupId || !senderPin || !message) {
          return json({
            success: false,
            error: "group_id, sender_pin dan message wajib diisi.",
          }, 400);
        }

        const access = await env.DB.prepare(`
          SELECT id
          FROM group_members
          WHERE group_id = ?
            AND member_pin = ?
          LIMIT 1
        `)
          .bind(groupId, senderPin)
          .first();

        if (!access) {
          return json({
            success: false,
            error: "Pengirim bukan anggota grup.",
          }, 403);
        }

        const timestamp = Date.now();

        const result = await env.DB.prepare(`
          INSERT INTO group_messages
            (group_id, sender_pin, message, timestamp, status)
          VALUES (?, ?, ?, ?, 'sent')
        `)
          .bind(
            groupId,
            senderPin,
            message,
            timestamp,
          )
          .run();

        if (!result.success) {
          throw new Error("Gagal menyimpan pesan grup.");
        }

        const saved = await env.DB.prepare(`
          SELECT
            id,
            group_id,
            sender_pin,
            message,
            timestamp,
            status
          FROM group_messages
          WHERE id = ?
        `)
          .bind(result.meta.last_row_id)
          .first();

        return json({
          success: true,
          message: saved,
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
            c.id,
            c.participant_1_pin,
            c.participant_2_pin,
            c.created_at,

            CASE
              WHEN c.participant_1_pin = ?
              THEN c.participant_2_pin
              ELSE c.participant_1_pin
            END AS other_pin,

            u.id AS other_user_id,
            u.name AS other_user_name,
            u.profile_photo_url AS other_profile_photo_url,

            (
              SELECT m.message
              FROM messages m
              WHERE m.chat_id = c.id
              ORDER BY m.id DESC
              LIMIT 1
            ) AS last_message,

            (
              SELECT m.timestamp
              FROM messages m
              WHERE m.chat_id = c.id
              ORDER BY m.id DESC
              LIMIT 1
            ) AS last_message_time,

            (
              SELECT COUNT(*)
              FROM messages m
              WHERE m.chat_id = c.id
                AND m.sender_pin != ?
                AND m.status != 'read'
            ) AS unread_count

          FROM chats c

          LEFT JOIN users u
            ON u.m8_pin = CASE
              WHEN c.participant_1_pin = ?
              THEN c.participant_2_pin
              ELSE c.participant_1_pin
            END

          WHERE
            c.participant_1_pin = ?
            OR c.participant_2_pin = ?

          ORDER BY
            COALESCE(
              (
                SELECT m.timestamp
                FROM messages m
                WHERE m.chat_id = c.id
                ORDER BY m.id DESC
                LIMIT 1
              ),
              c.created_at
            ) DESC
        `)
          .bind(
            myPin,
            myPin,
            myPin,
            myPin,
            myPin
          )
          .all();

        const chats = (result.results || []).map((chat) => ({
          id: chat.id,
          participant_1_pin: chat.participant_1_pin,
          participant_2_pin: chat.participant_2_pin,
          created_at: chat.created_at,

          last_message: chat.last_message ?? '',
          last_message_time: chat.last_message_time,
          unread_count: Number(chat.unread_count || 0),

          other_user: {
            id: chat.other_user_id,
            name: chat.other_user_name,
            m8_pin: chat.other_pin,
            profile_photo_url: chat.other_profile_photo_url,
          },
        }));

        return json({
          success: true,
          chats,
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

      const currentTime = Date.now();
      const activeTimeout = currentTime - 60000;

// Bersihkan sesi panggilan yang sudah stale agar crash/force-close
// tidak mengunci pengguna pada status ringing/accepted.
      await env.DB.prepare(`
        UPDATE call_sessions
        SET status = 'ended', updated_at = ?
        WHERE
          status IN ('ringing', 'accepted')
          AND updated_at <= ?
          AND (
            caller_pin = ?
            OR callee_pin = ?
          )
      `).bind(currentTime, activeTimeout, callerPin, callerPin).run();

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
          AND updated_at > ?
        ORDER BY created_at DESC
        LIMIT 5
      `).bind(pin, Date.now() - 60000).all();

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
      const userId = Number(body.user_id);
      const photoUrl = String(body.photo_url || "").trim();

      if (!Number.isInteger(userId) || userId <= 0 || !photoUrl) {
        return json({
          success: false,
          error: "User ID dan URL foto wajib diisi.",
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
        WHERE id = ?
        LIMIT 1
      `).bind(userId).first();

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

    // ============================================================
    // B'JO SESSIONS
    // ============================================================

    if (
      url.pathname === "/api/sessions" &&
      request.method === "GET"
    ) {
      await ensureSessionTables(env);

      const sessionUser = await getSessionUser(request, env);

      if (!sessionUser) {
        return json({
          success: false,
          error: "Sesi tidak valid atau sudah dicabut.",
        }, 401);
      }

      const sessions = await env.DB.prepare(`
        SELECT
          id,
          device_name,
          platform,
          created_at,
          last_seen_at,
          revoked_at
        FROM sessions
        WHERE user_id = ?
          AND revoked_at IS NULL
        ORDER BY last_seen_at DESC
      `)
        .bind(sessionUser.user_id)
        .all();

      const currentToken = await getBearerToken(request);
      const currentHash = await hashToken(currentToken);

      const rows = (sessions.results || []).map((item) => ({
        id: item.id,
        device_name: item.device_name || "Perangkat B'Jo",
        platform: item.platform || "unknown",
        created_at: item.created_at,
        last_seen_at: item.last_seen_at,
        current: false,
      }));

      const currentSession = await env.DB.prepare(`
        SELECT id
        FROM sessions
        WHERE token_hash = ?
        LIMIT 1
      `).bind(currentHash).first();

      for (const item of rows) {
        item.current = currentSession &&
          Number(item.id) === Number(currentSession.id);
      }

      return json({
        success: true,
        sessions: rows,
      });
    }

    // ============================================================
    // CABUT SESSION
    // ============================================================

    if (
      url.pathname === "/api/sessions/revoke" &&
      request.method === "POST"
    ) {
      await ensureSessionTables(env);

      const sessionUser = await getSessionUser(request, env);

      if (!sessionUser) {
        return json({
          success: false,
          error: "Sesi tidak valid atau sudah dicabut.",
        }, 401);
      }

      const body = await request.json();
      const sessionId = Number(body.session_id);

      if (!Number.isInteger(sessionId) || sessionId <= 0) {
        return json({
          success: false,
          error: "ID sesi tidak valid.",
        }, 400);
      }

      const target = await env.DB.prepare(`
        SELECT id
        FROM sessions
        WHERE id = ?
          AND user_id = ?
          AND revoked_at IS NULL
        LIMIT 1
      `)
        .bind(sessionId, sessionUser.user_id)
        .first();

      if (!target) {
        return json({
          success: false,
          error: "Sesi tidak ditemukan.",
        }, 404);
      }

      await env.DB.prepare(`
        UPDATE sessions
        SET revoked_at = unixepoch()
        WHERE id = ?
          AND user_id = ?
      `)
        .bind(sessionId, sessionUser.user_id)
        .run();

      return json({
        success: true,
        message: "Sesi perangkat berhasil dicabut.",
      });
    }

    // ============================================================
    // LOGOUT SEMUA PERANGKAT
    // ============================================================

    if (
      url.pathname === "/api/sessions/logout-all" &&
      request.method === "POST"
    ) {
      await ensureSessionTables(env);

      const sessionUser = await getSessionUser(request, env);

      if (!sessionUser) {
        return json({
          success: false,
          error: "Sesi tidak valid atau sudah dicabut.",
        }, 401);
      }

      await env.DB.prepare(`
        UPDATE sessions
        SET revoked_at = unixepoch()
        WHERE user_id = ?
          AND revoked_at IS NULL
      `)
        .bind(sessionUser.user_id)
        .run();

      return json({
        success: true,
        message: "Semua perangkat berhasil dikeluarkan.",
      });
    }

    // ============================================================
    // LOGOUT SESSION SAAT INI
    // ============================================================

    if (
      url.pathname === "/api/sessions/logout" &&
      request.method === "POST"
    ) {
      await ensureSessionTables(env);

      const sessionUser = await getSessionUser(request, env);

      if (!sessionUser) {
        return json({
          success: false,
          error: "Sesi tidak valid atau sudah dicabut.",
        }, 401);
      }

      await env.DB.prepare(`
        UPDATE sessions
        SET revoked_at = unixepoch()
        WHERE id = ?
      `)
        .bind(sessionUser.session_id)
        .run();

      return json({
        success: true,
        message: "Perangkat berhasil logout.",
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

      await ensureSessionTables(env);

      const token = await createToken();
      const tokenHash = await hashToken(token);
      const deviceName = getDeviceName(request);
      const platform = getPlatform(request);

      await env.DB.prepare(`
        INSERT INTO sessions
          (user_id, token_hash, device_name, platform, created_at, last_seen_at)
        VALUES (?, ?, ?, ?, unixepoch(), unixepoch())
      `)
        .bind(
          user.id,
          tokenHash,
          deviceName,
          platform
        )
        .run();

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

async function hashToken(token) {
  return sha256(token);
}

async function ensureSessionTables(env) {
  if (!env.DB) {
    throw new Error("Binding D1 DB belum tersedia.");
  }

  await env.DB.prepare(`
    CREATE TABLE IF NOT EXISTS sessions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      token_hash TEXT NOT NULL UNIQUE,
      device_name TEXT,
      platform TEXT,
      created_at INTEGER NOT NULL,
      last_seen_at INTEGER NOT NULL,
      revoked_at INTEGER
    )
  `).run();
}

async function getBearerToken(request) {
  const header = request.headers.get("Authorization") || "";

  if (!header.toLowerCase().startsWith("bearer ")) {
    return "";
  }

  return header.slice(7).trim();
}

async function getSessionUser(request, env) {
  const token = await getBearerToken(request);

  if (!token || !env.DB) {
    return null;
  }

  const tokenHash = await hashToken(token);

  const session = await env.DB.prepare(`
    SELECT
      s.id AS session_id,
      s.user_id,
      s.device_name,
      s.platform,
      s.created_at,
      s.last_seen_at,
      u.id,
      u.name,
      u.email,
      u.phone,
      u.m8_pin,
      u.profile_photo_url
    FROM sessions s
    JOIN users u ON u.id = s.user_id
    WHERE s.token_hash = ?
      AND s.revoked_at IS NULL
      AND u.active = 1
    LIMIT 1
  `).bind(tokenHash).first();

  if (!session) {
    return null;
  }

  await env.DB.prepare(`
    UPDATE sessions
    SET last_seen_at = unixepoch()
    WHERE id = ?
  `).bind(session.session_id).run();

  return session;
}

function getDeviceName(request) {
  const explicit = request.headers.get("X-BJo-Device");

  if (explicit && explicit.trim()) {
    return explicit.trim().slice(0, 100);
  }

  const agent = request.headers.get("User-Agent") || "";

  if (/Android/i.test(agent)) {
    return "Android";
  }

  if (/iPhone|iPad/i.test(agent)) {
    return "iPhone/iPad";
  }

  return "Perangkat B'Jo";
}

function getPlatform(request) {
  const explicit = request.headers.get("X-BJo-Platform");

  if (explicit && explicit.trim()) {
    return explicit.trim().slice(0, 40);
  }

  const agent = request.headers.get("User-Agent") || "";

  if (/Android/i.test(agent)) {
    return "android";
  }

  if (/iPhone|iPad/i.test(agent)) {
    return "ios";
  }

  return "unknown";
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
