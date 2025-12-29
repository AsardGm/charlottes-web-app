import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// Service Account JSON z Firebase (ulozeny jako secret)
const SERVICE_ACCOUNT = JSON.parse(Deno.env.get("FIREBASE_SERVICE_ACCOUNT") || "{}");
const PROJECT_ID = SERVICE_ACCOUNT.project_id || "spiderbagzz";

interface PushPayload {
  user_id: string;
  title: string;
  body: string;
  data?: Record<string, string>;
}

// Funkce pro ziskani OAuth2 access tokenu
async function getAccessToken(): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const exp = now + 3600;

  // JWT header a payload
  const header = { alg: "RS256", typ: "JWT" };
  const payload = {
    iss: SERVICE_ACCOUNT.client_email,
    sub: SERVICE_ACCOUNT.client_email,
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: exp,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
  };

  // Encode header a payload
  const encoder = new TextEncoder();
  const headerB64 = btoa(JSON.stringify(header)).replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");
  const payloadB64 = btoa(JSON.stringify(payload)).replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");
  const unsignedToken = `${headerB64}.${payloadB64}`;

  // Importuj private key a podepis JWT
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

  // Vymen JWT za access token
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
    const { user_id, title, body, data } = payload;

    if (!user_id || !title || !body) {
      return new Response(
        JSON.stringify({ error: "Missing required fields" }),
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

    // Posli notifikaci na kazdy token (FCM V1 API)
    const results = await Promise.all(
      tokens.map(async ({ token, platform }) => {
        const fcmPayload = {
          message: {
            token: token,
            notification: {
              title,
              body,
            },
            data: data || {},
            webpush: platform === "web" ? {
              notification: {
                icon: "/icons/Icon-192.png",
                badge: "/icons/Icon-192.png",
              },
              fcm_options: {
                link: "https://spiderbagzz.web.app",
              },
            } : undefined,
            android: platform === "android" ? {
              notification: {
                icon: "ic_notification",
                color: "#C41E24",
              },
            } : undefined,
            apns: platform === "ios" ? {
              payload: {
                aps: {
                  badge: 1,
                  sound: "default",
                },
              },
            } : undefined,
          },
        };

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

    return new Response(
      JSON.stringify({ success: true, results }),
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
