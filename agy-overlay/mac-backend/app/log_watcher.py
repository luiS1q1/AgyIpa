import os
import json
import asyncio
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
            if log_file.exists(): 
                break
        except Exception: 
            pass
        await asyncio.sleep(0.2)
    else: 
        return
    
    log_file = get_latest_session_directory() / ".system_generated" / "logs" / "transcript.jsonl"
    with open(log_file, "r", encoding="utf-8") as f:
        f.seek(0, os.SEEK_END)
        while True:
            line = f.readline()
            if not line:
                await asyncio.sleep(0.1)
                continue
            try: 
                yield json.loads(line.strip())
            except Exception: 
                continue
