# Charlotte's Web - PWA Documentation

Progressive Web App (PWA) dokumentace pro aplikaci Charlotte's Web.

---

## Obsah

1. [Přehled PWA](#přehled-pwa)
2. [Architektura](#architektura)
3. [Soubory a struktura](#soubory-a-struktura)
4. [Service Worker](#service-worker)
5. [Push notifikace](#push-notifikace)
6. [Offline podpora](#offline-podpora)
7. [Web Manifest](#web-manifest)
8. [Firebase integrace](#firebase-integrace)
9. [Instalace aplikace](#instalace-aplikace)
10. [Vývoj a testování](#vývoj-a-testování)
11. [Deployment](#deployment)
12. [Troubleshooting](#troubleshooting)

---

## Přehled PWA

Charlotte's Web je plně funkční Progressive Web App s následujícími vlastnostmi:

| Funkce | Stav | Popis |
|--------|------|-------|
| Instalovatelnost | ✅ | Lze nainstalovat na plochu (všechny platformy) |
| Offline podpora | ✅ | Cachování + offline fronta zpráv |
| Push notifikace | ✅ | FCM pro web, iOS 16.4+, Android |
| Background Sync | ⚡ | Připraveno (stub funkce) |
| Standalone režim | ✅ | Běží jako nativní aplikace |
| Responzivní design | ✅ | Optimalizováno pro mobil i desktop |

### Podporované platformy

| Platforma | Push notifikace | Instalace | Offline |
|-----------|----------------|-----------|---------|
| Chrome (desktop) | ✅ | ✅ | ✅ |
| Chrome (Android) | ✅ | ✅ | ✅ |
| Safari (iOS 16.4+) | ✅ | ✅ | ✅ |
| Safari (macOS) | ✅ | ✅ | ✅ |
| Firefox | ❌ | ✅ | ✅ |
| Edge | ✅ | ✅ | ✅ |

---

## Architektura

```
┌─────────────────────────────────────────────────────────────┐
│                      FLUTTER WEB APP                        │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────┐  │
│  │  UI Components  │  │  State (Riverpod)│  │  Services   │  │
│  └────────┬────────┘  └────────┬────────┘  └──────┬──────┘  │
│           │                    │                   │         │
│           └────────────────────┼───────────────────┘         │
│                                │                             │
│  ┌─────────────────────────────┴─────────────────────────┐  │
│  │              WEB PUSH SERVICE (Dart)                   │  │
│  │  - Token management                                    │  │
│  │  - Permission handling                                 │  │
│  │  - Notification stream                                 │  │
│  └─────────────────────────────┬─────────────────────────┘  │
└────────────────────────────────┼────────────────────────────┘
                                 │
                    ┌────────────┴────────────┐
                    │     JavaScript Bridge    │
                    │      (index.html)        │
                    └────────────┬────────────┘
                                 │
        ┌────────────────────────┼────────────────────────┐
        │                        │                        │
┌───────┴───────┐    ┌───────────┴───────────┐    ┌──────┴──────┐
│    sw.js      │    │ firebase-messaging-sw │    │  manifest   │
│ (Main SW)     │    │      (FCM SW)         │    │   .json     │
│               │    │                       │    │             │
│ - Caching     │    │ - Push handling       │    │ - App info  │
│ - Offline     │    │ - Notification display│    │ - Icons     │
│ - Routing     │    │ - Click handling      │    │ - Shortcuts │
└───────────────┘    └───────────────────────┘    └─────────────┘
                                 │
                    ┌────────────┴────────────┐
                    │    Firebase Cloud       │
                    │    Messaging (FCM)      │
                    └────────────┬────────────┘
                                 │
                    ┌────────────┴────────────┐
                    │   Supabase Edge         │
                    │   Functions             │
                    │   (send-push)           │
                    └─────────────────────────┘
```

---

## Soubory a struktura

```
community_app/
├── web/
│   ├── index.html              # Hlavní HTML s Firebase SDK
│   ├── manifest.json           # Web App Manifest
│   ├── sw.js                   # Hlavní Service Worker
│   ├── firebase-messaging-sw.js # Firebase Messaging SW
│   ├── favicon.png             # Favicon
│   ├── icons/
│   │   ├── Icon-192.png        # Standardní ikona
│   │   ├── Icon-512.png        # Velká ikona
│   │   ├── Icon-maskable-192.png # Adaptivní ikona
│   │   ├── Icon-maskable-512.png # Adaptivní ikona velká
│   │   └── badge-72.png        # Badge pro notifikace
│   └── splash/
│       ├── img-dark-1x.png     # iOS splash (tmavý)
│       ├── img-dark-2x.png
│       └── img-dark-3x.png
├── lib/services/
│   ├── push_notification_service_web.dart  # Web push Dart service
│   ├── web_push_service.dart               # Push service interface
│   ├── offline_queue_service.dart          # Offline fronta zpráv
│   └── push_sender_service.dart            # Odesílání push
├── firebase.json               # Firebase Hosting konfigurace
└── .firebaserc                 # Firebase projekt
```

---

## Service Worker

### Hlavní Service Worker (sw.js)

**Verze:** v4
**Cache název:** `charlottes-web-v4`

#### Cachovaní strategie

```javascript
// Network-first s fallback na cache
async function fetchWithCache(request) {
  try {
    const response = await fetch(request);
    if (response.ok) {
      cache.put(request, response.clone());
    }
    return response;
  } catch (error) {
    return cache.match(request);
  }
}
```

#### Precachované assety

```javascript
const PRECACHE_ASSETS = [
  '/',
  '/index.html',
  '/manifest.json',
  '/icons/Icon-192.png',
  '/icons/Icon-512.png',
  '/icons/Icon-maskable-192.png',
  '/icons/Icon-maskable-512.png',
  '/favicon.png'
];
```

#### Lifecycle eventy

| Event | Akce |
|-------|------|
| `install` | Cachuje app shell, skipWaiting() |
| `activate` | Čistí staré cache, claimClients() |
| `fetch` | Network-first, fallback na cache |
| `push` | Deleguje na FCM |
| `notificationclick` | Routing podle typu notifikace |
| `sync` | Background sync (připraveno) |
| `message` | SKIP_WAITING, GET_VERSION |

#### Notification click routing

```javascript
// Routing podle typu notifikace
switch (data.type) {
  case 'chat':
    url = `/chat/${data.conversation_id}`;
    break;
  case 'post':
  case 'like':
  case 'comment':
    url = `/post/${data.post_id}`;
    break;
  case 'follow':
    url = `/profile/${data.actor_id}`;
    break;
  default:
    url = data.url || '/';
}
```

---

### Firebase Messaging SW (firebase-messaging-sw.js)

**Verze:** 2.0.7
**Firebase SDK:** v10.7.1 (modulární)

#### Konfigurace

```javascript
const firebaseConfig = {
  apiKey: "AIzaSyAV3W6DuCbCyZZDo5LWkwrSUUER4qZzhJI",
  authDomain: "charlottes-web-app.firebaseapp.com",
  projectId: "charlottes-web-app",
  storageBucket: "charlottes-web-app.firebasestorage.app",
  messagingSenderId: "66173275380",
  appId: "1:66173275380:web:..."
};
```

#### Detekce platformy

```javascript
function detectPlatform() {
  const ua = navigator.userAgent;
  const isStandalone = window.matchMedia('(display-mode: standalone)').matches;

  if (/iPad|iPhone|iPod/.test(ua)) {
    return isStandalone ? 'ios_pwa' : 'ios_web';
  }
  if (/Android/.test(ua)) {
    return isStandalone ? 'android_pwa' : 'android_web';
  }
  return 'desktop_web';
}
```

#### Typy notifikací a ikony

| Typ | Ikona | Akce |
|-----|-------|------|
| `like` | ❤️ | Otevře post |
| `comment` | 💬 | Otevře post |
| `follow` | 👤 | Otevře profil |
| `mention` | @ | Otevře post |
| `reply` | ↩️ | Otevře post |
| `chat` | 💭 | Otevře chat |
| `post` | 📝 | Otevře post |

---

## Push notifikace

### Architektura

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   Flutter    │────▶│   Supabase   │────▶│     FCM      │
│   App        │     │   Edge Fn    │     │   Server     │
└──────────────┘     └──────────────┘     └──────┬───────┘
                                                  │
                     ┌────────────────────────────┘
                     ▼
              ┌──────────────┐
              │   Firebase   │
              │ Messaging SW │
              └──────┬───────┘
                     │
                     ▼
              ┌──────────────┐
              │  Notification │
              │   Display     │
              └──────────────┘
```

### VAPID Key

```
BPjYAJHAQQN1aViQ23YQCP0_J57aMbVr5Y_FkDMlhpAR_HpjkDZl6uwyMuXjefOhAymxVgGMj9CoWsP92eHhoeI
```

### Token management (Dart)

```dart
// Získání tokenu
Future<String?> getToken() async {
  final token = await js_util.promiseToFuture(
    js_util.callMethod(html.window, 'getFCMToken', [vapidKey])
  );
  return token;
}

// Uložení do Supabase
Future<void> saveTokenToDatabase(String token) async {
  await _supabase.from('push_tokens').upsert({
    'user_id': userId,
    'token': token,
    'platform': platform,
    'updated_at': DateTime.now().toIso8601String(),
  });
}
```

### Odesílání notifikací

```dart
// Použití PushSenderService
await PushSenderService.instance.sendLikeNotification(
  recipientUserId: postAuthorId,
  postId: postId,
  likerName: currentUserName,
);
```

### Supabase Edge Function (send-push)

```typescript
// Endpoint: /functions/v1/send-push
{
  "token": "fcm_token_here",
  "title": "Nový komentář",
  "body": "Jan okomentoval váš příspěvek",
  "data": {
    "type": "comment",
    "post_id": "123",
    "actor_id": "456"
  }
}
```

---

## Offline podpora

### Cache strategie

| Typ obsahu | Strategie | TTL |
|------------|-----------|-----|
| HTML (SPA) | Network-first, cache fallback | Always fresh |
| JS/CSS | Cache-first | 1 rok (immutable) |
| Obrázky | Cache-first | 1 rok (immutable) |
| API data | Network-only | - |
| Service Worker | No-cache | Always fresh |
| Manifest | No-cache | Always fresh |

### Offline fronta zpráv

```dart
// OfflineQueueService
class OfflineQueueService {
  // Přidání zprávy do fronty
  Future<void> addToQueue(QueuedMessage message);

  // Automatické odeslání při obnovení spojení
  void _onConnectivityChanged(ConnectivityResult result) {
    if (result != ConnectivityResult.none) {
      _processQueue();
    }
  }

  // Retry logika
  static const maxRetries = 3;
  static const retryDelay = Duration(seconds: 5);
}
```

### Struktura offline zprávy

```dart
class QueuedMessage {
  final String id;
  final String recipientId;
  final String content;
  final MessageType type;
  final int retryCount;
  final QueueStatus status; // pending, sending, sent, failed
  final DateTime createdAt;
}
```

### Detekce offline stavu

```dart
// Použití connectivity_plus
StreamSubscription<ConnectivityResult> subscription =
  Connectivity().onConnectivityChanged.listen((result) {
    isOnline = result != ConnectivityResult.none;
  });
```

---

## Web Manifest

### Základní konfigurace (manifest.json)

```json
{
  "name": "Charlotte's Web",
  "short_name": "Charlotte",
  "description": "Komunitní aplikace s feedem, chatem a gamifikací",
  "start_url": "/",
  "scope": "/",
  "display": "standalone",
  "display_override": ["standalone", "minimal-ui"],
  "orientation": "portrait-primary",
  "theme_color": "#C41E24",
  "background_color": "#0D1B2A",
  "lang": "cs",
  "categories": ["social", "lifestyle"]
}
```

### Ikony

```json
{
  "icons": [
    {
      "src": "icons/Icon-192.png",
      "sizes": "192x192",
      "type": "image/png"
    },
    {
      "src": "icons/Icon-512.png",
      "sizes": "512x512",
      "type": "image/png"
    },
    {
      "src": "icons/Icon-maskable-192.png",
      "sizes": "192x192",
      "type": "image/png",
      "purpose": "maskable"
    },
    {
      "src": "icons/Icon-maskable-512.png",
      "sizes": "512x512",
      "type": "image/png",
      "purpose": "maskable"
    }
  ]
}
```

### App Shortcuts

```json
{
  "shortcuts": [
    {
      "name": "Nový příspěvek",
      "short_name": "Příspěvek",
      "url": "/create-post",
      "icons": [{ "src": "icons/shortcut-post.png", "sizes": "96x96" }]
    },
    {
      "name": "Chat",
      "short_name": "Chat",
      "url": "/chat",
      "icons": [{ "src": "icons/shortcut-chat.png", "sizes": "96x96" }]
    },
    {
      "name": "Profil",
      "short_name": "Profil",
      "url": "/profile",
      "icons": [{ "src": "icons/shortcut-profile.png", "sizes": "96x96" }]
    }
  ]
}
```

---

## Firebase integrace

### Firebase Hosting (firebase.json)

```json
{
  "hosting": {
    "public": "build/web",
    "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ],
    "headers": [
      {
        "source": "**/*.@(js|css)",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "public, max-age=31536000, immutable"
          }
        ]
      },
      {
        "source": "/sw.js",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "no-cache"
          }
        ]
      },
      {
        "source": "/manifest.json",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "no-cache"
          }
        ]
      }
    ]
  }
}
```

### Firebase projekt

```
Project ID: charlottes-web-app
Messaging Sender ID: 66173275380
```

---

## Instalace aplikace

### Desktop (Chrome/Edge)

1. Otevřete aplikaci v prohlížeči
2. Klikněte na ikonu instalace v adresním řádku (nebo menu → "Nainstalovat aplikaci")
3. Potvrďte instalaci

### Android (Chrome)

1. Otevřete aplikaci v Chrome
2. Klepněte na banner "Přidat na plochu" nebo menu → "Nainstalovat aplikaci"
3. Potvrďte instalaci

### iOS (Safari)

1. Otevřete aplikaci v Safari
2. Klepněte na tlačítko sdílení (□↑)
3. Vyberte "Přidat na plochu"
4. Potvrďte název a klepněte "Přidat"

> **Poznámka:** Push notifikace na iOS vyžadují verzi 16.4 nebo novější a aplikaci nainstalovanou na plochu.

### Detekce standalone režimu

```dart
bool get isStandalone {
  // CSS media query
  final mqStandalone = html.window.matchMedia('(display-mode: standalone)');
  // iOS Safari
  final navigatorStandalone = js_util.getProperty(html.window.navigator, 'standalone');

  return mqStandalone.matches || navigatorStandalone == true;
}
```

---

## Vývoj a testování

### Lokální vývoj

```bash
# Build web verze
flutter build web

# Spuštění lokálního serveru
cd build/web
python3 -m http.server 8080

# Nebo s Firebase emulátorem
firebase serve --only hosting
```

### Testování Service Workeru

1. Otevřete Chrome DevTools → Application → Service Workers
2. Zkontrolujte stav registrace
3. Použijte "Update on reload" pro vynucení aktualizace
4. Testujte offline režim pomocí "Offline" checkboxu

### Testování Push notifikací

```dart
// V aplikaci - test notifikace
await WebPushService.instance.sendTestNotification();
```

Nebo v DevTools Console:

```javascript
// Test z konzole
navigator.serviceWorker.controller.postMessage({
  type: 'TEST_NOTIFICATION'
});
```

### Lighthouse audit

1. Otevřete DevTools → Lighthouse
2. Vyberte "Progressive Web App"
3. Spusťte audit
4. Zkontrolujte PWA kritéria

### Debugging

```javascript
// Service Worker logy
// V sw.js jsou všechny akce logovány:
console.log('[SW] Installing service worker v4...');
console.log('[SW] Caching app shell...');
console.log('[SW] Fetch:', event.request.url);
```

---

## Deployment

### Build a deploy

```bash
# 1. Build Flutter web
flutter build web --release

# 2. Deploy na Firebase Hosting
firebase deploy --only hosting
```

### Deployment checklist

- [ ] Všechny ikony jsou aktuální
- [ ] manifest.json má správné barvy a názvy
- [ ] Service Worker verze je aktualizována
- [ ] VAPID key je správný
- [ ] Firebase konfigurace je aktuální
- [ ] Testovány push notifikace
- [ ] Testován offline režim
- [ ] Lighthouse PWA score > 90

### Aktualizace Service Workeru

Při změně SW:

1. Změňte `CACHE_NAME` verzi (např. `charlottes-web-v5`)
2. Aplikace automaticky:
   - Detekuje novou verzi
   - Nainstaluje nový SW
   - Vyčistí starou cache
   - Aktivuje nový SW

---

## Troubleshooting

### Push notifikace nefungují

**iOS:**
- Zkontrolujte verzi iOS (min. 16.4)
- Aplikace musí být nainstalována na plochu
- Povolte notifikace v Nastavení → Charlotte's Web

**Android/Web:**
- Zkontrolujte povolení notifikací v prohlížeči
- Ověřte FCM token v DevTools → Application → Service Workers

**Obecné:**
- Zkontrolujte VAPID key
- Ověřte Firebase konfiguraci
- Zkontrolujte Supabase Edge Function logy

### Service Worker se neaktualizuje

```javascript
// Vynucení aktualizace
navigator.serviceWorker.controller.postMessage({ type: 'SKIP_WAITING' });

// Nebo v DevTools
// Application → Service Workers → Update
```

### Aplikace nefunguje offline

1. Zkontrolujte, zda jsou assety v PRECACHE_ASSETS
2. Ověřte cache v DevTools → Application → Cache Storage
3. Zkontrolujte Network tab pro failed requesty

### Instalace nefunguje

- Ověřte HTTPS (nebo localhost)
- Zkontrolujte manifest.json validitu
- Ověřte, že ikony existují a mají správnou velikost
- Použijte Lighthouse pro diagnostiku

### Chyby v konzoli

```
// "Service Worker registration failed"
// → Zkontrolujte HTTPS a cesty k SW souborům

// "Push subscription failed"
// → Ověřte VAPID key a Firebase konfiguraci

// "Notification permission denied"
// → Uživatel zamítl notifikace, nelze obnovit bez změny nastavení
```

---

## Užitečné odkazy

- [Web App Manifest spec](https://www.w3.org/TR/appmanifest/)
- [Service Worker API](https://developer.mozilla.org/en-US/docs/Web/API/Service_Worker_API)
- [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging)
- [Workbox](https://developers.google.com/web/tools/workbox) (alternativa pro SW)
- [PWA Builder](https://www.pwabuilder.com/) (testování a generování)

---

## Changelog

### v4 (aktuální)
- Přidána podpora iOS 16.4+ push notifikací
- Vylepšeno cachování
- Přidány app shortcuts
- Background sync připraven

### v3
- Firebase Messaging SDK upgrade na v10.7.1
- Modularizace kódu

### v2
- Základní offline podpora
- Push notifikace pro web a Android

### v1
- Iniciální PWA implementace
- Service Worker s cache-first strategií
