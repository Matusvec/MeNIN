"""What the miner knows about Homer's world: names, nouns, modifiers, tags.

Everything here is a hand-written word list, so a mined formula's tags are
explainable: its themes come from its head word (the name or noun it
describes) plus a few modifier cues, and its emotions come from its
modifiers first, then the head.

Tags must stay inside content/README.md: the 16 theme tags and the 8 emotion
keys below. bank.validate() enforces it on every entry.
"""

from __future__ import annotations

from dataclasses import dataclass

THEMES = (
    "sea", "war", "home", "love", "loss", "journey", "night", "dawn",
    "storm", "fire", "gods", "feast", "city", "wild", "time", "glory",
)
EMOTIONS = ("anger", "grief", "joy", "awe", "tenderness", "fear", "defiance", "longing")


@dataclass(frozen=True)
class Head:
    """The word a formula describes: a name ("Achilles") or a noun ("ships")."""

    key: str  # identity for caps and dedupe: canonical name, or the noun's base form
    themes: tuple[str, ...]
    emotions: tuple[str, ...]
    tier: int  # 1 famous, 2 known, 3 obscure (ranked lower)
    kind: str  # "person", "people", "place", or "thing"


# ----- Names -----------------------------------------------------------------
# Canonical spelling (what goes in the bank) -> every spelling the translators use.
# Butler uses Roman names (Jove, Minerva, Ulysses); Lang, Leaf, Myers and
# Butcher transliterate (Athene, Achaians, Aias). The bank uses the familiar
# Greek forms ("grey-eyed Athena", "cloud-gathering Zeus"), and so do players.

NAMES: dict[str, Head] = {}
NAME_FORMS: dict[str, str] = {}  # surface spelling -> canonical


def _name(canon: str, forms: list[str], themes: list[str], emotions: list[str], tier: int, kind: str = "person") -> None:
    NAMES[canon] = Head(canon, tuple(themes), tuple(emotions), tier, kind)
    for f in [canon, *forms]:
        NAME_FORMS[f] = canon


