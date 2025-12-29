// Firebase Cloud Messaging Service Worker pro SpiderBagzz PWA
importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js');

// Firebase konfigurace
firebase.initializeApp({
  apiKey: "AIzaSyCp2it9pVTSSvUVqK9m70hxJ0Q_7qKz-8A",
  authDomain: "spiderbagzz.firebaseapp.com",
  projectId: "spiderbagzz",
  storageBucket: "spiderbagzz.firebasestorage.app",
  messagingSenderId: "700570202812",
  appId: "1:700570202812:web:71e6b3df01815714f996b9"
});

const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage((payload) => {
  console.log('[FCM SW] Received background message:', payload);

  const notificationTitle = payload.notification?.title || 'SpiderBagzz';
  const notificationOptions = {
    body: payload.notification?.body || 'Nova notifikace',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    tag: payload.data?.tag || 'default',
    data: payload.data || {},
    vibrate: [100, 50, 100],
    actions: [
      { action: 'open', title: 'Otevrit' },
      { action: 'dismiss', title: 'Zavrit' }
    ]
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});

// Handle notification click
self.addEventListener('notificationclick', (event) => {
  console.log('[FCM SW] Notification clicked:', event);

  event.notification.close();

  if (event.action === 'dismiss') {
    return;
  }

  // Navigate to app
  const urlToOpen = event.notification.data?.url || '/';

  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
      // Focus existing window if open
      for (const client of clientList) {
        if (client.url.includes(self.location.origin) && 'focus' in client) {
          client.focus();
          if (event.notification.data?.url) {
            client.navigate(urlToOpen);
          }
          return;
        }
      }
      // Open new window
      if (clients.openWindow) {
        return clients.openWindow(urlToOpen);
      }
    })
  );
});
