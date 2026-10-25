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
THEME_AT = 13.5  # where the hit lands in the video (C1, on a bar: every bar is counted from here)
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
    # Matus's answers to camera from Photo Booth: dragged to the Desktop ("Movie on …") or left in its library.
    booth = sorted((Path.home() / "Desktop").glob("Movie on*")) + sorted((Path.home() / "Pictures/Photo Booth Library/Pictures").glob("*.mov"))
    for f in booth:
        if f.suffix.lower() in MEDIA and f.stat().st_mtime >= cutoff and not (RAW / f.name).exists():
            (RAW / f.name).symlink_to(f)
            print(f"linked {f.parent.name}/{f.name} -> raw/{f.name}")
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
        elif n.startswith("movie on") or "photo booth" in c["path"].lower() or "photo booth" in str(Path(c["path"]).resolve()).lower():
            c["kind"], c["mirrored"] = "answer", False  # this Mac's Photo Booth saves un-mirrored (the banners read right)
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


def bars() -> list[float]:
    """The theme's bar starts on the video's clock (work/theme-beats.json: the leader's beat track of the trimmed
    master, 107.7 BPM; a bar is every 4th beat from its first), else none."""
    return [round(THEME_AT + b - THEME_HIT, 3) for b in load(WORK / "theme-beats.json", {}).get("beats", [])[::4]]


