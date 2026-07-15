import subprocess
import time
import os

def start_agy_session(session_id: str) -> bool:
    tmux_name = f"agy_{session_id}"
    res = subprocess.run(["tmux", "has-session", "-t", tmux_name], capture_output=True)
    if res.returncode == 0: 
        return True
    try:
        agy_path = os.path.expanduser("~/.local/bin/agy")
        subprocess.run(["tmux", "new-session", "-d", "-s", tmux_name, agy_path], check=True)
        time.sleep(0.8)
        return True
    except Exception: 
        return False

def inject_text(session_id: str, text: str) -> bool:
    tmux_name = f"agy_{session_id}"
    try:
        subprocess.run(["tmux", "send-keys", "-t", tmux_name, text, "ENTER"], check=True)
        return True
    except Exception: 
        return False

def kill_session(session_id: str) -> bool:
    tmux_name = f"agy_{session_id}"
    try:
        subprocess.run(["tmux", "kill-session", "-t", tmux_name], check=True)
        return True
    except Exception: 
        return False
