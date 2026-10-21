// Версия кэша берётся из version.js (APP_VERSION) — её меняют при каждом релизе.
importScripts('./version.js');
const VERSION = 'v' + APP_VERSION;
const PREFIX = 'hold-the-room-';
const CACHE = PREFIX + VERSION;
const FILES = [
  './',
  './index.html',
  './style.css',
  './version.js',
  './save.js',
  './tour.js',
  './game.js',
  './manifest.webmanifest',
  './icons/icon-192.png',
  './icons/icon-512.png',
  './assets/emo-heart.webp',
  './assets/emo-note.webp',
  './assets/emo-clap.webp',
  './assets/gold-heart.webp',
  './assets/gold-note.webp',
  './assets/gold-clap.webp',
  './assets/spark-0.webp',
  './assets/spark-1.webp',
  './assets/spark-2.webp',
  './assets/spark-3.webp',
  './assets/spark-4.webp',
  './assets/spark-5.webp',
  './assets/spark-6.webp',
  './assets/spark-7.webp',
  './assets/ring-0.webp',
  './assets/ring-1.webp',
  './assets/ring-2.webp',
  './assets/ring-3.webp',
  './assets/ring-4.webp',
  './assets/ring-5.webp',
  './assets/ring-6.webp',
  './assets/ring-7.webp',
  './assets/confetti-0.webp',
  './assets/confetti-1.webp',
  './assets/confetti-2.webp',
  './assets/confetti-3.webp',
  './assets/confetti-4.webp',
  './assets/confetti-5.webp',
  './assets/confetti-6.webp',
  './assets/confetti-7.webp',
  './assets/confetti-8.webp',
  './assets/confetti-9.webp',
  './assets/fire-0.webp',
  './assets/fire-1.webp',
  './assets/fire-2.webp',
  './assets/fire-3.webp',
  './assets/fire-4.webp',
  './assets/fire-5.webp',
  './assets/fire-6.webp',
  './assets/fire-7.webp',
  './assets/light-v-bored.webp',
  './assets/light-v-neutral.webp',
  './assets/light-v-interested.webp',
  './assets/light-v-ecstatic.webp',
  './assets/light-body-off.webp',
  './assets/light-body-on.webp',
  './assets/light-soul.webp',
  './assets/notebook-v-bored.webp',
  './assets/notebook-v-neutral.webp',
  './assets/notebook-v-interested.webp',
  './assets/notebook-v-ecstatic.webp',
  './assets/notebook-body-off.webp',
  './assets/notebook-body-on.webp',
  './assets/notebook-soul.webp',
  './assets/theater-v-bored.webp',
  './assets/theater-v-neutral.webp',
  './assets/theater-v-interested.webp',
  './assets/theater-v-ecstatic.webp',
  './assets/theater-body-off.webp',
  './assets/theater-body-on.webp',
  './assets/theater-soul.webp',
  './music/level1-bossa-antigua.mp3',
  './music/level2-backbay-lounge.mp3',
  './music/level3-funkorama.mp3',
  './music/level4-hep-cats.mp3',
  './music/level5-volatile-reaction.mp3',
];

self.addEventListener('install', e => {
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(FILES)).then(() => self.skipWaiting()));
});

// Удаляем только старые кэши этой игры: на том же домене живут другие приложения.
self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys()
      .then(keys => Promise.all(keys.filter(k => k.startsWith(PREFIX) && k !== CACHE).map(k => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

// Сначала кэш, в фоне обновляем из сети (и восстанавливаем кэш, если его кто-то удалил).
self.addEventListener('fetch', e => {
  if (e.request.method !== 'GET') return;
  const url = new URL(e.request.url);
  if (url.origin !== location.origin) return;
  e.respondWith(
    caches.open(CACHE).then(cache =>
      cache.match(e.request, { ignoreSearch: true }).then(hit => {
        const net = fetch(e.request)
          .then(res => { if (res.ok) cache.put(e.request, res.clone()); return res; })
          .catch(() => hit || (e.request.mode === 'navigate' ? cache.match('./index.html') : Response.error()));
        if (hit) { e.waitUntil(net.catch(() => {})); return hit; }
        return net;
      })
    )
  );
});
