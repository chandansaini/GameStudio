# Game Concept: LEXICON

*Created: 2026-03-24*
*Status: Approved*

---

## Elevator Pitch

> It's a daily word-grouping puzzle where you assign words to hidden categories,
> and each correct placement reveals letters in the category name — so you're
> solving two entangled puzzles at once with only 3 lives to spare.

---

## Core Identity

| Aspect | Detail |
| ---- | ---- |
| **Genre** | Daily puzzle / Word game |
| **Platform** | PC (primary), Mobile (future) |
| **Target Audience** | Daily puzzle completionists, word game enthusiasts |
| **Player Count** | Single-player |
| **Session Length** | 5-10 minutes |
| **Monetization** | None (jam scope) |
| **Estimated Scope** | Small — 1 week solo development |
| **Comparable Titles** | NYT Connections, Wordle, Spelling Bee |

---

## Core Fantasy

You are the person who sees the pattern everyone else misses. The category
name is hidden, the groupings are not obvious, and you have only 3 lives — but
through careful deduction, letter by letter, the picture assembles itself until
you see it whole. That moment of full revelation — "oh, of course" — is the
payoff. Not given. Earned.

---

## Unique Hook

Like NYT Connections, AND ALSO the category names are hidden and revealed
letter-by-letter as you correctly place words — so the grouping puzzle and
the naming puzzle are entangled, each one unlocking the other.

---

## Player Experience Analysis (MDA Framework)

### Target Aesthetics (What the player FEELS)

| Aesthetic | Priority | How We Deliver It |
| ---- | ---- | ---- |
| **Sensation** (sensory pleasure) | 4 | Clean letter-reveal animation, satisfying placement feedback |
| **Fantasy** (make-believe, role-playing) | N/A | Not applicable |
| **Narrative** (drama, story arc) | N/A | Not applicable |
| **Challenge** (obstacle course, mastery) | 2 | 3-life limit, difficulty dial, hard categories |
| **Fellowship** (social connection) | N/A | Not applicable at launch |
| **Discovery** (exploration, secrets) | 1 | Hidden category names, entangled reveal mechanic |
| **Expression** (self-expression, creativity) | N/A | Not applicable |
| **Submission** (relaxation, comfort zone) | 3 | Short daily session, no time pressure |

### Key Dynamics (Emergent player behaviors)

- Players will scan all words before placing any, forming hypotheses mentally first
- Players will prioritize slots where they feel most confident to bank letter reveals
- Players will use partial category name letters to cross-validate their grouping hunches
- Players who fail will replay after life restore, approaching the same puzzle differently
- Players will share results (like Wordle) — "got it with 1 life left"

### Core Mechanics (Systems we build)

1. **Slot Assignment** — Player clicks a word then clicks a slot to assign it; correct/wrong resolves immediately
2. **Letter Reveal System** — Each correct word placement in a slot reveals N letters of that slot's category name; N and letter order are tunable per puzzle (difficulty dial)
3. **3-Life System** — Wrong placements cost a life; 0 lives = puzzle failed; lives restore after a few hours enabling a fresh retry
4. **Anchor Words** — One word per group is pre-placed in its slot, giving the player a guaranteed foothold in each category
5. **Daily Puzzle Cadence** — One new puzzle per day; previous puzzles remain accessible

---

## Player Motivation Profile

### Primary Psychological Needs Served

| Need | How This Game Satisfies It | Strength |
| ---- | ---- | ---- |
| **Autonomy** (freedom, meaningful choice) | Player chooses which slot to tackle first; strategy in sequencing placements | Supporting |
| **Competence** (mastery, skill growth) | Solving with lives to spare; reading partial letters faster over time; completing harder puzzles | Core |
| **Relatedness** (connection, belonging) | Shared daily puzzle creates common experience; shareable results | Minimal (at launch) |

### Player Type Appeal (Bartle Taxonomy)

- [x] **Achievers** — Daily completion streak, solving with fewest mistakes
- [x] **Explorers** — Discovering hidden category names, understanding the puzzle's logic
- [ ] **Socializers** — Not a focus at launch
- [ ] **Killers/Competitors** — No PvP or leaderboards

### Flow State Design

