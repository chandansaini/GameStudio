# Systems Index: LEXICON

> **Status**: Approved
> **Created**: 2026-03-24
> **Last Updated**: 2026-03-24
> **Source Concept**: design/gdd/game-concept.md

---

## Overview

LEXICON is a UI-heavy daily puzzle game with no physics, no AI, and no networking.
Its systems are almost entirely data management, game state tracking, and UI feedback.
The core loop — assign words to slots, reveal category name letters, lose lives on
mistakes — requires a small set of tightly coupled systems to be designed correctly
from the start. The two highest-risk systems (Game State Manager and Puzzle Data
System) are also the most depended-upon; getting these right on day 1 determines
whether everything else falls into place or requires costly rework.

---

## Systems Enumeration

| # | System Name | Category | Priority | Status | Design Doc | Depends On |
|---|-------------|----------|----------|--------|------------|------------|
| 1 | Puzzle Data System | Core | MVP | Designed | design/gdd/puzzle-data-system.md | — |
| 2 | Scene Manager | Core | MVP | Designed | design/gdd/scene-manager.md | — |
| 3 | Game State Manager | Core | MVP | Designed | design/gdd/game-state-manager.md | Puzzle Data System |
| 4 | Puzzle Library | Core | MVP | Designed | design/gdd/puzzle-library.md | Puzzle Data System |
| 5 | Slot Assignment | Gameplay | MVP | Designed | design/gdd/slot-assignment.md | Game State Manager, Puzzle Data System |
| 6 | Life System | Gameplay | MVP | Designed | design/gdd/life-system.md | Game State Manager |
| 7 | Letter Reveal System ⚠️ | Gameplay | MVP | Designed | design/gdd/letter-reveal-system.md | Slot Assignment, Puzzle Data System, Game State Manager |
| 8 | Word Pool UI | UI | MVP | Designed | design/gdd/word-pool-ui.md | Slot Assignment, Game State Manager |
| 9 | Slot UI | UI | MVP | Designed | design/gdd/slot-ui.md | Slot Assignment, Letter Reveal System |
| 10 | Life Indicator UI | UI | MVP | Designed | design/gdd/life-indicator-ui.md | Life System |
| 11 | Save/Persist System ⚠️ | Persistence | Launch | Not Started | — | Game State Manager |
| 12 | Daily Lock System ⚠️ | Gameplay | Launch | Not Started | — | Puzzle Library |
| 13 | Life Restore Timer | Persistence | Launch | Not Started | — | Life System, Save/Persist System |
| 14 | Streak Tracker | Persistence | Launch | Not Started | — | Save/Persist System, Game State Manager |
| 15 | Results Screen | UI | Launch | Not Started | — | Game State Manager, Life System |
| 16 | Main Menu | UI | Launch | Not Started | — | Scene Manager, Daily Lock System, Streak Tracker |
| 17 | Audio System | Audio | Launch | Not Started | — | Slot Assignment, Letter Reveal System, Life System |
| 18 | Share Result System | Meta | Launch | Not Started | — | Results Screen, Game State Manager |
| 19 | Tutorial/Onboarding | Meta | Post-Launch | Not Started | — | Slot Assignment, Letter Reveal System, Life System |

⚠️ = high-risk system — prototype or paper-test before building

---

## Categories

| Category | Description | Systems in This Game |
|----------|-------------|----------------------|
| **Core** | Foundation systems everything depends on | Puzzle Data System, Scene Manager, Game State Manager, Puzzle Library |
| **Gameplay** | Systems that make it fun | Slot Assignment, Life System, Letter Reveal System, Daily Lock System |
| **Persistence** | State that survives closing the app | Save/Persist System, Life Restore Timer, Streak Tracker |
| **UI** | Player-facing displays | Word Pool UI, Slot UI, Life Indicator UI, Results Screen, Main Menu |
| **Audio** | Sound and music | Audio System |
| **Meta** | Outside the core loop | Share Result System, Tutorial/Onboarding |

---

## Priority Tiers

| Tier | Definition | Systems | Count |
|------|------------|---------|-------|
| **MVP** | Required for core loop to function — can't test "is this fun?" without these | 1–10 | 10 |
| **Launch** | Required for a shippable daily puzzle experience | 11–18 | 8 |
| **Post-Launch** | Polish and nice-to-haves after shipping | 19 | 1 |

---

## Dependency Map

### Foundation Layer (no dependencies — design first)

1. **Puzzle Data System** — defines the data structures (puzzle, category, word, reveal config) that every other system reads; must be locked before anything else is designed
2. **Scene Manager** — handles screen transitions; no gameplay dependencies; can be designed in parallel with Puzzle Data System

### Core Layer (depends on Foundation)

1. **Game State Manager** — depends on: Puzzle Data System. Tracks all in-flight state: word placements, slot solved states, lives remaining, puzzle complete/failed flag. Bottleneck: 9 systems depend on this.
2. **Puzzle Library** — depends on: Puzzle Data System. Stores all authored puzzles indexed by date; provides puzzle lookup by date key.
3. **Daily Lock System** — depends on: Puzzle Library. Date-checks to serve the correct puzzle; prevents skip-ahead.

### Feature Layer (depends on Core)

