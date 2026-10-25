"""The Devpost video's rough cut, assembled from the night shoot (docs/gtm/video.md, "The Devpost video (3:00)").

Matus polishes it in CapCut in the morning; this gets every cut, card, line and level in place first. The shoot's
files land in ~/Movies/MeNIN-video/raw/ (ingest moves them from ~/Downloads); the battle's events come from the take
log (docs/video/timeline-take.log, spacetime's `npm run timeline` with LOG), stamped on this Mac's clock like its
own ⌘⇧5 recording, so a moment is found by its event, not by eye.

    python3 rough_cut.py ingest --since 02:20     # move the shoot's files out of ~/Downloads (by time)
    python3 rough_cut.py probe                     # classify, sync (clap, creation time, a visual event), contact sheets
    python3 rough_cut.py plan                      # the cut list from the take: work/cuts.json and out/cuts.csv
    python3 rough_cut.py build                     # out/rough-cut-v1.mp4 (2:59), rough-cut-2min.mp4, cuts.csv, cuts.edl
    python3 rough_cut.py backup                    # out/menin-backup-90s.mp4: the battle, the room's sound, trimmed only

Hand fixes go in work/overrides.json (clip start times, the laptop crop, any cut's source or in-point); plan and
build read it. One encode at a time. Needs ffmpeg/ffprobe; HDR iPhone clips go through macOS avconvert to SDR.
"""

from __future__ import annotations

import json
import math
import re
import shutil
import statistics
import subprocess
import sys
import time
import urllib.request
from datetime import datetime
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
HOME = Path.home() / "Movies/MeNIN-video"
RAW, WORK, OUT = HOME / "raw", HOME / "work", HOME / "out"
DOCS = REPO / "docs/video"
VO, CARDS, BROLL = DOCS / "vo", DOCS / "cards", DOCS / "broll"
SCRIPT = REPO / "docs/gtm/video.md"
TAKE_LOG = DOCS / "timeline-take.log"
THEME = REPO / "homer/web/public/audio/menin-theme.m4a"
THEME_HIT = 0.03  # the theme's first hit, in the trimmed master (v3; it was 59.83 s before the trim)
THEME_AT = 16.0  # where the hit lands in the video (C1)
SQL = "https://maincloud.spacetimedb.com/v1/database/homer-calhacks/sql"

W, H, FPS = 1920, 1080, 30
LENGTH, CARTESIA = 179.0, 120.0  # 2:59 at most; the first 2:00 stands alone
COUNT_IN = 2.25  # start_turn to SPEAK (spacetime POETRY_COUNT_IN_MICROS)
MEDIA = {".mov", ".mp4", ".m4v", ".m4a", ".wav", ".aac", ".caf", ".mp3"}

# The grade (video.md "The look"): cream highlights, lifted blacks, saturation down ~20%, light grain.
GRADE = ("curves=master='0/0.05 0.5/0.51 1/0.96',colorbalance=rh=0.03:gh=0.015:bh=-0.035,"
         "eq=saturation=0.8,noise=alls=5:allf=t")
DESAT = "eq=saturation=0.45"  # website footage: cropped and desaturated

# Narration (video.md (a)): the file, where it starts in the video, and how much of it plays.
# Narration (video.md (a), re-timed at deebba2): line A is cut (M2 names the community). Line 4 is out of this pass:
# in the take Homer talks live from every verdict into the next step, and 1:12-1:21 is now Matus's M3.
NARRATION = [("vo-00-greek.wav", 0.0, 2.5), ("vo-06.wav", 87.1, None), ("vo-07.wav", 93.7, None),
             ("vo-08.wav", 120.6, None), ("vo-09.wav", 135.0, None), ("vo-10.wav", 172.0, None)]


# ----- small helpers ------------------------------------------------------------------------------------------------

def run(cmd: list[str], quiet: bool = True) -> str:
    out = subprocess.run(cmd, capture_output=True, text=True)
    if out.returncode:
        raise RuntimeError(f"{cmd[0]} failed ({out.returncode}): {out.stderr[-1500:]}")
    return out.stdout if quiet else out.stdout + out.stderr


def ff(*args: str) -> None:
    run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", *args])


def probe(path: Path) -> dict:
    return json.loads(run(["ffprobe", "-v", "error", "-print_format", "json", "-show_format", "-show_streams", str(path)]))


def load(path: Path, default):
    return json.loads(path.read_text()) if path.exists() else default


def save(path: Path, data) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=1, ensure_ascii=False))


def overrides() -> dict:
    return load(WORK / "overrides.json", {})


def clock(s: float) -> str:
    return f"{int(s // 60)}:{s % 60:05.2f}"


def tc(s: float) -> str:  # EDL timecode at FPS, non-drop
    f = round(s * FPS)
    return f"{f // (3600 * FPS):02d}:{f // (60 * FPS) % 60:02d}:{f // FPS % 60:02d}:{f % FPS:02d}"


# ----- ingest -------------------------------------------------------------------------------------------------------

def ingest(since: str) -> None:
    """Move the shoot's media (modified at or after `since`, HH:MM today) from ~/Downloads to raw/."""
    today = datetime.now().strftime("%Y-%m-%d")
    cutoff = datetime.strptime(f"{today} {since}", "%Y-%m-%d %H:%M").timestamp()
    RAW.mkdir(parents=True, exist_ok=True)
    # The Mac's own ⌘⇧5 recording saves to the Desktop: linked, not moved (Matus finds it where he left it).
    for f in sorted((Path.home() / "Desktop").glob("Screen Recording*")):
        if f.suffix.lower() in MEDIA and f.stat().st_mtime >= cutoff and not (RAW / f.name).exists():
            (RAW / f.name).symlink_to(f)
            print(f"linked Desktop/{f.name} -> raw/{f.name}")
    for f in sorted((Path.home() / "Downloads").iterdir()):
        if f.suffix.lower() in MEDIA and f.stat().st_mtime >= cutoff:
            dest = RAW / f.name
            n = 1
            while dest.exists():
                dest = RAW / f"{f.stem}-{n}{f.suffix}"
                n += 1
            shutil.move(str(f), dest)
            print(f"moved {f.name} -> raw/{dest.name}")


# ----- probe: classify, sync, contact sheets -------------------------------------------------------------------------

def created(meta: dict) -> float | None:
    tags = {k.lower(): v for k, v in (meta.get("format", {}).get("tags") or {}).items()}
    for key in ("com.apple.quicktime.creationdate", "creation_time"):
        v = tags.get(key)
        if v:
            try:
                return datetime.fromisoformat(v.replace("Z", "+00:00")).timestamp()
            except ValueError:
                continue
    return None


def clap(path: Path, within: float = 240.0) -> float | None:
    """The loudest sharp transient in the first `within` s: 10 ms peaks against the 0.5 s before them."""
    out = run(["ffmpeg", "-hide_banner", "-t", str(within), "-i", str(path), "-vn", "-af",
               "aresample=48000,asetnsamples=n=480:p=0,astats=metadata=1:reset=1,"
               "ametadata=print:key=lavfi.astats.Overall.Peak_level:file=-", "-f", "null", "-"])
    peaks = [float(v) if v != "-inf" else -120.0 for v in re.findall(r"Peak_level=(-?[\d.]+|-inf)", out)]
    best, at = 0.0, None
    for i in range(50, len(peaks)):
        rise = peaks[i] - statistics.median(peaks[i - 50:i])
        if peaks[i] > -12 and rise > best:
            best, at = rise, i * 0.01
    return at if best >= 20 else None


def classify(clips: list[dict]) -> None:
    """mac (⌘⇧5, landscape, no camera), phone (portrait screen recordings), wide (the longest camera clip over the
    battle), montage (the other cameras), slomo (100+ fps), memo (audio only). Hand-off names win when present."""
    for c in clips:
        n = c["name"].lower()
        if not c["video"]:
            c["kind"] = "memo"
        elif "battle-mac" in n:
            c["kind"] = "mac"
        elif "battle-phone" in n:
            c["kind"] = "phone"
        elif "battle-wide" in n:
            c["kind"] = "wide"
        elif "figma" in n:
            c["kind"] = "figma"
        elif c["fps"] >= 100:
            c["kind"] = "slomo"
        elif c["h"] > c["w"]:
            c["kind"] = "phone"
        elif c["camera"] or c["w"] < 2500:  # a Photos export can drop the camera tags; ⌘⇧5 here is 3420 wide
            c["kind"] = "camera"
        else:
            c["kind"] = "mac"
    if not any(c["kind"] == "wide" for c in clips):
        cams = [c for c in clips if c["kind"] == "camera" and c["audio"]]
        if cams:
            max(cams, key=lambda c: c["dur"])["kind"] = "wide"
    for c in clips:
        if c["kind"] == "camera":
            c["kind"] = "montage"


def probe_all() -> list[dict]:
    clips = []
    for f in sorted(RAW.iterdir()):
        if f.suffix.lower() not in MEDIA:
            continue
        meta = probe(f)
        v = next((s for s in meta["streams"] if s["codec_type"] == "video"), None)
        a = next((s for s in meta["streams"] if s["codec_type"] == "audio"), None)
        w, h, rot = (v or {}).get("width", 0), (v or {}).get("height", 0), 0
        for sd in (v or {}).get("side_data_list", []):
            rot = int(sd.get("rotation", 0) or 0)
        if abs(rot) in (90, 270):
            w, h = h, w
        num, den = ((v or {}).get("avg_frame_rate") or "0/1").split("/")
        tags = {k.lower() for k in (meta.get("format", {}).get("tags") or {})}
        c = {"name": f.name, "path": str(f), "dur": float(meta["format"].get("duration", 0)), "w": w, "h": h,
             "fps": round(float(num) / float(den or 1), 2) if v else 0, "video": v is not None, "audio": a is not None,
             "hdr": (v or {}).get("color_transfer") in ("arib-std-b67", "smpte2084"),
             "camera": "com.apple.quicktime.make" in tags, "created": created(meta)}
        clips.append(c)
    classify(clips)
    for c in clips:
        c["src"] = c["path"]  # an HDR clip gets its SDR copy when its picture is first used (picture())
        c["clap"] = clap(Path(c["path"])) if c["audio"] and c["kind"] in ("wide", "phone", "mac") else None
    sync(clips)
    if "--fast" not in sys.argv:
        sheets(clips)
    save(WORK / "clips.json", clips)
    for c in clips:
        print(f"{c['kind']:8} {c['name']:44} {c['dur']:7.1f} s {c['w']}x{c['h']} {c['fps']} fps"
              f"{' audio' if c['audio'] else ''}{' HDR' if c['hdr'] else ''} start={c.get('start')} clap={c['clap']}")
    return clips


def sync(clips: list[dict]) -> None:
    """Each clip's start on this Mac's clock (the take log's): the wide's creation time, then every clip that heard the
    clap moved onto the wide by it; the ⌘⇧5 picture by its own creation time (the same clock), refined on the first
    3-2-1 (the biggest picture change within 3 s of it). overrides.json "start" wins."""
    wide = next((c for c in clips if c["kind"] == "wide"), None)
    for c in clips:
        c["start"] = c["created"]
    if wide and wide["clap"] is not None:
        for c in clips:
            if c is not wide and c["clap"] is not None and c["kind"] in ("phone", "mac"):
                c["start"] = wide["start"] + wide["clap"] - c["clap"]
    for c in clips:  # a phone recording re-saved by Messages carries the transfer's date: line it up by sound
        if wide and c["kind"] == "phone" and c["audio"] and c["clap"] is None and wide.get("start"):
            found = audio_offset(wide, c)
            if found:
                c["start"], c["synced"] = wide["start"] + found[0], f"room sound (r={found[1]:.2f})"
    take = load_take()
    for c in clips:  # still unplaced (a silent screen recording with a re-saved date): line it up by its picture
        if take and c["kind"] == "phone" and not c.get("synced"):
            found = visual_offset(c, take)
            if found:
                c["start"], c["synced"] = found[0], f"screen changes ({found[1]} events)"
    first = next((e for e in take["events"] if e["reducer"] == "start_turn"), None) if take else None
    for c in clips:
        if c["kind"] == "mac" and first and c["start"] and 0 < first["t"] - c["start"] < c["dur"]:
            guess = first["t"] - c["start"]
            change = biggest_change(Path(c["src"]), guess - 3, 6)
            if change is not None:
                c["start"] = first["t"] - change
                c["synced"] = "first 3-2-1"
    for name, start in overrides().get("start", {}).items():
        for c in clips:
            if c["name"] == name:
                c["start"] = start
                c["synced"] = "override"