- **Onboarding curve**: First puzzle uses easy categories with high letter-reveal rate; anchor words are prominent; tutorial overlay explains mechanics in one screen
- **Difficulty scaling**: Letter reveal rate and letter order (common vs. rare letters first) tuned per puzzle; harder puzzles reveal fewer letters per placement and obscure letters longer
- **Feedback clarity**: Immediate visual feedback on placement (correct = letter reveal animation, wrong = life indicator decreases + word returns); partial category name always visible
- **Recovery from failure**: Lives restore after a few hours; retry starts completely fresh (no partial reveals carried over) — failure is educational, not permanent

---

## Core Loop

### Moment-to-Moment (30 seconds)
Scan the word pool → form a hypothesis about which words share a category →
select a word → assign it to a slot → receive immediate feedback (letter reveal
or life lost) → update hypothesis.

### Short-Term (5-10 minutes)
Solve all 4 groups within 3 lives. The entangled reveal mechanic creates a
natural rhythm: early placements are tentative and high-stakes, mid-puzzle
placements are increasingly informed by partial category name letters,
final placements often feel inevitable — the "aha" cascade.

### Session-Level (Daily)
One puzzle per day. Session ends at solve or failure. Failure state allows
return after life restore for a second attempt. Natural stopping point is
built into the format — there is nothing to binge.

### Long-Term Progression
Implicit mastery: players get faster at reading partial letters, better at
holding multiple hypotheses, more efficient at sequencing placements.
No explicit progression system at launch — the daily streak is the only
persistent state.

### Retention Hooks

- **Curiosity**: "What are today's hidden categories?" — renewed daily
- **Investment**: Daily streak; the unresolved failed puzzle waiting for life restore
- **Social**: Shareable result (lives remaining, solve path) — organic word of mouth
- **Mastery**: Solving harder puzzles with more lives remaining as skill grows

---

## Game Pillars

### Pillar 1: Every Placement Is a Deduction
Players should never feel like they're guessing randomly. Every word placement
is an informed decision based on what they know from the word pool, anchor
words, and partial category name letters.

*Design test*: If a mechanic rewards random clicking (e.g., no-cost unlimited
retries), it violates this pillar. The 3-life limit exists to enforce this.

### Pillar 2: The Aha Is Earned
The satisfaction of the full category name reveal must come from the player's
own reasoning — not from being handed the answer. Hints exist to unblock, not
to solve.

*Design test*: If we're tempted to add a "reveal category" button, this pillar
says no. The letter reveal IS the hint system — it's enough.

### Pillar 3: One Perfect Puzzle
Quality over quantity. One airtight, satisfying puzzle per day beats ten
mediocre ones. Every puzzle must be playtested for ambiguity before publishing.

*Design test*: If debating whether to add a second daily puzzle or spend time
QA-ing the one — QA the one.

### Pillar 4: Always Fair, Never Easy
Every wrong answer should feel like the player's mistake, never the designer's
fault. Category names must be unambiguous once the full name is revealed, even
if hard to reach.

*Design test*: If a category name could reasonably fit two different groups of
words in the same puzzle, rewrite it before shipping.

### Anti-Pillars (What This Game Is NOT)

- **NOT a speed game**: No countdown timer creates pressure. Mental challenge
  is about deduction quality, not reaction time. A timer would violate Pillar 1.
- **NOT a vocabulary test**: Categories must be guessable by someone who knows
  the words but isn't a linguist. Cleverness, not obscurity.
- **NOT multiplayer**: Scope and daily cadence don't support it. Solo deduction
  is the experience.
- **NOT pay-to-restore**: Lives restore on time, not money. Monetising the
  failure state would destroy trust and violate Pillar 4.

---

## Inspiration and References

| Reference | What We Take From It | What We Do Differently | Why It Matters |
| ---- | ---- | ---- | ---- |
| NYT Connections | Grouping mechanic, daily format, 4 categories | Category names are hidden; reveals are earned, not given | Proves grouping puzzle format has mass appeal |
| Wordle | Daily cadence, shareable results, 3-6 attempt limit | Our "lives" are a parallel; category names replace letter positions | Proves daily word puzzle retention model works |
| Mastermind | Deduction from partial feedback | Applied to word semantics, not color pegs | Validates that feedback-loop deduction is satisfying |
| Scrabble | Word knowledge rewarded, constrained decision-making | No board, no scoring — pure categorisation | Confirms target audience exists and is hungry |

**Non-game inspirations**: Cryptic crosswords (the satisfaction of a clue
"clicking"); escape rooms (layered information revealing a hidden truth);
Wheel of Fortune (partial letter reveals driving pattern recognition).

---

## Target Player Profile