# Gods
_name("Zeus", ["Jove", "Jupiter"], ["gods", "storm"], ["awe", "fear"], 1)
_name("Athena", ["Athene", "Minerva"], ["gods", "war"], ["awe", "defiance"], 1)
_name("Hera", ["Here", "Juno"], ["gods"], ["awe", "anger"], 1)
_name("Apollo", ["Apollon"], ["gods", "war"], ["awe", "fear"], 1)
_name("Poseidon", ["Poseidaon", "Neptune"], ["gods", "sea", "storm"], ["awe", "fear"], 1)
_name("Hermes", ["Hermeias", "Mercury"], ["gods", "journey"], ["awe", "joy"], 1)
_name("Aphrodite", ["Venus", "Cypris", "Kypris"], ["gods", "love"], ["tenderness", "longing"], 1)
_name("Ares", ["Mars"], ["gods", "war"], ["anger", "fear"], 1)
_name("Hephaestus", ["Hephaistos", "Vulcan"], ["gods", "fire"], ["awe", "defiance"], 1)
_name("Artemis", ["Diana"], ["gods", "wild"], ["awe", "defiance"], 1)
_name("Hades", ["Aidoneus", "Pluto"], ["gods", "loss"], ["grief", "fear"], 1)
_name("Dawn", ["Eos", "Aurora", "Morning", "Morn"], ["dawn", "gods"], ["joy", "awe"], 1)
_name("Iris", [], ["gods", "journey"], ["awe", "joy"], 2)
_name("Thetis", [], ["gods", "sea"], ["grief", "tenderness"], 2)
_name("Cronus", ["Kronos", "Cronos", "Saturn"], ["gods", "time"], ["awe", "fear"], 2)
_name("Persephone", ["Persephoneia", "Proserpine"], ["gods", "loss"], ["grief", "awe"], 2)
_name("Leto", ["Latona"], ["gods"], ["tenderness", "awe"], 2)
_name("Helios", ["Hyperion"], ["gods", "dawn"], ["awe", "joy"], 2)
_name("Calypso", ["Kalypso"], ["gods", "love", "sea"], ["longing", "tenderness"], 2)
_name("Circe", ["Kirke"], ["gods", "wild"], ["awe", "fear"], 2)
_name("Oceanus", ["Okeanos"], ["sea", "gods"], ["awe"], 2)
# Heroes and mortals
_name("Achilles", ["Achilleus"], ["war", "glory"], ["anger", "defiance"], 1)
_name("Hector", ["Hektor"], ["war", "glory"], ["defiance", "grief"], 1)
_name("Odysseus", ["Ulysses"], ["journey", "sea", "glory"], ["defiance", "longing"], 1)
_name("Agamemnon", [], ["war", "glory"], ["anger", "defiance"], 1)
_name("Menelaus", ["Menelaos"], ["war", "love"], ["anger", "defiance"], 1)
_name("Ajax", ["Aias"], ["war"], ["defiance", "anger"], 1)
_name("Patroclus", ["Patroklos"], ["war", "loss"], ["grief", "tenderness"], 1)
_name("Priam", ["Priamos"], ["city", "loss"], ["grief", "awe"], 1)
_name("Paris", ["Alexandros", "Alexandrus", "Alexander"], ["love", "war"], ["longing", "defiance"], 1)
_name("Helen", ["Helene"], ["love", "city"], ["longing", "tenderness"], 1)
_name("Penelope", ["Penelopeia"], ["home", "love"], ["longing", "tenderness"], 1)
_name("Telemachus", ["Telemachos"], ["home", "journey"], ["longing", "defiance"], 1)
_name("Nestor", [], ["war", "time"], ["awe", "tenderness"], 2)
_name("Diomedes", ["Diomede"], ["war", "glory"], ["defiance", "anger"], 2)
_name("Andromache", [], ["home", "loss"], ["grief", "tenderness"], 2)
_name("Hecuba", ["Hekabe"], ["home", "loss"], ["grief"], 2)
_name("Laertes", [], ["home", "time"], ["grief", "longing"], 2)
_name("Eumaeus", ["Eumaios"], ["home"], ["tenderness"], 2)
_name("Nausicaa", ["Nausikaa"], ["sea", "love"], ["joy", "tenderness"], 2)
_name("Aeneas", ["Aineias"], ["war", "journey"], ["defiance"], 2)
_name("Sarpedon", [], ["war", "loss"], ["defiance", "grief"], 2)
_name("Polyphemus", ["Polyphemos"], ["wild"], ["fear", "anger"], 2)
_name("Cyclops", ["Kyklops"], ["wild"], ["fear", "anger"], 2)
_name("Atreus", [], ["war", "glory"], ["awe"], 2)
_name("Peleus", [], ["home", "war"], ["awe"], 2)
_name("Tydeus", [], ["war"], ["defiance"], 3)
_name("Idomeneus", [], ["war"], ["defiance"], 3)
_name("Teucer", ["Teukros"], ["war"], ["defiance"], 3)
_name("Antilochus", ["Antilochos"], ["war"], ["defiance"], 3)
_name("Alcinous", ["Alkinoos"], ["feast", "home"], ["joy", "awe"], 3)
_name("Arete", [], ["home"], ["tenderness"], 3)
_name("Eurycleia", ["Euryclea", "Eurykleia"], ["home"], ["tenderness"], 3)
# Peoples (take "the", like the bank's "the bronze-armored Greeks")
_name("Achaeans", ["Achaians"], ["war"], ["defiance", "anger"], 1, "people")
_name("Trojans", [], ["war", "city"], ["defiance", "grief"], 1, "people")
_name("Greeks", [], ["war"], ["defiance"], 1, "people")
_name("Danaans", ["Danaoi"], ["war"], ["defiance"], 2, "people")
_name("Argives", [], ["war"], ["defiance"], 2, "people")
_name("Myrmidons", [], ["war"], ["anger", "defiance"], 2, "people")
_name("Phaeacians", ["Phaiakians"], ["sea", "feast"], ["joy", "awe"], 2, "people")
_name("Cyclopes", ["Kyklopes"], ["wild"], ["fear"], 2, "people")
# Places
_name("Troy", ["Ilios", "Ilium", "Ilion"], ["city", "war"], ["longing", "grief"], 1, "place")
_name("Ithaca", ["Ithake"], ["home", "sea"], ["longing", "tenderness"], 1, "place")
_name("Olympus", ["Olympos"], ["gods"], ["awe"], 1, "place")
_name("Ida", [], ["wild", "gods"], ["awe"], 2, "place")
_name("Argos", [], ["city", "home"], ["longing"], 2, "place")
_name("Sparta", ["Lacedaemon", "Lakedaimon"], ["city", "home"], ["longing"], 2, "place")
_name("Pylos", [], ["city"], ["awe"], 2, "place")
_name("Crete", [], ["sea", "city"], ["awe"], 2, "place")
_name("Hellas", [], ["home"], ["longing"], 2, "place")
_name("Erebus", ["Erebos"], ["night", "loss"], ["fear", "grief"], 2, "place")
_name("Hellespont", [], ["sea"], ["awe"], 2, "place")
_name("Scamander", ["Skamandros", "Xanthus", "Xanthos"], ["wild", "war"], ["awe", "fear"], 2, "place")
_name("Phthia", [], ["home"], ["longing"], 3, "place")

