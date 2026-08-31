# Design Summit 2026 – Org Chart (iPad-App)

Selbstbedienungs-Erfassung für den Summit: iPad weitergeben, die Person trägt sich
selbst ein, alles bleibt auf dem Gerät. Auswertung, Organigramm und Export liegen
hinter einer PIN.

---

## 1. Was in diesem Ordner liegt

| Datei / Ordner        | Zweck                                                        |
|-----------------------|--------------------------------------------------------------|
| `index.html`          | Die App                                                      |
| `app.css`, `app.js`   | Layout und Logik                                             |
| `manifest.webmanifest`| Macht die App auf dem Homescreen zur eigenständigen App       |
| `sw.js`               | Service Worker – sorgt für den Offline-Betrieb                |
| `fonts/`              | Mulish, lokale Kopie (SIL Open Font License 1.1)             |
| `vendor/`             | xlsx, html2canvas, jsPDF – lokal, kein CDN                   |
| `icons/`              | Homescreen-Icons                                             |
| `_lokal_testen.ps1`   | Kleiner Testserver für den Windows-Rechner (nicht Teil der App) |

Es gibt **keine** Verbindung nach außen. Kein CDN, keine Google-Fonts, kein Tracking.

---

## 2. Auf das iPad bringen

Der Ordner muss **einmal über HTTPS** erreichbar sein. Das ist keine Schikane,
sondern Bedingung von iOS: nur in einem „secure context“ darf sich der Service
Worker installieren, und nur dann läuft die App danach wirklich offline.

**So geht es:**

1. Den kompletten Ordner auf einen statischen HTTPS-Webspace legen
   (interner Webserver, Azure Static Web Apps, Netlify Drop, GitHub Pages – was
   die IT freigibt). Der Ordnerinhalt wird 1:1 hochgeladen, nichts umbenennen.
2. Auf dem iPad in **Safari** die URL öffnen.
3. Teilen-Symbol → **„Zum Home-Bildschirm“** → Name z. B. „Summit Org“.
4. Die App vom Homescreen einmal starten, solange noch Internet da ist. Damit
   legt der Service Worker alle Dateien lokal ab.
5. Ab jetzt läuft alles offline – Flugmodus zum Prüfen einschalten und die App
   neu starten. Unter *Admin → Daten & Einstellungen → Offline-Status* muss
   „Bereit“ stehen.

**Was nicht funktioniert:**

- Die HTML-Datei direkt aus der Dateien-App öffnen (`file://`): iOS speichert
  dort nicht zuverlässig, Einträge können verloren gehen.
- Ein interner Server über `http://` (ohne S): die App läuft, aber der Service
  Worker installiert sich nicht, also kein garantierter Offline-Betrieb.

**Vorab auf dem Windows-Rechner testen:** Rechtsklick auf `_lokal_testen.ps1`
→ „Mit PowerShell ausführen“, dann `http://localhost:8099/` im Browser öffnen.
`localhost` gilt für den Browser als sicher, daher lässt sich damit auch der
Offline-Betrieb prüfen.

---

## 3. Vor dem Summit einrichten

1. App öffnen, oben rechts auf das **Schloss-Symbol**, PIN eingeben.
   **Die Start-PIN ist `2026`.**
2. Unter *Daten & Einstellungen → Admin-PIN* eine eigene PIN setzen.
3. Bei *Firmenauswahl im Kiosk-Modus* entscheiden:
   - **Frei** (Vorgabe): Jede Person tippt ihre Firma selbst ein. Es wird nie
     eine Firmenliste angezeigt – nur Treffer zur Eingabe. Nach „Fertig“ ist das
     Feld wieder leer, die nächste Person sieht nichts vom Vorgänger.
   - **Fest**: Der Kiosk bleibt auf dem oben ausgewählten Lieferanten. Sinnvoll,
     wenn nur eine Firma erfasst wird.
4. Optional bestehende Daten laden: *Import → JSON* oder *Excel / CSV*.
   Die vorhandenen Dateien aus `L_Organigramm_TEST` passen dafür.
5. **iPad weitergeben** antippen. Damit ist der Admin-Bereich wieder gesperrt.

---

## 4. Ablauf am Summit

Die Person bekommt das iPad und sieht nur: Firma eingeben → Formular → *Eintragen*.
Danach kommt eine Bestätigung mit „Weitere Person“ oder „Fertig“.

- Nur der **Name** ist Pflicht. E-Mail wird auf Plausibilität geprüft.
- Gleiche Namen werden nachgefragt, nicht stillschweigend doppelt angelegt.
- Eigene Einträge kann die Person korrigieren, solange sie das iPad hat.
  Fremde Einträge sind schreibgeschützt.
