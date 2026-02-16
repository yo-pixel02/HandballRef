# HandballRef (watchOS) – Schiri Stoppuhr + Schritte + kcal

Dieses Repo ist so gebaut, dass es **ohne eigenen Mac** über **Codemagic** gebaut und nach **TestFlight** hochgeladen werden kann.
Du bearbeitest den Code auf Windows/iPhone, der Build läuft auf einem Cloud‑Mac.

## Was die App kann
- Große **Stoppuhr** (schwarzer Hintergrund, weiße Anzeige)
- **Schritte** + **aktive Kalorien** live via HealthKit (Workout‑Session)
- Start/Pause/Reset über große Buttons (Hardware‑Seitentaste kann von Apps nicht direkt abgefangen werden)

## Was du in Codemagic setzen musst
Lege in Codemagic → *Environment variables* diese Variablen an:

- `DEVELOPMENT_TEAM` = deine Apple Team ID (z. B. `AB12C3D4E5`)
- `BUNDLE_ID_PREFIX` = deine eindeutige Bundle‑ID‑Basis (z. B. `de.yourname.handballref`)

Die finalen Bundle IDs werden daraus:
- Container: `$(BUNDLE_ID_PREFIX)`
- Watch App: `$(BUNDLE_ID_PREFIX).watchapp`
- Watch Extension: `$(BUNDLE_ID_PREFIX).watchextension`

## App Store Connect (vor dem ersten Upload)
Bevor du den ersten Build hochlädst, musst du in App Store Connect einen App‑Record anlegen (Bundle ID = Container).
Anschließend fügst du watchOS‑Informationen hinzu.

## Projekt-Generierung
Codemagic installiert **XcodeGen** und generiert daraus ein Xcode‑Projekt aus `project.yml`.

