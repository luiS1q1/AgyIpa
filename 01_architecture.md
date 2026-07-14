# 01. Architektur
Tech-Stack: FastAPI, Tmux, uvicorn, SwiftUI, Apple Shortcuts

Verzeichnisstruktur:
agy-overlay/
├── mac-backend/
│   ├── app/
│   │   ├── __init__.py
│   │   ├── main.py
│   │   ├── config.py
│   │   ├── tmux_wrapper.py
│   │   └── log_watcher.py
│   ├── storage/
│   │   └── screenshots/
│   ├── requirements.txt
│   └── run.sh
└── ios-app/
    ├── agy-overlay/
    │   ├── agy_overlayApp.swift
    │   ├── Info.plist
    │   ├── Models/
    │   │   └── AppState.swift
    │   ├── Views/
    │   │   ├── MainOverlayView.swift
    │   │   └── Components/
    │   │       ├── FloatingTextBox.swift
    │   │       └── TranscriptStreamView.swift
    │   └── Services/
    │       └── WebSocketManager.swift
    └── agy-overlay.xcodeproj
