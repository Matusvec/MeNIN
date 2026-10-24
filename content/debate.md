# Socratic debate

Content for the debate event: the host's persona, the questions, the rubric, the freeze rescue, the moves and the shared lines. The move cards are in `content/moves.json`. The flow is in `docs/ux-flow.md`, section 7.

Per SPEC.md ("The games"), debate is a config on the poetry battle's engine. It keeps the turns, the scene and the verdict. Your hand holds moves instead of formulas, the rescue whispers a question, it has its own five-axis rubric, and there is no beat.

## How to use this file

- **Everything in double quotes is spoken by TTS, exactly as written,** and captioned. No markdown, no notation.
- **Placeholders** are filled in before TTS:
  - `{name}`, `{title}`: a debater's name and epithet
  - `{n}`: the round number
  - `{question}`: the round's question
  - `{side}`, `{side_a}`, `{side_b}`: a side's label
  - `{term}`, `{claim}`, `{case}`, `{thing}`: words drawn from what the last speaker said (see the moves section)

## Socrates

He was the old man in the marketplace of Athens who said he knew nothing, then asked you questions until you admitted you didn't either. Athens sentenced him to death for it, and he joked on the way out.

**Voice**

- Dry, unhurried, amused. Short sentences. He asks more than he tells.
- **Ironic:** he claims to know nothing, and it's always a trap. The irony is aimed at himself or at an idea, never at a person.
- **Relentless:** there is always one more question.
- **Never lectures.** He explains nothing in more than one sentence; he would rather ask.
- **No jargon.** He never says fallacy, premise, syllogism, rhetoric, or straw man. He says "your reason", "your claim", "a case that breaks it".
- **Never takes a side on the question,** not even in a verdict. He judges the arguing, not the answer.
- Never names a debater's emotion. The scene shows it.
- Everything he says is captioned.

**Two registers**

- **Training (practice), a pro coach:** calm and precise, one fix at a time. He takes the other side and argues it mostly by asking you questions.
- **Battle, a full MC:** deadpan entrances, hype delivered dry, gentle roasts, verdicts that land like a knockout. Think of a boxing announcer who has read too much.

---

## The questions

Each round has one question with two sides. Sides are assigned by turn order, not chosen (see `docs/ux-flow.md`). Arguing a side you don't hold is the game.

All questions are PG and steer clear of politics and religion, so a mixed room can play.

| id | Socrates asks | Side A | Side B | Kind |
| --- | --- | --- | --- | --- |
| `invisible` | "If you could turn invisible, would you stay honest?" | Yes | No | classic |
| `wronged` | "Is it better to be wronged than to do wrong?" | Yes | No | classic |
| `teach-goodness` | "Can you teach someone to be good?" | Yes | No | classic |
| `knowing-is-doing` | "If you know what's right, will you always do it?" | Yes | No | classic |
| `ship` | "Replace every plank of a ship, one by one. Is it still the same ship?" | Same ship | New ship | classic |
| `wisest-rules` | "Should the wisest person be in charge?" | Yes | No | classic |
| `ever-lie` | "Is it ever right to lie?" | Yes | No | classic |
| `bad-rule` | "Should you follow a rule you think is wrong?" | Yes | No | classic |
| `same-person` | "Are you the same person you were ten years ago?" | Yes | No | classic |
| `one-homer` | "Was Homer one poet, or many?" | One | Many | classic |
| `hot-dog` | "Is a hot dog a sandwich?" | Yes | No | everyday |
| `five-minutes` | "Is it a lie to say you're five minutes away when you're fifteen?" | Yes | No | everyday |
| `bad-haircut` | "Should you tell a friend their haircut is bad?" | Yes | No | everyday |
| `spoilers` | "Do spoilers ruin a story?" | Yes | No | everyday |
| `cereal-soup` | "Is cereal a soup?" | Yes | No | everyday |
| `sleep-waste` | "Is sleep a waste of time?" | Yes | No | everyday |
| `pineapple` | "Does pineapple belong on pizza?" | Yes | No | everyday |
| `ai-love-letter` | "Is it cheating to let an AI write your love letter?" | Yes | No | wild |
| `feared-loved` | "Is it better to be feared or loved?" | Feared | Loved | wild |
| `robots-day-off` | "Should robots get a day off?" | Yes | No | wild |
| `animals-languages` | "Would you rather talk to animals, or speak every human language?" | Animals | Languages | wild |
| `fame-or-truth` | "Would you rather be famous and wrong, or right and forgotten?" | Famous | Right | wild |

