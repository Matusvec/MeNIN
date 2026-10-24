# MeNIN: music brief

This is the brief for MeNIN's original soundtrack. It covers the feel, the one hard rule, every cue with its length, the sounds for the beat, and how to send the files. If anything here is unclear, ask Matus.

## What MeNIN is

MeNIN is ancient Greek party games on one shared screen, with phones as the controllers. The main event is a poetry battle: players improvise verse out loud over a slow drum-and-lyre beat, and Homer, the legendary poet, hosts and judges. There's also a debate hosted by Socrates, and a discus throw where you swing your phone. Lessons with Homer teach you how to battle.

The name is μῆνιν (mēnin, said "MAY-nin"), "rage", the first word of the Iliad.

## The feel

- **The Wii Sports menu, in an ancient Greek key.** Catchy, friendly, light on its feet, and recognizable in a few notes. Then set it in ancient Greece.
- **Classical meets party.** A lyre riff over a groove you can nod along to.
- **Matte.** Warm, dry and close, like the app's flat, cut-paper look. Real or real-sounding instruments, with little reverb. No shimmer, no glossy synth pads, no risers or EDM drops.
- **Professional and badass in battles.** Think of a title-fight walkout, not a cartoon: confident and not comedic. Homer is a legend, not a professor.

Instruments that fit: the lyre or kithara (plucked strings), the aulos (a double-reed pipe, like an oboe with attitude), frame drums, hand claps, and a low wordless male choir. Anachronisms are fine when they're fun, like a brass fanfare for the discus or a bass line under the hall theme.

**An idea, not a rule:** one short motif that runs through every cue, like a sonic logo. A two-note "MAY-nin" figure, strong then soft, is one way to do it.

## The one hard rule

**No music ever plays while a player is speaking.**

- In a poetry turn, the only sound is the app's own drum-and-lyre beat. The app decides when each drum hit and lyre note plays, so you don't write the beat. We'd like you to record its sounds, though (see "The beat's sounds" below).
- Whenever a microphone is open, the music fades out completely.
- When Homer or Socrates talks, the music drops well down (about 12 dB) and comes back up when he stops. He talks over a few cues (the notes on each cue say which), so leave room for a deep male voice: keep the melody out of his way there.

## The cues

Eleven cues, each its own file. The file name is the name in the first column.

| File name | Plays when | Length | Loops |
| --- | --- | --- | --- |
| `hall-theme` | The home menu, the lobby while players join, and between events | 60–90 s | Yes |
| `first-open-bed` | Under Homer's very first line, the first time anyone opens the app | about 7 s | No |
| `poetry-intro` | A poetry battle starts, just before Homer opens it | 3–4 s | No |
| `debate-intro` | A debate starts, just before Socrates opens it | 3–5 s | No |
| `discus-intro` | The discus event starts | 3–5 s | No |
| `discus-whoosh` | The discus leaves the hand and flies | about 2 s | No |
| `discus-fanfare` | The throw's distance appears | 2–3 s | No |
| `round-end` | A round ends and the scores appear | 2–4 s | No |
| `champion` | The winner is revealed | 4–6 s | No |
| `training-ambience` | Lessons and practice, between tries | 60–120 s | Yes |
| `rematch` | Someone taps Rematch | 1–2 s | No |

### hall-theme

MeNIN's main song, the one people hum on the way out. It plays on the home menu, where you pick an event, and in the lobby while players scan in to join. Homer talks over it to announce each player ("Enter Priya, Keeper of the Rubric!"). In the live demo, we talk over it while we pitch to the judges, so there it plays turned down the whole time. Make it catchy but not busy.

### first-open-bed

The first time someone opens MeNIN, Homer speaks before any menu: "The first word of Western literature is mēnin. Rage. Give me one line." Then the player answers out loud.

- Your bed starts the moment the app opens. Homer's line starts 1 s in and lasts about 6 s. "Rage" lands about 4.9 s into your bed.
- It must be finished by about 7 s, because the microphone opens right after Homer's line. Let it decay naturally, so it still sounds right if the app fades it a little early.
- This is the one cue written to sit under Homer, so the app doesn't turn it down. Keep it sparse: a low drone, a single lyre strum, and maybe one heavy hit on "Rage".
- We'll put Homer's recorded line in the shared folder, so you can score to it.

### poetry-intro

The poetry battle's title card. It plays as the battle begins, then Homer opens: "Three rounds. Every poet speaks. I judge." In the demo, it plays under the theme cards while Matus asks the judges to pick one, so it's the first cue they hear after the menu. It should feel like walking into the ring.

### debate-intro

The same job for the debate. Socrates is dry, ironic and amused: a boxing announcer who has read too much. His intro can have a wink, like something plucked and a little sly.

### discus-intro, discus-whoosh, discus-fanfare

Discus is the most physical event. You swing your phone and lift your thumb to throw.

- `discus-intro`: athletic and bright, the opening of the games.
- `discus-whoosh`: a sound effect, not music. It's a spinning disc cutting through air. It starts on the release and fades as the discus flies off (the flight lasts about 4 s).
- `discus-fanfare`: the distance appears. It's short, and Homer calls the distance right after it ("Strong arm.").

### round-end

Plays as the round's scores appear. Then Homer reads the verdict and quotes the best line, which gets carved in gold on screen. Make it a short, decisive "the round is over".

### champion

The winner is revealed. Homer crowns them right away, so the big moment has to land in the first 2 s. The rest can ring out under him.

### training-ambience

Homer's hall at night: low fire, a distant sea, an occasional lyre note. There's no beat, because the drum comes in when the player tries, and the ambience fades out then. It's calm focus. It loops for minutes, so nothing should stand out enough to get annoying.

