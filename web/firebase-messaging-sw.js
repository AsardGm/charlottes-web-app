// Firebase Messaging Service Worker pro PWA Push Notifications
// Podporuje iOS 16.4+ PWA, Android PWA i desktop prohlizece
// VERSION: 2.0.7 - 2024-12-30 - Remove ALL handlers, let FCM handle everything

importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js');

// Firebase konfigurace
firebase.initializeApp({
  apiKey: "AIzaSyAV3W6DuCbCyZZDo5LWkwrSUUER4qZzhJI",
  authDomain: "charlottes-web-app.firebaseapp.com",
  projectId: "charlottes-web-app",
  storageBucket: "charlottes-web-app.firebasestorage.app",
  messagingSenderId: "66173275380",
  appId: "1:66173275380:web:ec9c80a5a0679b9d1be2a1"
});

const messaging = firebase.messaging();

// =============================================================================
// POMOCNE FUNKCE
// =============================================================================

function log(level, message, data) {
  const timestamp = new Date().toISOString();
  const prefix = `[FCM-SW][${timestamp}][${level.toUpperCase()}]`;
  if (data) {
    console.log(`${prefix} ${message}`, data);
  } else {
    console.log(`${prefix} ${message}`);
  }
}

// Detekce platformy
function getPlatform() {
  const userAgent = self.navigator?.userAgent || '';

  if (/iPhone|iPad|iPod/.test(userAgent)) {
    return 'ios_pwa';
  }
  if (/Android/.test(userAgent)) {
    return 'android_pwa';
  }
  return 'web';
}

// Ziskani ikony podle typu notifikace
function getNotificationIcon(type) {
  const icons = {
    like: '/icons/notification-like.png',
    comment: '/icons/notification-comment.png',
    follow: '/icons/notification-follow.png',
    mention: '/icons/notification-mention.png',
    reply: '/icons/notification-reply.png',
    chat: '/icons/notification-chat.png',
    post: '/icons/notification-post.png',
    system: '/icons/Icon-192.png',
  };
  return icons[type] || '/icons/Icon-192.png';
}

// =============================================================================
// BACKGROUND MESSAGE HANDLER - DISABLED
// =============================================================================
// FCM s webpush.notification zobrazuje notifikace automaticky
// NEVOLAT messaging.onBackgroundMessage - zpusobuje duplicity!

// =============================================================================
// PUSH EVENT HANDLER - ZAKAZANO
// =============================================================================
// NEPOUZIVAT - FCM SDK s webpush.notification zpracovava push eventy automaticky
// Tento handler by zpusoboval duplicitni notifikace

// =============================================================================
// NOTIFICATION CLICK HANDLER
// =============================================================================

self.addEventListener('notificationclick', (event) => {
  log('info', 'Notification clicked', { action: event.action, data: event.notification.data });

  event.notification.close();

  // Akce "dismiss" - pouze zavri
  if (event.action === 'dismiss') {
    return;
  }

  const data = event.notification.data || {};
  const urlToOpen = data.url || '/';

  event.waitUntil(
    handleNotificationClick(urlToOpen, data)
  );
});

async function handleNotificationClick(url, data) {
  // Zkus najit existujici okno aplikace
  const clientList = await self.clients.matchAll({
    type: 'window',
    includeUncontrolled: true,
  });

  // Hledej okno na stejne domene
  for (const client of clientList) {
    const clientUrl = new URL(client.url);
    if (clientUrl.origin === self.location.origin) {
      // Fokusuj existujici okno
      await client.focus();

      // Posli zpravu do aplikace pro navigaci
      client.postMessage({
        type: 'NOTIFICATION_CLICK',
        url: url,
        data: data,
      });

      log('info', 'Focused existing window and sent navigation message');
      return;
    }
  }

  // Zadne okno nenalezeno - otevri nove
  if (self.clients.openWindow) {
    log('info', 'Opening new window', url);
    return self.clients.openWindow(url);
  }
}

// =============================================================================
// NOTIFICATION CLOSE HANDLER
// =============================================================================

self.addEventListener('notificationclose', (event) => {
  log('info', 'Notification closed', event.notification.tag);

  // Zde muzeme trackovat zavreni notifikace
  // Napr. poslat analytics event
});

// =============================================================================
// POMOCNE FUNKCE PRO NOTIFIKACE
// =============================================================================

function getNotificationUrl(data) {
  const type = data.type || 'system';

  switch (type) {
    case 'chat':
      return data.conversation_id ? `/chat/${data.conversation_id}` : '/chat';
    case 'post':
    case 'like':
    case 'comment':
    case 'reply':
    case 'mention':
      return data.post_id ? `/post/${data.post_id}` : '/';
    case 'follow':
      return data.actor_id ? `/profile/${data.actor_id}` : '/notifications';
    default:
      return data.url || '/notifications';
  }
}

function getNotificationActions(type, platform) {
  // iOS PWA nepodporuje akce
  if (platform === 'ios_pwa') {
    return [];
  }

  switch (type) {
    case 'chat':
      return [
        { action: 'reply', title: 'Odpovedet' },
        { action: 'dismiss', title: 'Zavrit' },
      ];
    case 'follow':
      return [
        { action: 'view', title: 'Zobrazit profil' },
        { action: 'dismiss', title: 'Zavrit' },
      ];
    case 'like':
    case 'comment':
    case 'reply':
    case 'mention':
    case 'post':
      return [
        { action: 'view', title: 'Zobrazit' },
        { action: 'dismiss', title: 'Zavrit' },
      ];
    default:
      return [
        { action: 'dismiss', title: 'Zavrit' },
      ];
  }
}

// =============================================================================
// SERVICE WORKER LIFECYCLE
// =============================================================================

self.addEventListener('install', (event) => {
  log('info', 'FCM Service Worker installing...');
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  log('info', 'FCM Service Worker activated');
  event.waitUntil(self.clients.claim());
});

// =============================================================================
// MESSAGE HANDLER (komunikace s aplikaci)
// =============================================================================

self.addEventListener('message', (event) => {
  log('info', 'Message from app', event.data);

  if (event.data?.type === 'SKIP_WAITING') {
    self.skipWaiting();
  }

  // Test notifikace
  if (event.data?.type === 'TEST_NOTIFICATION') {
    self.registration.showNotification('Test notifikace', {
      body: 'Push notifikace funguje!',
      icon: '/icons/Icon-192.png',
      badge: '/icons/badge-72.png',
    });
  }
});

log('info', 'FCM Service Worker loaded');
