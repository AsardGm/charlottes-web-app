import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// =============================================================================
// TYPY
// =============================================================================

interface ServiceAccount {
  project_id: string;
  client_email: string;
  private_key: string;
}

interface PushPayload {
  user_id: string;
  type?: NotificationType;
  actor_name?: string;
  actor_avatar?: string;
  post_title?: string;
  post_id?: string;
  message_preview?: string;
  custom_title?: string;
  custom_body?: string;
  // Zpetna kompatibilita se starym API
  title?: string;
  body?: string;
  data?: Record<string, string>;
}

type NotificationType =
  | 'like'
  | 'comment'
  | 'follow'
  | 'mention'
  | 'reply'
  | 'chat'
  | 'post'
  | 'system';

interface PushToken {
  token: string;
  platform: string;
}

interface FCMResult {
  platform: string;
  token: string;
  success: boolean;
  status: number;
  result: unknown;
  retries?: number;
}

// =============================================================================
// KONFIGURACE
// =============================================================================

const MAX_RETRIES = 3;
const RETRY_DELAY_MS = 1000;
const TOKEN_CACHE_DURATION_MS = 55 * 60 * 1000; // 55 minut (token plati 60)

// Cache pro access token
let cachedAccessToken: string | null = null;
let tokenExpiresAt: number = 0;

// =============================================================================
// POMOCNE FUNKCE
// =============================================================================

function validateServiceAccount(sa: unknown): ServiceAccount {
  if (!sa || typeof sa !== 'object') {
    throw new Error("FIREBASE_SERVICE_ACCOUNT is not set or invalid");
  }

  const account = sa as Record<string, unknown>;

  if (!account.project_id || typeof account.project_id !== 'string') {
    throw new Error("Missing project_id in FIREBASE_SERVICE_ACCOUNT");
  }
  if (!account.client_email || typeof account.client_email !== 'string') {
    throw new Error("Missing client_email in FIREBASE_SERVICE_ACCOUNT");
  }
  if (!account.private_key || typeof account.private_key !== 'string') {
    throw new Error("Missing private_key in FIREBASE_SERVICE_ACCOUNT");
  }

  return {
    project_id: account.project_id,
    client_email: account.client_email,
    private_key: account.private_key,
  };
}

function log(level: 'info' | 'warn' | 'error', message: string, data?: unknown): void {
  const timestamp = new Date().toISOString();
  const prefix = `[send-push][${timestamp}][${level.toUpperCase()}]`;

  if (data !== undefined) {
    console.log(`${prefix} ${message}`, JSON.stringify(data, null, 2));
  } else {
    console.log(`${prefix} ${message}`);
  }
}

function sleep(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}

// =============================================================================
// GENEROVANI TEXTU NOTIFIKACI
// =============================================================================

function generateNotificationContent(payload: PushPayload): { title: string; body: string } {
  const { type, actor_name, post_title, message_preview, custom_title, custom_body } = payload;

  // Custom texty maji prednost
  if (custom_title && custom_body) {
    return { title: custom_title, body: custom_body };
  }

  const name = actor_name || 'Někdo';
  const postPreview = post_title
    ? `"${post_title.substring(0, 50)}${post_title.length > 50 ? '...' : ''}"`
    : '';

  switch (type) {
    case 'like':
      return {
        title: `${name} ocenil tvůj příspěvek ❤️`,
        body: postPreview || 'Tvůj příspěvek se líbí!',
      };

    case 'comment':
      return {
        title: `${name} okomentoval tvůj příspěvek 💬`,
        body: message_preview
          ? `"${message_preview.substring(0, 80)}${message_preview.length > 80 ? '...' : ''}"`
          : postPreview || 'Podívej se na nový komentář',
      };

    case 'reply':
      return {
        title: `${name} ti odpověděl 💬`,
        body: message_preview
          ? `"${message_preview.substring(0, 80)}${message_preview.length > 80 ? '...' : ''}"`
          : 'Podívej se na odpověď',
      };

    case 'follow':
      return {
        title: `${name} tě začal sledovat 👋`,
        body: 'Máš nového sledujícího! Podívej se na jeho profil.',
      };

    case 'mention':
      return {
        title: `${name} tě zmínil 📣`,
        body: postPreview || 'Byl jsi zmíněn v příspěvku',
      };

    case 'chat':
      return {
        title: `Nová zpráva od ${name} 💬`,
        body: message_preview
          ? `${message_preview.substring(0, 100)}${message_preview.length > 100 ? '...' : ''}`
          : 'Máš novou zprávu',
      };

    case 'post':
      return {
        title: `${name} přidal nový příspěvek 📝`,
        body: postPreview || 'Podívej se na nový obsah',
      };

    case 'system':
    default:
      return {
        title: custom_title || "Charlotte's Web",
        body: custom_body || 'Máš novou notifikaci',
      };
  }
}

