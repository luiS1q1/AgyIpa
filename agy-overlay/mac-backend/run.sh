#!/bin/bash
# Installiere Abhängigkeiten, falls nötig
# pip install -r requirements.txt

# Starte den FastAPI-Server mit Uvicorn
echo "Starte FastAPI Server auf Port 8080..."
exec ./venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8080 --reload
