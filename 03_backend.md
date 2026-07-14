# 03. Mac Backend

### requirements.txt
fastapi==0.110.0
uvicorn==0.28.0
watchdog==4.0.0
websockets==12.0
python-multipart==0.0.9

### app/config.py
import os
from pathlib import Path
class Settings:
    AGY_BRAIN_DIR: Path = Path(os.path.expanduser("~/.gemini/antigravity-cli/brain"))
    BASE_DIR: Path = Path(__file__).resolve().parent.parent
    STORAGE_DIR: Path = BASE_DIR / "storage" / "screenshots"
    def __init__(self):
        os.makedirs(self.STORAGE_DIR, exist_ok=True)
settings = Settings()

### app/tmux_wrapper.py
import subprocess
import time
def start_agy_session(session_id: str) -> bool:
    tmux_name = f"agy_{session_id}"
    res = subprocess.run(["tmux", "has-session", "-t", tmux_name], capture_output=True)
    if res.returncode == 0: return True
    try:
        subprocess.run(["tmux", "new-session", "-d", "-s", tmux_name, "agy"], check=True)
        time.sleep(0.8)
        return True
    except: return False
def inject_text(session_id: str, text: str) -> bool:
    tmux_name = f"agy_{session_id}"
    try:
        subprocess.run(["tmux", "send-keys", "-t", tmux_name, text, "ENTER"], check=True)
        return True
    except: return False
def kill_session(session_id: str) -> bool:
    tmux_name = f"agy_{session_id}"
    try:
        subprocess.run(["tmux", "kill-session", "-t", tmux_name], check=True)
        return True
    except: return False

### app/log_watcher.py
import os, json, asyncio
from pathlib import Path
from app.config import settings
def get_latest_session_directory() -> Path:
    brain_dir = settings.AGY_BRAIN_DIR
    subdirs = [d for d in brain_dir.iterdir() if d.is_dir()]
    subdirs.sort(key=lambda x: x.stat().st_mtime, reverse=True)
    return subdirs[0]
async def stream_log_lines(session_id: str):
    for _ in range(30):
        try:
            log_file = get_latest_session_directory() / ".system_generated" / "logs" / "transcript.jsonl"
            if log_file.exists(): break
        except: pass
        await asyncio.sleep(0.2)
    else: return
    log_file = get_latest_session_directory() / ".system_generated" / "logs" / "transcript.jsonl"
    with open(log_file, "r", encoding="utf-8") as f:
        f.seek(0, os.SEEK_END)
        while True:
            line = f.readline()
            if not line:
                await asyncio.sleep(0.1)
                continue
            try: yield json.loads(line.strip())
            except: continue

### app/main.py
from fastapi import FastAPI, UploadFile, File, Form, HTTPException, WebSocket, WebSocketDisconnect
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
import shutil
from app.config import settings
from app import tmux_wrapper
from app.log_watcher import stream_log_lines

app = FastAPI()
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_credentials=True, allow_methods=["*"], allow_headers=["*"])
app.mount("/storage", StaticFiles(directory=settings.BASE_DIR / "storage"), name="storage")
ACTIVE_SESSIONS = {}

@app.post("/v1/trigger")
async def trigger_assistant(session_id: str = Form(...), file: UploadFile = File(...)):
    file_path = settings.STORAGE_DIR / f"{session_id}.png"
    with open(file_path, "wb") as b: shutil.copyfileobj(file.file, b)
    if not tmux_wrapper.start_agy_session(session_id): raise HTTPException(status_code=500)
    ACTIVE_SESSIONS[session_id] = {"current_screenshot_path": str(file_path)}
    return {"status": "initialized"}

@app.post("/v1/send")
async def send_prompt(session_id: str = Form(...), prompt: str = Form(...)):
    if session_id not in ACTIVE_SESSIONS: raise HTTPException(status_code=404)
    p = f"Analysiere das Bild unter '{ACTIVE_SESSIONS[session_id]['current_screenshot_path']}'. Befehl: {prompt}"
    tmux_wrapper.inject_text(session_id, p)
    return {"status": "sent"}

@app.websocket("/v1/stream/{session_id}")
async def websocket_endpoint(websocket: WebSocket, session_id: str):
    await websocket.accept()
    try:
        async for entry in stream_log_lines(session_id):
            if entry.get("type") in ["USER_INPUT", "ASSISTANT_RESPONSE", "TOOL_CALL", "TOOL_RESPONSE", "ERROR"]:
                await websocket.send_json(entry)
    except WebSocketDisconnect:
        tmux_wrapper.kill_session(session_id)
        ACTIVE_SESSIONS.pop(session_id, None)
