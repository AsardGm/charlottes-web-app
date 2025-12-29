// Charlotte's Web Service Worker pro PWA a Push Notifications
// Podporuje iOS 16.4+ PWA Push Notifications
const CACHE_NAME = 'charlottes-web-v4';
const OFFLINE_URL = '/offline.html';

// Assets to cache
const PRECACHE_ASSETS = [
  '/',
  '/index.html',
  '/manifest.json',
  '/icons/Icon-192.png',
  '/icons/Icon-512.png',
  '/icons/Icon-maskable-192.png',
  '/icons/Icon-maskable-512.png',
  '/favicon.png',
];

// Install event - cache assets
self.addEventListener('install', (event) => {
  console.log('[SW] Installing service worker v4...');
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      console.log('[SW] Caching app shell');
      return cache.addAll(PRECACHE_ASSETS);
    })
  );
  // Aktivuj okamžitě bez čekání na zavření starých tabů
  self.skipWaiting();
});

// Activate event - cleanup old caches
self.addEventListener('activate', (event) => {
  console.log('[SW] Activating service worker v4...');
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames
          .filter((name) => name !== CACHE_NAME)
          .map((name) => {
            console.log('[SW] Deleting old cache:', name);
            return caches.delete(name);
          })
      );
    })
  );
  // Převezmi kontrolu nad všemi klienty
  self.clients.claim();
});

// Fetch event - network first, then cache
self.addEventListener('fetch', (event) => {
  // Skip non-GET requests
  if (event.request.method !== 'GET') return;

  // Skip cross-origin requests (kromě CDN pro fonty atd.)
  const url = new URL(event.request.url);
  if (url.origin !== self.location.origin &&
      !url.hostname.includes('fonts.googleapis.com') &&
      !url.hostname.includes('fonts.gstatic.com')) {
    return;
  }

  event.respondWith(
    fetch(event.request)
      .then((response) => {
        // Ulož do cache pouze úspěšné odpovědi
        if (response && response.status === 200) {
          const responseToCache = response.clone();
          caches.open(CACHE_NAME).then((cache) => {
            cache.put(event.request, responseToCache);
          });
        }
        return response;
      })
      .catch(() => {
        // Fallback na cache při offline
        return caches.match(event.request).then((cachedResponse) => {
          if (cachedResponse) {
            return cachedResponse;
          }
          // Fallback pro navigaci
          if (event.request.mode === 'navigate') {
            return caches.match('/index.html');
          }
          return new Response('Offline', { status: 503 });
        });
      })
  );
});

// Push notification event - funguje na iOS 16.4+ PWA
self.addEventListener('push', (event) => {
  console.log('[SW] Push notification received');

  let data = {
    title: "Charlotte's Web",
    body: 'Nova notifikace',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    tag: 'default',
    data: {},
  };

  if (event.data) {
    try {
      const payload = event.data.json();
      data = {
        title: payload.notification?.title || payload.title || data.title,
        body: payload.notification?.body || payload.body || data.body,
        icon: payload.notification?.icon || payload.icon || data.icon,
        badge: payload.notification?.badge || payload.badge || data.badge,
        tag: payload.data?.tag || payload.tag || data.tag,
        data: payload.data || {},
      };
    } catch (e) {
      console.log('[SW] Push data parse error, using text:', e);
      data.body = event.data.text();
    }
  }

  const options = {
    body: data.body,
    icon: data.icon,
    badge: data.badge,
    tag: data.tag,
    data: data.data,
    // iOS nepodporuje vibrace
    ...(!/iPhone|iPad|iPod/.test(navigator?.userAgent || '') && { vibrate: [100, 50, 100] }),
    requireInteraction: false,
    // iOS nepodporuje actions v notifikacích
    renotify: true,
    silent: false,
  };

  event.waitUntil(
    self.registration.showNotification(data.title, options)
  );
});

// Notification click event
self.addEventListener('notificationclick', (event) => {
  console.log('[SW] Notification clicked:', event.action);

  event.notification.close();

  if (event.action === 'dismiss') {
    return;
  }

  // Zjisti URL pro navigaci
  const notificationData = event.notification.data || {};
  let urlToOpen = '/';

  if (notificationData.url) {
    urlToOpen = notificationData.url;
  } else if (notificationData.type === 'chat') {
    urlToOpen = `/chat/${notificationData.conversation_id || ''}`;
  } else if (notificationData.type === 'post') {
    urlToOpen = `/post/${notificationData.post_id || ''}`;
  }

  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
      // Zkus najít již otevřené okno
      for (const client of clientList) {
        if (client.url.includes(self.location.origin) && 'focus' in client) {
          client.focus();
          // Pošli zprávu do aplikace
          client.postMessage({
            type: 'NOTIFICATION_CLICK',
            url: urlToOpen,
            data: notificationData,
          });
          return;
        }
      }
      // Otevři nové okno
      if (clients.openWindow) {
        return clients.openWindow(urlToOpen);
      }
    })
  );
});

// Message event - komunikace s aplikací
self.addEventListener('message', (event) => {
  console.log('[SW] Message received:', event.data);

  if (event.data && event.data.type === 'SKIP_WAITING') {
    self.skipWaiting();
  }

  if (event.data && event.data.type === 'GET_VERSION') {
    event.ports[0].postMessage({ version: CACHE_NAME });
  }
});

// Background sync (pro offline akce)
self.addEventListener('sync', (event) => {
  console.log('[SW] Background sync:', event.tag);

  if (event.tag === 'sync-messages') {
    event.waitUntil(syncMessages());
  }
  if (event.tag === 'sync-notifications') {
    event.waitUntil(syncNotifications());
  }
});

async function syncMessages() {
  console.log('[SW] Syncing offline messages...');
  // Implementace sync offline zpráv
}

async function syncNotifications() {
  console.log('[SW] Syncing notifications...');
  // Implementace sync notifikací
}

// Periodic Background Sync (pro pravidelné aktualizace, pokud podporováno)
self.addEventListener('periodicsync', (event) => {
  console.log('[SW] Periodic sync:', event.tag);

  if (event.tag === 'check-notifications') {
    event.waitUntil(checkForNewNotifications());
  }
});

async function checkForNewNotifications() {
  console.log('[SW] Checking for new notifications...');
  // Implementace kontroly nových notifikací
}
