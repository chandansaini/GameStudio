# Sprint 01 — 2026-03-25 to 2026-03-31

## Sprint Goal
Ship a playable, daily-locked LEXICON puzzle game: core loop functional by Day 4,
all launch systems wired by Day 6, polish and export on Day 7.

## Capacity
- Total days: 7 (solo developer)
- Buffer (20%): 1.4 days reserved for debugging, integration surprises, and rework
- Available: 5.6 focused development days
- Daily rhythm: Foundation → Core State → Gameplay → UI → Launch → Polish → Ship

---

## Daily Milestones

### Day 1 — 2026-03-25: Foundation
*Goal: Godot project running, puzzle data flowing, scenes navigating.*

| ID | Task | Est. | GDD Reference | Acceptance Criteria |
|----|------|------|---------------|---------------------|
| T-001 | Set up Godot 4.3 project structure (`src/`, `assets/`, `data/puzzles/`, Autoloads registered) | 1h | — | Project opens; Autoload stubs registered without errors |
| T-002 | Implement `PuzzleData` resource + `GroupData` + `RevealConfig` + validation | 2h | puzzle-data-system.md | Valid puzzle loads; invalid puzzle rejected per two-tier rule |
| T-003 | Author 3 test puzzles as `.tres` files in `res://data/puzzles/` | 1h | puzzle-data-system.md | 3 puzzles load and validate without errors |
| T-004 | **Paper prototype Letter Reveal pacing** (pen + paper, 3 category names) | 30m | letter-reveal-system.md ⚠️ | `letters_per_placement` values chosen for Easy/Medium/Hard; written to notes |
| T-005 | Implement `PuzzleLibrary` autoload (scan, validate, index by date/id) | 1h | puzzle-library.md | `get_puzzle_by_date("2026-03-25")` returns correct puzzle |
| T-006 | Implement `SceneManager` autoload (fade transitions, 3 scenes) | 1.5h | scene-manager.md | `go_to_puzzle(id)` transitions with fade; double-call is no-op |

**Day 1 Milestone**: `PuzzleLibrary.get_puzzle_by_date()` returns a valid puzzle; `SceneManager` navigates between stub scenes.

---

### Day 2 — 2026-03-26: Core State
*Goal: GSM tracking placements and lives; Slot Assignment processing clicks.*

| ID | Task | Est. | GDD Reference | Acceptance Criteria |
|----|------|------|---------------|---------------------|
| T-007 | Implement `GameStateManager` autoload (`place_word()`, `deduct_life()`, `trigger_fail()`, all 6 signals) | 3h | game-state-manager.md | `place_word("WORD", 0)` returns CORRECT/WRONG; GSM signals fire correctly |
| T-008 | Implement `LifeSystem` node (connect to GSM signals, emit `life_lost`, `lives_restore_eligible`) | 1h | life-system.md | Wrong placement → `life_lost(2)` emitted; 3 wrongs → `puzzle_failed` fires |
| T-009 | Implement `SlotAssignment` node (two-step click model, IDLE/WORD_SELECTED/LOCKED states) | 2h | slot-assignment.md | Word click → selected; slot click → `gsm.place_word()` called; outside click → deselects |
| T-010 | Integration smoke test: place words via code, verify signal chain fires end-to-end | 30m | — | All 3 lives lost → `puzzle_failed`; correct placements → `word_placed_correct` |

**Day 2 Milestone**: Full gameplay signal chain functional without UI — verifiable via `print()` statements or GUT tests.

---

### Day 3 — 2026-03-27: Letter Reveal + UI Layer 1
*Goal: Letter reveals working; word pool interactive.*

| ID | Task | Est. | GDD Reference | Acceptance Criteria |
|----|------|------|---------------|---------------------|
| T-011 | Implement `LetterRevealSystem` node (reveal algorithm, 4 sort modes, frequency table) | 2h | letter-reveal-system.md | Correct placement reveals correct N letters in correct order; `left_to_right` verified |
| T-012 | Implement `WordPoolUI` scene (word buttons, SELECTED/WRONG_FLASH/REMOVED states, `wrong_flash_duration`) | 2h | word-pool-ui.md | Word selected → highlighted; correct placement → button removed; wrong → flashes 0.4s |
| T-013 | Implement `LifeIndicatorUI` scene (3 icons, FULL/LOST states, loss animation) | 1h | life-indicator-ui.md | `life_lost(2)` → one icon dims with animation |
| T-014 | Wire `WordPoolUI` + `LifeIndicatorUI` into puzzle scene; verify interactions | 30m | — | Clicking words in UI calls `slot_assignment.on_word_clicked()` correctly |

**Day 3 Milestone**: Word pool is interactive; life icons update on wrong placements; letter reveals execute correctly (verify in console).

---

### Day 4 — 2026-03-28: Slot UI + MVP Complete
*Goal: Full puzzle loop playable end-to-end in the UI.*