# Lowercase forms that still name a person ("rosy-fingered dawn" in Butler).
LOWER_NAME_FORMS = {"dawn": "Dawn", "morn": "Dawn", "morning": "Dawn"}

# Two-word names: an epithet that is itself a name.
NAME_PAIRS = {("Pallas", "Athena"): "Pallas Athena", ("Phoebus", "Apollo"): "Phoebus Apollo"}


# ----- Nouns -----------------------------------------------------------------

NOUNS: dict[str, Head] = {}  # lowercase surface form -> head


def _noun(key: str, forms: list[str], themes: list[str], emotions: list[str], tier: int = 1) -> None:
    head = Head(key, tuple(themes), tuple(emotions), tier, "thing")
    for f in forms:
        NOUNS[f] = head


_noun("sea", ["sea", "seas"], ["sea"], ["awe", "longing"])
_noun("deep", ["deep"], ["sea"], ["awe", "fear"])
_noun("wave", ["wave", "waves", "billow", "billows", "surf", "breakers"], ["sea", "storm"], ["awe", "fear"])
_noun("brine", ["brine"], ["sea"], ["longing"])
_noun("shore", ["shore", "shores", "beach", "strand", "coast"], ["sea", "journey"], ["longing"])
_noun("ship", ["ship", "ships", "galley", "galleys", "bark", "vessel", "vessels"], ["sea", "journey"], ["longing", "defiance"])
_noun("oar", ["oar", "oars"], ["sea", "journey"], ["defiance"])
_noun("raft", ["raft"], ["sea", "journey"], ["fear", "longing"])
_noun("harbor", ["harbor", "harbors", "haven", "havens"], ["sea", "home"], ["tenderness", "longing"])
_noun("island", ["isle", "isles", "island", "islands"], ["sea", "journey"], ["longing", "awe"])
_noun("river", ["river", "rivers", "stream", "streams", "waters", "flood"], ["wild", "journey"], ["awe"])
_noun("earth", ["earth"], ["wild", "gods"], ["awe"])
_noun("land", ["land", "lands", "country", "soil"], ["home", "journey"], ["longing"])
_noun("plain", ["plain", "plains", "field", "fields", "meadow", "meadows"], ["war", "wild"], ["awe"])
_noun("heaven", ["heaven", "heavens", "sky", "skies", "firmament"], ["gods", "night"], ["awe"])
_noun("star", ["star", "stars"], ["night"], ["awe", "longing"])
_noun("night", ["night"], ["night"], ["awe", "fear"])
_noun("darkness", ["darkness", "gloom", "shadow", "shadows", "mist"], ["night", "loss"], ["fear", "grief"])
_noun("sun", ["sun"], ["dawn"], ["joy", "awe"])
_noun("moon", ["moon"], ["night"], ["tenderness", "awe"])
_noun("evening", ["evening", "eve", "sunset", "twilight"], ["night", "time"], ["longing"])
_noun("mountain", ["mountain", "mountains", "hill", "hills", "peak", "peaks", "heights"], ["wild"], ["awe"])
_noun("forest", ["forest", "forests", "wood", "woods", "glade", "glades", "thicket"], ["wild"], ["fear", "awe"])
_noun("rock", ["rock", "rocks", "cliff", "cliffs", "crag", "crags", "reef"], ["wild", "sea"], ["awe", "fear"])
_noun("cave", ["cave", "caves", "cavern", "grotto"], ["wild"], ["fear", "awe"])
_noun("wind", ["wind", "winds", "blast", "blasts", "gale", "gales", "breeze"], ["storm"], ["fear", "awe"])
_noun("storm", ["storm", "storms", "tempest", "whirlwind", "hurricane"], ["storm"], ["fear", "awe"])
_noun("cloud", ["cloud", "clouds"], ["storm", "gods"], ["awe"])
_noun("thunder", ["thunder", "lightning", "thunderbolt", "thunderbolts", "levin"], ["storm", "gods"], ["fear", "awe"])
_noun("rain", ["rain", "snow", "hail", "frost"], ["storm"], ["grief"])
_noun("fire", ["fire", "fires", "flame", "flames", "blaze", "torch", "torches", "pyre"], ["fire"], ["awe", "fear"])
_noun("smoke", ["smoke", "ash", "ashes", "embers"], ["fire", "loss"], ["grief"])
_noun("spear", ["spear", "spears", "lance", "lances", "javelin", "javelins"], ["war"], ["anger", "defiance"])
_noun("sword", ["sword", "swords", "blade", "blades", "brand"], ["war"], ["anger", "defiance"])
_noun("shield", ["shield", "shields", "buckler"], ["war"], ["defiance"])
_noun("helmet", ["helm", "helms", "helmet", "helmets", "crest", "crests", "plume", "plumes"], ["war", "glory"], ["defiance"])
_noun("bow", ["bow", "bows"], ["war", "gods"], ["fear", "awe"])
_noun("arrow", ["arrow", "arrows", "shaft", "shafts", "dart", "darts"], ["war"], ["fear"])
_noun("armor", ["armor", "harness", "corslet", "corselet", "breastplate", "greaves"], ["war"], ["defiance"])
_noun("chariot", ["chariot", "chariots", "car"], ["war", "glory"], ["defiance", "joy"])
_noun("horse", ["horse", "horses", "steed", "steeds", "mare", "mares", "stallion"], ["war", "glory"], ["joy", "defiance"])
_noun("battle", ["battle", "battles", "fight", "fray", "war", "combat", "strife", "onset", "din"], ["war"], ["anger", "fear"])
_noun("blood", ["blood", "gore"], ["war", "loss"], ["anger", "grief"])
_noun("dust", ["dust"], ["war", "loss"], ["grief"])
_noun("bronze", ["bronze"], ["war"], ["defiance"])
_noun("goddess", ["goddess", "goddesses", "nymph", "nymphs"], ["gods"], ["awe"])
_noun("god", ["god", "gods", "immortals", "deity"], ["gods"], ["awe"])
_noun("queen", ["queen", "lady"], ["gods", "glory"], ["awe", "tenderness"])
_noun("lord", ["lord", "lords", "master"], ["glory", "gods"], ["awe"])
_noun("king", ["king", "kings", "prince", "princes", "chieftain", "chieftains", "captain", "captains", "leader", "leaders", "ruler", "rulers"], ["glory"], ["awe", "defiance"])
_noun("warrior", ["hero", "heroes", "warrior", "warriors", "spearmen", "fighters"], ["war", "glory"], ["defiance"])
_noun("men", ["men"], ["war"], ["defiance"])
_noun("host", ["host", "hosts", "army", "armies", "people", "folk", "throng"], ["war", "city"], ["awe"])
_noun("herald", ["herald", "heralds"], ["glory"], ["awe"])
_noun("bard", ["bard", "bards", "minstrel", "minstrels", "singer"], ["feast", "glory"], ["joy", "awe"])
_noun("seer", ["seer", "prophet", "soothsayer"], ["gods", "time"], ["awe", "fear"])
_noun("suitor", ["suitors", "wooers"], ["home", "feast"], ["anger", "defiance"])
_noun("maiden", ["maiden", "maidens", "handmaid", "handmaids", "handmaidens", "women", "damsels"], ["home", "love"], ["tenderness"])
_noun("wife", ["wife", "bride", "spouse"], ["home", "love"], ["tenderness", "longing"])
_noun("mother", ["mother"], ["home", "love"], ["tenderness"])
_noun("father", ["father", "sire"], ["home"], ["tenderness", "awe"])
_noun("son", ["son", "sons"], ["home", "glory"], ["tenderness", "defiance"])
_noun("daughter", ["daughter", "daughters"], ["home", "gods"], ["tenderness"])
_noun("child", ["child", "children"], ["home"], ["tenderness"])
_noun("nurse", ["nurse"], ["home"], ["tenderness"])
_noun("herdsman", ["swineherd", "shepherd", "herdsman", "neatherd", "goatherd"], ["home", "wild"], ["tenderness"])
_noun("hall", ["hall", "halls", "palace", "palaces", "mansion", "mansions"], ["feast", "home"], ["joy", "tenderness"])
_noun("house", ["house", "houses", "home", "dwelling", "roof", "chamber", "chambers"], ["home"], ["tenderness", "longing"])
_noun("door", ["door", "doors", "threshold", "doorway"], ["home"], ["longing"])
_noun("hearth", ["hearth"], ["home", "fire"], ["tenderness"])
_noun("city", ["city", "cities", "town", "towns", "citadel"], ["city"], ["awe", "longing"])
_noun("wall", ["wall", "walls", "rampart", "ramparts", "battlements", "tower", "towers"], ["city", "war"], ["defiance", "awe"])
_noun("gate", ["gate", "gates"], ["city", "war"], ["awe"])
_noun("street", ["street", "streets"], ["city"], ["longing"])
_noun("wine", ["wine", "wines", "mead", "nectar"], ["feast"], ["joy"])
_noun("cup", ["cup", "cups", "goblet", "goblets", "bowl", "bowls", "chalice", "beaker"], ["feast"], ["joy"])
_noun("feast", ["feast", "feasts", "banquet", "banquets", "meal", "supper", "revel"], ["feast"], ["joy"])
_noun("meat", ["meat", "flesh", "bread", "fare", "food"], ["feast"], ["joy"])
_noun("cattle", ["cattle", "kine", "oxen", "bulls", "bull", "heifer", "heifers", "herds", "herd", "cows"], ["wild", "feast"], ["awe"])
_noun("sheep", ["sheep", "flocks", "flock", "goats", "rams", "ram", "lambs", "ewes"], ["wild", "home"], ["tenderness"])
_noun("boar", ["swine", "boar", "boars", "hogs"], ["wild"], ["fear", "awe"])
_noun("lion", ["lion", "lions"], ["wild", "war"], ["fear", "defiance"])
_noun("wolf", ["wolf", "wolves", "jackals"], ["wild"], ["fear"])
_noun("dog", ["dog", "dogs", "hound", "hounds"], ["wild", "home"], ["fear"])
_noun("deer", ["deer", "stag", "fawn", "hind"], ["wild"], ["fear", "tenderness"])
_noun("bird", ["eagle", "eagles", "hawk", "hawks", "falcon", "vulture", "vultures", "bird", "birds", "cranes", "geese", "gulls"], ["wild"], ["awe"])
_noun("death", ["death", "doom", "fate", "destiny", "bane", "ruin"], ["loss", "time"], ["grief", "fear"])
_noun("sleep", ["sleep", "slumber", "dream", "dreams"], ["night"], ["tenderness", "longing"])
_noun("tears", ["tears", "grief", "sorrow", "sorrows", "woe", "woes", "lament", "wailing"], ["loss"], ["grief"])
_noun("words", ["words", "word", "speech", "tale", "song", "songs", "lay"], ["glory"], ["awe", "joy"])
_noun("voice", ["voice", "cry", "shout"], ["war", "glory"], ["defiance"])
_noun("gift", ["gift", "gifts", "ransom", "prize", "prizes", "spoils"], ["glory", "feast"], ["joy"])
_noun("gold", ["gold", "silver", "treasure", "treasures", "wealth", "riches"], ["glory"], ["joy", "awe"])
_noun("robe", ["robe", "robes", "raiment", "mantle", "cloak", "veil", "tunic", "garments", "garment", "web", "loom"], ["home", "love"], ["tenderness"])
_noun("day", ["day", "days", "years", "year", "age", "hour", "season", "seasons"], ["time"], ["longing"])
_noun("homecoming", ["homecoming", "return"], ["home", "journey"], ["longing"])
_noun("journey", ["journey", "voyage", "road", "roads", "path", "paths", "wanderings"], ["journey"], ["longing"])
_noun("glory", ["glory", "fame", "renown", "honor", "pride"], ["glory"], ["awe", "defiance"])
_noun("shade", ["ghost", "ghosts", "shade", "shades", "phantom"], ["loss", "night"], ["grief", "fear"])
_noun("tomb", ["tomb", "grave", "barrow", "mound"], ["loss"], ["grief"])