def on_bar(t: float, bars_: list[float], reach: float = 1.12) -> float:
    """A card's cut moved onto the nearest bar start (within half a bar), else left where it is."""
    near = min(bars_, key=lambda b: abs(b - t), default=t)
    return near if abs(near - t) <= reach else t


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
    # 0:02.5-0:04 the poet's phone: three phrases dealt (hard cut mid-word); L2 carries Moss
    if deal and phones:
        # The phone shows Homer's three phrases on its SPEAK screen; the recording we have is the second poet's.
        hand_phone = phone_of(turns[0]["who"] if turns else None)  # the first poet's phrases, on their own phone
        hand = turns[0]["speak"] + 0.5 if turns else deal + 2.0
        shot(2.5, 1.5, wide, at(wide, deal + 2.0), "full", "three phrases dealt", deal + 2.0,
             inset={"src": hand_phone["name"], "src_t": round(at(hand_phone, hand), 3)})
    lower("L2", 2.5, 1.5)
    # 0:04-0:13.5 the poet speaks (the wide, then the arena's live words; room sound, no music) under L0, the one
    # lower third (what this is, for a judge with the sound off); a second of silence; Homer's real verdict, 3 s, L4
    # at the top of the frame (lower, it sat on the arena's own verse and caption bar)
    v = None
    if first:
        s = first["speak"] + 0.2
        battle(4.0, 2.5, s, "verse 1: the wide", prefer="wide")
        battle(6.5, 3.0, s + 2.5, "verse 1: the live words")
        shot(9.5, 1.0, mac or wide, at(mac or wide, s + 7.0), "crop" if mac else "full", "a second of silence", s + 7.0,
             room=False)
        v = (first["score"] or (first["end"] or s + 18) + 3) - 0.3
        battle(10.5, THEME_AT - 10.5, v, "verdict 1 lands")
        lts.append({"id": "L4", "t0": 10.5, "dur": THEME_AT - 10.5, "file": card("L4"), "dy": -730})  # top: clear of the card
        faces = v + (THEME_AT - 10.5)
    else:
        faces = None
    l0 = card("L0") or (brand_badges()["L0"] if BRAND.exists() else None)
    if l0:
        lts.append({"id": "L0", "t0": 4.0, "dur": 6.5, "file": l0, "over": True})
    # C1 on the theme's hit; the room reacting (L1)
    shot(THEME_AT, 1.5, "C1", 0, "card", "C1 title on the theme's hit", room=False)
    if faces:
        shot(THEME_AT + 1.5, 2.5, wide, at(wide, faces), "full", "the room reacting", faces)
        lower("L1", THEME_AT + 1.5, 2.5)
    # Matus to camera: M1 (what it is, LM on it, three one-bar cut-ins under his voice), then M2 (the value)
    bar_ = bars()
    bar_len = (bar_[-1] - bar_[0]) / (len(bar_) - 1) if len(bar_) > 1 else 4 * 60 / 107.666
    answers = answer_clips(clips, take)
    a0 = THEME_AT + 4.0
    m1_end = answer(segs, "M1", answers.get("M1"), a0, 5.0, own=True)
    lower("LM", a0, 4.0)
    cut_end = 0.0

    def under(mid: str, cue: str, make, length: float = bar_len) -> None:
        """A cut-in under an answer's voice from its word `cue` (make(t0, dur) adds the shot): never before the last
        cut-in ends, never in the answer's last half second. The answer's picture splits around it; its sound runs on."""
        nonlocal cut_end
        seg = next((x for x in segs if x.get("answer") == mid), None)
        if not seg:
            return
        src0, n = seg.get("audio_src", seg["src_t"]), seg.get("audio_dur", seg["dur"])
        said = [w for w in heard(WORK / "answers" / f"{Path(seg['src']).stem}.wav") if src0 < w["end"] <= src0 + n]
        want = [norm(x) for x in cue.split()]
        k = next((i for i in range(len(said)) if [norm(x["w"]) for x in said[i:i + len(want)]] == want), None)
        if k is None:
            print(f"note: {mid} never says \"{cue}\"; no cut-in there")
            return
        w = said[k]
        a_ = max(cut_end, seg.get("audio_t0", seg["t0"]) + max(w["start"], w["end"] - 0.5) - src0 - 0.1)
        host = next((x for x in segs if x["src"] == seg["src"] and x["t0"] <= a_ < x["t0"] + x["dur"]), None)
        if not host:
            return
        b_ = min(a_ + length, host["t0"] + host["dur"] - 0.5)
        if b_ - a_ < 1.0:
            return
        segs.append({**host, "t0": round(b_, 3), "dur": round(host["t0"] + host["dur"] - b_, 3),
                     "src_t": round(host["src_t"] + b_ - host["t0"], 3), "own_audio": False, "answer": None,
                     "note": f"{mid}: Matus to camera (after a cut-in)"})
        host["dur"] = round(a_ - host["t0"], 3)
        make(a_, b_ - a_)
        cut_end = b_

    def game_of(c: dict) -> str:
        open_hall = [h for h in take.get("halls", []) if c.get("start") and h["created"] <= c["start"]]
        return open_hall[-1]["event"] if open_hall else ""

    if first and v is not None:
        speak_phone = phone_of(first["who"])
        under("M1", "speak a verse", lambda t, d: shot(
            t, d, wide, at(wide, first["speak"] + 1.0), "full", "cut-in: the SPEAK screen", room=False,
            inset={"src": speak_phone["name"], "src_t": round(at(speak_phone, first["speak"] + 0.3), 3)} if speak_phone else None))
        under("M1", "judges", lambda t, d: shot(t, d, mac or wide, at(mac or wide, v + 0.6), "crop" if mac else "full",
                                                "cut-in: the verdict", room=False))
    boxing = next((c for c in clips if c["kind"] in ("montage", "slomo") and game_of(c) == "Pygmachia"), None)
    if boxing:
        under("M1", "battle your friends", lambda t, d: shot(t, d, boxing, boxing["dur"] * 0.4, "full",
                                                             "cut-in: boxing (Pygmachia)", room=False))
    for sg in sorted((x for x in segs if x.get("note", "").endswith("(after a cut-in)")), key=lambda x: x["t0"]):
        if sg["dur"] < 0.4:  # a sliver of his face between two cut-ins: the cut-in before it runs on instead
            prev = max((x for x in segs if x["t0"] < sg["t0"]), key=lambda x: x["t0"])
            prev["dur"] = round(prev["dur"] + sg["dur"], 3)
            segs.remove(sg)
    m2_end = answer(segs, "M2", answers.get("M2"), m1_end, 8.0, own=True)
    # 0:33-1:12 the rest of the battle, in order: the next poet stepping up, each answer (laptop, wide, the poet's own
    # phone), its verdict (Homer heard whole, to the arena's next step), faces; the freeze rescue uncut at 1x inside
    # its verse; the round's call and the gold line last. Never into the finale (the song has its own place).
    # Short of time, the reactions grow; past it, the verses give way first.
    B0, B1 = m2_end, m2_end + 24.0  # the battle keeps 24 s after the answers
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
        if tr["score"]:  # the verdict's reveal, 4.5 s, then faces as Homer goes on (the sound runs straight through)
            vd = min(4.5, after(tr["score"]) - tr["score"] + 0.3)
            beats_.append([tr["score"] - 0.3, vd, "verdict", f"verdict {i}", {}])
            beats_.append([tr["score"] - 0.3 + vd, 1.5, "faces", "faces after the score", {}])
    total = lambda: sum(x[1] for x in beats_)
    seen = lambda: max((b[0] + b[1] for b in beats_), default=round_end or 0.0)
    gold_len = min(3.5, (finale_at or (round_end or 0) + 8.0) - max(round_end, seen())) if round_end else 0.0
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
        bt[1] = max(6.0, bt[1] - (total() - room_for))
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
        battle(t, B1 - t, call_from + 0.3, "the round's call and the gold line, carved")  # past the screen change
        l8 = t + max(0.5, (carved or call_from) - call_from)
        lower("L8", l8, min(4.0, B1 - l8))
    elif t < B1 and wide and faces:
        shot(t, B1 - t, wide, at(wide, faces + 8.0), "full", "the room (fill)", faces + 8.0)
    lower("L5", B0 + 1.0, 4.0)
    verdict_at, stab = B0, None
    for bt in beats_:
        if bt[2] == "verdict":
            lower("L7", verdict_at + 0.3, 4.0)
            stab = verdict_at  # the theme stabs for two bars on the reveal
            break
        verdict_at += bt[1]
    # 1:12-1:21 Matus to camera: M3 (what we built), with 2.5 s of real website footage cut in under his voice: the
    # arena in the browser, address bar in frame (the take's minigame recording, the archery range). L9 over it.
    games_mac = max((c for c in clip_by_kind(clips, "mac") if c is not mac and (c.get("start") or 0) > take["created"]),
                    key=lambda c: c["dur"], default=None)
    toxeia = next((h for h in take.get("halls", []) if h["event"] == "Toxeia"), None)
    cut_in = snap(B1 + 3.5, grid) if games_mac and toxeia else None
    m3_end = answer(segs, "M3", answers.get("M3"), B1, 9.0, cutaway=(cut_in, 2.5) if cut_in else None,
                    covers=(2.5, 4.0) if cut_in else ())
    joins = CUTAWAY_AT.get("M3") or []
    cut_in = joins[0] if joins else cut_in  # M3 joined at sentence ends: the website hides its first join
    if cut_in:
        src_t = min(games_mac["dur"] - 4.0, max(0.0, toxeia["created"] + 40.0 - games_mac["start"]))
        shot(cut_in, 2.5, games_mac, src_t, "browser", "website: the arena in the browser (archery), under M3", room=False)
        lower("L9", cut_in, 2.5)
    # The SpacetimeDB moment: multiplayer's timeline rows (broll/timeline.mp4, frame 0 on this Mac's clock in
    # timeline.json) beside the wide at the same instant, around the verdict it anchors on; else the turn that ran out.
    # It hides M3's second join (his "the SpacetimeDB team told us…") when M3 has one; else it follows M3 to C2.
    tl = BROLL / "timeline.json"
    stdb_at = joins[1] if len(joins) > 1 and tl.exists() and wide else None
    c2 = on_bar(m3_end if stdb_at is not None else 87.0, bar_)
    stdb_t, stdb_d = (stdb_at, 4.0) if stdb_at is not None else (m3_end, c2 - m3_end)
    if tl.exists() and wide:
        meta = json.loads(tl.read_text())
        from_s = max(0.0, meta["anchor"]["atSecond"] - 3.0)
        epoch = meta["frame0"]["epochMs"] / 1000 + from_s
        shot(stdb_t, stdb_d, wide, at(wide, epoch), "full", "SpacetimeDB: the verdict lands, every screen at once",
             epoch, beside=str(BROLL / "timeline.mp4"), beside_t=from_s, beside_crop="1240:420:60:640")  # the last rows, big
        if BRAND.exists():
            lts.append({"id": "N-LOG", "t0": stdb_t, "dur": stdb_d, "file": brand_badges()["N-LOG"], "over": True})
    else:
        timeout = next((tr for tr in turns if tr["timeout"]), None)
        if timeout:
            shot(stdb_t, stdb_d, wide, at(wide, timeout["end"] - 3.0), "full", "SpacetimeDB: the timer ends the turn",
                 timeout["end"] - 3.0)
    lower("L10", stdb_t, stdb_d)
    if stdb_at is not None:  # M3's last picture ends where C2 lands on its bar (his last word may run under C2)
        last = max((x for x in segs if x.get("answer") == "M3"), key=lambda x: x["t0"])
        last["dur"] = round(c2 - last["t0"], 3)
    # The diagram and the number card on the bars (lines 6 and 7 are 6.5 s and 4.5 s: the cards hold them whole),
    # then the stitched song to C5 (the song gives back whatever M3 took past 1:27), C5 over its tail
    c3 = on_bar(c2 + 6.7, bar_)
    song0 = on_bar(c3 + 4.6, bar_)
    c5 = on_bar(song0 + 7 * bar_len, bar_)  # the song: seven bars
    mont0 = on_bar(c5 + 2 * bar_len, bar_)  # C5: two
    shot(c2, c3 - c2, "C2", 0, "card", "C2 the diagram (line 6)", room=False)
    shot(c3, song0 - c3, "C3", 0, "card", "C3 20% -> 3% (line 7)", room=False)
    finale = moment(take, "advance", "finale")
    if finale:  # the song, cut between the laptop, faces on the wide and a poet's phone; the room sound runs on
        f0 = finale + 1.0
        song = [(0.0, 3.8, "the stitched song", {}), (3.8, 3.6, "the song: faces", None),
                (7.4, 3.4, "the song: the phone", {"prefer": "wide", "inset": phone_of(first["who"] if first else None)}),
                (10.8, 3.2, "the song, line by line", {}), (14.0, 99.0, "the song: faces", None)]
        for off, d, note, kw in song:
            a_, b_ = song0 + off, min(song0 + off + d, c5)
            if b_ - a_ < 0.6:  # out of room: the shot before runs on to C5
                segs[-1]["dur"] = round(c5 - segs[-1]["t0"], 3)
                break
            if kw is None:
                shot(a_, b_ - a_, wide, at(wide, f0 + off), "full", note, f0 + off)
            else:
                battle(a_, b_ - a_, f0 + off, note, **kw)
        shot(c5, mont0 - c5, "C5", 0, "card", "C5 responsible card (the song's tail under it)", f0 + (c5 - song0))
    else:
        shot(song0, mont0 - song0, "C5", 0, "card", "C5 (no song in the take)", room=False)
    # The training montage, cut on the bars at varied lengths (one label); then the Figma workflow, three bars centred
    # on F1's Atelier -> Hall flip (at 10 s in artist's render), L14 held over it
    fig0 = on_bar(mont0 + 6 * bar_len, bar_)
    m4_0 = on_bar(fig0 + 3 * bar_len, bar_)
    montage(segs, lts, clips, take, grid, start=mont0, end=fig0, bars_=bar_)
    if BRAND.exists():
        lts.append({"id": "N-MONTAGE", "t0": mont0, "dur": round(bar_len, 3), "file": brand_badges()["N-MONTAGE"], "over": True})
    f1 = card("F1")
    if f1 and f1.endswith(".mp4"):
        shot(fig0, m4_0 - fig0, f1, max(0.0, 10.0 - (m4_0 - fig0) / 2), "file", "Figma: F1-flip.mp4, on the flip",
             room=False, graded=True, hold=True)
    else:
        shot(fig0, m4_0 - fig0, "FIGMA", 0, "card", "(the Figma workflow: artist's render goes here)", room=False)
    lower("L14", fig0, m4_0 - fig0)
    # Matus to camera: M4 (what's next) from a bar; the end card lands on the first bar after his last word
    m4_end = answer(segs, "M4", answers.get("M4"), m4_0, 21.0)
    c6 = next((b for b in bar_ if m4_end - 0.2 <= b <= m4_end + 1.6), on_bar(m4_end, bar_))  # after his last word
    m4s = sorted((x for x in segs if x.get("answer") == "M4"), key=lambda x: x["t0"])
    if m4s:  # his picture ends at C6 (a held frame if C6 is later; his last word under C6 if it's earlier)
        m4s[-1]["dur"] = round(c6 - m4s[-1]["t0"], 3)
    # L15 v2, the exact claim (a public fork, fixes sent upstream): on his face after the SpacetimeDB beat, and from
    # M4's SDK sentence to 2 s into the end card
    sdk = card("L15") or (brand_badges()["L-SDK"] if BRAND.exists() else None)
    if sdk and stdb_at is not None and c2 - (stdb_at + 4.0) > 1.0:
        lts.append({"id": "L-SDK", "t0": round(stdb_at + 4.0, 3), "dur": round(c2 - stdb_at - 4.0, 3), "file": sdk, "over": True})
    if sdk and len(m4s) > 1:
        lts.append({"id": "L-SDK", "t0": m4s[-1]["t0"], "dur": round(c6 + 2.0 - m4s[-1]["t0"], 3), "file": sdk, "over": True})
    # The end: at C6 the theme jumps (bar to bar) to its last bars, so its final chord lands on the end card; the video
    # ends 0.8 s after it
    theme_bars = load(WORK / "theme-beats.json", {}).get("beats", [])[::4]
    theme_len = seconds(THEME)
    natural = THEME_AT + theme_len - THEME_HIT
    near_end = [b for b in theme_bars if 6.0 <= theme_len - b <= 7.7]
    tail_from = min(near_end, key=lambda b: abs(theme_len - b - 6.7)) if near_end else None
    if tail_from is not None and c6 + theme_len - tail_from < natural - 0.5:
        tail = theme_len - tail_from
    else:
        tail_from, tail = None, natural - c6
    global LENGTH
    LENGTH = round(min(179.0, c6 + tail + 0.8), 3)
    shot(c6, LENGTH - c6, "C6", 0, "card", "C6 the end card (Play it now, held)", room=False)
    if BRAND.exists():  # the sponsors' badges ride with their lower thirds and cards
        badges = brand_badges()
        for lt in list(lts):
            if f"B-{lt['id']}" in badges:
                lts.append({"id": f"B-{lt['id']}", "t0": lt["t0"], "dur": lt["dur"], "file": badges[f"B-{lt['id']}"], "over": True,
                            "dy": lt.get("dy", 0)})
        for sg in segs:
            bid = {"C5": "B-C5"}.get(sg["src"])  # C2 and C6 carry their own logos (artist, v5) or ("B-FIG" if sg["note"].startswith("Figma") else None)
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
    narr = [("vo-00-greek.wav", 0.0, 2.5), ("vo-06.wav", round(c2 + 0.1, 3), None), ("vo-07.wav", round(c3 + 0.1, 3), None),
            ("vo-08.wav", round(mont0 + 0.6, 3), None), ("vo-09.wav", round(fig0 + 0.6, 3), None),
            ("vo-10.wav", round(c6 + 1.0, 3), None)]
    marks = {"stdb": stdb_t, "song": song0, "montage": mont0, "figma": fig0, "m4": m4_0, "c6": c6, "bar": round(bar_len, 4),
             "stab": stab, "tail_from": tail_from, "b1": B1}
    cuts = {"segments": segs, "lowers": lts, "take": take["code"], "theme_at": THEME_AT, "length": LENGTH,
            "music": music_plan(segs, turns, B0, marks), "narration": narr, "marks": marks}
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


