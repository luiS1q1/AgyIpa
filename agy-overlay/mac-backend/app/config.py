import os
from pathlib import Path

class Settings:
    AGY_BRAIN_DIR: Path = Path(os.path.expanduser("~/.gemini/antigravity-cli/brain"))
    BASE_DIR: Path = Path(__file__).resolve().parent.parent
    STORAGE_DIR: Path = BASE_DIR / "storage" / "screenshots"
    
    def __init__(self):
        os.makedirs(self.STORAGE_DIR, exist_ok=True)

settings = Settings()
