export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    const corsHeaders = {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "POST, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type",
    };

    // CORS preflight
    if (request.method === "OPTIONS") {
      return new Response(null, {
        status: 204,
        headers: corsHeaders,
      });
    }

    // ==============================
    // HEALTH CHECK
    // ==============================
    if (url.pathname === "/" && request.method === "GET") {
      return new Response(
        JSON.stringify({
          success: true,
          app: "TeSN AI",
          status: "online",
          service: "Cloudflare Worker + Gemini API",
        }),
        {
          status: 200,
          headers: {
            ...corsHeaders,
            "Content-Type": "application/json; charset=UTF-8",
          },
        }
      );
    }

    // ==============================
    // CHAT API
    // ==============================
    if (url.pathname === "/api/chat" && request.method === "POST") {
      try {
        // Pastikan API key tersedia
        if (!env.GEMINI_API_KEY) {
          return new Response(
            JSON.stringify({
              error: "GEMINI_API_KEY belum dikonfigurasi di Cloudflare Worker.",
            }),
            {
              status: 500,
              headers: {
                ...corsHeaders,
                "Content-Type": "application/json; charset=UTF-8",
              },
            }
          );
        }

        // Baca JSON
        let body;

        try {
          body = await request.json();
        } catch {
          return new Response(
            JSON.stringify({
              error: "Request harus menggunakan JSON yang valid.",
            }),
            {
              status: 400,
              headers: {
                ...corsHeaders,
                "Content-Type": "application/json; charset=UTF-8",
              },
            }
          );
        }

        const message =
          typeof body?.message === "string"
            ? body.message.trim()
            : "";

        if (!message) {
          return new Response(
            JSON.stringify({
              error: "Pesan tidak boleh kosong.",
            }),
            {
              status: 400,
              headers: {
                ...corsHeaders,
                "Content-Type": "application/json; charset=UTF-8",
              },
            }
          );
        }

        // ==========================================
        // MODEL GEMINI
        // ==========================================
        const model = "gemini-3.6-flash";

        const apiUrl =
          `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent` +
          `?key=${encodeURIComponent(env.GEMINI_API_KEY)}`;

        // ==========================================
        // SYSTEM PROMPT TeSN AI
        // ==========================================
        const systemInstruction = `
Kamu adalah TeSN AI, asisten AI pribadi yang ramah, cerdas,
jelas, dan membantu.

Jawablah menggunakan bahasa yang sama dengan bahasa pengguna.
Jika pengguna menggunakan Bahasa Indonesia, gunakan Bahasa Indonesia.

Berikan jawaban yang:
- jelas
- langsung
- mudah dipahami
- tidak bertele-tele
- tetap informatif

Jika pengguna meminta bantuan teknis, berikan langkah yang
bisa langsung dijalankan.

Jangan mengaku sebagai manusia.
`;

        const geminiResponse = await fetch(apiUrl, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            systemInstruction: {
              parts: [
                {
                  text: systemInstruction,
                },
              ],
            },
            contents: [
              {
                role: "user",
                parts: [
                  {
                    text: message,
                  },
                ],
              },
            ],
          }),
        });

        // Ambil response JSON
        const data = await geminiResponse.json();

        // ==========================================
        // GEMINI ERROR
        // ==========================================
        if (!geminiResponse.ok) {
          return new Response(
            JSON.stringify({
              error: "Gemini API error",
              status: geminiResponse.status,
              details: data,
            }),
            {
              status: geminiResponse.status,
              headers: {
                ...corsHeaders,
                "Content-Type": "application/json; charset=UTF-8",
              },
            }
          );
        }

        // ==========================================
        // AMBIL JAWABAN GEMINI
        // ==========================================
        const reply =
          data?.candidates?.[0]?.content?.parts
            ?.map((part) => part?.text || "")
            .join("")
            .trim() || "";

        if (!reply) {
          return new Response(
            JSON.stringify({
              error: "Gemini tidak memberikan jawaban.",
              details: data,
            }),
            {
              status: 502,
              headers: {
                ...corsHeaders,
                "Content-Type": "application/json; charset=UTF-8",
              },
            }
          );
        }

        // ==========================================
        // RESPONSE KE FLUTTER
        // ==========================================
        return new Response(
          JSON.stringify({
            success: true,
            reply: reply,
          }),
          {
            status: 200,
            headers: {
              ...corsHeaders,
              "Content-Type": "application/json; charset=UTF-8",
            },
          }
        );
      } catch (error) {
        return new Response(
          JSON.stringify({
            error: "Server error",
            message:
              error instanceof Error
                ? error.message
                : String(error),
          }),
          {
            status: 500,
            headers: {
              ...corsHeaders,
              "Content-Type": "application/json; charset=UTF-8",
            },
          }
        );
      }
    }

    // ==============================
    // 404
    // ==============================
    return new Response(
      JSON.stringify({
        error: "Endpoint tidak ditemukan.",
        path: url.pathname,
        method: request.method,
      }),
      {
        status: 404,
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json; charset=UTF-8",
        },
      }
    );
  },
};