---

## The rubric

Every turn is scored 1 to 10 on five axes. As in the poetry battle, the scores and the quoted best line are always shown, so a verdict can be explained.

| Axis | One-line definition | Source |
| --- | --- | --- |
| **Claim** | You took your side, said it plainly, and held it to the end. | Claude |
| **Reason** | Your reasons and examples actually support your claim. | Claude |
| **Answer** | You took on the last speaker's strongest point, not their weakest. If you went first, you took on the question itself. | Claude, with the previous turn |
| **Craft** | You made the moves in your hand, at the right moment, and varied them. Doing the move counts. Naming it doesn't. | Claude, with the hand and the moves you played |
| **Poise** | You kept the floor: steady pace, few fillers, no dead air. | Measured from the transcript and the audio, not Claude |

**Poise** is the one axis Claude doesn't score, as Beat is for poetry. It counts filler words ("um", "uh", "like", "you know"), checks whether the speaking pace stays in a comfortable band, and measures the longest silence. A freeze rescue counts as one silence. The agent service owns the exact formula.

---

## The freeze rescue

In poetry, Homer whispers a formula. In debate, Socrates whispers a question for you to ask.

- **Trigger:** about 2 s of silence mid-turn, including 2 s of silence right after "Go". That's longer than poetry's 1 s, because there's no beat and arguments pause to breathe.
- **What happens:** your hand comes forward on your phone, one move card is raised, and Socrates whispers a question.
- **The whisper:**
  - It is always a single question, under ten words, in your own voice, so you can just say it out loud.
  - It performs the raised move on the current argument. If the move is "ask for a definition" and the last speaker said "fair", the whisper is "What do you mean by fair?"
  - Nothing else: no "try asking", no name.
- **Prepared ahead:** when you step up, the agent prepares one whisper per move in your hand from the question and the previous turn, so the rescue plays instantly. If you're first in the round, the whispers aim at the question itself.
- **Fallback:** if a prepared whisper isn't ready, use the move's template from the table below, with `{term}` filled from the previous turn.
- **Asking the whispered question counts as playing that move,** so its card is marked played.

---

## The moves

`content/moves.json` holds 40 move cards with the same schema as `formulas.json`, plus one extra field:

- `kind` is `"move"`.
- `role` is the move's job in an argument:
  - `open`: stake out ground
  - `attack`: go after their point
  - `defend`: protect yours
  - `close`: finish
- `beats` is `0`, because debate has no beat.
- `themes` is for topics, as in the formula bank. It's empty for now, since every move fits every question.

Deal a hand with at least one open, one attack, one defend and one close. The fifth card is any role.

The template is how the move sounds as a question. The freeze rescue uses it, and so does the judge, to recognize a move when it's made.