# ----- Modifiers -------------------------------------------------------------

# Single-word epithets that may stand before a name or noun ("goodly Odysseus",
# "the barren sea"). A closed list keeps verbs ("said Achilles") and stray
# adjectives out without a part-of-speech tagger.
SIMPLE_ADJ = frozenset(
    """
    goodly godlike divine noble wise prudent wary wily crafty cunning sage fair
    white swift fleet mighty glorious stout brave valiant gallant bold dauntless
    peerless blameless faultless deep wide broad vast dark black grey gray hollow
    barren unharvested unwearied tireless starry rosy shining bright holy sacred
    hallowed sweet gentle dread terrible awful grim baneful deadly chill loud
    windy rugged rocky steep sheer lofty sharp keen heavy brazen golden silver
    silvery wretched hapless unhappy pitiless ruthless cruel kindly dear beloved
    lovely beautiful sturdy strong lordly princely royal ancient aged misty murky
    shadowy gloomy dusky murderous fierce savage furious raging stalwart haughty
    famous renowned immortal deathless everlasting eternal restless salt briny
    foaming echoing resounding fruitful fertile rich wealthy horned curved crooked
    beaked tawny bloody gory sandy grassy wooded shady clear limpid flowing eddying
    hateful bitter woeful sorrowful mournful piteous doleful grievous stern
    great old high long good young tall
    """.split()
)
# Common adjectives that pair with anything ("the great hall"): they need
# twice the usual count before they count as a formula.
GENERIC_ADJ = frozenset("great old high long good young tall mighty fair dear".split())
# Before a common noun only these count: the adjectives Homer fixes to things
# ("the hollow ships", "the salt sea", "sweet sleep"), not "the great wall".
NOUN_ADJ = frozenset(
    """
    hollow black swift curved beaked salt barren unharvested starry wide broad deep
    dark grey immortal deathless everlasting sweet sharp keen brazen golden silver
    silvery shadowy windy sandy rocky rugged holy sacred misty murky gloomy dusky
    echoing resounding foaming bright shining horned tawny fruitful fertile lofty
    steep sheer limpid flowing eddying bloody gory chill cruel pitiless grim baneful
    deadly dread terrible awful
    """.split()
)
# Heads too plain for an ADJ + noun formula ("dear son", "great glory").
PLAIN_HEADS = frozenset(
    """
    son daughter child father mother wife nurse maiden men warrior king lord queen
    herdsman glory tears words day gift gold robe land house battle voice meat feast
    journey host herald
    """.split()
)
# Formulas whose head isn't the name they mention: Hermes is the slayer of Argus.
FIXED = {"slayer of Argos": ("slayer of Argus", "Hermes")}
# Titles that stand before a name ("father Zeus", "lady Hera", "king Priam").
TITLES = frozenset("father lady queen king lord prince".split())
# Name-epithets that are themselves names ("Pallas Athene", "Phoebus Apollo").
NAME_EPITHETS = frozenset({"Pallas", "Phoebus"})