# What each answer is about (leader, 04:15): Matus speaks loose versions and may ad-lib, so a piece of the take is
# matched to its answer by these anchors, not by the script's exact words.
ANSWER_KEYS = {
    "M1": ["iliad", "homer", "out loud", "coaches", "practise", "practice", "battle", "socrates", "games"],
    "M2": ["scared", "speaking", "greeks", "sport", "gym"],
    "M3": ["weekend", "shipped", "battle", "talk to homer", "lessons", "motion games", "website", "server", "faked", "mocked"],
    "M4": ["weekend project", "testflight", "test flight", "app store", "open mic", "classroom", "party", "rooms",
           "spacetimedb", "spacetime db", "swift sdk", "fixes"],
}


def anchors(said: str) -> dict[str, set[str]]:
    """The anchors each answer finds in a piece of speech (a phrase counts as its number of words)."""
    t = " " + re.sub(r"\s+", " ", re.sub(r"[^a-z0-9 ]", " ", said.lower())) + " "
    return {m: {k for k in ks if f" {k} " in t} for m, ks in ANSWER_KEYS.items()}


def weight(keys: set[str]) -> int:
    return sum(len(k.split()) for k in keys)


RETAKE_CUES = ("again", "let me", "sorry", "hold on", "wait", "redo", "one more", "start over", "scratch that")


# How Matus opens each answer (both takes, 04:15 and 04:22): the cue that starts it.
ANSWER_CUES = {
    "M1": ["what is"],
    "M2": ["why would", "why should", "why do"],
    "M3": ["this weekend", "this entire weekend", "ended up building", "what we built", "this whole weekend"],
    "M4": ["whats next", "what is next", "not stopping", "not really stopping"],
}