1. **Slot Assignment** — depends on: Game State Manager, Puzzle Data System. Core interaction: player selects a word and assigns it to a slot; resolves correct/wrong immediately; updates game state.
2. **Life System** — depends on: Game State Manager. Deducts lives on wrong placement; triggers fail state at 0; signals life restore eligibility.
3. **Letter Reveal System** ⚠️ — depends on: Slot Assignment, Puzzle Data System, Game State Manager. On correct placement, reveals N letters of the slot's category name in a configured order; difficulty dial lives here.
4. **Save/Persist System** ⚠️ — depends on: Game State Manager. Writes and reads save file: life count, restore timestamp, current puzzle progress, streak data.

### Presentation Layer (depends on Features)

1. **Word Pool UI** — depends on: Slot Assignment, Game State Manager. Displays available words; highlights selection; removes placed words from pool.
2. **Slot UI** — depends on: Slot Assignment, Letter Reveal System. Displays 4 slots with anchor word, blank category name, placed words, and solved state with reveal animations.
3. **Life Indicator UI** — depends on: Life System. Shows 3 lives visually; animates on loss.
4. **Life Restore Timer** — depends on: Life System, Save/Persist System. Countdown to life restore after failure; persists across app close.
5. **Streak Tracker** — depends on: Save/Persist System, Game State Manager. Tracks consecutive days solved; resets on missed day.
6. **Results Screen** — depends on: Game State Manager, Life System. Win/lose state; lives remaining; category name reveals for all groups; link to share.
7. **Main Menu** — depends on: Scene Manager, Daily Lock System, Streak Tracker. Entry point; today's puzzle button; streak display.
8. **Audio System** — depends on: Slot Assignment, Letter Reveal System, Life System. SFX: placement click, letter reveal chime, life lost sting, puzzle solved fanfare, puzzle failed tone.

### Polish Layer (depends on everything)

1. **Share Result System** — depends on: Results Screen, Game State Manager. Generates Wordle-style emoji summary of lives used and solve path; copies to clipboard.
2. **Tutorial/Onboarding** — depends on: all MVP gameplay systems. First-time overlay teaching slots, anchor words, lives, and letter reveals.

---

## Circular Dependencies

None found.

---

## High-Risk Systems

| System | Risk Type | Risk Description | Mitigation |
|--------|-----------|-----------------|------------|
| Letter Reveal System | Design | Reveal pacing unproven — too fast makes grouping trivial, too slow makes it decoration; difficulty dial values unknown | Paper prototype before coding; playtest with 3-5 people before tuning |
| Save/Persist System | Technical | Life restore timer must persist correctly across app close/open from day 1; bugs here break the core retention loop | Implement and test on day 1 of launch build phase, not as an afterthought |
| Daily Lock System | Technical | Timezone handling and day-rollover edge cases can cause players to get wrong puzzle or be locked out | Use UTC date throughout; test rollover explicitly; paper-test edge cases before coding |
| Game State Manager | Scope | Bottleneck — 9 systems depend on it; a data model mistake here cascades everywhere | Design this GDD before writing any code; review data model with a second pair of eyes |

---

## Recommended Design Order

| Order | System | Priority | Layer | Effort | Notes |
|-------|--------|----------|-------|--------|-------|
| 1 | Puzzle Data System | MVP | Foundation | S | Lock data structures first — everything reads from this |
| 2 | Scene Manager | MVP | Foundation | S | Can design in parallel with #1 |
| 3 | Game State Manager | MVP | Core | M | Bottleneck system — design carefully |
| 4 | Puzzle Library | MVP | Core | S | Simple after Puzzle Data System is done |
| 5 | Slot Assignment | MVP | Feature | M | Core interaction verb |
| 6 | Life System | MVP | Feature | S | Simple deduction system |
| 7 | Letter Reveal System | MVP | Feature | M | ⚠️ Paper prototype first |
| 8 | Word Pool UI | MVP | Presentation | S | Follows Slot Assignment |
| 9 | Slot UI | MVP | Presentation | M | Most complex UI component |
| 10 | Life Indicator UI | MVP | Presentation | S | Simple visual |
| 11 | Save/Persist System | Launch | Feature | M | ⚠️ Build and test early in launch phase |
| 12 | Daily Lock System | Launch | Feature | S | ⚠️ Test timezone edge cases |
| 13 | Life Restore Timer | Launch | Feature | S | Depends on Save/Persist |
| 14 | Streak Tracker | Launch | Presentation | S | Low cost — 2 fields in save file |
| 15 | Results Screen | Launch | Presentation | S | Straightforward display |
| 16 | Main Menu | Launch | Presentation | S | Last UI piece |
| 17 | Audio System | Launch | Presentation | S | Hook into existing systems |
| 18 | Share Result System | Launch | Polish | S | Clipboard + emoji formatting |
| 19 | Tutorial/Onboarding | Post-Launch | Polish | M | After all gameplay systems stable |

*S = 1 session (~1-2 hours), M = 2-3 sessions*

---

## Progress Tracker

| Metric | Count |
|--------|-------|
| Total systems identified | 19 |
| Design docs started | 10 |
| Design docs reviewed | 0 |
| Design docs approved | 0 |
| MVP systems designed | 0 / 10 |
| Launch systems designed | 0 / 8 |
| Post-Launch systems designed | 0 / 1 |

---

## Next Steps

- [ ] Design systems in order above using `/design-system [system-name]`
- [ ] Start with: **Puzzle Data System** (order #1)
- [ ] Paper prototype Letter Reveal System before coding (order #7)
- [ ] Run `/design-review` on each completed GDD
- [ ] Run `/gate-check pre-production` when all 10 MVP systems are designed
- [ ] Prototype Letter Reveal System early with `/prototype letter-reveal`
