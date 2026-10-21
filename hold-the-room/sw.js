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
  './assets/ghost-0.webp',
  './assets/ghost-1.webp',
  './assets/ghost-2.webp',
  './assets/ghost-3.webp',
  './assets/body-gray.webp',
  './assets/body-color.webp',
  './assets/spark-0.webp',
  './assets/spark-1.webp',
  './assets/spark-2.webp',
  './assets/spark-3.webp',
  './assets/spark-4.webp',
  './assets/spark-5.webp',
  './assets/spark-6.webp',
  './assets/spark-7.webp',
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