### rematch

Plays when someone taps Rematch, while the app resets for a new battle. In the demo we may hear it three times in a row, so keep it tiny and punchy, like a bell before the next round.

## The beat's sounds

Poetry turns and lessons run on a beat the app plays itself, at about 80 BPM in 4/4. Each bar has a kick on beats 1 and 3, a rim click on 2 and 4, and a few plucked lyre notes. Right now the app makes those sounds with a synthesizer. **We'd like real ones from you.** The app still decides when each sound plays, so you only record single hits.

This matters more than any single cue. The beat plays under every turn and every lesson, so it's the sound people hear most.

| File name | What it is |
| --- | --- |
| `lyre-d3` | One plucked lyre note: D3 |
| `lyre-f3` | F3 |
| `lyre-g3` | G3 |
| `lyre-a3` | A3 |
| `lyre-c4` | C4 |
| `lyre-d4` | D4 |
| `drum-kick` | A low, round hit in the center of a frame drum, played with the hand |
| `drum-rim` | A sharp tap on the frame drum's edge |

- **Dry:** no reverb or echo, so each hit stays crisp in a loud hall and when hits overlap.
- **Trimmed tight:** the hit starts on the very first sample. The lyre notes ring for about 1.5 s, and the drums stop as soon as they've decayed.
- **Even:** play all six lyre notes at the same strength, and keep them in tune (A = 440).
- **Together:** when a poet's stressed word lands on the beat, the app plays the kick and the rim at once as a "drum strike", so check that the two sound good together.
- **Format:** WAV, 48 kHz, 24-bit, mono, with peaks around -6 dB. The app sets the mix, so you don't need to match loudness for these.

The lyre notes make D Dorian (D, F, G, A, C, D). Music and the beat never play at the same time, so you don't need to match the tempo. But writing the poetry cues in D (D minor or D Dorian) will make the whole app feel like one piece.

## What to avoid

- **Sung words.** Lyrics would compete with Homer. Wordless voices, like a hum or an "ah", are fine.
- **Any existing tune**, including anything from Wii Sports. We want the feeling, not the melody. Don't use samples from other recordings, unless they're royalty-free and you tell us the source.
- **Silence at the start of a file.** The app plays each cue at an exact moment, so silence at the front sounds like lag.
- **Long tails on stings.** A natural ring-out is fine. Then stop.
- **Fades on loops.** A loop goes straight from its end back to its start.

## How to send the files

- **Format:** WAV or AIFF, 48 kHz, stereo, 24-bit. The beat's sounds are the exception: mono (see above).
- **Loudness:** about -16 LUFS integrated, with peaks below -1 dB true peak. Stings are too short to measure reliably, so match them to the hall theme by ear.
- **One file per cue or sound,** named exactly as in the tables: `hall-theme.wav`, `lyre-d3.wav`, and so on.
- **Mark the loop points** on `hall-theme` and `training-ambience`. The simplest way is to make the file exactly one loop, so its last sample flows straight into its first. If the loop has an intro before it, write the loop's start and end times in a `notes.txt`.
- **Check on a phone.** Most people will hear MeNIN through an iPhone, iPad or MacBook speaker in a loud hall. Those speakers drop deep bass, so make sure the melody and the hits are clear without it. Before sending, play each file on your phone's speaker.
- **Where:** the shared folder Matus picks. **[Matus adds the link here.]** We'll commit the files into the app.
- **New versions:** keep the same file name, replace the old file in the folder, and tell Matus what changed.
- **Credit:** tell Matus how you'd like to be credited in the app and on Devpost.

## Order and timing

A rough version with the right length and file name is worth more early than a polished one late. We can wire the app to the rough version and drop in the final with the same name.

| Priority | Cues | Why |
| --- | --- | --- |
| 1 | `hall-theme`, `first-open-bed`, `poetry-intro`, `round-end`, `champion`, `rematch` | The judges hear all of them in the 2-minute demo |
| 2 | The beat's sounds: the six `lyre-` notes, `drum-kick`, `drum-rim` | They play under every turn and lesson |
| 3 | `discus-intro`, `discus-whoosh`, `discus-fanfare`, `debate-intro` | The other events, if they make the demo |
| 4 | `training-ambience` | Lessons and practice, which the judges don't see live |

**Suggested deadlines** (Matus confirms):

- **Priority 1 by Sat 6 PM,** so it's in the build for the hall noise test at 9 PM.
- **The beat's sounds as soon as you can after that.** The noise test also sets the beat's level, so it helps to have the real sounds in by then.
- **Everything by Sat 9 PM.**
- **Sat 11 PM is feature freeze.** After that, only fixes to files we already have. The demo video is recorded around then too, and it may use the hall theme.

## If you have time (optional)

Only after everything above:

- `discus-crowd`: a crowd that builds while the thrower winds up, 1–4 s, cut off at the release.
- `discus-fanfare-big`: a bigger fanfare for a new record.
- `lesson-landed`: a 1–2 s sting when a player lands a lesson.
- `drum-kick-soft` and `drum-rim-soft`: the same hits played gently. While a poet speaks, the beat plays quietly, and a soft hit sounds more natural than a loud one turned down.

## Before you send

- [ ] Every file is named exactly as in the tables
- [ ] WAV or AIFF, 48 kHz, 24-bit, stereo (the beat's sounds: mono)
- [ ] Cues at about -16 LUFS, peaks below -1 dB
- [ ] No silence at the start of any file
- [ ] The two loops loop without a click or a gap
- [ ] The beat's sounds are dry, in tune, mono, and start right on the hit
- [ ] No sung words and no borrowed melodies
- [ ] Played once on a phone speaker
