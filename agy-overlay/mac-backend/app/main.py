from fastapi import FastAPI, UploadFile, File, Form, HTTPException, WebSocket, WebSocketDisconnect
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
import shutil
from app.config import settings
from app import tmux_wrapper
from app.log_watcher import stream_log_lines

app = FastAPI()

# CORS Middleware aktivieren
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Statisches Verzeichnis mounten, damit Screenshots abgerufen werden können
app.mount("/storage", StaticFiles(directory=settings.BASE_DIR / "storage"), name="storage")

ACTIVE_SESSIONS = {}

@app.post("/v1/trigger")
async def trigger_assistant(session_id: str = Form(...), file: UploadFile = File(...)):
    file_path = settings.STORAGE_DIR / f"{session_id}.png"
    try:
        with open(file_path, "wb") as b:
            shutil.copyfileobj(file.file, b)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Fehler beim Speichern des Screenshots: {e}")
        
    if not tmux_wrapper.start_agy_session(session_id):
        raise HTTPException(status_code=500, detail="Tmux Session konnte nicht gestartet werden.")
        
    ACTIVE_SESSIONS[session_id] = {"current_screenshot_path": str(file_path)}
    return {"status": "initialized"}

@app.post("/v1/send")
async def send_prompt(session_id: str = Form(...), prompt: str = Form(...)):
    if session_id not in ACTIVE_SESSIONS:
        raise HTTPException(status_code=404, detail="Session nicht gefunden.")
    p = f"Analysiere das Bild unter '{ACTIVE_SESSIONS[session_id]['current_screenshot_path']}'. Befehl: {prompt}"
    if not tmux_wrapper.inject_text(session_id, p):
        raise HTTPException(status_code=500, detail="Text konnte nicht injiziert werden.")
    return {"status": "sent"}

@app.websocket("/v1/stream/{session_id}")
async def websocket_endpoint(websocket: WebSocket, session_id: str):
    await websocket.accept()
    try:
        async for entry in stream_log_lines(session_id):
            if entry.get("type") in ["USER_INPUT", "ASSISTANT_RESPONSE", "TOOL_CALL", "TOOL_RESPONSE", "ERROR"]:
                await websocket.send_json(entry)
    except WebSocketDisconnect:
        pass
    finally:
        tmux_wrapper.kill_session(session_id)
        ACTIVE_SESSIONS.pop(session_id, None)
