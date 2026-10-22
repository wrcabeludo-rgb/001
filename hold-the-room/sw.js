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
  './art/hero-sit.svg',
  './art/hero-play.svg',
  './art/hero-rock.svg',
  './art/soul.svg',
  './art/viewer-1.svg',
  './art/viewer-2.svg',
  './art/viewer-3.svg',
  './art/viewer-4.svg',
  './art/viewer-5.svg',
  './art/viewer-6.svg',
  './art/stage-1.webp',
  './art/stage-2.webp',
  './art/stage-3.webp',
  './art/fx/pickup.webp',
  './art/fx/wave.webp',
  './art/fx/chain.webp',
  './art/fx/climax.webp',
  './art/fx/evolve.webp',
  './music/level1-bossa-antigua.mp3',
  './music/level2-backbay-lounge.mp3',
  './music/level3-funkorama.mp3',
  './music/level4-hep-cats.mp3',
  './music/level5-volatile-reaction.mp3',
];

self.addEventListener('install', e => {
  // cache: 'reload' — мимо HTTP-кэша браузера, иначе в кэш новой версии попадали старые файлы
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(FILES.map(f => new Request(f, { cache: 'reload' })))).then(() => self.skipWaiting()));
});

// Удаляем только старые кэши этой игры: на том же домене живут другие приложения.
self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys()
      .then(keys => Promise.all(keys.filter(k => k.startsWith(PREFIX) && k !== CACHE).map(k => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

// Сначала кэш своей версии. Чего в нём нет — берём из сети и докладываем в кэш.
// Фоном файлы не обновляются: иначе в кэш старой версии подмешивались файлы новой.
// Новая версия приходит целиком — новым service worker'ом со своим кэшем.
self.addEventListener('fetch', e => {
  if (e.request.method !== 'GET') return;
  const url = new URL(e.request.url);
  if (url.origin !== location.origin) return;
  e.respondWith(
    caches.open(CACHE).then(cache =>
      cache.match(e.request, { ignoreSearch: true }).then(hit => {
        if (hit) return hit;
        return fetch(e.request)
          .then(res => { if (res.ok) cache.put(e.request, res.clone()); return res; })
          .catch(() => (e.request.mode === 'navigate' ? cache.match('./index.html') : Response.error()));
      })
    )
  );
});