def loudness_track(path: str, hop: float) -> list[float]:
    """The clip's loudness (dB, floored at -60) every `hop` seconds, mono."""
    out = run(["ffmpeg", "-hide_banner", "-i", path, "-vn", "-af",
               f"aresample=16000,aformat=channel_layouts=mono,asetnsamples=n={int(16000 * hop)}:p=0,"
               "astats=metadata=1:reset=1,ametadata=print:key=lavfi.astats.Overall.RMS_level:file=-", "-f", "null", "-"])
    return [max(-60.0, float(v)) if v != "-inf" else -60.0 for v in re.findall(r"RMS_level=(-?[\d.]+|-inf)", out)]


def lag(a: list[float], b: list[float], lo: int, hi: int, least: int) -> tuple[int, float]:
    """The shift d (in samples) that best lines b up under a (b[j] ~ a[j + d]), by normalised correlation."""
    def norm(x):
        m = sum(x) / len(x)
        sd = (sum((v - m) ** 2 for v in x) / len(x)) ** 0.5 or 1.0
        return [(v - m) / sd for v in x]
    a, b = norm(a), norm(b)
    best = (0, -9.0)
    for d in range(lo, hi + 1):
        j0, j1 = max(0, -d), min(len(b), len(a) - d)
        if j1 - j0 < least:
            continue
        score = sum(a[j + d] * b[j] for j in range(j0, j1)) / (j1 - j0)
        if score > best[1]:
            best = (d, score)
    return best


def audio_offset(ref: dict, clip: dict) -> tuple[float, float] | None:
    """Where `clip` starts on `ref`'s clock (seconds after ref's start), from their room sound: coarse at 0.1 s over
    +/-150 s, then 0.02 s around it. Returns (offset, correlation) or None when they don't share enough sound."""
    a, b = loudness_track(ref["src"], 0.1), loudness_track(clip["src"], 0.1)
    if len(a) < 200 or len(b) < 200:
        return None
    d, score = lag(a, b, -1500, 1500, 200)
    if score < 0.3:
        return None
    a2, b2 = loudness_track(ref["src"], 0.02), loudness_track(clip["src"], 0.02)
    d2, score2 = lag(a2, b2, d * 5 - 15, d * 5 + 15, 1000)
    return d2 * 0.02, score2


def changes(path: str, threshold: float = 0.12) -> list[float]:
    """The times of the picture's big changes (a screen swapping), whole clip."""
    out = run(["ffmpeg", "-hide_banner", "-i", path, "-an", "-vf",
               f"scale=160:-2,select='gt(scene,{threshold})',metadata=print:key=lavfi.scene_score", "-f", "null", "-"],
              quiet=False)
    return [float(t) for t in re.findall(r"pts_time:([\d.]+)", out)]


def visual_offset(clip: dict, take: dict) -> tuple[float, int] | None:
    """Where a screen recording starts on the take's clock, from its picture: the start that lines the most of its
    screen changes up (within 0.3 s) with the battle's events (3-2-1, SPEAK, each close, score and advance)."""
    marks = []
    for e in take["events"]:
        if e["reducer"] in ("start_turn", "end_turn", "turn_timeout", "post_score", "advance", "start_battle"):
            marks.append(e["t"])
            if e["reducer"] == "start_turn":
                marks.append(e["t"] + COUNT_IN)
    seen = changes(clip["src"])
    if len(seen) < 4 or len(marks) < 4:
        return None
    best = (None, 0)
    lo, hi = take["created"] - 90.0, take["created"] + 90.0
    start = lo
    while start <= hi:
        hits = sum(1 for m in marks if any(abs((m - start) - c) <= 0.3 for c in seen))
        if hits > best[1]:
            best = (start, hits)
        start += 0.05
    return best if best[0] is not None and best[1] >= 4 else None


def biggest_change(path: Path, at: float, span: float) -> float | None:
    """The time of the strongest picture change (a panel swapping, not the sea's drift: scene > 0.1) in [at, at+span]."""
    if at < 0:
        span, at = span + at, 0.0
    out = run(["ffmpeg", "-hide_banner", "-ss", f"{at:.2f}", "-t", f"{span:.2f}", "-i", str(path), "-an",
               "-vf", "scale=480:-2,select='gt(scene,0.1)',metadata=print:key=lavfi.scene_score", "-f", "null", "-"],
              quiet=False)
    hits = re.findall(r"pts_time:([\d.]+)\s*\n.*?lavfi\.scene_score=([\d.]+)", out)
    if not hits:
        return None
    t, score = max(((float(a), float(b)) for a, b in hits), key=lambda h: h[1])
    return at + t


def picture(c: dict) -> str:
    """The clip to read pictures from: an HDR iPhone clip through macOS avconvert to SDR (once, cached)."""
    if not c.get("hdr"):
        return c["src"]
    sdr = WORK / "sdr" / f"{Path(c['name']).stem}.mov"
    if not sdr.exists():
        sdr.parent.mkdir(parents=True, exist_ok=True)
        run(["avconvert", "--source", c["path"], "--preset", "Preset1920x1080", "--output", str(sdr), "--replace"])
    return str(sdr)


def sheets(clips: list[dict]) -> None:
    """Contact sheets, one thumbnail every 2 s, 10×6 to a sheet (sheet k covers k·120 s to (k+1)·120 s)."""
    for c in clips:
        if not c["video"]:
            continue
        d = WORK / "sheets" / Path(c["name"]).stem
        if d.exists():
            continue
        d.mkdir(parents=True)
        ff("-skip_frame", "nokey", "-i", c["src"], "-vf", "fps=1/2,scale=192:-2,tile=10x6", "-q:v", "4", str(d / "sheet-%02d.jpg"))


# ----- the take: the battle's events and rows ------------------------------------------------------------------------

def load_take(code: str | None = None) -> dict | None:
    """The battle hall's events from the take log: the newest Poetry hall that reached its song (or ROOM)."""
    if not TAKE_LOG.exists():
        return None
    halls: dict[str, dict] = {}
    current = None
    for line in TAKE_LOG.read_text().splitlines():
        parts = line.split("\t")
        if len(parts) < 5:
            continue
        coded = re.fullmatch(r"[A-Z]{4}", parts[2]) is not None  # since 02:19 a line carries its hall's code
        if coded:
            parts = parts[:2] + parts[3:] + [parts[2]]
        e = {"wall": parts[0], "t": int(parts[1]) / 1000, "who": parts[2], "reducer": parts[3], "text": parts[4],
             "code": parts[-1] if coded else None}
        m = re.search(r"(\w[\w ]*?) · hall ([A-Z]{4})", e["text"])
        if e["reducer"] == "create_room" and m:
            if m[2] not in halls:
                halls[m[2]] = {"code": m[2], "event": m[1].replace("watching:", "").replace("new hall:", "").strip(),
                               "created": e["t"], "events": []}
            current = m[2]
            continue
        hall = e["code"] or current
        if hall:
            halls.setdefault(hall, {"code": hall, "event": "Poetry", "created": e["t"], "events": []})["events"].append(e)
    order = sorted(({"code": h["code"], "event": h["event"], "created": h["created"]} for h in halls.values()),
                   key=lambda h: h["created"])
    pick = code or overrides().get("room")
    if pick and pick in halls:
        return {**halls[pick], "halls": order}
    poetry = [h for h in halls.values() if h["event"] == "Poetry" and any(e["reducer"] == "post_song" for e in h["events"])]
    poetry = poetry or [h for h in halls.values() if h["event"] == "Poetry" and any(e["reducer"] == "start_turn" for e in h["events"])]
    take = max(poetry, key=lambda h: h["created"]) if poetry else None
    return {**take, "halls": order} if take else None


def sql(query: str) -> list[dict]:
    try:
        req = urllib.request.Request(SQL, data=query.encode(), method="POST")
        with urllib.request.urlopen(req, timeout=15) as res:
            out = []
            for table in json.load(res):
                names = [e["name"]["some"] for e in table["schema"]["elements"]]
                out.extend(dict(zip(names, row)) for row in table["rows"])
            return out
    except Exception as exc:  # the cut never waits on the database
        print(f"sql skipped: {exc}")
        return []


def turns_of(take: dict) -> list[dict]:
    """The verses in order: SPEAK (start_turn + count-in), the close (end_turn/turn_timeout), the score, the verdict."""
    out, cur = [], None
    for e in take["events"]:
        r = e["reducer"]
        if r == "start_turn":
            cur = {"who": e["text"].split(" · ")[0], "start": e["t"], "speak": e["t"] + COUNT_IN, "end": None,
                   "timeout": False, "score": None, "verdict": "", "total": None, "words": []}
            out.append(cur)
        elif cur and r == "update_transcript":
            cur["words"].append((e["t"], e["text"].split(": ", 1)[-1]))
        elif cur and r in ("end_turn", "turn_timeout") and cur["end"] is None:
            cur["end"], cur["timeout"] = e["t"], r == "turn_timeout"
        elif cur and r == "post_score" and cur["score"] is None:
            cur["score"] = e["t"]
            m = re.search(r"(\d+)/(\d+)", e["text"])
            cur["total"] = int(m[1]) if m else None
        elif cur and r == "verdict" and not cur["verdict"]:
            cur["verdict"] = e["text"].strip("“”\"")
    return out


def rescued(take: dict) -> float | None:
    """The take's first freeze rescue, from builder's prod watcher (the take log doesn't carry rescues): its lines
    are HH:MM:SS.mmm on this Mac's clock, dated by the take."""
    log = Path(overrides().get("watch_log", "/private/tmp/claude-501/-Users-matus-dev-projects-MeNIN/"
                                            "420b4cd7-2c7a-4d88-a723-026d5d5d44f5/scratchpad/matus_watch.log"))
    if not log.exists():
        return None
    day = datetime.fromtimestamp(take["created"]).strftime("%Y-%m-%d")
    for line in log.read_text().splitlines():
        m = re.match(rf"^(\d\d:\d\d:\d\d\.\d+) {take['code']} .+ rescued \(1\)", line)
        if m:
            t = datetime.strptime(f"{day} {m[1]}", "%Y-%m-%d %H:%M:%S.%f").timestamp()
            if t >= take["created"]:
                return t
    return None


def moment(take: dict, reducer: str, contains: str = "") -> float | None:
    return next((e["t"] for e in take["events"] if e["reducer"] == reducer and contains in e["text"]), None)


# ----- beats ---------------------------------------------------------------------------------------------------------

