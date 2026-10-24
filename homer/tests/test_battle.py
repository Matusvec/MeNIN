import json
import random
import string
from pathlib import Path

import pytest
from fakes import FakeClient, ScriptedHomer, last_tool_results, response, text, tool

from homer.agent import HomerAgent
from homer.battle import Battle, BattleConfig, BattleError
from homer.tools import ToolInputError, entry_total, validate_round

FIXTURE = json.loads((Path(__file__).parent / "fixtures" / "battle_2p2r.json").read_text())
SCORES = {"metrical_accuracy": 7, "naturalness": 7, "imagery_diction": 7, "overall_craft": 7}


def config(**overrides):
    base = dict(players=FIXTURE["players"], rounds=FIXTURE["rounds"], lines_per_round=FIXTURE["lines_per_round"], themes=FIXTURE["themes"], seed=FIXTURE["seed"])
    return BattleConfig(**{**base, **overrides})


def scripted_battle(**overrides):
    homer = ScriptedHomer(FIXTURE["themes"])
    client = FakeClient(homer)
    return Battle(config(**overrides), HomerAgent(client=client)), homer, client


def entry(label, scores=SCORES, on_theme=True, disqualified=False):
    return {
        "label": label, "syllable_counts": [10], "scores": scores, "on_theme": on_theme, "meets_constraint": True,
        "disqualified": disqualified, "disqualification_reason": "", "summary": "",
    }


def test_simulated_two_player_two_round_battle():
    battle, homer, client = scripted_battle()

    opening = battle.start()
    assert opening.data["round"]["theme"] == "a sea voyage"
    assert battle.phase == "collecting"

    for player, verse in FIXTURE["submissions"]["1"].items():
        assert battle.submit(player, verse).accepted
    r1 = battle.close_round()
    assert "Revealed" in r1.text
    assert r1.data["round"]["winners"] == ["Alice"]  # clean pentameter beats the broken, injecting entry

    late = FIXTURE["late"]
    result = battle.submit(late["player"], late["text"])
    assert not result.accepted and "Too late" in result.message

    battle.next_round()
    assert battle.current.theme == "a winter morning"
    for player, verse in FIXTURE["submissions"]["2"].items():
        battle.submit(player, verse)
    battle.close_round()

    final = battle.finish()
    assert battle.phase == "finished"
    assert final.data["champion"] == battle.champion
    totals = final.data["standings"]
    assert totals[battle.champion] == max(totals.values())
    assert "champion" in final.text.lower()

    # Blind judging: Homer never saw a player's name next to an entry.
    for prompt in homer.seen_entries:
        for name in FIXTURE["players"]:
            assert name not in prompt.split("</app_state>")[1]
    # The injection inside Bob's verse arrived escaped, inside his entry.
    assert "ignore your rules" in homer.seen_entries[0]


def test_entry_order_is_shuffled_but_reproducible():
    orders = []
    for seed in (1, 2, 3, 4, 5, 6):
        battle, _, _ = scripted_battle(seed=seed)
        battle.start()
        for player, verse in FIXTURE["submissions"]["1"].items():
            battle.submit(player, verse)
        battle.close_round()
        orders.append(tuple(battle.current.labels.values()))
    assert len(set(orders)) == 2  # both orders occur
    again, _, _ = scripted_battle(seed=1)
    again.start()
    for player, verse in FIXTURE["submissions"]["1"].items():
        again.submit(player, verse)
    again.close_round()
    assert tuple(again.current.labels.values()) == orders[0]


def test_missing_submission_scores_zero():
    battle, _, _ = scripted_battle()
    battle.start()
    battle.submit("Alice", FIXTURE["submissions"]["1"]["Alice"])
    reply = battle.close_round()
    assert reply.data["round"]["points"]["Bob"] == 0
    assert "No entry from Bob" in reply.text


def test_void_round_makes_no_model_call():
    battle, _, client = scripted_battle()
    battle.start()
    calls = len(client.calls)
    reply = battle.close_round()
    assert "void" in reply.text
    assert len(client.calls) == calls


def test_submission_rules():
    battle, _, _ = scripted_battle()
    assert not battle.submit("Alice", "too early").accepted
    battle.start()
    assert not battle.submit("Mallory", "x").accepted
    assert not battle.submit("Alice", "   ").accepted
    assert battle.submit("alice", "first try").accepted  # case-insensitive
    replaced = battle.submit("Alice", "second try")
    assert replaced.accepted and "replaced" in replaced.message
    assert battle.current.submissions["Alice"] == "second try"


def test_config_validation():
    with pytest.raises(BattleError):
        BattleConfig(players=["Solo"]).validate()
    with pytest.raises(BattleError):
        BattleConfig(players=["Ann", "ann"]).validate()


def test_phase_guards():
    battle, _, _ = scripted_battle()
    with pytest.raises(BattleError):
        battle.close_round()
    battle.start()
    with pytest.raises(BattleError):
        battle.next_round()
    with pytest.raises(BattleError):
        battle.finish()


