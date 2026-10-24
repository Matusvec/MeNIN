"""Tool definitions Homer can call, and validators for the structured records.

Every tool is `strict`, so the API guarantees inputs match the schema. The
validators here check what a schema cannot: that line counts match the
submission, that labels match the entries, that a declared winner matches the
scores.
"""

from __future__ import annotations

import json
from typing import Any

from .scansion import scan_poem
from .state import STEP_IDS, STEP_STATUSES

SCORE = {"type": "integer", "enum": list(range(1, 11))}
RUBRIC = ("metrical_accuracy", "naturalness", "imagery_diction", "overall_craft")
SCORES_SCHEMA = {
    "type": "object",
    "properties": {k: SCORE for k in RUBRIC},
    "required": list(RUBRIC),
    "additionalProperties": False,
}
DEVIATION_TYPES = [
    "trochaic_inversion",
    "feminine_ending",
    "spondee",
    "pyrrhic",
    "headless_line",
    "elision",
    "extra_syllable",
    "missing_syllable",
    "misplaced_stress",
    "other",
]


def _obj(properties: dict, required: list[str] | None = None) -> dict:
    return {
        "type": "object",
        "properties": properties,
        "required": required if required is not None else list(properties),
        "additionalProperties": False,
    }


SCAN_POEM = {
    "name": "scan_poem",
    "description": (
        "Deterministic scansion baseline from the CMU Pronouncing Dictionary. Pass one or more lines "
        "(newline-separated). Returns, per line: syllable count, per-word stress options, lexical stress "
        "marks, a suggested iambic fit with feet, stress clashes, variation hints, caesurae, elision "
        "candidates, an elided fit when elision helps, and words missing from the dictionary. "
        "Monosyllable stress is context-dependent and left to your judgment."
    ),
    "strict": True,
    "input_schema": _obj({"text": {"type": "string", "description": "The verse to scan."}}),
}

RECORD_JUDGMENT = {
    "name": "record_judgment",
    "description": "Record the structured verdict for a Judge-mode submission. Call once, before writing your reply.",
    "strict": True,
    "input_schema": _obj(
        {
            "input_kind": {"type": "string", "enum": ["line", "stanza", "poem", "not_verse"]},
            "lines": {
                "type": "array",
                "items": _obj(
                    {
                        "line_number": {"type": "integer"},
                        "text": {"type": "string"},
                        "syllables": {"type": "integer"},
                        "scansion": {"type": "string", "description": "e.g. 'ˇ / | ˇ / | ˇ / | ˇ / | ˇ /'"},
                        "feet": {"type": "integer"},
                        "deviations": {
                            "type": "array",
                            "items": _obj(
                                {
                                    "foot": {"type": "integer"},
                                    "type": {"type": "string", "enum": DEVIATION_TYPES},
                                    "classification": {"type": "string", "enum": ["variation", "error"]},
                                    "explanation": {"type": "string"},
                                }
                            ),
                        },
                    }
                ),
            },
            "scores": SCORES_SCHEMA,
            "revisions": {
                "type": "array",
                "items": _obj({"original": {"type": "string"}, "revised": {"type": "string"}, "reason": {"type": "string"}}),
            },
            "verdict": {"type": "string"},
        }
    ),
}

DECLINE_SUBMISSION = {
    "name": "decline_submission",
    "description": "Use instead of record_judgment when a submission is inappropriate for a PG app and you will not judge it.",
    "strict": True,
    "input_schema": _obj(
        {
            "category": {"type": "string", "enum": ["hateful", "sexual", "violent", "other"]},
            "note": {"type": "string", "description": "Short, clean reason. Do not quote the content."},
        }
    ),
}

UPDATE_PROGRESS = {
    "name": "update_progress",
    "description": "Record the student's progress on a curriculum step.",
    "strict": True,
    "input_schema": _obj(
        {
            "step_id": {"type": "string", "enum": STEP_IDS},
            "status": {"type": "string", "enum": list(STEP_STATUSES)},
            "note": {"type": "string", "description": "What the student showed or struggled with; may be empty."},
        }
    ),
}