# Hyphenated words that are not epithets.
HYPHEN_STOP = frozenset(
    """
    to-day to-morrow to-night hand-to-hand pell-mell drink-offering drink-offerings
    thigh-bones look-out son-in-law daughter-in-law father-in-law mother-in-law
    brother-in-law by-word self-same mid-day store-room maid-servant man-servant
    house-keeper sea-shore half-way hey-day well-nigh any-one no-one some-one
    every-one good-bye fellow-student shoulder-notes over-saturation work-box
    bearing-post bearing-posts thole-pins thole-pin rope-ends main-beams
    mixing-bowl mixing-bowls assembly-place pasture-land barley-meal butt-end
    look-out-station death-throes sleeping-ground down-stroke spear-stand
    """.split()
)
HYPHEN_STOP_PARTS = frozenset("to by in of on the a an and or self no any every some year years old".split())

FUNCTION_WORDS = frozenset(
    """
    the a an and or nor but of to in on at by from with as for that which who
    whom whose when while so then yet if than this these those his her their its
    my thy your our he she it they them him we you i me us
    """.split()
)
SENTENCE_END = frozenset(". ; : ! ? \" ( ) [ ]".split())

# Prepositions that open a half-line ("over the wine-dark sea").
HALF_LINE_PREPS = frozenset(
    "over upon across beside along among beneath through into".split()
)