def answer_runs(clip: dict) -> list[dict]:
    """One Photo Booth take, cut into its four answers by how he opens each (ANSWER_CUES, in order: "So what is
    MeNIN?", "So why would…", "…this weekend…", "What's next…"): an answer runs from its cue's sentence to the next
    answer's. A cue said twice before the next answer's (a retake) starts the answer at the later one. Anchors
    (ANSWER_KEYS) are kept for the record. Empty when the cues aren't there."""
    wav = WORK / "answers" / f"{Path(clip['name']).stem}.wav"
    if not wav.exists():
        wav.parent.mkdir(parents=True, exist_ok=True)
        ff("-i", clip["path"], "-vn", "-ac", "1", "-ar", "16000", str(wav))
    words = heard(wav)
    if not words:
        return []
    toks = [norm(w["w"]) for w in words]  # "what's" -> "whats": one token a word

    def hits(cue: str) -> list[int]:
        parts = cue.split()
        return [i for i in range(len(toks)) if toks[i:i + len(parts)] == parts]

    def sentence_start(i: int) -> int:  # back to the start of the sentence the cue is in ("So what's next?")
        while i > 0 and not words[i - 1]["w"].rstrip().endswith((".", "?", "!")) and words[i]["start"] - words[i - 1]["end"] < 1.0:
            i -= 1
        return i

    starts: dict[str, int] = {}
    floor = 0
    for m in ANSWER_CUES:
        found = sorted(i for c in ANSWER_CUES[m] for i in hits(c) if i >= floor)
        if not found:
            if m == "M1":
                found = [0]
            else:
                continue
        nxt = [i for c in ANSWER_CUES.get(f"M{int(m[1]) + 1}", []) for i in hits(c) if i > found[0]] if m != "M4" else []
        before = [i for i in found if not nxt or i < min(nxt)] or found[:1]
        # cues within 5 s of each other are one opening ("So what's next? So we're not stopping…"); a later
        # opening is a retake: the answer starts at the first cue of the last opening
        opening = before[0]
        for prev_i, i in zip(before, before[1:]):
            if words[i]["start"] - words[prev_i]["start"] > 5.0:
                opening = i
        starts[m] = sentence_start(opening)
        floor = starts[m] + 3
    order = [m for m in ANSWER_CUES if m in starts]
    runs = []
    for k, m in enumerate(order):
        i0 = starts[m]
        i1 = starts[order[k + 1]] if k + 1 < len(order) else len(words)
        seg = words[i0:i1]
        if not seg:
            continue
        said = " ".join(w["w"] for w in seg)
        runs.append({"clip": clip["name"], "a": max(0.0, seg[0]["start"] - 0.15), "b": min(clip["dur"], seg[-1]["end"] + 0.3),
                     "m": m, "said": said, "keys": anchors(said)[m]})
    return runs


def answer_takes(clip: dict) -> dict[str, tuple[float, float]]:
    """The best take of each answer in one Photo Booth take (see answer_runs), as (from, to) in seconds."""
    return {m: (r_["a"], r_["b"]) for m, r_ in best_runs(answer_runs(clip)).items()}


def best_runs(runs: list[dict]) -> dict[str, dict]:
    """Of several takes of a line (in one file or across files, in recording order), the one carrying most of its
    anchors wins, the later on a tie."""
    picked: dict[str, dict] = {}
    for r_ in runs:
        if r_["m"] not in picked or weight(r_["keys"]) >= weight(picked[r_["m"]]["keys"]):
            picked[r_["m"]] = r_
    for m, r_ in sorted(picked.items()):
        print(f"{m}: {r_['a']:.1f}-{r_['b']:.1f} s of {r_['clip']} (anchors: {', '.join(sorted(r_['keys']))})")
    return picked


# What Cartesia hears for names it doesn't know, set right in his captions.
SPELLED = {"menon": "MeNIN", "meenan": "MeNIN", "menin": "MeNIN", "meenin": "MeNIN", "mennin": "MeNIN",
           "manning": "MeNIN", "maning": "MeNIN", "menning": "MeNIN", "testlight": "TestFlight",
           "meanin": "MeNIN", "menan": "MeNIN", "testflight": "TestFlight", "spacetimedb": "SpacetimeDB",
           "socrates": "Socrates", "iliad": "Iliad", "homer": "Homer", "cartesia": "Cartesia", "manny": "MeNIN",
           "testfight": "TestFlight"}
# Whole-phrase fixes in his captions (what Cartesia heard, as he said it)
CAPTION_FIXES = {"AI is just talks": "AI just talks"}


def spelled(w: str) -> str:
    key = norm(w)
    if key in SPELLED:
        tail = re.search(r"[^\w]*$", w).group(0)
        return SPELLED[key] + tail
    return w


def answer_clips(clips: list[dict], take: dict) -> dict[str, dict]:
    """Matus's four answers to camera: the clips (with sound) filmed after the last hall closed, in order, the longest
    taking M4 (~18 s). overrides.json "answers": {"M1": clip name, ...} wins."""
    by_name = {c["name"]: c for c in clips}
    o = overrides().get("answers", {})
    if o:
        return {k: by_name[v] for k, v in o.items() if v in by_name}
    booth = sorted((c for c in clips if c["kind"] == "answer"), key=lambda c: c.get("start") or 0)
    if booth:  # Photo Booth takes: each cut into its answers; one take is used for all four (his voice and light match)
        want = overrides().get("answer_take", "")
        takes = [(c, answer_runs(c)) for c in booth]
        full = [(c, rs) for c, rs in takes if len(rs) == 4 and (not want or want in c["name"])]
        c, rs = (full or [max(takes, key=lambda t: len(t[1]))])[-1]
        for r_ in rs:
            print(f"{r_['m']}: {r_['a']:.1f}-{r_['b']:.1f} s of {c['name']} ({r_['b'] - r_['a']:.1f} s): {r_['said'][:70]}")
        return {r_["m"]: {**c, "span": (r_["a"], r_["b"])} for r_ in rs}
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


def sentence_end(clip: dict, a: float, slot: float) -> float | None:
    """How long an answer runs if it stops at the end of the sentence nearest `slot` seconds in (within -2..+2.5 s)."""
    wav = WORK / "answers" / f"{Path(clip['name']).stem}.wav"
    if not wav.exists():
        return None
    ends = [w["end"] - a + 0.25 for w in heard(wav) if w["start"] >= a and w["w"].rstrip().endswith((".", "?", "!"))]
    near = [e for e in ends if slot - 2.0 <= e <= slot + 2.5]
    return min(near, key=lambda e: abs(e - slot)) if near else None


MUST_KEEP = {"M3": ["swift sdk"]}  # the line a sponsor asked for (leader, 04:25): never trimmed out
CUTAWAY_AT: dict[str, list[float]] = {}  # where an answer's joins landed (its cut-ins hide them)


def sentences(clip: dict, a: float, b: float) -> list[tuple[float, float, str]]:
    """An answer's sentences as heard: (start, end, text), split at . ? !"""
    wav = WORK / "answers" / f"{Path(clip['name']).stem}.wav"
    out, cur = [], []
    for w in (x for x in heard(wav) if a <= x["start"] < b) if wav.exists() else []:
        cur.append(w)
        if w["w"].rstrip().endswith((".", "?", "!")):
            out.append((cur[0]["start"], cur[-1]["end"], " ".join(x["w"] for x in cur)))
            cur = []
    if cur:
        out.append((cur[0]["start"], cur[-1]["end"], " ".join(x["w"] for x in cur)))
    return out


def must_parts(clip: dict, mid: str, a: float, b: float, slot: float) -> list[tuple[float, float]] | None:
    """An answer too long for its slot but holding a must-keep line: its opening sentence, then a cut to the
    sentences holding the line (the middle goes). None when nothing must be kept."""
    keep = MUST_KEEP.get(mid)
    if not keep:
        return None
    sents = sentences(clip, a, b)
    musts = [k for k, st in enumerate(sents) if any(m in norm_text(st[2]) for m in keep)]
    if not sents or not musts:
        return None
    picks = sorted({0, *musts})
    parts: list[list[float]] = []
    for k in picks:
        s0, s1 = sents[k][0] - 0.15, sents[k][1] + 0.3
        if parts and k - 1 in picks:
            parts[-1][1] = s1
        else:
            parts.append([s0, s1])
    return [(max(0.0, x), y) for x, y in parts]