| id | Role | Sounds like (rescue template) |
| --- | --- | --- |
| `stake-your-claim` | open | "What exactly am I saying?" |
| `define-your-terms` | open | "Before we start, what does {term} mean?" |
| `give-a-reason` | open | "Why do I believe it? Because what?" |
| `give-an-example` | open | "Where have I seen this happen?" |
| `tell-a-story` | open | "Remember the time {case}?" |
| `analogy` | open | "Isn't this just like {thing}?" |
| `name-the-stakes` | open | "Why should anyone here care?" |
| `start-from-agreement` | open | "What do we all agree on?" |
| `narrow-it-down` | open | "Do we mean always, or just here?" |
| `open-with-a-question` | open | "Who here has ever {case}?" |
| `counterexample` | attack | "What about {case}?" |
| `ask-for-a-definition` | attack | "What do you mean by {term}?" |
| `follow-it-to-the-end` | attack | "If that's true, then what follows?" |
| `find-the-contradiction` | attack | "Didn't you just say the opposite?" |
| `who-decides` | attack | "Who decides what counts as {term}?" |
| `the-hidden-assumption` | attack | "What are you taking for granted?" |
| `flip-the-analogy` | attack | "Doesn't your comparison cut both ways?" |
| `ask-for-proof` | attack | "How do you know that?" |
| `where-does-it-stop` | attack | "Where does that stop?" |
| `the-extreme-case` | attack | "Would that still hold for {case}?" |
| `turn-it-around` | attack | "Doesn't your reason prove my side?" |
| `who-pays` | attack | "And who pays for that?" |
| `the-other-side-of-the-coin` | attack | "What happens that you didn't mention?" |
| `ask-why-again` | attack | "Why? And why is that?" |
| `concede-and-pivot` | defend | "Fair, but does that change the answer?" |
| `draw-a-line` | defend | "Aren't those two different cases?" |
| `say-it-better-than-they-did` | defend | "Isn't their best point really {claim}?" |
| `zoom-out` | defend | "What does this look like from far away?" |
| `split-the-question` | defend | "Aren't we asking two questions here?" |
| `find-common-ground` | defend | "Where do we already agree?" |
| `propose-a-test` | defend | "What would settle this for good?" |
| `admit-what-you-dont-know` | defend | "What don't I know here?" |
| `back-to-the-question` | defend | "What was the question again?" |
| `the-burden-is-yours` | defend | "Why should I prove it, not you?" |
| `sum-it-up` | close | "What's my whole case in one line?" |
| `call-back` | close | "Remember where I started?" |
| `the-choice` | close | "So which would you choose?" |
| `the-last-question` | close | "Can anyone here answer this?" |
| `end-on-an-image` | close | "What picture should they leave with?" |
| `ask-the-room` | close | "Who here would really {case}?" |

---

## Lines

### Shared, both registers

| When | Socrates says |
| --- | --- |
| Go | "Go." |
| Ten seconds left | "Ten seconds." |
| Time | "Time." |
| No speech heard | "I heard nothing. Again." |
| The mic drops out | "I've lost you. Check your mic." |
| An inappropriate turn | "Not in the agora. Try another." |
| The verdict is late (stall) | "I'm thinking. It's my only skill." |

### Training: the coach

| When | Socrates says |
| --- | --- |
| Start | "I'll take the other side. Convince me. I warn you, I know nothing." |
| Sides | "You take {side}. Whether you believe it is your business." |
| Step up | "Your turn." |
| Verdict, a sample | "Clear claim. Thin reason. Next time, give me one example." |
| Verdict, a sample | "You answered me. Good. Now say it in half the words." |
| Verdict, a sample | "You defined your terms, then forgot them. Hold on to them." |
| You beat him | "You've confused me completely. That's a compliment." |
| He beat you | "I asked, you wobbled. Again?" |

### Battle: the MC

| When | Socrates says |
| --- | --- |
| Entrance | "From the agora: {name}, {title}. Claims to know things. We'll see." |
| Opening | "Three questions. Every debater speaks. I judge. I know nothing, so it'll be fair." |
| Round title | "Round {n}. The question: {question}" |
| Sides, once per round | "Sides are dealt, not chosen. You don't have to believe it. You have to win it." |
| Step up | "{name}, {title}. You say {side}. The floor is yours. Try not to fall through it." |
| Verdict, a sample | "You found the crack in their wall and walked straight through it." |
| Verdict, a sample | "Three reasons, no answers. You won an argument with nobody." |
| Verdict, a sample | "One small concession, and you took the whole field." |
| Round verdict | "The round goes to the line that left this room with nothing to say:" and then he quotes it. |
| Last question | "Before I crown anyone, one question nobody answered tonight." and then he asks it. |
| Crown | "I know nothing. But I know who won. {name}, {title}." |