# Genitive epithets: TITLE of X ("son of Atreus", "king of men", "sacker of cities")
# take no article; PLACE of X ("the gates of Hades") keeps one.
GENITIVE_TITLES = frozenset(
    """
    son sons daughter daughters king lord shepherd sacker tamer gatherer shaker
    slayer breaker bearer father mother queen leader captain
    """.split()
)
GENITIVE_THINGS = frozenset("house halls hall gates walls wrath shore depths streams land city plain".split())
PATRONYMIC = frozenset("son sons daughter daughters".split())
# Heads too plain to follow a title ("son of the king", "lord of the house").
GENITIVE_X_STOP = frozenset("king son daughter father mother child lord queen wife house hall day".split())

# Translators' spellings -> the bank's.
SPELLING = {
    "armour": "armor", "harbour": "harbor", "harbours": "harbors", "honour": "honor",
    "colour": "color", "builded": "built", "ancle": "ankle", "gray": "grey",
}

# Different English for one Greek formula. Used only for dedupe: "fleet-footed
# Achilles" is the bank's "swift-footed Achilles".
COMPOUND_SYNONYMS = {
    "fleet-footed": "swift-footed", "rosy-fingered": "rose-fingered",
    "bright-eyed": "grey-eyed", "flashing-eyed": "grey-eyed",
    "loud-sounding": "loud-roaring", "loud-resounding": "loud-roaring",
    "far-darting": "far-shooting", "far-darter": "far-shooter",
    "cloud-compelling": "cloud-gathering", "man-slaying": "man-killing",
    "bronze-clad": "bronze-armored", "mail-clad": "bronze-armored",
    "bronze-armed": "bronze-armored", "brazen-coated": "bronze-armored",
    "mail-coated": "bronze-armored", "well-builded": "well-built", "ever-living": "immortal",
    "ever-during": "immortal",
}
WORD_SYNONYMS = {
    "fleet": "swift", "greeks": "achaeans", "morn": "dawn", "morning": "dawn", "steeds": "horses",
    "deathless": "immortal", "everlasting": "immortal", "slumber": "sleep", "goblet": "cup",
}


