## Setup in 10 Minuten (ohne Mac)

### 1) Apple Developer Program
Für TestFlight brauchst du in der Regel das **Apple Developer Program**.

### 2) App Store Connect: App-Record anlegen
- Bundle ID = **Container**: `<dein.prefix.handballref>` (das ist `BUNDLE_ID_PREFIX`)
- Danach: watchOS‑Informationen hinzufügen

### 3) App Store Connect API Key
In App Store Connect einen API‑Key erzeugen (Key ID / Issuer ID / `.p8`).

### 4) Codemagic
1. Repo verbinden
2. **App Store Connect Integration** mit dem API‑Key einrichten
3. Environment variables setzen:
   - `DEVELOPMENT_TEAM`
   - `BUNDLE_ID_PREFIX`
4. Workflow `watchos-testflight` starten

Wenn der Build fehlschlägt, kopiere aus dem Log den **ersten** Block mit `error:` und schicke ihn hier.

