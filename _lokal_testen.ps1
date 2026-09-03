# Kleiner Testserver fuer den Windows-Rechner. Nicht Teil der App - die Datei
# wird nie auf den Webspace hochgeladen und auch nicht vom Service Worker
# zwischengespeichert.
#
# Rechtsklick auf diese Datei -> "Mit PowerShell ausfuehren", dann im Browser
#   http://localhost:8099/
# oeffnen. Fuer den Browser gilt localhost als sicherer Kontext, deshalb laesst
# sich hier auch der Offline-Betrieb (Service Worker) pruefen.
#
# Beenden: dieses Fenster schliessen oder Strg+C.

param(
  [int]$Port = 8099
)

$Root = $PSScriptRoot
if (-not $Root) { $Root = (Get-Location).Path }

$mime = @{
  ".html"        = "text/html; charset=utf-8"
  ".js"          = "application/javascript; charset=utf-8"
  ".css"         = "text/css; charset=utf-8"
  ".json"        = "application/json; charset=utf-8"
  ".webmanifest" = "application/manifest+json; charset=utf-8"
  ".png"         = "image/png"
  ".svg"         = "image/svg+xml"
  ".woff2"       = "font/woff2"
  ".md"          = "text/plain; charset=utf-8"
}

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$Port/")

try {
  $listener.Start()
} catch {
  Write-Host ""
  Write-Host "Port $Port ist belegt oder wurde blockiert." -ForegroundColor Red
  Write-Host "Laeuft der Server schon in einem anderen Fenster?"
  Write-Host "Anderer Port:  .\_lokal_testen.ps1 -Port 8100"
  Write-Host ""
  Read-Host "Mit Enter schliessen"
  exit 1
}

Write-Host ""
Write-Host "Summit Org laeuft auf  http://localhost:$Port/" -ForegroundColor Green
Write-Host "Ordner: $Root"
Write-Host "Beenden mit Strg+C."
Write-Host ""

try { Start-Process "http://localhost:$Port/" } catch { }

while ($listener.IsListening) {
  try {
    $ctx = $listener.GetContext()
  } catch {
    break
  }
  $path = [System.Uri]::UnescapeDataString($ctx.Request.Url.AbsolutePath)
  if ($path -eq "/") { $path = "/index.html" }

  # Nur innerhalb des Ordners ausliefern
  $rel = $path.TrimStart("/") -replace "/", "\"
  $file = Join-Path $Root $rel
  $full = [System.IO.Path]::GetFullPath($file)
  $rootFull = [System.IO.Path]::GetFullPath($Root)

  if ($full.StartsWith($rootFull) -and (Test-Path -LiteralPath $full -PathType Leaf)) {
    $ext = [System.IO.Path]::GetExtension($full).ToLower()
    $ct = $mime[$ext]
    if (-not $ct) { $ct = "application/octet-stream" }
    $bytes = [System.IO.File]::ReadAllBytes($full)
    $ctx.Response.ContentType = $ct
    # Kein Caching im Browser: sonst sieht man Aenderungen an app.js nicht
    $ctx.Response.Headers.Add("Cache-Control", "no-store")
    $ctx.Response.ContentLength64 = $bytes.Length
    $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
    Write-Host ("200  " + $path)
  } else {
    $ctx.Response.StatusCode = 404
    Write-Host ("404  " + $path) -ForegroundColor DarkYellow
  }
  $ctx.Response.Close()
}

$listener.Stop()