// =============================================================================
// OAUTH2 ACCESS TOKEN
// =============================================================================

async function getAccessToken(serviceAccount: ServiceAccount): Promise<string> {
  // Pouzij cachovany token pokud je platny
  if (cachedAccessToken && Date.now() < tokenExpiresAt) {
    log('info', 'Using cached access token');
    return cachedAccessToken;
  }

  log('info', 'Generating new access token');

  const now = Math.floor(Date.now() / 1000);
  const exp = now + 3600;

  const header = { alg: "RS256", typ: "JWT" };
  const payload = {
    iss: serviceAccount.client_email,
    sub: serviceAccount.client_email,
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: exp,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
  };

  // Base64URL encoding
  const base64url = (obj: unknown): string => {
    return btoa(JSON.stringify(obj))
      .replace(/=/g, "")
      .replace(/\+/g, "-")
      .replace(/\//g, "_");
  };

  const headerB64 = base64url(header);
  const payloadB64 = base64url(payload);
  const unsignedToken = `${headerB64}.${payloadB64}`;

  // Import private key
  const keyData = serviceAccount.private_key
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

  // Sign the token
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    cryptoKey,
    new TextEncoder().encode(unsignedToken)
  );

  const signatureB64 = btoa(String.fromCharCode(...new Uint8Array(signature)))
    .replace(/=/g, "")
    .replace(/\+/g, "-")
    .replace(/\//g, "_");

  const jwt = `${unsignedToken}.${signatureB64}`;

  // Exchange JWT for access token
  const tokenResponse = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });

  if (!tokenResponse.ok) {
    const errorText = await tokenResponse.text();
    throw new Error(`Failed to get access token: ${tokenResponse.status} ${errorText}`);
  }

  const tokenData = await tokenResponse.json();

  if (!tokenData.access_token) {
    throw new Error("No access_token in response");
  }

  // Cache token
  cachedAccessToken = tokenData.access_token;
  tokenExpiresAt = Date.now() + TOKEN_CACHE_DURATION_MS;

  log('info', 'Access token obtained and cached');

  return tokenData.access_token;
}

// =============================================================================
// FCM ODESLANI S RETRY
// =============================================================================

async function sendToFCMWithRetry(
  token: string,
  platform: string,
  fcmPayload: Record<string, unknown>,
  accessToken: string,
  projectId: string
): Promise<FCMResult> {
  let lastError: unknown;
  let lastStatus = 0;
  let lastResult: unknown;

  for (let attempt = 1; attempt <= MAX_RETRIES; attempt++) {
    try {
      const response = await fetch(
        `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
        {
          method: "POST",
          headers: {
            "Authorization": `Bearer ${accessToken}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify(fcmPayload),
        }
      );

      lastStatus = response.status;
      lastResult = await response.json();

      if (response.ok) {
        return {
          platform,
          token,
          success: true,
          status: response.status,
          result: lastResult,
          retries: attempt - 1,
        };
      }

      // Neprovadej retry pro permanentni chyby
      if (response.status === 400 || response.status === 404 || response.status === 410) {
        log('warn', `Permanent error for ${platform}, not retrying`, { status: response.status, result: lastResult });
        break;
      }

      // Retry pro docasne chyby (5xx, 429)
      if (attempt < MAX_RETRIES && (response.status >= 500 || response.status === 429)) {
        const delay = RETRY_DELAY_MS * Math.pow(2, attempt - 1); // Exponential backoff
        log('warn', `Retry ${attempt}/${MAX_RETRIES} for ${platform} after ${delay}ms`, { status: response.status });
        await sleep(delay);
        continue;
      }

      break;
    } catch (err) {
      lastError = err;
      log('error', `Network error on attempt ${attempt}/${MAX_RETRIES} for ${platform}`, { error: String(err) });

      if (attempt < MAX_RETRIES) {
        const delay = RETRY_DELAY_MS * Math.pow(2, attempt - 1);
        await sleep(delay);
      }
    }
  }

  return {
    platform,
    token,
    success: false,
    status: lastStatus,
    result: lastResult || { error: String(lastError) },
    retries: MAX_RETRIES - 1,
  };
}

