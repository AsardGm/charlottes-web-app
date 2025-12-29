import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// Service Account JSON z Firebase (ulozeny jako secret)
const SERVICE_ACCOUNT = JSON.parse(Deno.env.get("FIREBASE_SERVICE_ACCOUNT") || "{}");
const PROJECT_ID = SERVICE_ACCOUNT.project_id || "spiderbagzz";

interface PushPayload {
  user_id: string;
  type?: 'like' | 'comment' | 'follow' | 'mention' | 'reply' | 'chat' | 'post' | 'system';
  actor_name?: string;
  actor_avatar?: string;
  post_title?: string;
  message_preview?: string;
  custom_title?: string;
  custom_body?: string;
  // Zpetna kompatibilita se starym API
  title?: string;
  body?: string;
  data?: Record<string, string>;
}

// Generovani hezkych textu notifikaci
function generateNotificationContent(payload: PushPayload): { title: string; body: string } {
  const { type, actor_name, post_title, message_preview, custom_title, custom_body } = payload;

  // Custom texty maji prednost
  if (custom_title && custom_body) {
    return { title: custom_title, body: custom_body };
  }

  const name = actor_name || 'Nekdo';
  const postPreview = post_title ? `"${post_title.substring(0, 50)}${post_title.length > 50 ? '...' : ''}"` : '';

  switch (type) {
    case 'like':
      return {
        title: `${name} ocenil tvuj prispevek ❤️`,
        body: postPreview || 'Tvuj prispevek se libi!',
      };

    case 'comment':
      return {
        title: `${name} okomentoval tvuj prispevek 💬`,
        body: message_preview
          ? `"${message_preview.substring(0, 80)}${message_preview.length > 80 ? '...' : ''}"`
          : postPreview || 'Podivej se na novy komentar',
      };

    case 'reply':
      return {
        title: `${name} ti odpoveděl 💬`,
        body: message_preview
          ? `"${message_preview.substring(0, 80)}${message_preview.length > 80 ? '...' : ''}"`
          : 'Podivej se na odpoved',
      };

    case 'follow':
      return {
        title: `${name} te zacal sledovat 👋`,
        body: 'Mas noveho sledujiciho! Podivej se na jeho profil.',
      };

    case 'mention':
      return {
        title: `${name} te zminil 📣`,
        body: postPreview || 'Byl jsi zminen v prispevku',
      };

    case 'chat':
      return {
        title: `Nova zprava od ${name} 💬`,
        body: message_preview
          ? `${message_preview.substring(0, 100)}${message_preview.length > 100 ? '...' : ''}`
          : 'Mas novou zpravu',
      };

    case 'post':
      return {
        title: `${name} pridal novy prispevek 📝`,
        body: postPreview || 'Podivej se na novy obsah',
      };

    case 'system':
    default:
      return {
        title: custom_title || "Charlotte's Web",
        body: custom_body || 'Mas novou notifikaci',
      };
  }
}

// Funkce pro ziskani OAuth2 access tokenu
async function getAccessToken(): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const exp = now + 3600;

  const header = { alg: "RS256", typ: "JWT" };
  const payload = {
    iss: SERVICE_ACCOUNT.client_email,
    sub: SERVICE_ACCOUNT.client_email,
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: exp,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
  };

  const encoder = new TextEncoder();
  const headerB64 = btoa(JSON.stringify(header)).replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");
  const payloadB64 = btoa(JSON.stringify(payload)).replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");
  const unsignedToken = `${headerB64}.${payloadB64}`;

  const privateKey = SERVICE_ACCOUNT.private_key;
  const keyData = privateKey
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\n/g, "");

  const binaryKey = Uint8Array.from(atob(keyData), (c) => c.charCodeAt(0));

  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    binaryKey,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"]
  );

  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    cryptoKey,
    encoder.encode(unsignedToken)
  );

  const signatureB64 = btoa(String.fromCharCode(...new Uint8Array(signature)))
    .replace(/=/g, "")
    .replace(/\+/g, "-")
    .replace(/\//g, "_");

  const jwt = `${unsignedToken}.${signatureB64}`;

  const tokenResponse = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });

  const tokenData = await tokenResponse.json();
  return tokenData.access_token;
}

