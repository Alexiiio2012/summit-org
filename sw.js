/* Service Worker – macht die App nach dem ersten Laden komplett offline nutzbar.
   Bei Aenderungen an einer der Dateien unten die CACHE-Version hochzaehlen. */
"use strict";

const CACHE = "summit-org-v3";

const ASSETS = [
  "./",
  "./index.html",
  "./app.css",
  "./app.js",
  "./manifest.webmanifest",
  "./fonts/mulish.css",
  "./fonts/mulish-latin.woff2",
  "./fonts/mulish-latin-ext.woff2",
  "./vendor/xlsx.full.min.js",
  "./vendor/html2canvas.min.js",
  "./vendor/jspdf.umd.min.js",
  "./icons/icon-180.png",
  "./icons/icon-192.png",
  "./icons/icon-512.png",
  "./icons/icon-512-maskable.png"
];

self.addEventListener("install", event => {
  event.waitUntil(
    caches.open(CACHE)
      // einzeln adden, damit eine fehlende Datei nicht die ganze Installation kippt
      .then(c => Promise.all(ASSETS.map(u => c.add(new Request(u, { cache: "reload" })).catch(() => null))))
      .then(() => self.skipWaiting())
  );
});

self.addEventListener("activate", event => {
  event.waitUntil(
    caches.keys()
      .then(keys => Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener("fetch", event => {
  const req = event.request;
  if (req.method !== "GET") return;

  // Seitenaufruf bewusst zuerst aus dem Cache: die App startet dadurch sofort und
  // haengt nicht an einem WLAN, das Verbindungen annimmt aber nicht antwortet
  // (Hotel-/Messe-Portale). Aktualisiert wird ueber die CACHE-Version oben.
  if (req.mode === "navigate") {
    event.respondWith(
      caches.match("./index.html").then(hit => hit || fetch(req).catch(() => Response.error()))
    );
    return;
  }

  event.respondWith(
    caches.match(req, { ignoreSearch: true }).then(hit => {
      if (hit) return hit;
      return fetch(req).then(res => {
        if (res && res.ok && new URL(req.url).origin === self.location.origin) {
          const copy = res.clone();
          caches.open(CACHE).then(c => c.put(req, copy));
        }
        return res;
      }).catch(() => hit || Response.error());
    })
  );
});
