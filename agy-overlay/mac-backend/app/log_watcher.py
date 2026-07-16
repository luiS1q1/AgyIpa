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

def map_entry(entry: dict):
    entry_type = entry.get("type")
    
    if entry_type == "USER_INPUT":
        content = entry.get("content", "")
        if "<USER_REQUEST>" in content:
            try:
                content = content.split("<USER_REQUEST>")[1].split("</USER_REQUEST>")[0].strip()
            except Exception:
                pass
        return [{"type": "USER_INPUT", "content": content}]
        
    elif entry_type == "PLANNER_RESPONSE":
        payloads = []
        if entry.get("content"):
            payloads.append({
                "type": "ASSISTANT_RESPONSE",
                "content": entry.get("content")
            })
        if entry.get("tool_calls"):
            for tc in entry.get("tool_calls"):
                name = tc.get("name", "")
                args = tc.get("args", {})
                summary = args.get("toolSummary", "") or args.get("toolAction", "") or str(args)
                if isinstance(summary, str) and summary.startswith('"') and summary.endswith('"'):
                    summary = summary[1:-1]
                payloads.append({
                    "type": "TOOL_CALL",
                    "content": f"Rufe {name} auf: {summary}",
                    "tool": name
                })
        return payloads
        
    elif entry_type == "ERROR_MESSAGE":
        return [{
            "type": "ERROR",
            "content": entry.get("error") or "Systemfehler"
        }]
        
    elif entry_type not in ["CONVERSATION_HISTORY", "CHECKPOINT", None]:
        content = entry.get("content", "")
        if len(content) > 1000:
            content = content[:1000] + "\n... [Ausgabe gekürzt]"
        return [{
            "type": "TOOL_RESPONSE",
            "content": content or "Tool ausgeführt."
        }]
        
    return []

async def stream_log_lines(session_id: str):
    from app.main import ACTIVE_SESSIONS
    
    brain_dir_name = None
    if session_id in ACTIVE_SESSIONS:
        brain_dir_name = ACTIVE_SESSIONS[session_id].get("brain_dir_name")
        
    log_file = None
    if not brain_dir_name:
        # Snapshot the existing folders before waiting
        existing_dirs = set()
        if settings.AGY_BRAIN_DIR.exists():
            existing_dirs = {d.name for d in settings.AGY_BRAIN_DIR.iterdir() if d.is_dir()}
            
        # Loop and wait for the new directory to be created (when the first prompt is sent)
        # We poll for up to 10 minutes (1200 iterations * 0.5s), allowing the user plenty of time to write.
        for _ in range(1200):
            if settings.AGY_BRAIN_DIR.exists():
                current_dirs = {d.name for d in settings.AGY_BRAIN_DIR.iterdir() if d.is_dir()}
                new_dirs = current_dirs - existing_dirs
                if new_dirs:
                    brain_dir_name = sorted(list(new_dirs))[0]
                    if session_id in ACTIVE_SESSIONS:
                        ACTIVE_SESSIONS[session_id]["brain_dir_name"] = brain_dir_name
                    
                    candidate = settings.AGY_BRAIN_DIR / brain_dir_name / ".system_generated" / "logs" / "transcript.jsonl"
                    # Wait up to 5 seconds for the transcript file to be written
                    for _ in range(50):
                        if candidate.exists():
                            log_file = candidate
                            break
                        await asyncio.sleep(0.1)
                    if log_file:
                        break
            await asyncio.sleep(0.5)
    else:
        log_file = settings.AGY_BRAIN_DIR / brain_dir_name / ".system_generated" / "logs" / "transcript.jsonl"
        
    # If we couldn't resolve a log file, exit cleanly
    if not log_file or not log_file.exists():
        return
        
    with open(log_file, "r", encoding="utf-8") as f:
        f.seek(0)
        while True:
            line = f.readline()
            if not line:
                await asyncio.sleep(0.2)
                continue
            try:
                entry = json.loads(line.strip())
                for mapped in map_entry(entry):
                    yield mapped
            except Exception: 
                continue
