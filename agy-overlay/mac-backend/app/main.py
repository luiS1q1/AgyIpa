from fastapi import FastAPI, UploadFile, File, Form, HTTPException, WebSocket, WebSocketDisconnect
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from typing import Optional
import shutil
import logging
import asyncio
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

@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request, exc):
    try:
        form = await request.form()
        form_dict = {k: v if not isinstance(v, UploadFile) else f"<File: {v.filename}>" for k, v in form.items()}
    except Exception:
        form_dict = None
    headers = dict(request.headers)
    body_length = 0
    try:
        body = await request.body()
        body_length = len(body)
        body_snippet = body[:200]
    except Exception:
        body_snippet = None
    logging.error(f"Validation Error detail: {exc.errors()}")
    logging.error(f"Request Headers: {headers}")
    logging.error(f"Request Form fields: {form_dict}")
    logging.error(f"Request Body length: {body_length}, snippet: {body_snippet}")
    print(f"Validation Error detail: {exc.errors()}", flush=True)
    print(f"Request Headers: {headers}", flush=True)
    print(f"Request Form fields: {form_dict}", flush=True)
    print(f"Request Body length: {body_length}", flush=True)
    return JSONResponse(
        status_code=422,
        content={"detail": exc.errors()},
    )

# Statisches Verzeichnis mounten, damit Screenshots abgerufen werden können
app.mount("/storage", StaticFiles(directory=settings.BASE_DIR / "storage"), name="storage")

ACTIVE_SESSIONS = {}

@app.post("/v1/trigger")
async def trigger_assistant(session_id: str = Form(...), file: Optional[UploadFile] = File(None)):
    file_path = None
    if file is not None and file.filename:
        file_path = settings.STORAGE_DIR / f"{session_id}.png"
        try:
            with open(file_path, "wb") as b:
                shutil.copyfileobj(file.file, b)
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Fehler beim Speichern des Screenshots: {e}")
            
    if not tmux_wrapper.start_agy_session(session_id):
        raise HTTPException(status_code=500, detail="Tmux Session konnte nicht gestartet werden.")
        
    ACTIVE_SESSIONS[session_id] = {
        "current_screenshot_path": str(file_path) if file_path else "",
        "brain_dir_name": None
    }
    return {"status": "initialized"}

@app.post("/v1/send")
async def send_prompt(session_id: str = Form(...), prompt: str = Form(...)):
    if session_id not in ACTIVE_SESSIONS:
        raise HTTPException(status_code=404, detail="Session nicht gefunden.")
    
    screenshot_path = ACTIVE_SESSIONS[session_id].get("current_screenshot_path", "")
    if screenshot_path:
        p = f"Analysiere das Bild unter '{screenshot_path}'. Befehl: {prompt}"
    else:
        p = prompt
        
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
