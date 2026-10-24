from homer.emotion import EMOTIONS, lexicon_weights, range_score


def one_hot(emotion, strength=0.9):
    rest = (1 - strength) / (len(EMOTIONS) - 1)
    return {e: strength if e == emotion else rest for e in EMOTIONS}


def test_one_feeling_held_is_narrow():
    assert range_score([one_hot("grief")] * 5) <= 2


def test_a_verse_that_travels_scores_high():
    history = [one_hot("grief"), one_hot("anger"), one_hot("defiance"), one_hot("awe")]
    assert range_score(history) >= 8


def test_range_is_always_one_to_ten():
    assert range_score([]) == 1
    assert range_score([{}]) >= 1
    assert range_score([one_hot(e) for e in EMOTIONS] * 3) == 10


def test_lexicon_stands_in_without_history():
    assert lexicon_weights("the cat is fine") is None
    w = lexicon_weights("I weep at the grave")
    assert max(w, key=w.get) == "grief"
    assert range_score([], ["I weep at the grave", "but I rise and fight with iron"]) > range_score([], ["I weep at the grave"])