ANNOUNCE_ROUND = {
    "name": "announce_round",
    "description": "Set the theme and metrical constraint for a battle round (including a tiebreaker).",
    "strict": True,
    "input_schema": _obj(
        {
            "round_number": {"type": "integer"},
            "theme": {"type": "string"},
            "constraint": {"type": "string"},
        }
    ),
}

RECORD_ROUND = {
    "name": "record_round",
    "description": "Record blind scores for every entry in the round. Call before writing the round report.",
    "strict": True,
    "input_schema": _obj(
        {
            "entries": {
                "type": "array",
                "items": _obj(
                    {
                        "label": {"type": "string"},
                        "syllable_counts": {"type": "array", "items": {"type": "integer"}},
                        "scores": SCORES_SCHEMA,
                        "on_theme": {"type": "boolean"},
                        "meets_constraint": {"type": "boolean"},
                        "disqualified": {"type": "boolean"},
                        "disqualification_reason": {"type": "string"},
                        "summary": {"type": "string", "description": "One-sentence condensed judgment."},
                    }
                ),
            },
            "winner_labels": {"type": "array", "items": {"type": "string"}, "description": "More than one only for a tie."},
            "close_call_note": {"type": "string", "description": "Why a close round went the way it did; may be empty."},
        }
    ),
}

MODE_TOOLS = {
    "bard": [SCAN_POEM, UPDATE_PROGRESS],
    "judge": [SCAN_POEM, RECORD_JUDGMENT, DECLINE_SUBMISSION],
    "battle": [SCAN_POEM, ANNOUNCE_ROUND, RECORD_ROUND],
}


class ToolInputError(ValueError):
    """Raised by validators; the message goes back to Homer as an is_error tool result."""


def run_scan_poem(tool_input: dict[str, Any]) -> str:
    return json.dumps(scan_poem(tool_input.get("text", "")), ensure_ascii=False)


def validate_judgment(record: dict[str, Any], expected_lines: int) -> None:
    if record["input_kind"] != "not_verse" and len(record["lines"]) != expected_lines:
        raise ToolInputError(
            f"The submission has {expected_lines} non-empty line(s) but the record has {len(record['lines'])}. "
            "Record every line, in order."
        )
    numbers = [line["line_number"] for line in record["lines"]]
    if numbers != list(range(1, len(numbers) + 1)):
        raise ToolInputError("line_number must run 1, 2, 3, ... in order.")


ROUND_PENALTY_OFF_THEME = 5


def entry_total(entry: dict[str, Any]) -> int:
    """Round points for one entry: rubric sum (4-40), minus a fixed off-theme penalty; 0 if disqualified."""
    if entry["disqualified"]:
        return 0
    total = sum(entry["scores"][k] for k in RUBRIC)
    if not entry["on_theme"]:
        total -= ROUND_PENALTY_OFF_THEME
    return max(total, 0)


def validate_round(record: dict[str, Any], labels: list[str]) -> list[str]:
    """Check a record_round call; return the winning labels as computed from the scores."""
    got = [e["label"] for e in record["entries"]]
    if sorted(got) != sorted(labels) or len(set(got)) != len(got):
        raise ToolInputError(f"Record exactly one entry for each label: {', '.join(labels)}. You recorded: {', '.join(got) or 'none'}.")
    totals = {e["label"]: entry_total(e) for e in record["entries"]}
    best = max(totals.values())
    winners = sorted(label for label, t in totals.items() if t == best)
    if sorted(record["winner_labels"]) != winners:
        shown = ", ".join(f"{k}={v}" for k, v in sorted(totals.items()))
        raise ToolInputError(
            f"By your scores the round totals are {shown} (off-theme entries lose {ROUND_PENALTY_OFF_THEME}; "
            f"disqualified score 0), so the winner is {' and '.join(winners)}. Either name that winner or adjust "
            "the scores you believe are wrong, then call record_round again."
        )
    return winners
