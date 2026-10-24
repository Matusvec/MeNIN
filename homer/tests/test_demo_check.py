import importlib.util
from pathlib import Path

import pytest

spec = importlib.util.spec_from_file_location("demo_check", Path(__file__).parents[1] / "scripts" / "demo_check.py")
dc = importlib.util.module_from_spec(spec)
spec.loader.exec_module(dc)

HEALTHY = {"ok": True, "judge": "warm", "stdb": "claimed", "stdbDb": "homer-calhacks"}


@pytest.fixture(autouse=True)
def fresh():
    dc.results.clear()


def levels():
    return {check: level for level, check, _ in dc.results}


def test_unclaimed_spacetimedb_is_a_fail(monkeypatch):
    monkeypatch.setattr(dc, "get_json", lambda base, path, body=None: (200, {**HEALTHY, "stdb": "failed"}))
    dc.check_health("http://x")
    assert levels()["spacetimedb"] == "FAIL"


def test_cold_cache_is_only_a_warning(monkeypatch):
    monkeypatch.setattr(dc, "get_json", lambda base, path, body=None: (200, {**HEALTHY, "judge": "warming"}))
    dc.check_health("http://x")
    assert levels() == {"health": "PASS", "judge cache": "WARN", "spacetimedb": "PASS"}


@pytest.mark.parametrize("voice, level", [("", "FAIL"), ("a0e99841", "PASS")])
def test_a_mute_homer_is_a_fail(monkeypatch, voice, level):
    replies = {
        "/themes?n=3&demo=true": (200, {"themes": ["a", "b", "c"]}),
        "/rescue": (200, {"formula": "the whale-road"}),
        "/voice/token": (200, {"token": "t", "stt": {"model": "ink-2"}, "tts": {"model": "sonic-3.6", "voiceId": voice}}),
    }
    monkeypatch.setattr(dc, "get_json", lambda base, path, body=None: replies[path])
    dc.check_quick("http://x")
    assert levels()["voice token"] == level