def keep_parts(clip: dict, mid: str, a: float, b: float) -> list[tuple[float, float]] | None:
    """An answer cut by hand at sentence ends (overrides.json "answer_keep": {"M3": [["so what we actually",
    "end to end"], …]}): each pair names the first and last words of a stretch to keep, in order; stretches that
    touch are joined. None when the answer has none."""
    spans = overrides().get("answer_keep", {}).get(mid)
    if not spans:
        return None
    words = [w for w in heard(WORK / "answers" / f"{Path(clip['name']).stem}.wav") if a - 1.0 <= w["start"] < b + 1.0]
    toks = [norm(w["w"]) for w in words]

    def find(phrase: str, after: int) -> int:
        want = [norm(x) for x in phrase.split()]
        for i in range(after, len(toks) - len(want) + 1):
            if toks[i:i + len(want)] == want:
                return i
        sys.exit(f"{mid}: \"{phrase}\" isn't in {clip['name']} between {a:.1f} and {b:.1f} s")

    parts: list[list[float]] = []
    i = 0
    for first, last in spans:
        i0 = find(first, i)
        i1 = find(last, i0) + len(last.split()) - 1
        start = max(words[i0]["start"], words[i0]["end"] - 0.5) - 0.05  # a first word's start is often its gap's
        if parts and start - parts[-1][1] < 0.4:
            parts[-1][1] = words[i1]["end"] + 0.2
        else:
            parts.append([start, words[i1]["end"] + 0.2])
        i = i1 + 1
    return [(max(0.0, x), y) for x, y in parts]


def norm_text(t: str) -> str:
    return re.sub(r"\s+", " ", re.sub(r"[^a-z0-9 ]", " ", t.lower()))


def answer(segs: list[dict], mid: str, clip: dict | None, t0: float, slot: float,
           cutaway: tuple[float, float] | None = None, own: bool = False, covers: tuple[float, ...] = ()) -> float:
    """Matus to camera: the answer from its start with its own sound, landscape filled or portrait cropped to 16:9,
    graded; held on its last frame if it runs short of its slot (M4 runs its own length, the end card takes the
    rest). A labelled card until the clip lands. Returns where it ends."""
    a, b = clip["span"] if clip and clip.get("span") else speech_span(clip) if clip else (0.0, slot)
    # M1, M2 and M4 run their own length (M4 at most its slot); M3 keeps its slot (the cut-in sits inside it). An
    # answer longer than its slot ends at the sentence end nearest the slot's end, never mid-sentence.
    dur = (b - a) if clip and own else min(slot, b - a) if clip and mid == "M4" else slot
    parts = (keep_parts(clip, mid, a, b) if clip else None) or (
        must_parts(clip, mid, a, b, slot) if clip and not own and b - a > slot + 0.3 else None)
    if parts and len(parts) > 1:  # stretches joined at sentence ends: a cut-in (covers) hides a join, else he punches in
        base = {"src": clip["name"], "mode": "portrait" if clip["h"] > clip["w"] else "full", "epoch": None,
                "room": False, "hold": True, "hflip": bool(clip.get("mirrored")), "own_audio": True, "answer": mid}
        t, joins = t0, []
        for k, (pa, pb) in enumerate(parts):
            n = pb - pa
            # his sound for this stretch runs from t (under a cut-in too); the picture resumes after the cut-in
            hide = min(covers[k - 1], n - 1.0) if 0 < k <= len(covers) else 0.0
            seg = {**base, "t0": round(t + hide, 3), "dur": round(n - hide, 3), "src_t": round(pa + hide, 3),
                   "note": f"{mid}: Matus to camera (part {k + 1})", "audio_t0": round(t, 3), "audio_src": round(pa, 3),
                   "audio_dur": round(n, 3)}
            if k % 2 and not hide:
                seg["zoom"] = 1.12  # a punch-in hides the jump (the next stretch punches back out)
            segs.append(seg)
            if k:
                joins.append(round(t, 3))
            t += n
        CUTAWAY_AT[mid] = joins
        return t
    if clip and not own and b - a > slot + 0.3:
        dur = sentence_end(clip, a, slot) or slot
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
               "epoch": None, "room": False, "hold": True, "hflip": bool(clip.get("mirrored"))}
        if k == 0:
            seg.update(own_audio=True, answer=mid, audio_dur=round(dur, 3))
        segs.append(seg)
    return t0 + dur


def montage(segs, lts, clips, take, grid, start: float = 120.0, end: float = 134.0,
            bars_: list[float] | None = None) -> None:
    """The training montage, start to end: the games' longest takes (two a game at most), in shoot order, cut on the
    theme's bars at varied lengths (1 bar, half, half, 2 bars, 1, half, half, 1.5; never one length throughout). A
    shot of a bar or more runs up at 2-4x and lands on its last 3 beats at 1x (0.25x for slo-mo); a half-bar shot is
    its landing alone. L13 at each game's first shot. The last shot is the last take's end (a miss, a laugh)."""
    pool = sorted([c for c in clips if c["kind"] in ("montage", "slomo")], key=lambda c: c.get("start") or 0)
    if not pool:
        segs.append({"t0": start, "dur": end - start, "src": "C5", "src_t": 0, "mode": "card",
                     "note": "(no montage footage)", "epoch": None, "room": False})
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
    bar = (bars_[-1] - bars_[0]) / (len(bars_) - 1) if bars_ and len(bars_) > 1 else 4 * 60 / 107.666
    beat = bar / 4
    pattern = [1.0, 0.5, 1.0, 2.0, 1.5, 0.5, 1.0]  # boxing (the 4th take) gets the two bars; Stadion a whole one
    lens: list[float] = []
    while sum(lens) < end - start - 0.01:
        rest = end - start - sum(lens)
        want = pattern[len(lens) % len(pattern)] * bar
        lens.append(rest if rest - want < 0.45 * bar else want)  # the last shot takes what's left
    order = list(picked)
    uses = {c["name"]: 1 for c in picked}
    while len(order) < len(lens):  # more shots than takes: the longest takes come back (an earlier stretch of each)
        c = max(picked, key=lambda c: c["dur"] / (uses[c["name"]] + 1))
        uses[c["name"]] += 1
        order.insert(max(i for i, x in enumerate(order) if x is c) + 1, c)
    if len(order) > len(lens):  # fewer shots than takes: the last take still ends it
        order = order[:len(lens) - 1] + order[-1:]
    t, seen, used, plate = start, set(), {}, None
    for c, length in zip(order, lens):
        k = used.get(c["name"], 0)
        used[c["name"]] = k + 1
        rate = 0.25 if c["kind"] == "slomo" else 1.0
        hero = length if length <= 0.6 * bar else 3 * beat
        run = length - hero
        # the landing: the take's end (its second shot lands a third of the way back)
        land = max(0.0, c["dur"] * (1 - k / 3) - hero * rate - (0.3 if k == 0 else 0.0))
        if run > 0.05:
            speed = max(1.0, min(4.0, land / run))
            src0 = max(0.0, land - run * speed)
            segs.append({"t0": round(t, 3), "dur": round(run, 3), "src": c["name"], "src_t": round(src0, 3),
                         "speed": round(speed, 2), "mode": "full", "note": f"montage {c['game']}: the run-up at {speed:.1f}x",
                         "epoch": None, "room": False})
        segs.append({"t0": round(t + run, 3), "dur": round(hero, 3), "src": c["name"], "src_t": round(land, 3),
                     "speed": rate, "mode": "full", "note": f"montage {c['game']}: the landing at {rate:g}x ({length / bar:g} bar)",
                     "epoch": None, "room": False})
        t += length  # no per-game stamps: plan() puts one label over the montage's first bar


def narration(cuts: dict) -> list[tuple[str, float, float | None]]:
    """NARRATION as this cut places it (plan() moves lines 6-9 with their cards and sections)."""
    return [tuple(x) for x in cuts.get("narration", NARRATION)]


