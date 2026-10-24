import random

from homer import formulas
from homer.deal import DEFAULT_THEMES, deal, pick_theme, rescue, tags


def test_theme_tags():
    assert tags("A ship that never came home") >= {"sea", "home", "loss"}
    assert tags("The night before the deadline") >= {"night", "time"}
    assert tags("xyzzy") == set()


def test_hand_fits_the_theme_with_a_mix_of_kinds():
    hand = deal("A storm on the open sea", rng=random.Random(1))
    assert len(hand) == 5 and len({c.text for c in hand}) == 5
    assert {c.kind for c in hand} == {"half_line", "epithet", "kenning"}
    bank = {f.id: f for f in formulas.bank()}
    fitting = [c for c in hand if {"sea", "storm"} & set(bank[c.id].themes)]
    assert len(fitting) >= 4


def test_hand_draws_from_the_hoard_and_skips_exclusions():
    hand = deal("The forge at midnight", ["storm-throated", "Breaker of Horses", "the code-whisperer"],
                exclude=["the wine-dark sea"], rng=random.Random(2))
    own = [c for c in hand if c.hoard]
    assert len(own) == 2 and all(1 <= c.beats <= 2 for c in own)
    assert "the code-whisperer" not in {c.text for c in own}  # a hoard card from after the Bronze Age stays home
    assert "the wine-dark sea" not in {c.text for c in hand}


def test_pick_theme_avoids_used_ones():
    used = list(DEFAULT_THEMES[:-1])
    assert pick_theme(random.Random(0), avoid=used) == DEFAULT_THEMES[-1]


HAND = ["when Dawn came early", "the whale-road", "the wine-dark sea", "grey-eyed Athena", "the black ships"]


def test_rescue_fills_what_the_line_needs():
    assert rescue("", HAND).kind == "half_line"  # a fresh line: half a line at once
    one_left = rescue("the wind was cold the waves were", HAND)  # three hits in, one to go
    assert one_left.beats == 1
    two_left = rescue("my brother sailed", HAND)  # two hits in
    assert two_left.beats == 2


def test_rescue_skips_spent_cards_and_handles_an_empty_hand():
    assert rescue("", HAND, played=["when Dawn came early"]).text != "when Dawn came early"
    assert rescue("", ["the whale-road"], played=["the whale-road"]) is None