# ----- Tags ------------------------------------------------------------------
# Modifier words (or parts of a compound) -> emotions they carry.

EMOTION_CUES: dict[str, tuple[str, ...]] = {}


def _cue(emotions: list[str], words: str) -> None:
    for w in words.split():
        EMOTION_CUES[w] = tuple(dict.fromkeys(EMOTION_CUES.get(w, ()) + tuple(emotions)))


_cue(["awe"], "divine godlike god immortal deathless glorious mighty great broad wide vast starry holy sacred "
     "hallowed aegis cloud heaven lofty high ever seeing fountained ruling throned lordly royal peerless "
     "noble goodly famous famed renowned far many ox everlasting eternal echoing resounding")
_cue(["fear"], "aegis dread terrible awful grim baneful deadly slaying black dark shadowy murky misty gloomy dusky "
     "loud roaring sounding darting shooting pitiless ruthless cruel chill sharp keen storm shadowing pointed "
     "edged thundering crooked")
_cue(["anger"], "wrath fierce savage raging furious blood bloody gory murderous stormer haughty slaying hateful")
_cue(["grief"], "barren unharvested wretched hapless unhappy piteous woeful sorrowful mournful bitter doleful "
     "grievous hateful ill fated grey dust")
_cue(["joy"], "rosy laughter loving sweet honey merry glad fair lovely beautiful rich silver silvery clear "
     "sparkling fruitful golden shining bright")