def music_plan(segs: list[dict], turns: list[dict], b0: float = 33.0, marks: dict | None = None) -> list[tuple[float, float]]:
    """The theme's level (dB) as keyframes on the video's clock: silent under C0 and the first verse; the hit at C1;
    a -18 bed under the room's reaction and M1/M2; out (hard) from the battle's first step so the live room stands
    alone (and hard-muted inside every verse, its 3-2-1 to its score); back at -20 from the SpacetimeDB moment through
    C2 and C3; out under the stitched song (it's sung) and C5; full (-6) under the montage; -18 under Figma, -16 under
    M4; up into C6 and its final chord; silence for the last 2 s. Ducks under the narration and Matus's words are
    added in mix(). `marks` are the sections' starts as plan() placed them on the bars."""
    m = {"stdb": 81.0, "song": 98.2, "montage": 120.0, "figma": 134.0, "m4": 149.0, "c6": 170.0, "bar": 2.229,
         **{k: v for k, v in (marks or {}).items() if v is not None}}
    sections = [(0.0, -90), (THEME_AT, -4), (THEME_AT + 1.5, -18), (b0, -90), (m["stdb"], -20), (m["song"], -90),
                (m["montage"], -6), (m["figma"], -18), (m["m4"], -16), (m["c6"], -8)]
    if "stab" in m:  # two bars of the theme on verdict 2's reveal, then out again
        sections += [(m["stab"], -10), (round(m["stab"] + 2 * m["bar"], 3), -90)]
    sections.sort()
    verses = [(tr["start"], tr["score"] or (tr["end"] or tr["start"] + 22) + 4) for tr in turns]
    muted = [(s["t0"], s["t0"] + s["dur"]) for s in segs  # hard-muted inside a verse (its 3-2-1 and the words)
             if b0 <= s["t0"] < m.get("b1", 72.0) and s["note"].startswith("verse") and s.get("epoch")
             and any(a <= s["epoch"] <= b for a, b in verses)]

    def level(t: float) -> float:
        if any(a <= t < b for a, b in muted):
            return -90
        return next((d for x, d in reversed(sections) if x <= t), -90)

    keys: list[tuple[float, float]] = [(0.0, -90)]
    for m in sorted({x for x, _ in sections} | {a for a, _ in muted} | {b for _, b in muted}):
        before, after = level(m - 0.001), level(m)
        if before != after:
            keys += [(round(max(0.0, m - 0.02), 3), before), (round(m, 3), after)]
    if marks and marks.get("figma") is not None:  # out of the montage over one bar, not a 12 dB step in a frame
        f, bar = marks["figma"], marks.get("bar") or 2.229
        keys = [k for k in keys if not (f - 0.03 <= k[0] < f + bar)]
        keys = sorted(keys + [(round(f, 3), -6), (round(f + bar, 3), -18)])
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
    for f, start, dur in narration(cuts):
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
    for f, start, dur in narration(cuts):
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
        if not clip:
            continue
        wav = WORK / "answers" / f"{Path(clip['name']).stem}.wav"
        if not wav.exists():
            wav.parent.mkdir(parents=True, exist_ok=True)
            ff("-i", clip["path"], "-vn", "-ac", "1", "-ar", "16000", str(wav))
        src0, n = seg.get("audio_src", seg["src_t"]), seg.get("audio_dur", seg["dur"])
        # A heard word's start includes the gap before it; its end doesn't: a word is this stretch's if it ends inside
        # it (by start, the next sentence's first word leaked in and the stretch's own first word fell out).
        words = [w for w in heard(wav) if src0 + 0.1 < w["end"] <= src0 + n - 0.15]
        shift = seg.get("audio_t0", seg["t0"]) - src0
        own: list[dict] = []
        for w in words:  # his own words (he speaks loose versions), names spelled right
            w = {**w, "w": spelled(w["w"]), "start": max(w["start"], src0) + shift, "end": w["end"] + shift, "who": "matus"}
            if own and w["w"].startswith("-"):  # "end -to -end" is one word
                own[-1] = {**own[-1], "w": own[-1]["w"] + w["w"], "end": w["end"]}
            else:
                own.append(w)
        if own and seg.get("audio_src") is not None:  # a stretch cut at sentence ends reads as sentences
            own[0]["w"] = own[0]["w"][:1].upper() + own[0]["w"][1:]
            if not re.search(r"[.?!]$", own[-1]["w"]):
                own[-1]["w"] = own[-1]["w"].rstrip(",;:") + "."
        out += own
        busy.append((seg.get("audio_t0", seg["t0"]), seg.get("audio_t0", seg["t0"]) + seg.get("audio_dur", seg["dur"])))
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
        if (cur and w["start"] - cur[-1]["end"] < 0.7 and not re.search(r"[.?!]$", cur[-1]["w"]) and cur[-1]["who"] == w["who"]
                and (w["who"] != "room" and not (cur[-1]["w"].endswith(",") and len(" ".join(x["w"] for x in cur)) >= 20)
                     # his and Homer's: a clause (a comma ends one past 20 characters), then balanced
                     or w["who"] == "room" and len(cur) < 7 and len(" ".join(x["w"] for x in cur + [w])) <= 40)):
            cur.append(w)
        else:
            lines.append([w])
    balanced: list[list[dict]] = []
    for ln in lines:  # his and Homer's clauses: split into even chunks of 44 characters at most
        ends, acc = [], 0
        for x in ln:
            acc += len(x["w"]) + 1
            ends.append(acc)
        n = -(-acc // 45) if ln[0]["who"] != "room" else 1
        cuts = sorted({min(range(len(ln) - 1), key=lambda i: abs(ends[i] - k * acc / n)) + 1 for k in range(1, n)}) if n > 1 else []
        for a, b in zip([0] + cuts, cuts + [len(ln)]):
            if b > a:
                balanced.append(ln[a:b])
    lines = balanced
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
    plates = [lt for lt in cuts["lowers"] if lt["id"] == "L0" or not lt.get("over") and lt["id"].startswith("L")]
    full = [lt for lt in cuts["lowers"] if lt["id"] == "L-SDK"]
    on = lambda group, a, b: any(lt["t0"] < b and a < lt["t0"] + lt["dur"] for lt in group)
    beside = [sg for sg in cuts["segments"] if sg.get("beside")]  # the event log beside the wide
    arena = [sg for sg in cuts["segments"] if sg["mode"] == "crop"]  # the arena's own screen (its verse, its captions)
    inside = lambda group, t: any(sg["t0"] <= t < sg["t0"] + sg["dur"] for sg in group)
    overlap = lambda group, a, b: sum(max(0.0, min(b, sg["t0"] + sg["dur"]) - max(a, sg["t0"])) for sg in group)
    breaks = sorted(sg["t0"] for sg in cuts["segments"] if sg.get("beside") or sg["mode"] == "card")
    for i, ln in enumerate(lines):
        t0, t1 = ln["starts"][0], ln["end"]
        if ln["who"] == "matus":  # his line ends at a cut to the event log or a card (one caption at a time there)
            t1 = min([t1] + [b for b in breaks if t0 + 0.2 < b < t1])
        text = re.sub(r" -(?=\w)", "-", " ".join(ln["words"]))  # "end -to -end"
        if ln["who"] == "matus":  # his words: each phrase whole, beside his face (not his mouth), never on a plate:
            for a, b in CAPTION_FIXES.items():  # left; right while a lower third is up; at the foot under L15
                text = text.replace(a, b)
            # over the event log: left, above L10 (never on the terminal rows); over the arena's screen: the foot band
            pos = ("foot" if on(full, t0, t1) else "left" if inside(beside, t0) else "foot" if overlap(arena, t0, t1) > 0.5
                   else "right" if on(plates, t0, t1) else "left")
            states.append({"id": f"{i:03d}-00", "words": [text], "k": 1, "t0": t0, "t1": t1, "side": True, "pos": pos})
            continue
        if ln["who"] == "homer":  # the narration: whole phrases on a band, at the foot over a card or a lower third
            low = any(sg["mode"] == "card" and sg["t0"] <= t0 < sg["t0"] + sg["dur"] for sg in cuts["segments"]) or on(plates, t0, t1)
            states.append({"id": f"{i:03d}-00", "words": [text], "k": 1, "t0": t0, "t1": t1, "whole": True, "low": low})
            continue
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
    # Each state on whole frames of the video's clock (padding sub-frame states to 0.034 s drifted the track ~0.1 s
    # late by 1:16); a state shorter than a frame is skipped.
    seq, f = [], 0
    blank = d / "png" / "blank.png"
    for s in states:
        a, b = max(round(s["t0"] * FPS), f), round(s["t1"] * FPS)
        if b <= a:
            continue
        if a > f:
            seq.append((blank, (a - f) / FPS))
        seq.append((d / "png" / f"{s['id']}.png", (b - a) / FPS))
        f = b
    seq.append((blank, max(0.1, LENGTH - f / FPS)))
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
PLATE_RIGHT = {"L3": 1332, "L4": 1096, "L10": 1452, "L2": 792, "L7": 944, "L9": 1250}  # where artist's lower-third plates end (1920×1080; all span y 804-908)
BADGES = {  # badge id -> where it sits and which logos, in order
    "B-L3": ("plate", "L3", ["cartesia"]),
    "B-L4": ("plate", "L4", ["anthropic", "cartesia"]),
    "B-L10": ("plate", "L10", ["spacetimedb"]),
    "B-C2": ("corner", None, ["cartesia", "spacetimedb", "anthropic"]),
    "B-FIG": ("corner", None, ["figma"]),
    "B-C6": ("corner", None, ["apify", "moss"]),
    "B-C5": ("corner", None, ["digitalocean"]),
    "L0": ("lower", None, ["cartesia"]),  # the open's one lower third: what this is, for a judge with the sound off
    "L-SDK": ("sdk", None, ["spacetimedb"]),  # L15 v2: the Swift SDK fork, the exact claim
    "N-LOG": ("label", None, []),  # over the timeline rows
    "N-MONTAGE": ("top", None, []),  # the montage's one label
}
LABELS = {"N-LOG": "The hall's event log, live from SpacetimeDB", "N-MONTAGE": "Four motion games · in beta"}
SDK_URL = "github.com/Matusvec/spacetimedb-swift"


def brand_logo(name: str, scale: float = 1.0) -> str:
    """One sponsor's logo as inline markup: its official SVG unaltered (scaled by CSS height), or for Moss, whose
    site offers no wordmark file, its name in Inter Bold (brand/sources.txt says where each came from)."""
    files = {"cartesia": ("cartesia-wordmark.svg", 30), "anthropic": ("anthropic-wordmark.svg", 22),
             "spacetimedb": ("spacetimedb-light-logo-text.svg", 38), "apify": ("apify-logo-dark.svg", 40),
             "figma": ("figma-kit/Figma Brand Assets/Figma Lockup/Figma Lockup.svg", 190),
             "digitalocean": ("digitalocean-logo-horizontal-black-RGB.svg", 30)}
    if name == "moss":
        return '<span style="font:700 34px/1 Inter,\'Helvetica Neue\',Arial,sans-serif;color:#141413;letter-spacing:-.01em">Moss</span>'
    f, h = files[name]
    h = round(h * scale)
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
        band = ("background:rgba(16,24,30,.55);padding:10px 22px 12px;border-radius:12px;color:#efe6d2;"
                "font:500 34px/1.2 Inter,Helvetica,Arial,sans-serif;text-shadow:0 1px 3px rgba(0,0,0,.5);white-space:nowrap")
        text = 'font:400 34px/1.15 Inter,Helvetica,Arial,sans-serif;color:#2c4757;white-space:nowrap'
        bar = '<span style="width:6px;height:46px;border-radius:3px;background:#3a8fb0;flex:none"></span>'
        if where == "lower":  # L0, in artist's plate style (white, a teal bar, Inter)
            box = f"position:absolute;left:96px;top:808px;height:96px;{pill};padding:0 34px 0 30px"
            inner = (bar + f'<span style="{text}"><b style="font-weight:600">MeNIN</b> · Homer judges your verse out loud. '
                     'Live.</span>' + inner)
        elif where == "sdk":  # L15 v2: full width, two lines, the exact claim and a larger logo
            box = (f"position:absolute;left:64px;right:64px;top:790px;height:132px;{pill};padding:0 40px 0 30px;"
                   "justify-content:space-between")
            inner = ('<span style="display:flex;align-items:center;gap:26px">' + bar.replace("46px", "84px") +
                     f'<span style="{text};font-size:32px;line-height:1.3">A public fork of the community Swift SDK, fixes sent '
                     f'upstream (BSL 1.1)<br><b style="font-weight:600">{SDK_URL}</b></span></span>'
                     + "".join(brand_logo(n, 1.6) for n in logos))
        elif where == "label":  # over the right half (the timeline rows)
            box = f"position:absolute;left:1000px;top:286px;{band}"
            inner = LABELS[bid]
        elif where == "top":  # one label, top centre
            box = f"position:absolute;left:50%;transform:translateX(-50%);top:56px;{band};font-size:40px"
            inner = LABELS[bid]
        elif where == "plate":
            box = f"position:absolute;left:{PLATE_RIGHT[lt] + 14}px;top:808px;height:96px;{pill}"
        else:
            box = f"position:absolute;right:64px;top:56px;height:{110 if bid == 'B-FIG' else 84}px;{pill}"
        html = ('<style>@import url("https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700&display=block");</style>'
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
        flip = "hflip," if s.get("hflip") else ""  # Photo Booth's mirror, undone (his shirt reads the right way)
        chain = f"setpts=(PTS-STARTPTS)/{speed}," + flip + hide + fit(s["mode"], clips.get(s["src"]), s.get("crop"))
        if s.get("zoom"):  # a punch-in (an answer's jump cut): centred, a little above the middle (his face)
            z = s["zoom"]
            chain += f",crop=iw/{z}:ih/{z}:(iw-iw/{z})/2:(ih-ih/{z})*0.4,scale={W}:{H}:flags=lanczos,setsar=1"
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
        rows = f"crop={s['beside_crop']}," if s.get("beside_crop") else ""
        graph = (f"[0:v]{chain},crop={W // 2}:{H}:{W // 4}:0,fps={FPS}[l];[1:v]{rows}scale={W // 2}:-2,"
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
    lines = [(start, start + (dur or seconds(VO / f))) for f, start, dur in narration(cuts) if (VO / f).exists()]
    if labels:  # the room ducks ~14 dB under each narration line
        duck = ducked([(0.0, 0.0), (LENGTH, 0.0)], lines, -14.0, pre=0.25)
        parts.append("".join(labels) + f"amix=inputs={len(labels)}:normalize=0,asetpts=N/SR/TB,{envelope(duck)}[room]")
        labels = ["[room]"]
    for s in cuts["segments"]:  # Matus's answers to camera: their own sound
        clip = clips.get(s["src"]) if s.get("own_audio") else None
        if not clip:
            continue
        n = len(inputs) // 2
        inputs += ["-i", clip["path"]]
        ms = int(s.get("audio_t0", s["t0"]) * 1000)
        d = s.get("audio_dur", s["dur"])
        parts.append(f"[{n}:a]aresample=48000,aformat=channel_layouts=stereo,atrim=start={s.get('audio_src', s['src_t']):.3f}:duration={d:.3f},"
                     f"asetpts=PTS-STARTPTS,afade=t=out:st={max(0.0, d - 0.12):.3f}:d=0.12,adelay={ms}|{ms}[m{n}]")
        labels.append(f"[m{n}]")
    words = [(s.get("audio_t0", s["t0"]), s.get("audio_t0", s["t0"]) + s.get("audio_dur", s["dur"]))
             for s in cuts["segments"] if s.get("own_audio")]
    for f, start, dur in narration(cuts):
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
    # the theme ducks ~10 dB under each narration line and under Matus's words (spans merged: no zigzag where they meet)
    keys = ducked([tuple(k) for k in cuts["music"]], lines + words, -10.0)
    n = len(inputs) // 2
    inputs += ["-i", str(THEME)]
    marks = cuts.get("marks", {})
    if marks.get("tail_from") is not None:  # at C6 the theme jumps, bar to bar, to its last bars (its final chord)
        c6, x = marks["c6"], 0.25
        main = c6 - THEME_AT + x
        inputs += ["-i", str(THEME)]
        parts.append(f"[{n}:a]atrim=start={THEME_HIT}:duration={main:.3f},asetpts=PTS-STARTPTS,aresample=48000,"
                     f"afade=t=out:st={main - 2 * x:.3f}:d={2 * x},adelay={int(THEME_AT * 1000)}|{int(THEME_AT * 1000)}[th0]")
        parts.append(f"[{n + 1}:a]atrim=start={marks['tail_from'] - x:.3f},asetpts=PTS-STARTPTS,aresample=48000,"
                     f"afade=t=in:d={2 * x},adelay={int((c6 - x) * 1000)}|{int((c6 - x) * 1000)}[th1]")
        parts.append(f"[th0][th1]amix=inputs=2:normalize=0,asetpts=N/SR/TB,{envelope(keys)}[theme]")
    else:
        parts.append(f"[{n}:a]atrim=start={THEME_HIT},asetpts=PTS-STARTPTS,aresample=48000,"
                     f"adelay={int(THEME_AT * 1000)}|{int(THEME_AT * 1000)},{envelope(keys)}[theme]")
    labels.append("[theme]")
    # amix's output timestamps don't start at 0 (ffmpeg 9) when its inputs start late (adelay), and atrim trims by
    # timestamp: v1-v3's atrim=duration=179 left 2.5 s of silence. Re-stamp by sample count, pad, then cut by samples.
    parts.append(f"{''.join(labels)}amix=inputs={len(labels)}:normalize=0,asetpts=N/SR/TB,apad=whole_dur={LENGTH},"
                 f"atrim=end_sample={int(LENGTH * 48000)},loudnorm=I=-14:TP=-1.5:LRA=11,aresample=48000[mix]")
    ff(*inputs, "-filter_complex", ";".join(parts), "-map", "[mix]", "-t", str(LENGTH), "-c:a", "pcm_s16le", str(out))
    sound_check(out, LENGTH)
    return out


def ducked(keys: list[tuple[float, float]], spans: list[tuple[float, float]], depth: float, pre: float = 0.2,
           post: float = 0.3, floor: float = -60.0) -> list[tuple[float, float]]:
    """A level plan (dB keyframes, linear between) with `depth` dB off inside each span (overlapping spans merged,
    ramps of `pre` and `post` s); left alone where the plan is under `floor` (the music is out there anyway)."""
    merged: list[list[float]] = []
    for a, b in sorted(spans):
        if merged and a - pre <= merged[-1][1] + post:
            merged[-1][1] = max(merged[-1][1], b)
        else:
            merged.append([a, b])

    def base(t: float) -> float:
        if t <= keys[0][0]:
            return keys[0][1]
        for (t0, d0), (t1, d1) in zip(keys, keys[1:]):
            if t0 <= t < t1:
                return d0 + (d1 - d0) * (t - t0) / (t1 - t0)
        return keys[-1][1]

    def duck(t: float) -> float:
        for a, b in merged:
            if a - pre <= t <= b + post:
                return depth * min(1.0, (t - a + pre) / pre, (b + post - t) / post)
        return 0.0

    points = sorted({t for t, _ in keys} | {x for a, b in merged for x in (a - pre, a, b, b + post)} | {0.0})
    out = []
    for t in (x for x in points if x >= 0):
        lv = base(t)
        out.append((round(t, 3), round(lv + (duck(t) if lv > floor else 0.0), 2)))
    # a step in the plan (two keys 20 ms apart) survives: base() reads its two sides
    return out


def sound_check(path: Path, length: float, video: bool = False) -> None:
    """Fails the build, loudly, unless the sound runs the whole length and isn't silent (v1-v3 went out with 2.5 s
    of silence). A video must hold exactly one picture and one sound, the same length."""
    info = probe(path)
    kinds = [s["codec_type"] for s in info["streams"]]
    a = next((s for s in info["streams"] if s["codec_type"] == "audio"), None)
    dur = float((a or {}).get("duration") or info["format"].get("duration") or 0)
    peak = re.search(r"max_volume: (-?[\d.]+) dB", run(["ffmpeg", "-hide_banner", "-i", str(path), "-map", "0:a:0",
                                                          "-af", "volumedetect", "-f", "null", "-"], quiet=False))
    peak_db = float(peak[1]) if peak else -99.0
    problems = []
    if dur < length - 0.5:
        problems.append(f"sound is {dur:.2f} s, wants {length:.2f}")
    if peak_db < -6.0:
        problems.append(f"sound peaks at {peak_db} dB (silent?)")
    if video:
        v = next((s for s in info["streams"] if s["codec_type"] == "video"), None)
        if kinds.count("video") != 1 or kinds.count("audio") != 1:
            problems.append(f"streams are {kinds}, want one video and one audio")
        if v and abs(float(v.get("duration") or 0) - dur) > 0.2:
            problems.append(f"sound {dur:.2f} s vs picture {float(v.get('duration') or 0):.2f} s")
    if problems:
        raise SystemExit(f"SOUND CHECK FAILED for {path.name}: " + "; ".join(problems))
    print(f"sound check ok: {path.name} {dur:.2f} s, peak {peak_db} dB")


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
    global LENGTH
    cuts = load(WORK / "cuts.json", None) or plan()
    LENGTH = cuts.get("length", LENGTH)  # the cut ends where its theme does (plan())
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
        y = str(lt.get("dy", 0)) if lt["file"] or lt.get("over") else f"{H - 250}"
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
    short = min(CARTESIA, cuts.get("marks", {}).get("montage") or CARTESIA)  # Cartesia's cut closes on C5's last frame
    part = OUT / f".rough-cut-v{n}.part.mp4"
    ff(*inputs, "-filter_complex", ";".join(graph), "-map", "[vout]", "-map", "1:a", "-t", str(LENGTH),
       "-c:v", "libx264", "-preset", "medium", "-crf", "19", "-r", str(FPS), "-force_key_frames", f"{short:.3f}",
       "-c:a", "aac", "-b:a", "192k", "-ar", "48000", "-movflags", "+faststart", str(part))
    sound_check(part, LENGTH, video=True)
    part.rename(final)
    ff("-i", str(final), "-t", f"{short:.3f}", "-c:v", "copy", "-af", f"afade=t=out:st={short - 0.6:.3f}:d=0.6",
       "-c:a", "aac", "-b:a", "192k", "-movflags", "+faststart", str(part))
    sound_check(part, short, video=True)
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
