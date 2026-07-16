# Status Log: Antigravity iOS Overlay Assistant (AGY IPA)

Dieses Dokument dient der Protokollierung des aktuellen Entwicklungsstands, der implementierten Features sowie wichtiger Randbedingungen und Hinweise für das Projekt.

---

## 1. Aktueller Status

### Verzeichnisstruktur & Dateien
* **Projekt-Wurzelverzeichnis**: `G:\Meine Ablage\projects\agyipa`
* [x] **Spezifikationsdokumente** (bereitgestellt vom User):
  * [README](file:///G:/Meine%20Ablage/projects/agyipa/00_README.md)
  * [Architektur](file:///G:/Meine%20Ablage/projects/agyipa/01_architecture.md)
  * [Datenmodell](file:///G:/Meine%20Ablage/projects/agyipa/02_datamodel.md)
  * [Backend-Spezifikation](file:///G:/Meine%20Ablage/projects/agyipa/03_backend.md)
  * [iOS-App-Spezifikation](file:///G:/Meine%20Ablage/projects/agyipa/04_ios_app.md)
  * [Shortcut-Anleitung](file:///G:/Meine%20Ablage/projects/agyipa/05_shortcut.md)
* [x] **Codebase (`agy-overlay/`)**: Erstellt und initialisiert.
  * **Mac Backend**:
    * [requirements.txt](file:///G:/Meine%20Ablage/projects/agyipa/agy-overlay/mac-backend/requirements.txt) - Python dependencies
    * [config.py](file:///G:/Meine%20Ablage/projects/agyipa/agy-overlay/mac-backend/app/config.py) - Einstellungen & Pfade
    * [tmux_wrapper.py](file:///G:/Meine%20Ablage/projects/agyipa/agy-overlay/mac-backend/app/tmux_wrapper.py) - Tmux Control-Interface
    * [log_watcher.py](file:///G:/Meine%20Ablage/projects/agyipa/agy-overlay/mac-backend/app/log_watcher.py) - JSONL Transcript Streamer
    * [main.py](file:///G:/Meine%20Ablage/projects/agyipa/agy-overlay/mac-backend/app/main.py) - FastAPI API & WebSocket Endpunkte
    * [run.sh](file:///G:/Meine%20Ablage/projects/agyipa/agy-overlay/mac-backend/run.sh) - Startskript
  * **iOS SwiftUI App & Build Tooling**:
    * [Message.swift](file:///G:/Meine%20Ablage/projects/agyipa/agy-overlay/ios-app/agy-overlay/Models/Message.swift) - Datenmodell für Log-Messages
    * [AppState.swift](file:///G:/Meine%20Ablage/projects/agyipa/agy-overlay/ios-app/agy-overlay/Models/AppState.swift) - Globaler App-Zustand
    * [WebSocketManager.swift](file:///G:/Meine%20Ablage/projects/agyipa/agy-overlay/ios-app/agy-overlay/Services/WebSocketManager.swift) - WebSocket Verbindung & Parser
    * [TranscriptStreamView.swift](file:///G:/Meine%20Ablage/projects/agyipa/agy-overlay/ios-app/agy-overlay/Views/Components/TranscriptStreamView.swift) - Scrollbare Live-Log-Liste
    * [FloatingTextBox.swift](file:///G:/Meine%20Ablage/projects/agyipa/agy-overlay/ios-app/agy-overlay/Views/Components/FloatingTextBox.swift) - Prompt Input & Server POST-Sender
    * [MainOverlayView.swift](file:///G:/Meine%20Ablage/projects/agyipa/agy-overlay/ios-app/agy-overlay/Views/MainOverlayView.swift) - Screenshot-Hintergrund, Blur & Steuerung
    * [agy_overlayApp.swift](file:///G:/Meine%20Ablage/projects/agyipa/agy-overlay/ios-app/agy-overlay/agy_overlayApp.swift) - App-Einstiegspunkt
    * [Info.plist](file:///G:/Meine%20Ablage/projects/agyipa/agy-overlay/ios-app/agy-overlay/Info.plist) - Custom URL Scheme `myassistant` & ATS-Freigaben
    * [project.yml](file:///G:/Meine%20Ablage/projects/agyipa/agy-overlay/ios-app/project.yml) - XcodeGen Projektbeschreibung
    * [.gitignore](file:///G:/Meine%20Ablage/projects/agyipa/.gitignore) - Git Ignore-Regeln (ignoriert generierte Xcode-Dateien)
    * [build-ios.yml](file:///G:/Meine%20Ablage/projects/agyipa/.github/workflows/build-ios.yml) - GitHub Actions CI/CD für Unsigned IPA Build


---

## 2. Zu implementierende Features

### Mac Backend (Python / FastAPI)
- **Session-Management (`tmux`)**:
  - Dynamisches Starten einer tmux-Session (`agy_[session_id]`) mit dem Befehl `agy`.
  - Senden/Injektion von Tastenanschlägen in die tmux-Session.
  - Automatisches Beenden/Killen der tmux-Session bei Verbindungsabbruch.
- **Log Watcher**:
  - Echtzeit-Überwachung der Logdatei `transcript.jsonl` im neuesten Unterverzeichnis von `~/.gemini/antigravity-cli/brain`.
  - Streaming der Log-Einträge via WebSocket an die iOS-App.
- **REST-Endpunkte**:
  - `POST /v1/trigger`: Empfängt Screenshot, speichert ihn unter `storage/screenshots/{session_id}.png` und startet die tmux-Session.
  - `POST /v1/send`: Sendet Prompt an die aktive tmux-Session (inklusive Bild-Referenz).
- **WebSocket-Endpunkt**:
  - `WS /v1/stream/{session_id}`: Streamt Log-Events (`USER_INPUT`, `ASSISTANT_RESPONSE`, etc.) live.

### iOS App (SwiftUI)
- **Deep-Link Integration**:
  - Öffnen der App via Custom-URL-Scheme `myassistant://task?id=[session_id]`.
- **Benutzeroberfläche (Overlay)**:
  - Hintergrundbild: Anzeige des empfangenen/abgerufenen Screenshots.
  - Ultra-thin Material (Glasmorphismus-Effekt) über dem Screenshot.
  - `TranscriptStreamView`: Live-Chat-Ansicht mit Nachrichtenstrom (User, Assistant, Tool-Calls, Errors).
  - `FloatingTextBox`: Inputfeld zur Eingabe von Prompts und Button zum Senden.
- **WebSocket-Client**:
  - Live-Verbindung zum Mac-Backend für asynchronen Datenempfang und UI-Updates.

---

## 3. Wichtige Randbedingungen & Beachtenswertes

> [!IMPORTANT]
> **Betriebssystem-Einschränkungen**:
> Das Backend steuert `tmux` und liest lokale Pfade von `~/.gemini/antigravity-cli/brain` aus. Es ist primär für die Ausführung auf macOS konzipiert.

> [!WARNING]
> **Netzwerkkonfiguration**:
> Die iOS-App nutzt eine fest hinterlegte IP-Adresse (`192.168.178.50`). Für Tests und den Produktiveinsatz muss sichergestellt sein, dass sich beide Geräte im selben WLAN befinden und die IP übereinstimmt (ggf. dynamisch konfigurierbar machen).

> [!NOTE]
> **Log-Verzeichnis-Erkennung**:
> `log_watcher.py` sucht nach dem zeitlich neuesten Ordner in `settings.AGY_BRAIN_DIR` (`~/.gemini/antigravity-cli/brain`). Wenn keine Session vorhanden ist oder Pfade abweichen, kann das Streaming fehlschlagen.

---

## 4. Nächste Schritte & Testen (Kompilierung über GitHub)

1. **Mac Backend auf deinem Server starten**:
   - Stelle sicher, dass du Python installiert hast.
   - Installiere die Abhängigkeiten aus [requirements.txt](file:///G:/Meine%20Ablage/projects/agyipa/agy-overlay/mac-backend/requirements.txt) (`pip install -r requirements.txt`).
   - Starte den Server über [run.sh](file:///G:/Meine%20Ablage/projects/agyipa/agy-overlay/mac-backend/run.sh) oder direkt mit `uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload`.

2. **iOS App über GitHub Actions kompilieren**:
   - Committe und pushe das gesamte Repository auf GitHub.
   - Der GitHub Actions Workflow [build-ios.yml](file:///G:/Meine%20Ablage/projects/agyipa/.github/workflows/build-ios.yml) wird automatisch gestartet.
   - Er installiert `xcodegen`, generiert das Xcode-Projekt auf einem macOS-Runner und baut eine unsignierte `.ipa` Datei (`agy-overlay.ipa`).
   - Lade das fertige Build-Artefakt `agy-overlay-ipa` aus der Zusammenfassung des GitHub-Action-Runs herunter.

3. **App auf dem iOS-Gerät installieren (Sideloading)**:
   - Da die `.ipa` unsigniert ist, kannst du sie über Sideloading-Tools wie **AltStore**, **SideStore** oder **Sideloadly** auf deinem iPhone/iPad installieren. Diese Tools signieren die App während der Installation mit deiner Apple-ID.

4. **Apple Shortcut einrichten**:
   - Shortcut wie in [05_shortcut.md](file:///G:/Meine%20Ablage/projects/agyipa/05_shortcut.md) beschrieben erstellen.
   - *Hinweis:* Vergiss nicht, die IP-Adresse deines Servers in [AppState.swift](file:///G:/Meine%20Ablage/projects/agyipa/agy-overlay/ios-app/agy-overlay/Models/AppState.swift) anzupassen, bevor du den Code auf GitHub pushst!

---

## 5. Änderungshistorie & Fehlerbehebung (CI/CD)

* **Build-Fix #1 (Xcode-Format-Konflikt)**: Anheben des GitHub Runners auf `macos-15` (Xcode 16.4), um das von XcodeGen erzeugte Xcode-Projektformat 77 öffnen zu können.
* **Build-Fix #2 (Ad-Hoc Signing auf iOS 18.5 SDK)**: Deaktivieren des Ad-Hoc Signings (`CODE_SIGNING_ALLOWED=NO`), da dieses im iOS 18.5 SDK ohne Developer Team ungültig ist.
* **Build-Fix #3 (SwiftUI-Compiler-Fehler)**: Ersetzen der fehlerhaften UIKit-Zuweisungen in `VisualEffectBlur` und Portierung auf natives SwiftUI `.ultraThinMaterial` in [FloatingTextBox.swift](file:///G:/Meine%20Ablage/projects/agyipa/agy-overlay/ios-app/agy-overlay/Views/Components/FloatingTextBox.swift).
* **Build-Fix #4 (Missing Bundle Identifier)**: Ergänzen der Standard-App-Metadaten-Keys (z.B. `CFBundleIdentifier`, `CFBundleExecutable` etc.) in [Info.plist](file:///G:/Meine%20Ablage/projects/agyipa/agy-overlay/ios-app/agy-overlay/Info.plist), um den `xcodebuild` Archivierungsfehler *"Archive Missing Bundle Identifier"* zu beheben.
* **Build-Fix #5 (Sideloading "Invalid file" Fehler)**: Hinzufügen des Parameters `-y` zum `zip`-Befehl beim Verpacken der `.ipa`. Damit werden symbolische Verknüpfungen (Symlinks) innerhalb des App-Bundles erhalten, die andernfalls zerstört werden und die Installation via Sideloadly mit *"Invalid file"* fehlschlagen lassen.
* **Build-Fix #6 (Port-Konflikt gelöst)**: Ändern des Backend-Ports von 8000 auf 8080, da Port 8000 auf dem Server durch eine andere Anwendung belegt war.
* **Build-Fix #7 (Absoluter Pfad für agy)**: Verwenden des absoluten Pfads `~/.local/bin/agy` beim Starten der tmux-Sitzung, da der Pfad in der nicht-interaktiven SSH-Umgebung gefehlt hat.
* **Build-Fix #8 (Lokale Netzwerkberechtigung)**: Ergänzen von `NSLocalNetworkUsageDescription` in der `Info.plist`, um lokalen Netzwerkzugriff (WebSockets & Screenshots) auf iOS zu erlauben.
* **Build-Fix #9 (Protokoll-Mapping & Chat-Verlauf)**: Umschreiben von `log_watcher.py`, um die Rohdaten der `.jsonl`-Logs in das von der iOS-App erwartete Format zu übersetzen und den gesamten bisherigen Chat-Verlauf bei Verbindungsaufbau zu übertragen.