serve(async (req) => {
  // CORS
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST",
        "Access-Control-Allow-Headers": "Content-Type, Authorization",
      },
    });
  }

  try {
    const payload: PushPayload = await req.json();
    const { user_id, type, data } = payload;

    if (!user_id) {
      return new Response(
        JSON.stringify({ error: "Missing required field: user_id" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    // Zpetna kompatibilita - pokud neni type, pouzij title/body primo
    let title: string;
    let body: string;

    if (type) {
      // Nove API - generuj texty podle typu
      const content = generateNotificationContent(payload);
      title = content.title;
      body = content.body;
    } else if (payload.title && payload.body) {
      // Stare API - pouzij primo title a body
      title = payload.title;
      body = payload.body;
    } else {
      return new Response(
        JSON.stringify({ error: "Missing required fields: type OR (title AND body)" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    // Supabase client
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") || "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || ""
    );

    // Najdi push tokeny uzivatele
    const { data: tokens, error } = await supabase
      .from("push_tokens")
      .select("token, platform")
      .eq("user_id", user_id);

    if (error || !tokens || tokens.length === 0) {
      return new Response(
        JSON.stringify({ error: "No push tokens found", details: error }),
        { status: 404, headers: { "Content-Type": "application/json" } }
      );
    }

    // Ziskej access token
    const accessToken = await getAccessToken();

    // Notifikacni data
    const notificationData: Record<string, string> = {
      type: type || data?.type || 'system',
      click_action: "FLUTTER_NOTIFICATION_CLICK",
      ...(data || {}),
    };

    // Posli notifikaci na kazdy token (FCM V1 API)
    const results = await Promise.all(
      tokens.map(async ({ token, platform }) => {
        const isIOSPWA = platform === 'ios_pwa';
        const isWeb = platform === 'web' || platform === 'ios_web' || isIOSPWA;
        const isAndroid = platform === 'android';
        const isIOS = platform === 'ios';

        const fcmPayload: Record<string, unknown> = {
          message: {
            token: token,
            notification: {
              title,
              body,
            },
            data: notificationData,
          },
        };

        // Web-specificke nastaveni
        if (isWeb) {
          (fcmPayload.message as Record<string, unknown>).webpush = {
            notification: {
              icon: "/icons/Icon-192.png",
              badge: "/icons/Icon-192.png",
              tag: type || data?.type || 'notification',
              renotify: true,
              requireInteraction: false,
            },
            fcm_options: {
              link: data?.url || "https://spiderbagzz-app.web.app",
            },
          };
        }

        // Android-specificke nastaveni
        if (isAndroid) {
          (fcmPayload.message as Record<string, unknown>).android = {
            notification: {
              icon: "ic_notification",
              color: "#C41E24",
              channel_id: "default",
              click_action: "FLUTTER_NOTIFICATION_CLICK",
            },
            priority: "high",
          };
        }

        // iOS-specificke nastaveni
        if (isIOS) {
          (fcmPayload.message as Record<string, unknown>).apns = {
            payload: {
              aps: {
                badge: 1,
                sound: "default",
                "mutable-content": 1,
              },
            },
            fcm_options: {
              image: payload.actor_avatar,
            },
          };
        }

        const response = await fetch(
          `https://fcm.googleapis.com/v1/projects/${PROJECT_ID}/messages:send`,
          {
            method: "POST",
            headers: {
              "Authorization": `Bearer ${accessToken}`,
              "Content-Type": "application/json",
            },
            body: JSON.stringify(fcmPayload),
          }
        );

        const result = await response.json();
        return {
          platform,
          success: response.ok,
          status: response.status,
          result,
        };
      })
    );

    // Odstran neplatne tokeny
    const failedTokens = results
      .filter(r => !r.success && (r.status === 404 || r.status === 410))
      .map(r => tokens.find(t => t.platform === r.platform)?.token)
      .filter(Boolean);

    if (failedTokens.length > 0) {
      await supabase
        .from("push_tokens")
        .delete()
        .in("token", failedTokens);
    }

    return new Response(
      JSON.stringify({
        success: true,
        title,
        body,
        results,
        removed_invalid_tokens: failedTokens.length,
      }),
      {
        status: 200,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        }
      }
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ error: err.message }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