| ID | Task | Est. | GDD Reference | Acceptance Criteria |
|----|------|------|---------------|---------------------|
| T-015 | Implement `SlotUI` scene (4 panels, anchor word, category name cells, placed words list, `letter_reveal_stagger_delay`) | 3h | slot-ui.md | Correct placement → word appears in slot; letter revealed → character cell animates in with stagger |
| T-016 | Implement slot solved state + `puzzle_solved` / `puzzle_failed` terminal states in `SlotUI` | 1h | slot-ui.md | All words in slot → solved animation plays; `puzzle_failed` → all slots lock |
| T-017 | Full MVP integration: play a complete puzzle in the UI, win and lose paths | 1.5h | all MVP GDDs | Can place all words correctly (win) and lose all lives (fail); both paths reach terminal state |

**Day 4 Milestone (MVP gate)**: LEXICON core loop is fully playable. A real person can sit down, solve a puzzle, and lose a puzzle.

---

### Day 5 — 2026-03-29: Launch Systems Part 1
*Goal: Daily puzzle delivery and save system working.*

| ID | Task | Est. | GDD Reference | Acceptance Criteria |
|----|------|------|---------------|---------------------|
| T-018 | Implement `DailyLockSystem` (UTC date, serve today's puzzle, prevent skip-ahead) | 1.5h | systems-index.md | `get_today_puzzle()` returns correct puzzle; running twice same day returns same puzzle |
| T-019 | Implement `SavePersistSystem` (write/read save file: lives, restore timestamp, puzzle progress, streak) | 3h | systems-index.md | Save written on placement; app reopen restores mid-puzzle state; lives count persists |
| T-020 | Implement `MainMenu` scene (today's puzzle button, streak display, calls `SceneManager.go_to_puzzle()`) | 1.5h | systems-index.md | "Play" button loads today's puzzle; streak shown |

**Day 5 Milestone**: App opens to Main Menu, serves today's puzzle, saves progress on close.

---

### Day 6 — 2026-03-30: Launch Systems Part 2
*Goal: Full daily experience loop complete.*

| ID | Task | Est. | GDD Reference | Acceptance Criteria |
|----|------|------|---------------|---------------------|
| T-021 | Implement `ResultsScreen` scene (win/lose state, lives remaining, category reveals, back button) | 2h | systems-index.md | Win state shows all category names; "Back" returns to Main Menu |
| T-022 | Implement `LifeRestoreTimer` (countdown after fail, persists across app close, restores lives) | 1.5h | systems-index.md | Fail → timer starts; reopen app → timer continues; timer expires → lives restored |
| T-023 | Implement `AudioSystem` (SFX hookup: placement click, reveal chime, life lost, solved fanfare, fail tone) | 2h | systems-index.md | Each gameplay event plays correct SFX; no audio errors on load |
| T-024 | Implement `StreakTracker` (consecutive days solved, resets on missed day) | 1h | systems-index.md | Solve today → streak increments; miss a day → streak resets |

**Day 6 Milestone**: Complete daily loop: open → play → win/lose → results → back → repeat tomorrow.

---

### Day 7 — 2026-03-31: Polish + Ship
*Goal: Playable build exported and ready.*

| ID | Task | Est. | GDD Reference | Acceptance Criteria |
|----|------|------|---------------|---------------------|
| T-025 | Implement `ShareResultSystem` (Wordle-style emoji summary, copy to clipboard) | 1.5h | systems-index.md | Share text generated correctly; copies to clipboard on mobile/desktop |
| T-026 | Art pass: colours, fonts, button styles, animation polish | 2h | — | Game feels cohesive; no placeholder grey boxes |
| T-027 | Bug fix buffer | 2h | — | No S1 bugs (crashes, data loss, wrong puzzle served) |
| T-028 | Export build + smoke test on target platform | 1h | — | Build launches, plays a full puzzle, saves correctly |

**Day 7 Milestone (Launch gate)**: Exported build passes smoke test. Ship it.

---

## Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Slot UI takes longer than 3h (most complex component) | High | Delays Day 4 MVP gate | Start Day 4 with Slot UI; defer art polish if needed |
| Save/Persist System timezone edge cases | Medium | Wrong puzzle served on rollover | Use UTC throughout; test at midnight boundary |
| Letter Reveal pacing feels wrong in practice | Medium | Core loop less satisfying | Paper prototype on Day 1 locks values before coding |
| Integration surprises wiring all systems | Medium | Day 4 overruns | 1.4-day buffer absorbs up to 1 day of rework |
| Audio assets not ready | Low | Launch without SFX | Use placeholder Godot AudioStreamGenerator tones |

---

## Definition of Done for Sprint 01

- [ ] Day 4 MVP milestone: full puzzle loop playable (win + lose paths)
- [ ] Day 6 milestone: daily lock, save, results, life restore all functional
- [ ] Day 7: exported build smoke-tested on target platform
- [ ] No S1 bugs (crash, data loss, wrong puzzle) in exported build
- [ ] Letter Reveal System paper-prototyped before coding (T-004)
- [ ] 3+ authored test puzzles validate the puzzle data pipeline
- [ ] Design documents updated if any GDD decisions were changed during implementation

---

## Carryover from Previous Sprint
None — first sprint.

## Dependencies on External Factors
- Puzzle content: at least 7 authored puzzles needed for launch (1 per day of first week). Author 1/day during development using the test puzzle workflow from T-003.
- Audio assets: source or generate SFX by Day 6. Freesound.org or generated tones as fallback.