// =============================================================================
// HELPER PRO NOTIFICATION LINK
// =============================================================================

function getNotificationLink(data: Record<string, string>): string {
  const type = data.type || 'system';
  const baseUrl = 'https://charlottes-web-app.web.app';

  switch (type) {
    case 'chat':
      return data.conversation_id ? `${baseUrl}/chat/${data.conversation_id}` : `${baseUrl}/chat`;
    case 'post':
    case 'like':
    case 'comment':
    case 'reply':
    case 'mention':
      return data.post_id ? `${baseUrl}/post/${data.post_id}` : baseUrl;
    case 'follow':
      return data.actor_id ? `${baseUrl}/profile/${data.actor_id}` : `${baseUrl}/notifications`;
    default:
      return `${baseUrl}/notifications`;
  }
}

// =============================================================================
// SESTAVENI FCM PAYLOAD
// =============================================================================

function buildFCMPayload(
  token: string,
  platform: string,
  title: string,
  body: string,
  notificationData: Record<string, string>,
  actorAvatar?: string
): Record<string, unknown> {
  const isNativeAndroid = platform === 'android'; // Nativni Android app
  const isNativeIOS = platform === 'ios'; // Nativni iOS app
  const isWeb = platform === 'web' || platform === 'android_pwa' || platform === 'android_web' || platform === 'ios_pwa' || platform === 'ios_web';

  // Data payload - vsechny hodnoty musi byt stringy
  const dataPayload: Record<string, string> = {
    ...notificationData,
    title: String(title),
    body: String(body),
  };

  const fcmPayload: Record<string, unknown> = {
    message: {
      token: token,
      data: dataPayload,
    },
  };

  const message = fcmPayload.message as Record<string, unknown>;

  // Pro WEB platformy pouzij webpush.notification
  // FCM zobrazi notifikaci automaticky - Service Worker NESMI zobrazovat duplicitne
  if (isWeb) {
    message.webpush = {
      headers: {
        Urgency: 'high',
      },
      notification: {
        title: title,
        body: body,
        icon: '/icons/Icon-192.png',
        badge: '/icons/badge-72.png',
      },
      fcm_options: {
        link: getNotificationLink(notificationData),
      },
    };
    log('info', `Web webpush.notification for ${platform}`, { title, body });
  } else {
    // Pro nativni aplikace pouzij standardni notification objekt
    message.notification = { title, body };
  }

  // Android nativni-specificke nastaveni
  if (isNativeAndroid) {
    message.android = {
      notification: {
        icon: "ic_notification",
        color: "#C41E24",
        channel_id: "default",
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
      priority: "high",
    };
  }

  // iOS nativni-specificke nastaveni
  if (isNativeIOS) {
    message.apns = {
      payload: {
        aps: {
          badge: 1,
          sound: "default",
          "mutable-content": 1,
        },
      },
      ...(actorAvatar && {
        fcm_options: {
          image: actorAvatar,
        },
      }),
    };
  }

  return fcmPayload;
}

// =============================================================================
// CORS HEADERS
// =============================================================================

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization, x-client-info, apikey",
};

// =============================================================================
// HLAVNI HANDLER
// =============================================================================