| Attribute | Detail |
| ---- | ---- |
| **Age range** | 22-45 |
| **Gaming experience** | Casual to mid-core |
| **Time availability** | 5-10 minutes daily — commute, lunch break, morning routine |
| **Platform preference** | Browser / Mobile |
| **Current games they play** | Wordle, NYT Connections, Spelling Bee |
| **What they're looking for** | A daily mental workout with more depth than existing puzzles |
| **What would turn them away** | Ambiguous categories that feel unfair; puzzles that require specialist knowledge |

---

## Technical Considerations

| Consideration | Assessment |
| ---- | ---- |
| **Recommended Engine** | Godot 4.3 — UI-heavy game, no physics, GDScript sufficient, fast iteration |
| **Key Technical Challenges** | Letter reveal sequencing system; daily puzzle delivery / date-locking; life restore timer |
| **Art Style** | Clean flat UI — typography-forward, minimal illustration |
| **Art Pipeline Complexity** | Low — text, geometric shapes, color palette only |
| **Audio Needs** | Minimal — placement feedback sounds, reveal chime, fail/success stings |
| **Networking** | None at launch |
| **Content Volume** | 7 hand-authored puzzles for launch week; 1 new puzzle authored per week ongoing |
| **Procedural Systems** | None — all puzzles hand-authored for quality control |

---

## Risks and Open Questions

### Design Risks
- Category ambiguity: two groups sharing overlapping valid words will feel unfair to players — requires careful authoring and second-pair-of-eyes QA on every puzzle
- Letter reveal pacing: if too fast, word grouping becomes trivial; if too slow, the reveal mechanic loses meaning — needs playtesting to calibrate

### Technical Risks
- Daily puzzle date-locking: ensuring players can't skip ahead or replay today's puzzle requires a reliable date-check system in Godot
- Life restore timer: persisting timer state across app close/open needs save file handling from day one

### Market Risks
- NYT Connections already owns this space; differentiation must be immediately felt in the first 60 seconds of play
- Daily puzzle format requires ongoing content commitment — authoring one quality puzzle per week must be sustainable solo

### Scope Risks
- Hand-authoring 7 launch puzzles while building the game simultaneously is the tightest constraint — puzzle authoring must begin on day 1, not day 5
- UI polish (animations, transitions) can balloon; timebox strictly

### Open Questions
- Does the letter reveal mechanic feel satisfying in practice, or does it feel arbitrary? → Answer via paper prototype before coding
- What's the right reveal rate for "normal" difficulty? → Needs playtest with 3-5 people before launch

---

## MVP Definition

**Core hypothesis**: Players find the entangled word-grouping + letter-reveal mechanic engaging and fair for a 5-10 minute daily session.

**Required for MVP**:
1. 4-slot UI with anchor words pre-placed and category name blanks visible
2. Word placement mechanic with immediate correct/wrong feedback
3. Letter reveal system (count and order configurable per puzzle)
4. 3-life system with fail state
5. 3 complete hand-authored puzzles to validate the mechanic end-to-end

**Explicitly NOT in MVP** (defer to later):
- Daily date-locking (use manual puzzle select during testing)
- Life restore timer (use manual reset during testing)
- Sound effects and animations (placeholder only)
- Streak tracking
- Shareable results format
- Backward solve / Wheel of Fortune mode *(noted for post-launch)*

### Scope Tiers

| Tier | Content | Features | Timeline |
| ---- | ---- | ---- | ---- |
| **MVP** | 3 puzzles | Core loop only — slots, placement, reveal, lives | Day 1-4 |
| **Launch Build** | 7 puzzles | Full daily cadence, life restore timer, basic audio, share result | Day 5-7 |
| **Post-Launch** | Weekly puzzle | Streak tracking, backward solve mode, mobile export | Week 2+ |

---

## Next Steps

- [x] Game concept approved
- [x] Engine configured — Godot 4.3 (`/setup-engine` complete)
- [ ] Decompose concept into systems (`/map-systems`)
- [ ] Author per-system GDDs (`/design-system` for each)
- [ ] Create first architecture decision record (`/architecture-decision`)
- [ ] Paper prototype the letter reveal mechanic before coding
- [ ] Begin puzzle authoring on Day 1 in parallel with development
- [ ] Prototype core loop (`/prototype word-placement`)
- [ ] Validate with 3-5 playtesters (`/playtest-report`)
- [ ] Plan the week (`/sprint-plan new`)