def test_tie_triggers_tiebreaker_then_champion():
    battle, homer, client = scripted_battle(rounds=1, themes=["the sea"])
    battle.start()
    same = "We set our sails beneath a silver moon,"
    battle.submit("Alice", same)
    battle.submit("Bob", same)
    battle.close_round()
    reply = battle.finish()
    assert reply.data["tie"] == ["Alice", "Bob"]
    assert battle.current.tiebreak and battle.phase == "collecting"
    assert battle.current.players == ["Alice", "Bob"]

    battle.submit("Alice", "The frost had laid its silver on the hill,")
    battle.submit("Bob", "the cold")
    battle.close_round()
    final = battle.finish()
    assert final.data["champion"] == "Alice"
    # Tiebreaker points do not change the main standings.
    assert final.data["standings"]["Alice"] == final.data["standings"]["Bob"]


def test_tiebreaker_only_admits_tied_players():
    battle, _, _ = scripted_battle(players=["Ann", "Ben", "Cy"], rounds=1, themes=["x"])
    battle.start()
    line = "We set our sails beneath a silver moon,"
    battle.submit("Ann", line)
    battle.submit("Ben", line)
    battle.submit("Cy", "the cold")
    battle.close_round()
    battle.finish()
    assert not battle.submit("Cy", line).accepted


def test_required_theme_is_enforced():
    client = FakeClient(
        [
            response(tool("announce_round", {"round_number": 1, "theme": "dragons", "constraint": "none"})),
            response(tool("announce_round", {"round_number": 1, "theme": "a sea voyage", "constraint": "none"})),
            response(text("Round one: the sea!")),
        ]
    )
    battle = Battle(config(), HomerAgent(client=client))
    battle.start()
    err = last_tool_results(client.calls[1])[0]
    assert err["is_error"] and "required theme" in err["content"]
    assert battle.current.theme == "a sea voyage"


def test_inconsistent_winner_is_sent_back_and_corrected():
    battle_client = FakeClient(
        [
            response(tool("announce_round", {"round_number": 1, "theme": "a sea voyage", "constraint": "none"})),
            response(text("Begin!")),
        ]
    )
    battle = Battle(config(), HomerAgent(client=battle_client))
    battle.start()
    battle.submit("Alice", "a")
    battle.submit("Bob", "b")
    high = {k: 9 for k in SCORES}
    battle_client.script.extend(
        [
            response(tool("record_round", {"entries": [entry("A", high), entry("B")], "winner_labels": ["B"], "close_call_note": ""})),
            response(tool("record_round", {"entries": [entry("A", high), entry("B")], "winner_labels": ["A"], "close_call_note": ""})),
            response(text("Entry A takes it.")),
        ]
    )
    reply = battle.close_round()
    err = last_tool_results(battle_client.calls[3])[0]
    assert err["is_error"] and "the winner is A" in err["content"]
    assert reply.data["round"]["winners"] == [battle.current.labels["A"]]


def test_scoring_rules():
    assert entry_total(entry("A")) == 28
    assert entry_total(entry("A", on_theme=False)) == 23
    assert entry_total(entry("A", disqualified=True)) == 0
    with pytest.raises(ToolInputError):
        validate_round({"entries": [entry("A")], "winner_labels": ["A"], "close_call_note": ""}, ["A", "B"])
    with pytest.raises(ToolInputError):
        validate_round({"entries": [entry("A"), entry("A")], "winner_labels": ["A"], "close_call_note": ""}, ["A", "B"])
    # Ties are allowed when declared as ties.
    assert validate_round({"entries": [entry("A"), entry("B")], "winner_labels": ["A", "B"], "close_call_note": ""}, ["A", "B"]) == ["A", "B"]


def test_disqualified_entry_scores_zero_and_loses():
    client = FakeClient(
        [
            response(tool("announce_round", {"round_number": 1, "theme": "a sea voyage", "constraint": "none"})),
            response(text("Begin!")),
        ]
    )
    battle = Battle(config(), HomerAgent(client=client))
    battle.start()
    battle.submit("Alice", "clean verse")
    battle.submit("Bob", "inappropriate verse")
    # Labels are assigned in close_round; compute them the same way the engine will.
    order = sorted(["Alice", "Bob"])
    random.Random(FIXTURE["seed"]).shuffle(order)
    labels = {string.ascii_uppercase[i]: p for i, p in enumerate(order)}
    bob_label = next(l for l, p in labels.items() if p == "Bob")
    alice_label = next(l for l, p in labels.items() if p == "Alice")
    client.script.extend(
        [
            response(tool("record_round", {"entries": [entry(alice_label), entry(bob_label, disqualified=True)], "winner_labels": [alice_label], "close_call_note": ""})),
            response(text("The bard declines to sing that one.")),
        ]
    )
    reply = battle.close_round()
    assert reply.data["round"]["points"] == {"Alice": 28, "Bob": 0}