serve(async (req) => {
  // CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  // Pouze POST
  if (req.method !== "POST") {
    return new Response(
      JSON.stringify({ error: "Method not allowed" }),
      { status: 405, headers: { "Content-Type": "application/json", ...corsHeaders } }
    );
  }

  const startTime = Date.now();

  try {
    // Validace service account
    const serviceAccount = validateServiceAccount(
      JSON.parse(Deno.env.get("FIREBASE_SERVICE_ACCOUNT") || "{}")
    );

    // Parsovani payloadu
    const payload: PushPayload = await req.json();
    const { user_id, type, data } = payload;

    log('info', 'Received push request', { user_id, type });

    // Validace
    if (!user_id) {
      return new Response(
        JSON.stringify({ error: "Missing required field: user_id" }),
        { status: 400, headers: { "Content-Type": "application/json", ...corsHeaders } }
      );
    }

    // Validace UUID formatu
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    if (!uuidRegex.test(user_id)) {
      return new Response(
        JSON.stringify({ error: "Invalid user_id format" }),
        { status: 400, headers: { "Content-Type": "application/json", ...corsHeaders } }
      );
    }

    // Generovani textu notifikace
    let title: string;
    let body: string;

    if (type) {
      const content = generateNotificationContent(payload);
      title = content.title;
      body = content.body;
      log('info', 'Generated notification content', {
        type,
        title,
        body,
        actor_name: payload.actor_name,
        post_title: payload.post_title,
        message_preview: payload.message_preview,
      });
    } else if (payload.title && payload.body) {
      title = payload.title;
      body = payload.body;
      log('info', 'Using custom notification content', { title, body });
    } else {
      return new Response(
        JSON.stringify({ error: "Missing required fields: type OR (title AND body)" }),
        { status: 400, headers: { "Content-Type": "application/json", ...corsHeaders } }
      );
    }

    // Supabase client
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (!supabaseUrl || !supabaseKey) {
      throw new Error("Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY");
    }

    const supabase = createClient(supabaseUrl, supabaseKey);

    // Ziskani push tokenu uzivatele
    const { data: tokens, error: tokensError } = await supabase
      .from("push_tokens")
      .select("token, platform")
      .eq("user_id", user_id);

    if (tokensError) {
      log('error', 'Failed to fetch tokens', { error: tokensError });
      return new Response(
        JSON.stringify({ error: "Database error", details: tokensError.message }),
        { status: 500, headers: { "Content-Type": "application/json", ...corsHeaders } }
      );
    }

    if (!tokens || tokens.length === 0) {
      log('info', 'No push tokens found for user', { user_id });
      return new Response(
        JSON.stringify({ error: "No push tokens found for user", user_id }),
        { status: 404, headers: { "Content-Type": "application/json", ...corsHeaders } }
      );
    }

    log('info', `Found ${tokens.length} token(s) for user`, { user_id, platforms: tokens.map(t => t.platform) });

    // Ziskani access tokenu
    const accessToken = await getAccessToken(serviceAccount);

    // Notifikacni data
    const notificationData: Record<string, string> = {
      type: type || data?.type || 'system',
      click_action: "FLUTTER_NOTIFICATION_CLICK",
      ...(payload.post_id && { post_id: payload.post_id }),
      ...(data || {}),
    };

    // Odeslani na vsechny tokeny
    const results = await Promise.all(
      tokens.map(async ({ token, platform }: PushToken) => {
        const fcmPayload = buildFCMPayload(
          token,
          platform,
          title,
          body,
          notificationData,
          payload.actor_avatar
        );

        log('info', `Sending to ${platform}`, {
          token: token.substring(0, 20) + '...',
          fcmPayload: JSON.stringify(fcmPayload, null, 2),
        });

        return sendToFCMWithRetry(
          token,
          platform,
          fcmPayload,
          accessToken,
          serviceAccount.project_id
        );
      })
    );

    // Statistiky
    const successCount = results.filter(r => r.success).length;
    const failedCount = results.filter(r => !r.success).length;

    // Odstraneni neplatnych tokenu (404 = not found, 410 = unregistered)
    const invalidTokens = results
      .filter(r => !r.success && (r.status === 404 || r.status === 410))
      .map(r => r.token);

    if (invalidTokens.length > 0) {
      log('info', `Removing ${invalidTokens.length} invalid token(s)`);

      const { error: deleteError } = await supabase
        .from("push_tokens")
        .delete()
        .in("token", invalidTokens);

      if (deleteError) {
        log('warn', 'Failed to delete invalid tokens', { error: deleteError });
      }
    }

    const duration = Date.now() - startTime;
    log('info', `Push completed in ${duration}ms`, { successCount, failedCount, invalidRemoved: invalidTokens.length });

    return new Response(
      JSON.stringify({
        success: successCount > 0,
        title,
        body,
        stats: {
          total: tokens.length,
          success: successCount,
          failed: failedCount,
          invalid_removed: invalidTokens.length,
        },
        results,
        duration_ms: duration,
      }),
      {
        status: successCount > 0 ? 200 : 500,
        headers: { "Content-Type": "application/json", ...corsHeaders },
      }
    );
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : "Unknown error";
    const stack = err instanceof Error ? err.stack : undefined;

    log('error', 'Push function error', { message, stack });

    return new Response(
      JSON.stringify({ error: message }),
      { status: 500, headers: { "Content-Type": "application/json", ...corsHeaders } }
    );
  }
});
