import asyncio
import random
from types import SimpleNamespace

from homer import formulas, moss_dealer
from homer.deal import deal
from homer.moss_dealer import MossDealer, documents, index_name

SEA_FIRST = ["whale-road", "wine-dark-sea", "loud-roaring-sea", "hollow-ships", "black-ships", "swan-road"]


class FakeMoss:
    def __init__(self, existing=(), delay=0.0, fail=None, ids=SEA_FIRST):
        self.existing, self.delay, self.fail, self.ids = set(existing), delay, fail, ids
        self.created, self.loaded, self.queries = [], [], []

    async def list_indexes(self):
        if self.fail == "list":
            raise RuntimeError("network down")
        return [SimpleNamespace(name=n) for n in self.existing]

    async def delete_index(self, name):
        self.existing.discard(name)
        return True

    async def create_index(self, name, docs, model):
        self.created.append((name, len(docs), model))
        self.existing.add(name)

    async def load_index(self, name):
        self.loaded.append(name)
        return name

    async def query(self, name, text, options):
        self.queries.append((name, text, options.top_k))
        if self.delay:
            await asyncio.sleep(self.delay)
        if self.fail == "query":
            raise RuntimeError("boom")
        return SimpleNamespace(docs=[SimpleNamespace(id=i, score=1 - k / 10) for k, i in enumerate([*self.ids, "not-in-bank"])])


def run(c):
    return asyncio.run(c)


def test_the_index_is_the_bank_with_its_themes_and_versioned():
    docs = documents()
    assert len(docs) == len(formulas.bank()) and docs[0]["id"] == "wine-dark-sea"
    assert docs[0]["text"].startswith("the wine-dark sea. themes: sea, journey")
    assert index_name().startswith("menin-formulas-") and index_name() == index_name()


def test_start_builds_once_per_bank_version_then_loads():
    fake = FakeMoss()
    d = MossDealer("p", "k", client=fake)
    run(d.start())
    assert d.ready and fake.created == [(d.name, len(formulas.bank()), "moss-minilm")] and fake.loaded == [d.name]
    again = FakeMoss(existing=[d.name])
    run(MossDealer("p", "k", client=again).start())
    assert again.created == [] and again.loaded == [d.name]


def test_a_new_bank_replaces_only_its_own_older_indexes():
    fake = FakeMoss(existing=["menin-formulas-0ld0ld0ld0", "on-device-context"])
    d = MossDealer("p", "k", client=fake)
    run(d.start())
    assert d.ready and fake.existing == {d.name, "on-device-context"}


def test_ranked_follows_moss_and_drops_unknown_ids():
    d = MossDealer("p", "k", client=FakeMoss())
    run(d.start())
    ranked = run(d.ranked("A storm on the open sea"))
    assert [f.id for f in ranked] == SEA_FIRST


def test_any_trouble_falls_back_to_the_tag_dealer():
    broken = MossDealer("p", "k", client=FakeMoss(fail="list"))
    run(broken.start())
    assert not broken.ready and run(broken.ranked("the sea")) is None
    slow = MossDealer("p", "k", client=FakeMoss(delay=0.2), timeout_s=0.05)
    run(slow.start())
    assert run(slow.ranked("the sea")) is None
    failing = MossDealer("p", "k", client=FakeMoss(fail="query"))
    run(failing.start())
    assert run(failing.ranked("the sea")) is None


def test_a_failed_start_retries_until_moss_answers(monkeypatch):
    fake = FakeMoss(fail="list")
    naps = []

    async def nap(s):
        naps.append(s)
        if len(naps) == 3:
            fake.fail = None  # the usage limit lifts

    monkeypatch.setattr(moss_dealer.asyncio, "sleep", nap)
    d = MossDealer("p", "k", client=fake)
    run(d.keep_starting())
    assert d.ready and naps == list(moss_dealer.RETRY_S[:3]) and fake.loaded == [d.name]


def test_off_unless_switched_on_with_credentials(monkeypatch):
    monkeypatch.setattr(moss_dealer, "_dealer", None)
    monkeypatch.delenv("HOMER_DEALER", raising=False)
    assert moss_dealer.dealer() is None and run(moss_dealer.ranked_formulas("the sea")) is None
    monkeypatch.setenv("HOMER_DEALER", "moss")
    monkeypatch.delenv("MOSS_PROJECT_ID", raising=False)
    assert moss_dealer.dealer() is None  # no credentials: still the tag dealer
    monkeypatch.setenv("MOSS_PROJECT_ID", "p")
    monkeypatch.setenv("MOSS_PROJECT_KEY", "k")
    assert isinstance(moss_dealer.dealer(), MossDealer)


def test_a_ranked_hand_keeps_the_mix_of_kinds_and_the_hoard():
    bank = {f.id: f for f in formulas.bank()}
    ranked = [bank[i] for i in SEA_FIRST] + [f for f in formulas.bank() if f.id not in SEA_FIRST]
    hand = deal("the sea", ["storm-throated"], n=5, rng=random.Random(1), ranked=ranked)
    assert hand[0].hoard and len(hand) == 5
    assert {c.kind for c in hand[1:]} >= {"half_line", "epithet", "kenning"}
    # Moss's best fits lead: across seeds, at least one dealt card in five is one of its top picks
    # (one seed's shuffle is luck; pm measured 49-58% of seeds giving two or more).
    dealt = [c for seed in range(50) for c in deal("the sea", ["storm-throated"], n=5, rng=random.Random(seed), ranked=ranked)[1:]]
    assert sum(c.id in SEA_FIRST for c in dealt) >= len(dealt) / 5
