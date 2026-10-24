"""Settings from the environment, with homer/.env (gitignored) filled in first."""

from __future__ import annotations

import os
from dataclasses import dataclass
from functools import cache
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]  # the homer/ service folder


def read_env(path: Path) -> dict[str, str]:
    """KEY=VALUE lines from an env file, skipping blanks and comments."""
    out = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if line and not line.startswith("#") and "=" in line:
            k, v = line.split("=", 1)
            out[k.strip()] = v.strip().strip("'\"")
    return out


def load_env(path: Path = ROOT / ".env") -> None:
    """Read homer/.env into os.environ without overriding what's set.

    HOMER_DOTENV=0 skips the file (the tests set it).
    """
    if os.environ.get("HOMER_DOTENV") == "0" or not path.is_file():
        return
    for k, v in read_env(path).items():
        os.environ.setdefault(k, v)


def _env(name: str, default: str = "") -> str:
    return os.environ.get(name, default).strip()


@dataclass(frozen=True)
class Settings:
    judge_model: str
    judge_effort: str  # low | medium | high
    judge_speed: str  # "" or "fast" (Opus fast mode)
    judge_thinking: str  # "off" where the model allows it, else "adaptive"
    judge_timeout: float  # seconds before Homer is silent on Craft, Image and Answer
    fallbacks: bool  # server-side refusal fallbacks where the model supports them
    model: str  # everything else Homer writes: names, round verdicts, the song, spar verses
    effort: str
    speed: str
    timeout: float
    emotion_model: str  # the classifier that colors the scene every ~1.5 s
    stdb_url: str
    stdb_db: str
    stdb_token: str
    service_key: str


@cache
def settings() -> Settings:
    load_env()
    return Settings(
        judge_model=_env("HOMER_JUDGE_MODEL", "claude-opus-5-5"),
        judge_effort=_env("HOMER_JUDGE_EFFORT", "low"),
        judge_speed=_env("HOMER_JUDGE_SPEED", "fast"),
        judge_thinking=_env("HOMER_JUDGE_THINKING", "off"),
        judge_timeout=float(_env("HOMER_JUDGE_TIMEOUT", "10")),
        fallbacks=_env("HOMER_FALLBACKS", "1") not in ("0", "false", "no"),
        model=_env("HOMER_MODEL", "claude-opus-5-5"),
        effort=_env("HOMER_EFFORT", "low"),
        speed=_env("HOMER_SPEED", "fast"),
        timeout=float(_env("HOMER_TIMEOUT", "15")),
        emotion_model=_env("HOMER_EMOTION_MODEL", "claude-haiku-5-5"),
        stdb_url=_env("STDB_URL", "http://127.0.0.1:3000").rstrip("/"),
        stdb_db=_env("STDB_DB", "homer"),
        stdb_token=_env("STDB_TOKEN"),
        service_key=_env("HOMER_SERVICE_KEY"),
    )