_cue(["tenderness"], "gentle kind kindly dear beloved loved soft tressed ankled girdled wise "
     "prudent faithful robed lady father fair lovely")
_cue(["defiance"], "bold stout dauntless brave valiant gallant strong sturdy stalwart swift fleet "
     "bronze brazen mail clad greaved taming horse spear shod lion iron unwearied tireless wily crafty cunning "
     "helmeted glancing flashing proud stern")
_cue(["defiance"], "sacker tamer breaker")
_cue(["anger", "fear"], "slayer")
_cue(["awe"], "gatherer bearer")
_cue(["fear"], "shaker")
_cue(["longing"], "distant homecoming wandering hollow deep wine suffering seen lying borne salt wayed evening "
     "grey wide")

# Whole compounds whose sense isn't the sum of their parts ("white-armed" is
# tender, "white-tusked" is not). Checked before the parts.
_cue(["tenderness"], "white-armed fair-cheeked")
_cue(["defiance", "awe"], "great-hearted high-hearted")
_cue(["defiance"], "stout-hearted lion-hearted bold-hearted")
_cue(["tenderness", "awe"], "wise-hearted")

# Places a half-line can move through ("over the wine-dark sea", "beside the hollow ships").
HALF_LINE_HEADS = frozenset(
    """
    sea deep wave brine shore ship island river earth land plain heaven night darkness
    mountain forest rock cave cloud fire smoke hall house door city wall gate street dust
    battle blood harbor evening star
    """.split()
)

# Modifier words -> extra themes ("cloud-gathering" adds storm).
THEME_CUES: dict[str, tuple[str, ...]] = {
    "cloud": ("storm",), "thunder": ("storm",), "thundering": ("storm",), "storm": ("storm",),
    "wind": ("storm",), "windy": ("storm",), "fire": ("fire",), "flame": ("fire",),
    "star": ("night",), "starry": ("night",), "rosy": ("dawn",), "sea": ("sea",),
    "horse": ("war",), "spear": ("war",), "bronze": ("war",), "mail": ("war",), "greaved": ("war",),
    "aegis": ("gods",), "god": ("gods",), "divine": ("gods",), "godlike": ("gods", "glory"),
    "home": ("home",), "homecoming": ("home",), "famed": ("glory",), "famous": ("glory",),
    "glorious": ("glory",), "renowned": ("glory",), "laughter": ("love",),
    "night": ("night",), "dawn": ("dawn",), "death": ("loss",), "blood": ("war",),
}

assert all(t in THEMES for h in [*NAMES.values(), *NOUNS.values()] for t in h.themes)
assert all(e in EMOTIONS for h in [*NAMES.values(), *NOUNS.values()] for e in h.emotions)
assert all(e in EMOTIONS for es in EMOTION_CUES.values() for e in es)
assert all(t in THEMES for ts in THEME_CUES.values() for t in ts)