- Kategorien, Sprachen und Software lassen sich über das Feld unter den Chips
  jederzeit ergänzen; neue Einträge stehen danach allen zur Verfügung.
- Oben rechts kann jede Person zwischen **EN** und **DE** umschalten.
  Vorgabe ist Englisch.

---

## 5. Speicherung

Jede Änderung wird sofort auf dem iPad gespeichert – kein Speichern-Knopf, und
ein versehentlicher Neustart kostet keine Daten. Zusätzlich legt die App bei
jedem Start und vor jedem Import einen **Wiederherstellungspunkt** an
(die fünf neuesten, unter *Daten & Einstellungen*).

Trotzdem: Am Ende jedes Summit-Tages einmal *JSON-Sicherung → Sicherung speichern*
und die Datei vom iPad wegschieben. Der Speicher hängt an Safari; wenn jemand die
Website-Daten löscht oder die App vom Homescreen entfernt, ist der Stand weg.

**Warnung im Admin-Bereich beachten:** Erscheint dort ein roter Hinweis
„Kein Speicher“, läuft Safari im privaten Modus. Dann bestehen die Einträge nur
bis zum Schließen des Tabs.

---

## 6. Daten herausholen

Alles unter *Admin → Daten & Einstellungen*:

- **Excel-Arbeitsmappe** – ein Blatt mit allen Lieferanten plus je ein Blatt pro
  Lieferant. Diese Datei lässt sich unverändert wieder importieren.
- **Organigramm als PDF** – der aktuelle Lieferant, komplett auf einer Seite.
- **JSON-Sicherung** – vollständiger Stand, für Backup und Weiterbearbeitung.

Auf dem iPad öffnet sich dabei das iOS-Teilen-Menü (AirDrop, Mail, „In Dateien
speichern“, Teams). Am Rechner wird die Datei normal heruntergeladen.

---

## 7. Wenn Dateien geändert werden

Der Service Worker liefert die Dateien aus seinem Cache aus. Nach einer Änderung
an `index.html`, `app.css` oder `app.js` deshalb in `sw.js` die Zeile

```js
const CACHE = "summit-org-v1";
```

hochzählen (`v2`, `v3`, …) und die App auf dem iPad zweimal starten. Ohne das
bleibt die alte Version aktiv.

---

## 8. Organigramm-Logik

**Wurzel:** Wer **Teamleiter** angehakt hat, steht oben. Sind mehrere Teamleiter
erfasst, wird der erste zur Wurzel, die anderen behalten ihre Kennzeichnung.
Ist niemand markiert, bildet ein Firmenknoten die Wurzel, damit das Diagramm
zusammenhängend bleibt.

**Gruppierung:** Darunter wird nach Kategorien gruppiert. Maßgeblich ist die
**erste** Kategorie einer Person – wer „DIY & Hardware · Toys" angegeben hat,
erscheint unter DIY & HARDWARE. Die Zahl im schwarzen Kreis am Label ist die
Personenzahl der Gruppe.

- Kategorien mit **mehreren** Personen bekommen eine eigene Zeile: Label links,
  alle Personen nebeneinander. Die Labels sind gleich breit, damit die
  Personen-Spalten über alle Zeilen bündig untereinander stehen.
- Kategorien mit **genau einer** Person stehen gemeinsam in der letzten Zeile
  nebeneinander, jede mit ihrem Label darüber. Das hält das Diagramm kompakt.
- Zeilen mit mehreren Personen kommen zuerst, nach Gruppengröße absteigend.

**Ohne Kategorie:** Personen, die keine Kategorie angegeben haben, landen in
einer Sammelgruppe mit dem Label **„Sonderprojekte"** (englisch *Special
projects*). Das ist eine reine Beschriftung – sie sagt nur „keine Kategorie
angegeben". Wenn dir eine andere Bezeichnung lieber ist, lässt sich das in
`app.js` beim Schlüssel `chart.noCat` ändern.

**Sonstiges:**

- Filter blenden Nichttreffer ab, entfernen sie aber nicht – die Struktur und
  die Gruppengrößen bleiben lesbar.
- Zoomen über **+ / − / Einpassen** oder mit zwei Fingern direkt im Diagramm.
  Bei vielen Kategorien wird das Diagramm breit; „Einpassen" holt es auf die
  Bildschirmbreite, der PDF-Export bleibt davon unberührt und immer vollständig.