def beats() -> list[float]:
    """The theme's beat grid (seconds in the master): onset strength from 10 ms energy, the tempo by autocorrelation
    (70–180 BPM), the phase by the strongest onsets. Cached in work/beats.json."""
    cache = WORK / "beats.json"
    if cache.exists():
        return load(cache, [])
    out = run(["ffmpeg", "-hide_banner", "-i", str(THEME), "-af",
               "aresample=48000,pan=mono|c0=0.5*c0+0.5*c1,asetnsamples=n=480:p=0,astats=metadata=1:reset=1,"
               "ametadata=print:key=lavfi.astats.Overall.RMS_level:file=-", "-f", "null", "-"])
    db = [float(v) if v != "-inf" else -120.0 for v in re.findall(r"RMS_level=(-?[\d.]+|-inf)", out)]
    flux = [max(0.0, db[i] - db[i - 1]) for i in range(1, len(db))]
    lags = range(int(100 * 60 / 180), int(100 * 60 / 70) + 1)
    period = max(lags, key=lambda lag: sum(flux[i] * flux[i - lag] for i in range(lag, len(flux))))
    phase = max(range(period), key=lambda p: sum(flux[i] for i in range(p, len(flux), period)))
    grid = [(phase + k * period) / 100 for k in range((len(flux) - phase) // period + 1)]
    save(cache, grid)
    print(f"beats: {60 * 100 / period:.1f} BPM, {len(grid)} beats")
    return grid


def snap(t: float, grid: list[float], reach: float = 0.4) -> float:
    """A video time moved onto the nearest beat of the theme as it plays in the video (from THEME_AT)."""
    if not grid:
        return t
    vt = [THEME_AT + b - THEME_HIT for b in grid]
    near = min(vt, key=lambda b: abs(b - t))
    return near if abs(near - t) <= reach else t


# ----- plan ----------------------------------------------------------------------------------------------------------

def overlap(c: dict, take: dict) -> float:
    """Seconds of the battle (its first to its last event) that a clip covers."""
    if not c.get("start") or not take["events"]:
        return 0.0
    a, b = take["events"][0]["t"], take["events"][-1]["t"]
    return max(0.0, min(b, c["start"] + c["dur"]) - max(a, c["start"]))


def covering(cands: list[dict], take: dict | None) -> dict | None:
    """Of several clips of one kind (the Mac records a file per take), the one covering most of the battle."""
    if not cands:
        return None
    return max(cands, key=lambda c: overlap(c, take)) if take else cands[0]


def clip_by_kind(clips: list[dict], kind: str) -> list[dict]:
    return [c for c in clips if c["kind"] == kind]


def card(card_id: str) -> str | None:
    """artist's file for a card or lower third (its name starts with the ID), else None (a placeholder is drawn)."""
    for f in sorted(CARDS.glob(f"{card_id}*")) if CARDS.exists() else []:
        if re.match(rf"{re.escape(card_id)}(\b|[-_.])", f.name) and f.suffix.lower() in (".png", ".mp4", ".mov"):
            return str(f)
    return None


def plan() -> dict:
    """The cut list (video.md "The timeline"), every slot from the take's own moments."""
    clips = load(WORK / "clips.json", [])
    take = load_take()
    if not take:
        sys.exit("no battle in the take log yet")
    o = overrides()
    mac = covering(clip_by_kind(clips, "mac"), take)
    wide = covering(clip_by_kind(clips, "wide"), take)
    phones = [c for c in clip_by_kind(clips, "phone") if overlap(c, take) > 0] or clip_by_kind(clips, "phone")
    turns = turns_of(take)
    grid = beats()
    segs: list[dict] = []
    lts: list[dict] = []

    def at(c: dict | None, t: float | None) -> float | None:
        return None if c is None or t is None or c.get("start") is None else t - c["start"]

    def shot(t0, dur, src, src_t, mode, note, epoch=None, room=True, **kw):
        if src is None or src_t is None:
            return
        segs.append({"t0": round(t0, 3), "dur": round(dur, 3), "src": src["name"] if isinstance(src, dict) else src,
                     "src_t": round(src_t, 3), "mode": mode, "note": note, "epoch": epoch,
                     "room": room and epoch is not None, **kw})

    by_name = {c["name"]: c for c in clips}
    owners = {who: by_name[n] for who, n in o.get("phones", {}).items() if n in by_name}

    def phone_of(who: str | None):
        """The poet's own phone (overrides.json "phones": {poet: clip}); else the first phone recording."""
        return owners.get(who or "") or (phones[0] if phones else None)

    def battle(t0, dur, epoch, note, prefer="mac", inset=None):
        """A battle moment: the laptop (cropped to the words and the scene), else the wide; a phone inset if asked."""
        src = mac if prefer == "mac" and mac else wide
        extra = {}
        if inset is not None:  # a phone recording (the poet's own, from phone_of)
            extra["inset"] = {"src": inset["name"], "src_t": round(at(inset, epoch), 3)}
        shot(t0, dur, src, at(src, epoch), "crop" if src is mac else "full", note, epoch, **extra)

    def lower(card_id, t0, dur):
        lts.append({"id": card_id, "t0": t0, "dur": dur, "file": card(card_id)})

    first = turns[0] if turns else None
    second = turns[1] if len(turns) > 1 else None
    deal = moment(take, "deal_round")
    # 0:00-0:02.5 the painted scene at rest, Homer's Greek (G) under C0
    shot(0, 2.5, f"{BROLL}/scene-at-rest-ui-hidden.mp4", 0.5, "file", "G: the painted scene at rest", room=False)
    lts.append({"id": "C0", "t0": 0, "dur": 2.5, "file": card("C0"), "over": True})
    # 0:02.5-0:04 the poet's phone: three phrases dealt (hard cut mid-word)
    if deal and phones:
        # The phone shows Homer's three phrases on its SPEAK screen; the recording we have is the second poet's.
        hand_phone = phone_of(turns[0]["who"] if turns else None)  # the first poet's phrases, on their own phone
        hand = turns[0]["speak"] + 0.5 if turns else deal + 2.0
        shot(2.5, 1.5, wide, at(wide, deal + 2.0), "full", "three phrases dealt", deal + 2.0,
             inset={"src": hand_phone["name"], "src_t": round(at(hand_phone, hand), 3)})
    lower("L2", 2.5, 1.5)
    # 0:04-0:11 the poet speaks: the wide, the arena's live words, a phone inset; room sound, no music
    if first:
        s = first["speak"] + 0.2
        battle(4.0, 2.5, s, "verse 1: the wide", prefer="wide")
        battle(6.5, 2.5, s + 2.5, "verse 1: the live words")
        battle(9.0, 2.0, s + 5.0, "verse 1: phone inset", prefer="wide", inset=phone_of(first["who"]))
        lower("L3", 4.0, 7.0)
        # 0:11-0:11.5 silence (the picture holds on the arena), then Homer's real verdict and the score
        shot(11.0, 0.5, mac or wide, at(mac or wide, s + 7.0), "crop" if mac else "full", "0.5 s of silence", s + 7.0,
             room=False)
        v = (first["score"] or (first["end"] or s + 18) + 3) - 0.3
        battle(11.5, 4.5, v, "verdict 1 lands")
        lower("L4", 11.5, 4.5)
        faces = v + 4.5
    else:
        faces = None
    # 0:16-0:17.5 C1 on the theme's hit; 0:17.5-0:20 the room reacting (L1)
    shot(16.0, 1.5, "C1", 0, "card", "C1 title on the theme's hit", room=False)
    if faces:
        shot(17.5, 2.5, wide, at(wide, faces), "full", "the room reacting", faces)
        lower("L1", 17.5, 2.5)
    # 0:20-0:33 Matus to camera: M1 (what it is, LM on it), then M2 (the value)
    answers = answer_clips(clips, take)
    m1_end = answer(segs, "M1", answers.get("M1"), 20.0, 5.0, own=True)  # M1 runs its own length (~12 s)
    lower("LM", 20.0, 4.0)
    m2_end = answer(segs, "M2", answers.get("M2"), m1_end, 8.0, own=True)
    # 0:33-1:12 the rest of the battle, in order: the next poet stepping up, each answer (laptop, wide, the poet's own
    # phone), its verdict (Homer heard whole, to the arena's next step), faces; the freeze rescue uncut at 1x inside
    # its verse; the round's call and the gold line last. Never into the finale (the song has its own place).
    # Short of time, the reactions grow; past it, the verses give way first.
    B0, B1 = m2_end, 72.0  # the battle takes what the answers leave
    carved = moment(take, "post_verdict", "carved")
    round_end = moment(take, "advance", "round 1 ends") or (carved - 0.3 if carved else None)
    finale_at = moment(take, "advance", "finale")
    rescue = rescued(take)
    advances = sorted(e["t"] for e in take["events"] if e["reducer"] in ("advance", "start_turn"))
    after = lambda t: next((x for x in advances if x > t + 0.5), t + 8.0)
    beats_: list[list] = []  # [epoch, seconds, kind, note, extra]
    if first and first["score"] and len(turns) > 1 and faces:
        up_from = faces + 2.5  # where the intro's reaction shot ended
        beats_.append([up_from, max(0.0, turns[1]["start"] + COUNT_IN - up_from), "up", f"{turns[1]['who']} steps up", {}])
    for i, tr in enumerate(turns[1:], 2):
        s_ = tr["speak"] + 0.2
        close = tr["end"] or s_ + 20
        if rescue and s_ <= rescue <= close:
            beats_.append([rescue - 4.0, 8.0, "rescue", f"verse {i}: the freeze rescue, uncut", {}])
        else:
            beats_.append([s_, close - s_, "verse", f"verse {i}: {tr['who']}", {"inset": phone_of(tr["who"])}])
        if tr["score"]:
            beats_.append([tr["score"] - 0.3, min(8.0, after(tr["score"]) - tr["score"] + 0.3), "verdict", f"verdict {i}", {}])
            beats_.append([tr["score"] + 0.3 + min(8.0, after(tr["score"]) - tr["score"]), 1.5, "faces", "faces after the score", {}])
    total = lambda: sum(x[1] for x in beats_)
    seen = lambda: max((b[0] + b[1] for b in beats_), default=round_end or 0.0)
    gold_len = min(10.0, (finale_at or (round_end or 0) + 8.0) - max(round_end, seen())) if round_end else 0.0
    room_for = (B1 - B0) - max(0.0, gold_len)
    if first and total() < room_for:  # short: the part of the first verse the intro didn't show
        rest_from = first["speak"] + 0.2 + 7.0
        rest = min(room_for - total(), (first["end"] or rest_from) - rest_from)
        if rest > 2.0:
            beats_.insert(0, [rest_from, rest, "verse", f"verse 1, continued: {first['who']}", {"inset": phone_of(first["who"])}])
    for bt in beats_:  # short: the reactions grow (to 4 s)
        if bt[2] == "faces" and total() < room_for:
            bt[1] += min(2.5, room_for - total())
    while total() > room_for and any(x[2] == "verse" and x[1] > 6.0 for x in beats_):
        bt = max((x for x in beats_ if x[2] == "verse"), key=lambda x: x[1])
        bt[1] = max(6.0, bt[1] - 1.0)
    while total() > room_for and beats_:
        beats_.pop(0 if beats_[0][2] == "up" else len(beats_) - 1)
    t = B0
    for epoch, dur, kind, note, extra in beats_:
        if dur <= 0.05:
            continue
        if kind == "verse":
            third = dur / 3
            battle(t, third, epoch, note)
            battle(t + third, third, epoch + third, note + ": the wide", prefer="wide")
            battle(t + 2 * third, third, epoch + 2 * third, note + ": the poet's phone", prefer="wide", inset=extra.get("inset"))
        elif kind == "faces":
            shot(t, dur, wide, at(wide, epoch), "full", note, epoch)
        else:
            battle(t, dur, epoch, note)
            if kind == "rescue":
                lower("L6", t + 0.5, 4.0)
        t += dur
    if round_end:
        call_from = max(round_end, max((b[0] + b[1] for b in beats_), default=round_end))  # never back over a moment
        battle(t, B1 - t, call_from, "the round's call and the gold line, carved")
        lower("L8", t + max(0.5, (carved or call_from) - call_from), 4.0)
    elif t < B1 and wide and faces:
        shot(t, B1 - t, wide, at(wide, faces + 8.0), "full", "the room (fill)", faces + 8.0)
    lower("L5", B0 + 1.0, 4.0)
    verdict_at = B0
    for bt in beats_:
        if bt[2] == "verdict":
            lower("L7", verdict_at + 0.3, 4.0)
            break
        verdict_at += bt[1]
    if not rescue:
        lower("L6", B0 + 14.0, 4.0)
    # 1:12-1:21 Matus to camera: M3 (what we built), with 2.5 s of real website footage cut in under his voice: the
    # arena in the browser, address bar in frame (the take's minigame recording, the archery range). L9 over it.
    games_mac = max((c for c in clip_by_kind(clips, "mac") if c is not mac and (c.get("start") or 0) > take["created"]),
                    key=lambda c: c["dur"], default=None)
    toxeia = next((h for h in take.get("halls", []) if h["event"] == "Toxeia"), None)
    cut_in = snap(75.5, grid) if games_mac and toxeia else None
    answer(segs, "M3", answers.get("M3"), 72.0, 9.0, cutaway=(cut_in, 2.5) if cut_in else None)
    if cut_in:
        src_t = min(games_mac["dur"] - 4.0, max(0.0, toxeia["created"] + 40.0 - games_mac["start"]))
        shot(cut_in, 2.5, games_mac, src_t, "browser", "website: the arena in the browser (archery), under M3", room=False)
        lower("L9", cut_in, 2.5)
    # 1:21-1:27 the SpacetimeDB moment: multiplayer's timeline rows (broll/timeline.mp4, frame 0 on this Mac's clock in
    # timeline.json) beside the wide at the same instant, around the verdict it anchors on; else the turn that ran out.
    tl = BROLL / "timeline.json"
    if tl.exists() and wide:
        meta = json.loads(tl.read_text())
        from_s = max(0.0, meta["anchor"]["atSecond"] - 3.0)
        epoch = meta["frame0"]["epochMs"] / 1000 + from_s
        shot(81.0, 6.0, wide, at(wide, epoch), "full", "SpacetimeDB: the verdict lands, every screen at once", epoch,
             beside=str(BROLL / "timeline.mp4"), beside_t=from_s)
    else:
        timeout = next((tr for tr in turns if tr["timeout"]), None)
        if timeout:
            shot(81.0, 6.0, wide, at(wide, timeout["end"] - 3.0), "full", "SpacetimeDB: the timer ends the turn",
                 timeout["end"] - 3.0)
    lower("L10", 81.0, 6.0)
    # 1:27-1:38 the diagram and the number card (lines 6 and 7 are 6.5 s and 4.5 s: the cards hold them whole);
    # 1:38-1:55 the stitched song; 1:55-2:00 C5 over its last line
    shot(87.0, 6.6, "C2", 0, "card", "C2 the diagram (line 6)", room=False)
    shot(93.6, 4.6, "C3", 0, "card", "C3 20% -> 3% (line 7)", room=False)
    finale = moment(take, "advance", "finale")
    if finale:  # the song, cut between the laptop, faces on the wide and a poet's phone; the room sound runs on
        f0 = finale + 1.0
        battle(98.2, 3.8, f0, "the stitched song")
        shot(102.0, 3.6, wide, at(wide, f0 + 3.8), "full", "the song: faces", f0 + 3.8)
        battle(105.6, 3.4, f0 + 7.4, "the song: the phone", prefer="wide", inset=phone_of(first["who"] if first else None))
        battle(109.0, 3.2, f0 + 10.8, "the song, line by line")
        shot(112.2, 2.8, wide, at(wide, f0 + 14.0), "full", "the song: faces", f0 + 14.0)
        shot(115.0, 5.0, "C5", 0, "card", "C5 responsible card (the song's tail under it)", finale + 17.8)
    else:
        shot(98.2, 21.8, "C5", 0, "card", "C5 (no song in the take)", room=False)
    # 2:00-2:14 the training montage: 2-4x with 1x hero beats, cuts on the theme's beats, ends on a miss and a laugh
    montage(segs, lts, clips, take, grid, end=134.0)
    # 2:14-2:29 the Figma workflow (artist's renders, graded already), one stat (L14)
    figma = sorted(CARDS.glob("F*.mp4")) if CARDS.exists() else []
    figma = [str(f) for f in figma] + [c["src"] for c in clip_by_kind(clips, "figma")]
    t = 134.0
    for f in figma:
        try:  # artist may still be writing it
            d = min(15.0 / max(1, len(figma)), float(probe(Path(f))["format"]["duration"]))
        except (RuntimeError, KeyError, ValueError):
            print(f"note: {Path(f).name} isn't readable yet; its slot keeps the placeholder")
            continue
        shot(t, d, f, 0, "file", f"Figma: {Path(f).name}", room=False, graded=True)
        t += d
    if t < 149.0 and segs and segs[-1]["note"].startswith("Figma: "):  # the last render holds to the slot's end
        segs[-1]["dur"] = round(149.0 - segs[-1]["t0"], 3)
        segs[-1]["hold"] = True
    elif t < 149.0:
        shot(t, 149.0 - t, "FIGMA", 0, "card", "(the Figma workflow: artist's render goes here)", room=False)
    lower("L14", 135.0, 5.0)
    # 2:29-2:50 Matus to camera: M4 (what's next, ~18 s); the end card takes any time it leaves
    m4_end = answer(segs, "M4", answers.get("M4"), 149.0, 21.0)  # its own length, at most 21 s
    # 2:50-3:00 C6, the end card ("Play it now" and the URL held), line 10
    shot(m4_end, LENGTH - m4_end, "C6", 0, "card", "C6 the end card (Play it now, held)", room=False)
    if BRAND.exists():  # the sponsors' badges ride with their lower thirds and cards
        badges = brand_badges()
        for lt in list(lts):
            if f"B-{lt['id']}" in badges:
                lts.append({"id": f"B-{lt['id']}", "t0": lt["t0"], "dur": lt["dur"], "file": badges[f"B-{lt['id']}"], "over": True})
        for sg in segs:
            bid = {"C2": "B-C2", "C6": "B-C6"}.get(sg["src"]) or ("B-FIG" if sg["note"].startswith("Figma") else None)
            if bid and bid in badges:
                lts.append({"id": bid, "t0": sg["t0"], "dur": sg["dur"], "file": badges[bid], "over": True})
    for s in o.get("cuts", []):  # hand fixes: {"t0": 4.0, "src": "...", "src_t": 12.3, ...}
        for seg in segs:
            if abs(seg["t0"] - s["t0"]) < 0.01:
                seg.update(s)
    for seg in segs:
        if seg["mode"] in ("crop", "browser"):
            c = next((x for x in clips if x["name"] == seg["src"]), None)
            if c:
                seg["masks"] = masks(c, seg["src_t"], seg["dur"])
    segs.sort(key=lambda s: s["t0"])
    cuts = {"segments": segs, "lowers": lts, "take": take["code"], "theme_at": THEME_AT,
            "music": music_plan(segs, turns, B0)}
    save(WORK / "cuts.json", cuts)
    write_lists(cuts)
    return cuts


def answer_texts() -> dict[str, str]:
    """video.md's four answers to camera, word for word (M1-M4)."""
    out = {}
    for line in SCRIPT.read_text().splitlines():
        m = re.match(r'^\| (M[1-4]) \| [^|]+\| "([^"]+)"', line)
        if m:
            out[m[1]] = m[2]
    return out


def answer_clips(clips: list[dict], take: dict) -> dict[str, dict]:
    """Matus's four answers to camera: the clips (with sound) filmed after the last hall closed, in order, the longest
    taking M4 (~18 s). overrides.json "answers": {"M1": clip name, ...} wins."""
    by_name = {c["name"]: c for c in clips}
    o = overrides().get("answers", {})
    if o:
        return {k: by_name[v] for k, v in o.items() if v in by_name}
    last = max((int(line.split("\t")[1]) / 1000 for line in TAKE_LOG.read_text().splitlines()
                if line.count("\t") >= 4 and line.split("\t")[1].isdigit()), default=take["created"])
    pool = sorted((c for c in clips if c["kind"] in ("montage", "phone", "camera") and c["audio"]
                   and (c.get("start") or 0) > last + 30), key=lambda c: c["start"])[:4]
    if len(pool) == 4:
        longest = max(pool, key=lambda c: c["dur"])
        pool.remove(longest)
        pool.append(longest)
    return {f"M{i}": c for i, c in enumerate(pool, 1)}


def speech_span(clip: dict) -> tuple[float, float]:
    """Where the speaking starts and ends in a clip (its own sound): the lead-in and the tail trimmed, 0.25 s kept."""
    out = run(["ffmpeg", "-hide_banner", "-i", clip["path"], "-vn", "-af", "silencedetect=noise=-38dB:d=0.35",
               "-f", "null", "-"], quiet=False)
    ends = [float(x) for x in re.findall(r"silence_end: ([\d.]+)", out)]
    starts = [float(x) for x in re.findall(r"silence_start: ([\d.]+)", out)]
    a = ends[0] if starts and starts[0] < 0.05 and ends else 0.0
    b = starts[-1] if starts and starts[-1] > a + 1.0 and (not ends or ends[-1] < starts[-1]) else clip["dur"]
    return max(0.0, a - 0.25), min(clip["dur"], b + 0.35)


def answer(segs: list[dict], mid: str, clip: dict | None, t0: float, slot: float,
           cutaway: tuple[float, float] | None = None, own: bool = False) -> float:
    """Matus to camera: the answer from its start with its own sound, landscape filled or portrait cropped to 16:9,
    graded; held on its last frame if it runs short of its slot (M4 runs its own length, the end card takes the
    rest). A labelled card until the clip lands. Returns where it ends."""
    a, b = speech_span(clip) if clip else (0.0, slot)
    # M1, M2 and M4 run their own length (M4 at most its slot); M3 keeps its slot (the cut-in sits inside it).
    dur = (b - a) if clip and own else min(slot, b - a) if clip and mid == "M4" else slot
    # With a cutaway (website footage under his voice), his picture runs before and after it; his sound runs through.
    pieces = [(t0, dur)] if not cutaway else [(t0, cutaway[0] - t0), (cutaway[0] + cutaway[1], t0 + dur - cutaway[0] - cutaway[1])]
    for k, (a_seg, d) in enumerate(pieces):
        if d <= 0.05:
            continue
        if clip is None:
            segs.append({"t0": round(a_seg, 3), "dur": round(d, 3), "src": mid, "src_t": 0, "mode": "card",
                         "note": f"{mid}: Matus to camera (pending)", "epoch": None, "room": False})
            continue
        seg = {"t0": round(a_seg, 3), "dur": round(d, 3), "src": clip["name"], "src_t": round(a + (a_seg - t0), 3),
               "mode": "portrait" if clip["h"] > clip["w"] else "full", "note": f"{mid}: Matus to camera",
               "epoch": None, "room": False, "hold": True}
        if k == 0:
            seg.update(own_audio=True, answer=mid, audio_dur=round(dur, 3))
        segs.append(seg)
    return t0 + dur


def montage(segs, lts, clips, take, grid, end: float = 150.0) -> None:
    """2:00-2:30: two clips a game at most (eight in all), in shoot order; each runs up at 2-4x and lands on its last
    1.5 s at 1x (slo-mo at 0.25x), its cuts on the theme's beats; L13 at each game's first clip. A clip's game is the
    hall open when it started rolling (the take log names each hall's event). The last clip ends it (a miss, a laugh)."""
    pool = sorted([c for c in clips if c["kind"] in ("montage", "slomo")], key=lambda c: c.get("start") or 0)
    if not pool:
        segs.append({"t0": 120.0, "dur": end - 120.0, "src": "C5", "src_t": 0, "mode": "card", "note": "(no montage footage)",
                     "epoch": None, "room": False})
        return
    halls = take.get("halls", [])
    games = {"Stadion": "stadion", "Toxeia": "toxeia", "Pygmachia": "pygmachia", "Discus": "discus"}
    for c in pool:
        open_hall = [h for h in halls if c.get("start") and h["created"] <= c["start"]]
        c["game"] = games.get(open_hall[-1]["event"], "") if open_hall else ""
    picked, per_game = [], {}
    for c in sorted(pool, key=lambda c: -c["dur"]):  # the longest takes of each game
        if per_game.get(c["game"], 0) < 2 and len(picked) < 8:
            per_game[c["game"]] = per_game.get(c["game"], 0) + 1
            picked.append(c)
    picked.sort(key=lambda c: c.get("start") or 0)
    t, seen = 120.0, set()
    slot = (end - 120.0) / len(picked)
    for n, c in enumerate(picked):
        slow = c["kind"] == "slomo"
        hero_rate = 0.25 if slow else 1.0
        stop = end if n == len(picked) - 1 else snap(t + slot, grid)
        out = stop - t
        hero = min(1.5, out / 2)
        run = out - hero
        source_run = c["dur"] - hero * hero_rate
        speed = min(4.0, max(2.0, source_run / max(run, 0.1)))
        if source_run < run * 2.0:  # too short to fill its slot at 2x: it plays what it has
            run = max(0.5, source_run / 2.0)
        start = max(0.0, c["dur"] - hero * hero_rate - run * speed)
        segs.append({"t0": round(t, 3), "dur": round(run, 3), "src": c["name"], "src_t": round(start, 3),
                     "speed": round(speed, 2), "mode": "full", "note": f"montage {c['game']}: the run-up at {speed:.1f}x",
                     "epoch": None, "room": False})
        segs.append({"t0": round(t + run, 3), "dur": round(hero, 3), "src": c["name"],
                     "src_t": round(start + run * speed, 3), "speed": hero_rate, "mode": "full",
                     "note": f"montage {c['game']}: the hero beat at {hero_rate:g}x", "epoch": None, "room": False})
        if c["game"] and c["game"] not in seen:
            seen.add(c["game"])
            lts.append({"id": f"L13-{c['game']}", "t0": round(t, 3), "dur": 3.0, "file": card(f"L13-{c['game']}")})
        t += run + hero
    for c in sorted(pool, key=lambda c: -c["dur"]):  # short of 30 s: the longest clips again, from their start at 2x
        if t >= end - 0.05:
            break
        d = min(end - t, c["dur"] / 2.0)
        segs.append({"t0": round(t, 3), "dur": round(d, 3), "src": c["name"], "src_t": 0.0, "speed": 2.0, "mode": "full",
                     "note": f"montage {c['game']}: more of the take at 2x", "epoch": None, "room": False})
        t += d


def music_plan(segs: list[dict], turns: list[dict], b0: float = 33.0) -> list[tuple[float, float]]:
    """The theme's level (dB) as keyframes on the video's clock (video.md A2): silent until the hit at 0:16, a bed
    under the battle that is hard-muted on every shot inside a verse (its 3-2-1 to its score) and slams back after,
    off under the song, up to -6 dB for the montage, out with the end card. Narration ducks are added in mix()."""
    sections = [(0.0, -90), (THEME_AT, -12), (17.5, -18), (20.0, -28), (b0, -24), (72.0, -28), (81.0, -24),
                (87.0, -28), (98.2, -90), (120.0, -6), (134.0, -18), (149.0, -28), (170.0, -14), (LENGTH, -90)]
    verses = [(tr["start"], tr["score"] or (tr["end"] or tr["start"] + 22) + 4) for tr in turns]
    muted = [(s["t0"], s["t0"] + s["dur"]) for s in segs
             if b0 <= s["t0"] < 72.0 and s.get("epoch") and any(a <= s["epoch"] <= b for a, b in verses)]

    def level(t: float) -> float:
        if any(a <= t < b for a, b in muted):
            return -90
        return next((d for x, d in reversed(sections) if x <= t), -90)

    keys: list[tuple[float, float]] = [(0.0, -90)]
    for m in sorted({x for x, _ in sections} | {a for a, _ in muted} | {b for _, b in muted}):
        before, after = level(m - 0.001), level(m)
        if before != after:
            keys += [(round(max(0.0, m - 0.02), 3), before), (round(m, 3), after)]
    return keys


def write_lists(cuts: dict) -> None:
    """out/cuts.csv (every cut, for redoing it by hand in CapCut) and out/cuts.edl (CMX3600, the picture track)."""
    OUT.mkdir(parents=True, exist_ok=True)
    rows = ["track,video_in,video_out,source,source_in,source_out,speed,mode,note"]
    edl = ["TITLE: MeNIN rough cut v1", "FCM: NON-DROP FRAME", ""]
    for i, s in enumerate(cuts["segments"], 1):
        sp = s.get("speed", 1.0)
        src = Path(s["src"]).name
        rows.append(f"V1,{clock(s['t0'])},{clock(s['t0'] + s['dur'])},{src},{s['src_t']:.2f},"
                    f"{s['src_t'] + s['dur'] * sp:.2f},{sp},{s['mode']},\"{s['note']}\"")
        if s.get("inset"):
            rows.append(f"V2,{clock(s['t0'])},{clock(s['t0'] + s['dur'])},{s['inset']['src']},{s['inset']['src_t']:.2f},"
                        f"{s['inset']['src_t'] + s['dur']:.2f},1,phone inset,\"\"")
        reel = re.sub(r"[^A-Z0-9]", "", src.upper())[:8] or "AX"
        edl.append(f"{i:03d}  {reel:8} V     C        {tc(s['src_t'])} {tc(s['src_t'] + s['dur'] * sp)} "
                   f"{tc(s['t0'])} {tc(s['t0'] + s['dur'])}")
        edl.append(f"* FROM CLIP NAME: {src}  ({s['note']})")
    for lt in cuts["lowers"]:
        rows.append(f"V3,{clock(lt['t0'])},{clock(lt['t0'] + lt['dur'])},{Path(lt['file']).name if lt['file'] else lt['id'] + ' (placeholder)'},0,"
                    f"{lt['dur']:.2f},1,{'card over' if lt.get('over') else 'lower third'},\"{lt['id']}\"")
    for f, start, dur in NARRATION:
        rows.append(f"A1,{clock(start)},{clock(start + (dur or seconds(VO / f)))},{f},0,{dur or seconds(VO / f):.2f},1,narration,\"\"")
    rows.append(f"A2,{clock(THEME_AT)},{clock(LENGTH)},menin-theme.m4a,{THEME_HIT},{THEME_HIT + LENGTH - THEME_AT:.2f},1,"
                "theme,\"levels: " + "; ".join(f"{clock(t)} {db} dB" for t, db in cuts["music"]) + "\"")
    (OUT / "cuts.csv").write_text("\n".join(rows) + "\n")
    (OUT / "cuts.edl").write_text("\n".join(edl) + "\n")
    print(f"{len(cuts['segments'])} cuts, {len(cuts['lowers'])} cards/lower thirds -> out/cuts.csv, out/cuts.edl")


def seconds(path: Path) -> float:
    return float(probe(path)["format"]["duration"])


# ----- captions: word by word, the current word bright (the arena's live words) --------------------------------------

def heard(path: Path) -> list[dict]:
    """What Cartesia hears in a file, word by word with times (ink-whisper), cached by the file's size and time."""
    st = path.stat()
    cache = WORK / "stt" / f"{path.stem}-{st.st_size}-{int(st.st_mtime)}.json"
    if cache.exists():
        return load(cache, [])
    sys.path.insert(0, str(Path(__file__).parent))
    import httpx
    import render_vo

    render_vo.load_env()
    cfg = render_vo.VoiceConfig.from_env()
    with path.open("rb") as f, httpx.Client(timeout=180) as http:
        res = http.post(render_vo.STT_URL, headers={"X-API-Key": cfg.api_key, "Cartesia-Version": cfg.version},
                        data={"model": "ink-whisper", "language": "en", "timestamp_granularities[]": "word"},
                        files={"file": (path.name, f, "audio/wav")})
    res.raise_for_status()
    words = [{"w": w["word"].strip(), "start": w["start"], "end": w["end"]} for w in res.json().get("words", []) if w["word"].strip()]
    save(cache, words)
    return words


def norm(w: str) -> str:
    return re.sub(r"[^a-z0-9]", "", w.lower())


def align(words: list[dict], text: str) -> list[dict]:
    """The known text's words (its spelling) on the heard words' times; words the ear missed are spread between."""
    import difflib

    known = text.split()
    sm = difflib.SequenceMatcher(a=[norm(w["w"]) for w in words], b=[norm(k) for k in known], autojunk=False)
    timed: list[dict | None] = [None] * len(known)
    for tag, a0, a1, b0, b1 in sm.get_opcodes():
        if tag in ("equal", "replace"):
            span = words[a0:a1]
            for j in range(b0, b1):
                if span:
                    w = span[min(len(span) - 1, (j - b0) * len(span) // max(1, b1 - b0))]
                    timed[j] = {"w": known[j], "start": w["start"], "end": w["end"]}
    for j, t in enumerate(timed):  # fill the gaps from the neighbours
        if t is None:
            prev = next((timed[i] for i in range(j - 1, -1, -1) if timed[i]), None)
            nxt = next((timed[i] for i in range(j + 1, len(timed)) if timed[i]), None)
            a = prev["end"] if prev else (nxt["start"] - 0.3 if nxt else 0.0)
            b = nxt["start"] if nxt else a + 0.3
            timed[j] = {"w": known[j], "start": a, "end": max(a + 0.05, b)}
    return [t for t in timed if t]


def narration_text() -> dict[str, str]:
    """video.md's narration table: line id -> the words as written (captions spell them as the script does)."""
    out = {}
    table = SCRIPT.read_text().split("### (a) The narration", 1)[-1].split("###", 1)[0]
    for line in table.splitlines():
        m = re.match(r'^\| (\w+) \| [^|]+\| "([^"]+)"', line)
        if m:
            out[m[1]] = m[2]
    return out


def caption_words(cuts: dict) -> list[dict]:
    """Every captioned word on the video's clock: the narration (as written), then the room's speech outside the
    narration (heard in the room stem, corrected against the take's transcripts, verdicts and song where it matches)."""
    texts = narration_text()
    out: list[dict] = []
    busy: list[tuple[float, float]] = []
    for f, start, dur in NARRATION:
        key = re.sub(r"^vo-0?|\.wav$", "", f).upper()
        if dur or key not in texts or not (VO / f).exists():
            continue  # the Greek is C0's (a card); a cut line has no row
        words = align(heard(VO / f), texts[key])
        out += [{**w, "start": w["start"] + start, "end": w["end"] + start, "who": "homer"} for w in words]
        busy.append((start, start + seconds(VO / f)))
    clips = {c["name"]: c for c in load(WORK / "clips.json", [])}
    said = answer_texts()
    for seg in cuts["segments"]:  # Matus's answers, heard in their own sound, spelled as video.md has them
        clip = clips.get(seg["src"]) if seg.get("answer") else None
        if not clip or seg["answer"] not in said:
            continue
        wav = WORK / "answers" / f"{Path(clip['name']).stem}.wav"
        if not wav.exists():
            wav.parent.mkdir(parents=True, exist_ok=True)
            ff("-i", clip["path"], "-vn", "-ac", "1", "-ar", "16000", str(wav))
        words = [w for w in heard(wav) if seg["src_t"] <= w["start"] < seg["src_t"] + seg.get("audio_dur", seg["dur"])]
        shift = seg["t0"] - seg["src_t"]
        out += [{**w, "start": w["start"] + shift, "end": w["end"] + shift, "who": "matus"}
                for w in align(words, said[seg["answer"]])]
        busy.append((seg["t0"], seg["t0"] + seg.get("audio_dur", seg["dur"])))
    room = WORK / "room.wav"
    laptop = [(s["t0"], s["t0"] + s["dur"]) for s in cuts["segments"] if s["mode"] in ("crop", "card")]  # no room words
    # over a laptop shot (the arena's live words caption it) or a card (C0-C6: the title owns the frame)
    if room.exists():
        known = take_texts(cuts.get("take", ""))
        heard_room = [w for w in heard(room) if not any(a - 0.2 <= w["start"] <= b + 0.2 for a, b in busy)
                      and not any(a <= w["start"] < b for a, b in laptop)]
        for group in phrases(heard_room, gap=0.9):
            said = " ".join(w["w"] for w in group)
            best = max(known, key=lambda k: fuzzy(said, k), default="")
            words = align(group, window(best, said)) if best and fuzzy(said, best) >= 0.55 else group
            out += [{**w, "who": "room"} for w in words]
    return sorted(out, key=lambda w: w["start"])


def take_texts(code: str) -> list[str]:
    room = sql(f"SELECT * FROM room WHERE code = '{code}'") if code else []
    if not room:
        return []
    rid = room[0]["id"]
    texts = [t["transcript"].replace("\n", " ") for t in sql(f"SELECT * FROM turn WHERE room_id = {rid}") if t.get("transcript")]
    texts += [s["verdict"] for s in sql(f"SELECT * FROM score WHERE room_id = {rid}") if s.get("verdict")]
    texts += [s["text"] for s in sql(f"SELECT * FROM song_line WHERE room_id = {rid}") if s.get("text")]
    return texts


def fuzzy(a: str, b: str) -> float:
    import difflib

    a_words, b_words = [norm(w) for w in a.split()], [norm(w) for w in b.split()]
    if not a_words or not b_words:
        return 0.0
    sm = difflib.SequenceMatcher(a=a_words, b=b_words, autojunk=False)
    return sum(m.size for m in sm.get_matching_blocks()) / len(a_words)


def window(known: str, said: str) -> str:
    """The stretch of a known text that the heard phrase covers (a verdict quoted in part, a verse cut in)."""
    import difflib

    k = known.split()
    sm = difflib.SequenceMatcher(a=[norm(w) for w in said.split()], b=[norm(w) for w in k], autojunk=False)
    blocks = [b for b in sm.get_matching_blocks() if b.size]
    if not blocks:
        return said
    return " ".join(k[blocks[0].b: blocks[-1].b + blocks[-1].size])


def phrases(words: list[dict], gap: float) -> list[list[dict]]:
    out: list[list[dict]] = []
    for w in words:
        if out and w["start"] - out[-1][-1]["end"] <= gap:
            out[-1].append(w)
        else:
            out.append([w])
    return out


def caption_lines(words: list[dict]) -> list[dict]:
    """Lines of 7 words or 40 characters at most, broken at a pause or a sentence's end; each shows from its first
    word to just past its last, never over the next."""
    lines: list[list[dict]] = []
    for w in words:
        cur = lines[-1] if lines else None
        if (cur and w["start"] - cur[-1]["end"] < 0.7 and len(cur) < 7 and len(" ".join(x["w"] for x in cur + [w])) <= 40
                and not re.search(r"[.?!]$", cur[-1]["w"]) and cur[-1]["who"] == w["who"]):
            cur.append(w)
        else:
            lines.append([w])
    out = []
    for i, ln in enumerate(lines):
        end = ln[-1]["end"] + 0.35
        if i + 1 < len(lines):
            end = min(end, lines[i + 1][0]["start"] - 0.02)
        out.append({"words": [w["w"] for w in ln], "starts": [w["start"] for w in ln], "end": end, "who": ln[0]["who"]})
    return out


def captions(cuts: dict) -> Path | None:
    """work/captions.mov (PNG with alpha): each word state rendered by headless Chrome (captions.mjs), held for its time."""
    lines = [ln for ln in caption_lines(caption_words(cuts)) if ln["end"] > 0 and ln["starts"][0] < LENGTH]
    card_starts = sorted(sg["t0"] for sg in cuts["segments"] if sg["mode"] == "card")
    for ln in lines:  # a line of the room's speech ends when a card comes up (the title owns the frame)
        if ln["who"] == "room":
            nxt = next((c for c in card_starts if c > ln["starts"][0]), None)
            if nxt is not None and ln["end"] > nxt:
                ln["end"] = nxt
                keep = [k for k, t in enumerate(ln["starts"]) if t < nxt]
                ln["words"], ln["starts"] = [ln["words"][k] for k in keep], [ln["starts"][k] for k in keep]
    lines = [ln for ln in lines if ln["words"]]
    states = []
    for i, ln in enumerate(lines):
        for k, start in enumerate(ln["starts"]):
            until = ln["starts"][k + 1] if k + 1 < len(ln["starts"]) else ln["end"]
            low = any(sg["mode"] == "card" and sg["t0"] <= start < sg["t0"] + sg["dur"] for sg in cuts["segments"])
            states.append({"id": f"{i:03d}-{k:02d}", "words": ln["words"], "k": k, "t0": start, "t1": until, "low": low})
    d = WORK / "captions"
    if d.exists():
        shutil.rmtree(d)
    (d / "png").mkdir(parents=True)
    save(d / "states.json", states)
    run(["node", str(Path(__file__).parent / "captions.mjs"), str(d)])
    seq, t = [], 0.0
    blank = d / "png" / "blank.png"
    for s in states:
        if s["t0"] > t + 0.001:
            seq.append((blank, s["t0"] - t))
        seq.append((d / "png" / f"{s['id']}.png", max(0.034, s["t1"] - max(s["t0"], t))))
        t = max(t, s["t1"])
    seq.append((blank, max(0.1, LENGTH - t)))
    lst = d / "list.txt"
    lst.write_text("".join(f"file '{f}'\nduration {dur:.3f}\n" for f, dur in seq) + f"file '{blank}'\n")
    out = WORK / "captions.mov"
    ff("-f", "concat", "-safe", "0", "-i", str(lst), "-vf", f"fps={FPS},format=rgba", "-t", str(LENGTH),
       "-c:v", "png", str(out))
    save(d / "lines.json", lines)
    print(f"captions: {len(lines)} lines, {len(states)} word states")
    return out


# ----- build ---------------------------------------------------------------------------------------------------------

def frame_rgb(path: str, t: float, div: int) -> tuple[int, int, bytes, int, int]:
    """One frame at 1/div scale as raw RGB, with the source's size."""
    v = next(x for x in probe(Path(path))["streams"] if x["codec_type"] == "video")
    sw, sh = v["width"], v["height"]
    w, h = sw // div, sh // div
    raw = subprocess.run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-ss", f"{max(0.0, t):.2f}", "-i", path,
                          "-frames:v", "1", "-vf", f"scale={w}:{h}", "-f", "rawvideo", "-pix_fmt", "rgb24", "-"],
                         capture_output=True).stdout
    return w, h, raw if len(raw) >= w * h * 3 else b"", sw, sh


NOTE_X = (1590, 2570)  # the operator note's column on the Mac's 3420-wide recording (centred under the panel)


def note_box(path: str, t: float) -> list[int] | None:
    """The arena's operator note ("This screen hosts room …"), as [x, y, w, h] in source pixels: a warm cream box
    with a tan border (red above blue by 18+) in its fixed column under the panel, where the frosted panel is cool
    white (blue at or above red). The cluster must span most of the note's width, so a warm patch of sea can't pass."""
    div = 5
    w, h, raw, sw, sh = frame_rgb(path, t, div)
    if not raw:
        return None
    x0, x1 = NOTE_X[0] // div, NOTE_X[1] // div
    warm = set()
    for y in range(int(h * 0.3), h):
        for x in range(x0, x1):
            i = (y * w + x) * 3
            r, g, b = raw[i], raw[i + 1], raw[i + 2]
            if r > 205 and r - b > 18 and g - b > 8 and r - g < 22:
                warm.add((x, y))
    best = None
    while warm:
        stack, cells = [warm.pop()], []
        while stack:
            cx, cy = stack.pop()
            cells.append((cx, cy))
            for n in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
                if n in warm:
                    warm.remove(n)
                    stack.append(n)
        xs, ys = [c[0] for c in cells], [c[1] for c in cells]
        if (max(xs) - min(xs) >= 0.7 * (x1 - x0) and (max(ys) - min(ys)) * div <= 175
                and min(ys) * div >= 0.6 * sh):
            if not best or len(cells) > len(best):
                best = cells
    if not best:
        return None
    xs, ys = [c[0] for c in best], [c[1] for c in best]
    bx0, by0 = max(2, (min(xs) - 3) * div), max(2, (min(ys) - 3) * div)
    return [bx0, by0, min(sw - 3, (max(xs) + 4) * div) - bx0, min(sh - 3, (max(ys) + 4) * div) - by0]


def cursor_box(path: str, t: float) -> list[int] | None:
    """The mouse pointer: the one small cluster of near-black pixels right of Homer (the arena draws no pure black)."""
    div = 4
    w, h, raw, sw, sh = frame_rgb(path, t, div)
    if not raw:
        return None
    dark = set()
    for y in range(int(h * 0.12), h):
        for x in range(900 // div, w):
            i = (y * w + x) * 3
            if raw[i] < 30 and raw[i + 1] < 30 and raw[i + 2] < 30:
                dark.add((x, y))
    best = None
    while dark:
        stack = [dark.pop()]
        cells = []
        while stack:
            cx, cy = stack.pop()
            cells.append((cx, cy))
            for n in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
                if n in dark:
                    dark.remove(n)
                    stack.append(n)
        xs, ys = [c[0] for c in cells], [c[1] for c in cells]
        if 3 <= len(cells) <= 120 and max(xs) - min(xs) <= 14 and max(ys) - min(ys) <= 18:
            if not best or len(cells) > len(best):
                best = cells
    if not best:
        return None
    xs, ys = [c[0] for c in best], [c[1] for c in best]
    x0, y0 = max(2, (min(xs) - 4) * div), max(2, (min(ys) - 4) * div)
    return [x0, y0, min(sw - 3, (max(xs) + 6) * div) - x0, min(sh - 3, (max(ys) + 7) * div) - y0]


def masks(clip: dict, src_t: float, dur: float) -> list[list[int]]:
    """What a laptop shot must not show: the operator note and the pointer, each found at the shot's start, middle
    and end (the union of what was found)."""
    out = []
    notes = [b for b in (note_box(clip["src"], src_t + f * dur) for f in (0.05, 0.5, 0.95)) if b]
    if notes:  # the note only slides up and down its column: one box spans where it was
        x0, y0 = min(b[0] for b in notes), min(b[1] for b in notes)
        x1, y1 = max(b[0] + b[2] for b in notes), max(b[1] + b[3] for b in notes)
        out.append([x0, y0, x1 - x0, y1 - y0])
    for b in (cursor_box(clip["src"], src_t + f * dur) for f in (0.05, 0.5, 0.95)):
        # each pointer sighting on its own (a union of far-apart ones would smear text between them)
        if b and b[2] <= 90 and b[3] <= 100 and not any(abs(b[0] - o[0]) < 30 and abs(b[1] - o[1]) < 30 for o in out):
            out.append(b)
    return out


BRAND = HOME / "brand"  # the sponsors' official logo files and sources.txt (not in the repo)
PLATE_RIGHT = {"L3": 1332, "L4": 1096, "L10": 1452}  # where artist's lower-third plates end (1920×1080; all span y 804-908)
BADGES = {  # badge id -> where it sits and which logos, in order
    "B-L3": ("plate", "L3", ["cartesia"]),
    "B-L4": ("plate", "L4", ["anthropic", "cartesia"]),
    "B-L10": ("plate", "L10", ["spacetimedb"]),
    "B-C2": ("corner", None, ["cartesia", "spacetimedb", "anthropic"]),
    "B-FIG": ("corner", None, ["figma"]),
    "B-C6": ("corner", None, ["apify", "moss"]),
}


def brand_logo(name: str) -> str:
    """One sponsor's logo as inline markup: its official SVG unaltered (scaled by CSS height), or for Moss, whose
    site offers no wordmark file, its name in Inter Bold (brand/sources.txt says where each came from)."""
    files = {"cartesia": ("cartesia-wordmark.svg", 30), "anthropic": ("anthropic-wordmark.svg", 22),
             "spacetimedb": ("spacetimedb-light-logo-text.svg", 38), "apify": ("apify-logo-dark.svg", 40),
             "figma": ("figma-kit/Figma Brand Assets/Figma Lockup/Figma Lockup.svg", 190)}
    if name == "moss":
        return '<span style="font:700 34px/1 Inter,\'Helvetica Neue\',Arial,sans-serif;color:#141413;letter-spacing:-.01em">Moss</span>'
    f, h = files[name]
    # Figma's lockup file carries wide padding of its own: scaled up, with that padding trimmed by negative margins
    # (the file itself untouched).
    extra = "margin:-48px -64px" if name == "figma" else ""
    svg = re.sub(r"<\?xml[^>]*>", "", (BRAND / f).read_text())
    svg = re.sub(r"<svg\b", f'<svg style="height:{h}px;width:auto;display:block;color:#141413;{extra}"', svg, count=1)
    return svg


def brand_badges() -> dict[str, str]:
    """The sponsor badges as transparent 1920×1080 overlays (headless Chrome, via captions.mjs): a pill in the plates'
    own style beside a lower third, or a row in a card's top-right corner. Cached in work/brand/."""
    d = WORK / "brand"
    out = {b: str(d / "png" / f"{b}.png") for b in BADGES}
    if all(Path(f).exists() for f in out.values()):
        return out
    (d / "png").mkdir(parents=True, exist_ok=True)
    pill = ("display:flex;align-items:center;gap:26px;padding:0 30px;background:rgba(255,255,255,.92);border-radius:14px;"
            "border:1px solid rgba(20,30,40,.06);box-shadow:0 6px 18px rgba(20,30,40,.10)")
    states = []
    for bid, (where, lt, logos) in BADGES.items():
        inner = "".join(brand_logo(n) for n in logos)
        if where == "plate":
            box = f"position:absolute;left:{PLATE_RIGHT[lt] + 14}px;top:808px;height:96px;{pill}"
        else:
            box = f"position:absolute;right:64px;top:56px;height:{110 if bid == 'B-FIG' else 84}px;{pill}"
        html = ('<style>@import url("https://fonts.googleapis.com/css2?family=Inter:wght@700&display=block");</style>'
                f'<div style="{box}">{inner}</div>')
        states.append({"id": bid, "html": html})
    save(d / "states.json", states)
    run(["node", str(Path(__file__).parent / "captions.mjs"), str(d)])
    return out


def placeholder(card_id: str, lower: bool) -> str:
    """A card artist hasn't delivered yet: its words from video.md on the Hall's ink (Quick Look renders the SVG);
    C0, a caption over the scene, as a transparent overlay (headless Chrome, as the captions)."""
    out = WORK / "placeholders" / f"{card_id}.png"
    if out.exists():
        return str(out)
    out.parent.mkdir(parents=True, exist_ok=True)
    if card_id == "C0":
        d = WORK / "placeholders" / "c0"
        (d / "png").mkdir(parents=True, exist_ok=True)
        html = ('<div style="position:absolute;inset:0;display:flex;flex-direction:column;align-items:center;'
                'justify-content:center;text-align:center;color:#f7f1e4;text-shadow:0 2px 18px rgba(20,30,40,.55)">'
                '<div style="font:400 120px/1.1 \'GFS Didot\',\'Bodoni 72\',Georgia,serif">μῆνιν ἄειδε θεὰ</div>'
                '<div style="margin-top:22px;font:italic 400 40px/1.2 Georgia,serif;opacity:.9">Sing, goddess, the rage…</div></div>')
        save(d / "states.json", [{"id": "C0", "html": html}])
        run(["node", str(Path(__file__).parent / "captions.mjs"), str(d)])
        shutil.copy(d / "png" / "C0.png", out)
        return str(out)
    text = card_text(card_id) or card_id
    lines = []
    for part in re.sub(r"\*+", "", text).split(" / "):
        part = part.strip()
        while len(part) > 62 and " · " in part[:62]:
            cut = part[:62].rindex(" · ")
            lines.append(part[:cut])
            part = part[cut + 3:]
        lines.append(part)
    lines = lines[:8]
    esc = lambda s: s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
    if card_id == "BACKUP":  # the backup's own opening card: finished, centered, no placeholder mark
        svg = ('<svg xmlns="http://www.w3.org/2000/svg" width="1920" height="1920"><rect width="1920" height="1920" fill="#1f2a33"/>'
               '<text x="960" y="520" text-anchor="middle" font-family="Bodoni 72" font-size="120" fill="#f4ecdc">Recorded live</text>'
               '<text x="960" y="610" text-anchor="middle" font-family="Helvetica" font-size="44" fill="#c8b98f">Sat Oct 24</text></svg>')
    elif lower:
        body = "".join(f'<text x="96" y="{80 + i * 52}" font-family="Helvetica" font-size="{40 if i == 0 else 30}" '
                       f'fill="#f4ecdc">{esc(s)}</text>' for i, s in enumerate(lines[:2]))
        svg = (f'<svg xmlns="http://www.w3.org/2000/svg" width="1920" height="1920"><rect width="1920" height="1920" fill="#000"/>'
               f'<rect x="64" y="20" width="1100" height="150" rx="12" fill="#1f2a33"/>{body}</svg>')
    else:
        body = "".join(f'<text x="160" y="{430 + i * 80}" font-family="{"Bodoni 72" if i == 0 else "Helvetica"}" '
                       f'font-size="{96 if i == 0 else 40}" fill="#f4ecdc">{esc(s)}</text>' for i, s in enumerate(lines))
        svg = (f'<svg xmlns="http://www.w3.org/2000/svg" width="1920" height="1920"><rect width="1920" height="1920" fill="#1f2a33"/>'
               f'{body}<text x="160" y="1000" font-family="Helvetica" font-size="26" fill="#6b7d88">placeholder {card_id}</text></svg>')
    svg_path = out.with_suffix(".svg")
    svg_path.write_text(svg)
    run(["qlmanage", "-t", "-s", "1920", "-o", str(out.parent), str(svg_path)])
    rendered = Path(f"{svg_path}.png")
    ff("-i", str(rendered), "-vf", "crop=1920:190:0:0" if lower else "crop=1920:1080:0:0", str(out))
    rendered.unlink(missing_ok=True)
    return str(out)


def card_text(card_id: str) -> str:
    if card_id == "BACKUP":
        return "Recorded live / Sat Oct 24"
    if card_id in ("M1", "M2", "M3", "M4"):
        return f"Matus to camera · {card_id} / “{answer_texts().get(card_id, '')}” / (the clip goes here)"
    if card_id == "LM":
        return "Matus · MeNIN"
    if card_id == "FIGMA":
        return "The Figma workflow / Atelier → Hall: the same frame, one variable mode / (artist's before/after goes here)"
    games = {"L13-stadion": "Stadion", "L13-toxeia": "Toxeia (archery): the webcam tracks your bow arm",
             "L13-pygmachia": "Pygmachia (boxing)", "L13-discus": "Discus"}
    if card_id in games:
        return games[card_id]
    base = card_id.split("-")[0]
    for line in SCRIPT.read_text().splitlines():
        m = re.match(rf"^\| {re.escape(base)} \| [^|]+\| [^|]+\| (.+) \|$", line)
        if m:
            return re.sub(r"\s*\((?:≥|small|[^)]*px)[^)]*\)", "", m[1])  # no stage directions in the frame
    return ""


def fit(mode: str, src: dict | None, crop: list | None) -> str:
    """The scale/crop to 1920×1080: the laptop cropped to the words and the scene (16:9, never letterboxed), a camera
    filled, a file at its own framing (or a crop of it)."""
    if crop:
        x, y, w, h = crop
        return f"crop=iw*{w}:iw*{w}*9/16:iw*{x}:ih*{y},scale={W}:{H}:flags=lanczos,setsar=1"
    if mode == "portrait":  # a portrait answer to camera: the upper body, cropped to 16:9
        return f"crop=iw:iw*9/16:0:ih*0.16,scale={W}:{H}:flags=lanczos,setsar=1"
    if mode == "browser":  # the screen below the menu bar, the browser's tabs and address bar in frame, 16:9
        return f"crop=iw:iw*9/16:0:ih*{62 / 2214:.4f},scale={W}:{H}:flags=lanczos,setsar=1"
    if mode == "whole" and src:  # the page without the menu bar and the browser's chrome, at 16:9
        top = overrides().get("page_top", 244 / 2214)  # ⌘⇧5 on this Mac (3420×2214): menu bar, tabs, address bar
        avail = src["h"] * (1 - top)
        ch = min(avail, src["w"] * 9 / 16)
        cw = ch * 16 / 9
        return (f"crop={int(cw)}:{int(ch)}:{int((src['w'] - cw) / 2)}:{int(src['h'] * top + (avail - ch) / 2)},"
                f"scale={W}:{H}:flags=lanczos,setsar=1")
    if mode == "whole":
        return f"scale={W}:{H}:force_original_aspect_ratio=decrease:flags=lanczos,pad={W}:{H}:(ow-iw)/2:(oh-ih)/2:color=#1f2a33,setsar=1"
    if mode == "crop":
        x, y, w = overrides().get("laptop_crop", [0.20, 0.20, 0.80])  # left, top, width as fractions; height follows 16:9
        return f"crop=iw*{w}:iw*{w}*9/16:iw*{x}:ih*{y},scale={W}:{H}:flags=lanczos,setsar=1"
    return f"scale={W}:{H}:force_original_aspect_ratio=increase:flags=lanczos,crop={W}:{H},setsar=1"


def render_segment(i: int, s: dict, clips: dict) -> Path:
    out = WORK / "seg" / f"{i:03d}.mp4"
    out.parent.mkdir(parents=True, exist_ok=True)
    speed = s.get("speed", 1.0)
    if s["mode"] == "card":
        f = card(s["src"]) or placeholder(s["src"], lower=False)
        inp = ["-loop", "1", "-t", f"{s['dur']:.3f}", "-i", f] if f.endswith(".png") else ["-i", f]
        chain = f"scale={W}:{H}:force_original_aspect_ratio=decrease,pad={W}:{H}:(ow-iw)/2:(oh-ih)/2:color=#1f2a33,setsar=1"
        if not f.endswith(".png"):  # artist's card runs once, then holds its last frame (never a visible loop)
            chain += ",tpad=stop_mode=clone:stop_duration=30"
    else:
        path = s["src"] if s["mode"] == "file" else picture(clips[s["src"]])
        inp = ["-ss", f"{max(0.0, s['src_t']):.3f}", "-i", path]
        hide = "".join(f"delogo=x={x}:y={y}:w={w}:h={h}," for x, y, w, h in s.get("masks", []))
        chain = f"setpts=(PTS-STARTPTS)/{speed}," + hide + fit(s["mode"], clips.get(s["src"]), s.get("crop"))
        if s.get("desat"):
            chain += "," + DESAT
        if not s.get("graded"):
            chain += "," + GRADE
        if s.get("hold"):
            chain += ",tpad=stop_mode=clone:stop_duration=30"
    graph = f"[0:v]{chain},fps={FPS},format=yuv420p[v]"
    extra: list[str] = []
    if s.get("inset"):
        ins = s["inset"]
        extra = ["-ss", f"{max(0.0, ins['src_t']):.3f}", "-i", picture(clips[ins["src"]])]
        graph = (f"[0:v]{chain},fps={FPS}[bg];[1:v]setpts=PTS-STARTPTS,scale=-2:{int(H * 0.86)},{GRADE},fps={FPS}[ph];"
                 f"[bg][ph]overlay=W-w-{int(W * 0.06)}:(H-h)/2,format=yuv420p[v]")
    if s.get("beside"):
        extra = ["-ss", f"{s.get('beside_t', 0.0):.3f}", "-i", s["beside"]]
        graph = (f"[0:v]{chain},crop={W // 2}:{H}:{W // 4}:0,fps={FPS}[l];[1:v]scale={W // 2}:-2,"
                 f"pad={W // 2}:{H}:0:(oh-ih)/2:color=#101418,fps={FPS}[r];[l][r]hstack,format=yuv420p[v]")
    files = [x for x in inp + extra if Path(x).is_file()]
    key = json.dumps({"seg": s, "graph": graph, "inputs": inp + extra,
                      "mtimes": [Path(x).stat().st_mtime for x in files]}, sort_keys=True)
    stamp = out.with_suffix(".json")
    if out.exists() and stamp.exists() and stamp.read_text() == key:
        return out
    ff(*inp, *extra, "-filter_complex", graph, "-map", "[v]", "-t", f"{s['dur']:.3f}", "-an",
       "-c:v", "libx264", "-preset", "veryfast", "-crf", "14", "-r", str(FPS), str(out))
    stamp.write_text(key)
    return out


def envelope(keys: list[tuple[float, float]]) -> str:
    """volume=… on the video's clock: dB keyframes, linear between them (0.15 s ramps make the hard cuts click-free)."""
    expr = f"{keys[-1][1]}"
    for (t0, d0), (t1, d1) in reversed(list(zip(keys, keys[1:]))):
        span = max(t1 - t0, 0.001)
        expr = f"if(lt(t,{t1:.3f}),{d0}+({d1}-({d0}))*(t-{t0:.3f})/{span:.3f},{expr})"
    return f"volume='pow(10,({expr})/20)':eval=frame"


def mix(cuts: dict, clips: dict) -> Path:
    """A1 (the room under the battle, from the wide; the narration) and A2 (the theme, its level plan, ducked under
    each narration line), to -14 LUFS."""
    out = WORK / "mix.wav"
    wide = next((c for c in clips.values() if c["kind"] == "wide"), None)
    inputs: list[str] = []
    parts: list[str] = []
    labels: list[str] = []
    room = [s for s in cuts["segments"] if s.get("room") and s.get("epoch") and wide and wide.get("start")]
    if room:
        inputs += ["-i", wide["src"]]
        parts.append(f"[0:a]aresample=48000,asplit={len(room)}" + "".join(f"[r{i}]" for i in range(len(room))))
        for i, s in enumerate(room):
            a = s["epoch"] - wide["start"]
            ms = int(s["t0"] * 1000)
            parts.append(f"[r{i}]atrim=start={max(0, a):.3f}:duration={s['dur']:.3f},asetpts=PTS-STARTPTS,"
                         f"afade=t=in:d=0.02,afade=t=out:st={max(0, s['dur'] - 0.02):.3f}:d=0.02,adelay={ms}|{ms}[ra{i}]")
            labels.append(f"[ra{i}]")
    if labels:  # the room ducks ~14 dB under each narration line
        under = [(start, start + (dur or seconds(VO / f))) for f, start, dur in NARRATION if (VO / f).exists()]
        duck = [(0.0, 0.0)]
        for a, b in under:
            duck += [(a - 0.25, 0.0), (a, -14.0), (b, -14.0), (b + 0.3, 0.0)]
        parts.append("".join(labels) + f"amix=inputs={len(labels)}:normalize=0,{envelope(sorted(duck) + [(LENGTH, 0.0)])}[room]")
        labels = ["[room]"]
    for s in cuts["segments"]:  # Matus's answers to camera: their own sound
        clip = clips.get(s["src"]) if s.get("own_audio") else None
        if not clip:
            continue
        n = len(inputs) // 2
        inputs += ["-i", clip["path"]]
        ms = int(s["t0"] * 1000)
        d = s.get("audio_dur", s["dur"])
        parts.append(f"[{n}:a]aresample=48000,aformat=channel_layouts=stereo,atrim=start={s['src_t']:.3f}:duration={d:.3f},"
                     f"asetpts=PTS-STARTPTS,afade=t=out:st={max(0.0, d - 0.12):.3f}:d=0.12,adelay={ms}|{ms}[m{n}]")
        labels.append(f"[m{n}]")
    keys = [tuple(k) for k in cuts["music"]]  # JSON gives lists; the narration ducks below are tuples
    for f, start, dur in NARRATION:
        path = VO / f
        if not path.exists():
            continue
        n = len(inputs) // 2
        inputs += ["-i", str(path)]
        length = dur or seconds(path)
        ms = int(start * 1000)
        trim = f"atrim=duration={dur},afade=t=out:st={dur - 0.08:.3f}:d=0.08," if dur else ""
        parts.append(f"[{n}:a]aresample=48000,{trim}pan=stereo|c0=c0|c1=c0,adelay={ms}|{ms}[n{n}]")
        labels.append(f"[n{n}]")
        base = next((db for t, db in reversed(cuts["music"]) if t <= start), -90)
        if base > -60:  # the theme ducks ~10 dB under the line
            keys += [(start - 0.2, base), (start, base - 10), (start + length, base - 10), (start + length + 0.3, base)]
    keys.sort()
    n = len(inputs) // 2
    inputs += ["-i", str(THEME)]
    parts.append(f"[{n}:a]atrim=start={THEME_HIT},asetpts=PTS-STARTPTS,aresample=48000,"
                 f"adelay={int(THEME_AT * 1000)}|{int(THEME_AT * 1000)},{envelope(keys)}[theme]")
    labels.append("[theme]")
    parts.append(f"{''.join(labels)}amix=inputs={len(labels)}:normalize=0,atrim=duration={LENGTH},"
                 f"loudnorm=I=-14:TP=-1.5:LRA=11,aresample=48000[mix]")
    ff(*inputs, "-filter_complex", ";".join(parts), "-map", "[mix]", "-c:a", "pcm_s16le", str(out))
    return out


def room_stem(cuts: dict, clips: dict) -> Path | None:
    """Just the room (the wide's sound under the battle shots) on the video's clock, for the captions' ear."""
    wide = next((c for c in clips.values() if c["kind"] == "wide"), None)
    room = [s for s in cuts["segments"] if s.get("room") and s.get("epoch") and wide and wide.get("start")]
    if not room:
        return None
    parts = [f"[0:a]aresample=16000,pan=mono|c0=0.5*c0+0.5*c1,asplit={len(room)}" + "".join(f"[r{i}]" for i in range(len(room)))]
    for i, s in enumerate(room):
        ms = int(s["t0"] * 1000)
        parts.append(f"[r{i}]atrim=start={max(0, s['epoch'] - wide['start']):.3f}:duration={s['dur']:.3f},"
                     f"asetpts=PTS-STARTPTS,adelay={ms}[s{i}]")
    parts.append("".join(f"[s{i}]" for i in range(len(room))) + f"amix=inputs={len(room)}:normalize=0,"
                 f"apad=whole_dur={LENGTH}[room]")
    out = WORK / "room.wav"
    ff("-i", wide["src"], "-filter_complex", ";".join(parts), "-map", "[room]", "-c:a", "pcm_s16le", str(out))
    return out


def backup() -> Path:
    """menin-backup-90s.mp4 (video.md "The backup video (90 s)"): the battle from the Mac's recording with the room's
    sound under it, trimmed only, opened by a 2 s "Recorded live, Sat Oct 24" card; no narration, music or grade.
    Each beat is found by its event in the take."""
    clips = {c["name"]: c for c in load(WORK / "clips.json", [])}
    take = load_take()
    mac = covering([c for c in clips.values() if c["kind"] == "mac"], take)
    wide = covering([c for c in clips.values() if c["kind"] == "wide"], take)
    if not take or not mac:
        sys.exit("the backup needs the take and the Mac's recording")
    turns = turns_of(take)
    begin = moment(take, "start_battle") or take["created"]
    deal = moment(take, "deal_round") or begin + 2
    carved = moment(take, "post_verdict", "carved")
    finale = moment(take, "advance", "finale")
    done = moment(take, "advance", "finished")
    beats_ = [(begin - 4.0, 4.0, "Homer's first-open line"), (deal, 4.0, "the theme, his call, the poet's entrance")]
    for i, tr in enumerate(turns[:2], 1):
        beats_.append((tr["start"], 15.0 if i == 1 else 18.0, f"turn {i}"))
        if tr["score"]:
            beats_.append((tr["score"] - 0.3, 6.0, f"verdict {i}"))
    if carved:
        beats_.append((carved - 1.0, 7.0, "the round verdict and the carved line"))
    if finale:
        beats_.append((finale + 1.0, min(23.0, (done or finale + 24.0) - finale - 1.0), "the stitched song"))
    if done:
        beats_.append((done, min(5.0, mac["start"] + mac["dur"] - done - 0.2), "the crown"))
    segs = [{"t0": 0.0, "dur": 2.0, "src": "BACKUP", "src_t": 0, "mode": "card", "note": "Recorded live, Sat Oct 24",
             "epoch": None, "room": False}]
    t, shown = 2.0, 0.0
    for epoch, dur, note in beats_:
        epoch = max(epoch, shown)  # never back over a moment already shown
        shown = epoch + dur
        segs.append({"t0": round(t, 3), "dur": dur, "src": mac["name"], "src_t": round(epoch - mac["start"], 3),
                     "mode": "whole", "note": note, "epoch": epoch, "room": True, "graded": True})
        t += dur
    files = []
    for i, sg in enumerate(segs):
        files.append(render_segment(500 + i, sg, clips))
    lst = WORK / "seg" / "backup.txt"
    lst.write_text("".join(f"file '{f}'\n" for f in files))
    picture = WORK / "backup-picture.mp4"
    ff("-f", "concat", "-safe", "0", "-i", str(lst), "-c", "copy", str(picture))
    OUT.mkdir(parents=True, exist_ok=True)
    out = OUT / "menin-backup-90s.mp4"
    if wide and wide.get("start"):
        parts = [f"[1:a]aresample=48000,asplit={len(segs) - 1}" + "".join(f"[r{i}]" for i in range(len(segs) - 1))]
        for i, sg in enumerate(segs[1:]):
            ms = int(sg["t0"] * 1000)
            parts.append(f"[r{i}]atrim=start={max(0, sg['epoch'] - wide['start']):.3f}:duration={sg['dur']:.3f},"
                         f"asetpts=PTS-STARTPTS,afade=t=in:d=0.03,afade=t=out:st={sg['dur'] - 0.03:.3f}:d=0.03,adelay={ms}|{ms}[a{i}]")
        parts.append("".join(f"[a{i}]" for i in range(len(segs) - 1)) + f"amix=inputs={len(segs) - 1}:normalize=0,"
                     f"apad=whole_dur={t},loudnorm=I=-14:TP=-1.5:LRA=11,aresample=48000[a]")
        ff("-i", str(picture), "-i", wide["src"], "-filter_complex", ";".join(parts), "-map", "0:v", "-map", "[a]",
           "-c:v", "copy", "-c:a", "aac", "-b:a", "192k", "-t", f"{t:.3f}", "-movflags", "+faststart", str(out))
    else:
        shutil.copy(picture, out)
    print(f"{out}  {seconds(out):.1f} s  {out.stat().st_size / 1e6:.1f} MB")
    return out


def build() -> None:
    cuts = load(WORK / "cuts.json", None) or plan()
    clips = {c["name"]: c for c in load(WORK / "clips.json", [])}
    segs = cuts["segments"]
    # Gaps (a slot the take couldn't fill) hold the end card's ink, so the timing never slips.
    filled, t = [], 0.0
    for s in segs:
        if s["t0"] > t + 0.01:
            filled.append({"t0": t, "dur": s["t0"] - t, "src": "C6", "src_t": 0, "mode": "card", "note": "(gap)",
                           "epoch": None, "room": False})
        filled.append(s)
        t = s["t0"] + s["dur"]
    files = []
    for i, s in enumerate(filled):
        print(f"segment {i + 1}/{len(filled)} {clock(s['t0'])} {s['note']}", flush=True)
        files.append(render_segment(i, s, clips))
    lst = WORK / "seg" / "list.txt"
    lst.write_text("".join(f"file '{f}'\n" for f in files))
    picture = WORK / "picture.mp4"
    ff("-f", "concat", "-safe", "0", "-i", str(lst), "-c", "copy", str(picture))
    audio = mix(cuts, clips)
    room_stem(cuts, clips)
    if "--reuse-captions" in sys.argv:
        caps = WORK / "captions.mov"
    else:
        caps = captions(cuts) if "--no-captions" not in sys.argv else None
    # Lower thirds and card-overs on top (artist's are transparent 1920×1080; placeholders are a band at the foot).
    inputs, graph, last = ["-i", str(picture), "-i", str(audio)], [], "[0:v]"
    for k, lt in enumerate(cuts["lowers"]):
        f = lt["file"] or placeholder(lt["id"], lower=not lt.get("over"))
        inputs += ["-loop", "1", "-i", f]
        n = k + 2
        y = "0" if lt["file"] or lt.get("over") else f"{H - 250}"
        graph.append(f"[{n}:v]format=rgba,fade=t=in:st=0:d=0.15:alpha=1,setpts=PTS-STARTPTS+{lt['t0']}/TB[o{k}];"
                     f"{last}[o{k}]overlay=0:{y}:enable='between(t,{lt['t0']:.3f},{lt['t0'] + lt['dur']:.3f})':eof_action=pass[v{k}]")
        last = f"[v{k}]"
    if caps and caps.exists():
        inputs += ["-i", str(caps)]
        graph.append(f"{last}[{len(cuts['lowers']) + 2}:v]overlay=0:0:eof_action=pass[vc]")
        last = "[vc]"
    graph.append(f"{last}format=yuv420p[vout]")
    # Each pass gets its own name (written under a temporary one, renamed when whole), and rough-cut-latest.mp4 is
    # copied only after: a reader never opens a file mid-write.
    n = 1 + max((int(m[1]) for f in OUT.glob("rough-cut-v*.mp4") if (m := re.match(r"rough-cut-v(\d+)\.mp4$", f.name))),
                default=0)
    final, two = OUT / f"rough-cut-v{n}.mp4", OUT / f"rough-cut-v{n}-2min.mp4"
    part = OUT / f".rough-cut-v{n}.part.mp4"
    ff(*inputs, "-filter_complex", ";".join(graph), "-map", "[vout]", "-map", "1:a", "-t", str(LENGTH),
       "-c:v", "libx264", "-preset", "medium", "-crf", "19", "-r", str(FPS), "-force_key_frames", str(CARTESIA),
       "-c:a", "aac", "-b:a", "192k", "-ar", "48000", "-movflags", "+faststart", str(part))
    part.rename(final)
    ff("-i", str(final), "-t", str(CARTESIA), "-c:v", "copy", "-af", f"afade=t=out:st={CARTESIA - 0.6}:d=0.6",
       "-c:a", "aac", "-b:a", "192k", "-movflags", "+faststart", str(part))
    part.rename(two)
    for src, name in ((final, "rough-cut-latest.mp4"), (two, "rough-cut-latest-2min.mp4")):
        shutil.copy(src, part)
        part.rename(OUT / name)
    write_lists(cuts)
    for f in (final, two):
        print(f"{f}  {seconds(f):.2f} s  {f.stat().st_size / 1e6:.1f} MB")


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else ""
    WORK.mkdir(parents=True, exist_ok=True)
    if cmd == "ingest":
        ingest(sys.argv[sys.argv.index("--since") + 1] if "--since" in sys.argv else "00:00")
    elif cmd == "probe":
        probe_all()
    elif cmd == "plan":
        plan()
    elif cmd == "build":
        build()
    elif cmd == "backup":
        backup()
    elif cmd == "captions":  # just the captions (headless Chrome), for a build --reuse-captions after
        cuts = load(WORK / "cuts.json", None)
        clips = {c["name"]: c for c in load(WORK / "clips.json", [])}
        room_stem(cuts, clips)
        captions(cuts)
    elif cmd == "beats":
        print(beats()[:12])
    else:
        sys.exit(__doc__)
