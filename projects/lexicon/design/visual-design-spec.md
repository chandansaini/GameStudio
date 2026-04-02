# LEXICON — Visual Design Specification
*For Figma handoff. Version 1.0 — 2026-03-26*

---

## 1. Art Direction

**Mood**: Focused. Quiet. Satisfying. Like a crossword at a good coffee shop.

**Visual language**: Dark-mode typographic UI. Color is used *only* for state communication — never for decoration. Every element on screen earns its place.

**Not**: Neon, playful, colorful, gamey. This is not Candy Crush. It is closer to a high-quality digital newspaper puzzle.

**Primary references**:
| Reference | What We Borrow |
|---|---|
| NYT Wordle | High-contrast dark theme, minimal chrome, confident typography |
| NYT Connections | Tile grid discipline, category panel rhythm |
| Linear.app | Restrained dark UI, tight spacing, system feels premium |
| Letterboxd (dark mode) | Typography hierarchy at small sizes |

---

## 2. Design Tokens

All tokens must be defined as Figma variables (Collections: Color, Spacing, Radius, Motion).

### 2.1 Color Tokens

#### Background
| Token | Hex | Usage |
|---|---|---|
| `bg/base` | `#0C0C12` | Screen background |
| `bg/surface` | `#171720` | Slot panels |
| `bg/surface-raised` | `#1E1E2A` | Word cards (resting) |
| `bg/overlay` | `#2A2A38` | Word card hover / pressed |

#### Text
| Token | Hex | Usage |
|---|---|---|
| `text/primary` | `#F0EFEB` | All primary labels |
| `text/secondary` | `#8888A0` | Subtext, hints, counters |
| `text/disabled` | `#3D3D50` | Inactive/removed states |

#### Accent — Gold
| Token | Hex | Usage |
|---|---|---|
| `accent/gold` | `#F5C842` | Anchor words, revealed letters |
| `accent/gold-dim` | `#7A6520` | Unrevealed letter underscores |
| `accent/gold-glow` | `#F5C84230` | Letter-reveal cell background flash (30% opacity) |

#### State Colors
| Token | Hex | Usage |
|---|---|---|
| `state/selected` | `#3A7BD5` | Currently selected word card border |
| `state/selected-bg` | `#1C3D6E` | Selected card background |
| `state/correct` | `#27AE60` | Slot panel — solved (bright) |
| `state/correct-dim` | `#143D25` | Solved slot background (settled) |
| `state/wrong` | `#C0392B` | Wrong flash — slot panel |
| `state/wrong-word` | `#E74C3C` | Wrong flash — word card |

#### Chrome
| Token | Hex | Usage |
|---|---|---|
| `chrome/divider` | `#2A2A3A` | Separator lines |
| `chrome/border` | `#2E2E40` | Card borders (1px) |
| `chrome/focus` | `#5B9BD5` | Keyboard focus ring |

---

### 2.2 Spacing Scale (8pt grid)

| Token | Value | Usage |
|---|---|---|
| `space/1` | `4px` | Tight intra-component gaps |
| `space/2` | `8px` | Standard intra-component padding |
| `space/3` | `12px` | Card internal padding |
| `space/4` | `16px` | Section gaps |
| `space/5` | `24px` | Major section separators |
| `space/6` | `32px` | Screen edge margins |
| `space/7` | `48px` | Between header and content |

### 2.3 Border Radius
| Token | Value | Usage |
|---|---|---|
| `radius/sm` | `4px` | Character cells, small chips |
| `radius/md` | `8px` | Word cards |
| `radius/lg` | `12px` | Slot panels |
| `radius/xl` | `16px` | End-screen cards |
| `radius/full` | `9999px` | Life indicators (circles), pill buttons |

### 2.4 Elevation (Box Shadows)
| Token | Value | Usage |
|---|---|---|
| `shadow/card` | `0 2px 8px #00000060` | Word cards |
| `shadow/panel` | `0 4px 16px #00000080` | Slot panels |
| `shadow/selected` | `0 0 0 2px #3A7BD5` | Selected state outline |

---

## 3. Typography

### Font Families
| Role | Font | Fallback | Source |
|---|---|---|---|
| **UI / Labels** | Space Grotesk | system-ui, sans-serif | Google Fonts (free) |
| **Letter Reveal Cells** | IBM Plex Mono | monospace | Google Fonts (free) — equal-width cells |
| **Game Title** | Space Grotesk Bold | — | Same family, heavier weight |

> **Why Space Grotesk**: Geometric, slightly idiosyncratic letterforms signal "puzzle" without feeling juvenile. Excellent legibility at 14–28px. Pairs naturally with IBM Plex Mono.
>
> **Why IBM Plex Mono for cells**: Monospaced = every character cell is identical width. This makes the blank/revealed row visually stable as letters appear — no layout shift.

### Type Scale
| Token | Font | Size | Weight | Line Height | Usage |
|---|---|---|---|---|---|
| `type/title` | Space Grotesk | 32px | 700 | 1.1 | LEXICON game title |
| `type/slot-anchor` | Space Grotesk | 22px | 600 | 1.2 | Anchor word in slot |
| `type/reveal-cell` | IBM Plex Mono | 26px | 700 | 1.0 | Category name characters |
| `type/reveal-cell-sm` | IBM Plex Mono | 20px | 700 | 1.0 | Long category names (>12 chars) |
| `type/word-card` | Space Grotesk | 18px | 600 | 1.0 | Word cards in pool |
| `type/placed-word` | Space Grotesk | 15px | 400 | 1.4 | Words listed inside solved slot |
| `type/body` | Space Grotesk | 15px | 400 | 1.5 | End screen text, instructions |
| `type/label` | Space Grotesk | 12px | 500 | 1.3 | Life counter label, section headers |
| `type/caption` | Space Grotesk | 11px | 400 | 1.3 | Timestamps, minor metadata |

---

## 4. Layout & Grid

### Canvas Sizes to Design
| Screen | Dimensions | Notes |
|---|---|---|
| Desktop (primary) | 1280×800 | Main design target |
| Desktop compact | 1024×768 | Second target |
| Mobile (future) | 390×844 | iPhone 14 — design for future |

### Game Screen Grid
```
┌────────────────────────────────┐  ← 1280px wide
│         [32px margin]          │
│  ┌──────────────────────────┐  │
│  │  LEXICON          ❤❤❤   │  │  ← Header: 56px tall
│  └──────────────────────────┘  │
│         [24px gap]             │
│  ┌──────────────────────────┐  │
│  │      SLOT 0 — 120px      │  │  ← 4 slot panels, 8px gap between
│  ├──────────────────────────┤  │
│  │      SLOT 1 — 120px      │  │
│  ├──────────────────────────┤  │
│  │      SLOT 2 — 120px      │  │
│  ├──────────────────────────┤  │
│  │      SLOT 3 — 120px      │  │
│  └──────────────────────────┘  │
│         [24px gap]             │
│  ────────── divider ─────────  │
│         [24px gap]             │
│  ┌──────────────────────────┐  │
│  │   3×4 WORD POOL GRID     │  │  ← 12 cards, 3 columns, 8px gap
│  └──────────────────────────┘  │
│         [32px margin]          │
└────────────────────────────────┘
```

**Content column max-width**: 720px, centered on screen.

---

## 5. Component Specifications

### 5.1 Word Card

**Purpose**: Clickable word in the word pool. Player selects one, then taps a slot.

**Dimensions**: 160×64px minimum. Expand horizontally to fill grid cell.

**Anatomy**:
```
┌─────────────────────────────────┐
│                                 │  ← 8px corner radius
│         SERENDIPITY             │  ← Space Grotesk SemiBold 18px, centered
│                                 │
└─────────────────────────────────┘
```

**States**:
| State | Background | Text Color | Border | Shadow |
|---|---|---|---|---|
| Normal | `bg/surface-raised` `#1E1E2A` | `text/primary` | 1px `chrome/border` | `shadow/card` |
| Hover | `bg/overlay` `#2A2A38` | `text/primary` | 1px `chrome/border` | `shadow/card` |
| Selected | `state/selected-bg` `#1C3D6E` | `#FFFFFF` | 2px `state/selected` | `shadow/selected` |
| Wrong-Flash | `state/wrong-word` `#E74C3C` | `#FFFFFF` | none | — |
| Removed | transparent, opacity 0 | — | — | — |

**Transition**: Normal ↔ Selected is instant. Wrong-Flash → Normal: 400ms ease-out fade.

---

### 5.2 Slot Panel

**Purpose**: Receives placed words. Displays anchor word + hidden category name + placed words.

**Dimensions**: Full content-column width × 120px minimum. Grows as words are placed.

**Anatomy**:
```
┌──────────────────────────────────────────────┐
│  SERENDIPITY                                  │  ← Anchor: Space Grotesk SemiBold 22px, accent/gold
│                                               │
│  [ _ ] [ _ ] [ _ ] [ O ] [ _ ] [ S ] [ _ ]   │  ← Character cells row (IBM Plex Mono)
│                                               │
│  placed word 1       placed word 2            │  ← 15px font, text/secondary
└──────────────────────────────────────────────┘
```

Internal padding: 12px all sides. Child gap: 4px.

**States**:
| State | Background | Left Accent Border | Notes |
|---|---|---|---|
| Active | `bg/surface` `#171720` | none | Default |
| Wrong-Flash | `state/wrong` `#C0392B` | — | 400ms, returns to Active |
| Solved | `state/correct` `#27AE60` | — | Brief celebration state |
| Solved-Settled | `state/correct-dim` `#143D25` | 3px `state/correct` | After 1s celebration |
| Locked (post-fail) | `bg/surface` + 40% opacity | — | Puzzle over |

---

### 5.3 Character Cell

**Purpose**: One cell per character in the category name. Hidden until letters are revealed.

**Dimensions**: 28px wide × 36px tall. Fixed-width (monospace font ensures stability).

**Hidden state**:
```
┌──────┐
│      │  ← bg: bg/surface-raised
│  _   │  ← underscore glyph, IBM Plex Mono Bold 26px, color: accent/gold-dim
│      │
└──────┘  ← 2px bottom border: accent/gold-dim
  4px radius
```

**Revealed state**:
```
┌──────┐
│      │  ← brief flash: bg accent/gold-glow → transparent
│  A   │  ← letter, IBM Plex Mono Bold 26px, color: accent/gold
│      │
└──────┘  ← 2px bottom border: accent/gold
```

**Space characters**: Width 12px, no border, no glyph — separates words in the category name.

---

### 5.4 Life Indicator

**Purpose**: Shows remaining lives (max 3). Lost life = circle empties.

**Layout**: 3 circles in a row, 8px gap. Right-aligned in header.

**Dimensions**: 18px diameter per circle.

| State | Fill | Border |
|---|---|---|
| Full | `accent/gold` | none |
| Lost | transparent | 2px `accent/gold-dim` |

**Transition on loss**: Circle scales 1.0 → 0 over 300ms ease-in, then snaps to Lost style.

---

### 5.5 Header

**Dimensions**: Full content width × 56px. Vertically centered content.

**Layout**:
```
[ LEXICON ]                    [ ❤  ❤  ❤ ]
  left-aligned, type/title       right-aligned, life indicators
```

**LEXICON logotype**: Space Grotesk Bold 700, 32px, `text/primary`, letter-spacing 0.08em.

---

### 5.6 End Screen — Solved

Centered card, max-width 480px, `radius/xl`, `bg/surface`, `shadow/panel`.

```
┌────────────────────────────┐
│                            │
│  ✓  SOLVED                 │  ← 48px, Space Grotesk Bold, state/correct
│                            │
│  Lives remaining: ❤❤      │
│  Words placed: 8 / 12      │
│                            │
│  ┌──────────────────────┐  │
│  │    COPY RESULT       │  │  ← Primary button, state/correct bg
│  └──────────────────────┘  │
│                            │
│  Next puzzle in 14:23:01   │  ← type/caption, text/secondary
│                            │
└────────────────────────────┘
```

---

### 5.7 End Screen — Failed

```
┌────────────────────────────┐
│                            │
│  ✗  FAILED                 │  ← 48px, Space Grotesk Bold, state/wrong
│                            │
│  The categories were:      │  ← type/body, text/secondary
│  OPTICAL ILLUSIONS         │  ← accent/gold, SemiBold — revealed names
│  CARD GAMES                │
│  ...                       │
│                            │
│  ┌──────────────────────┐  │
│  │  TRY AGAIN  02:14    │  │  ← disabled (timer) OR active (lives restored)
│  └──────────────────────┘  │
│                            │
└────────────────────────────┘
```

---

## 6. Iconography

Minimal. Prefer text over icons.

| Icon | Source | Usage |
|---|---|---|
| ✓ | Unicode U+2713 | Solved header |
| ✗ | Unicode U+2717 | Failed header |
| ❤ | SVG circle (see §5.4) | Life indicator — use custom SVG, not emoji |
| Copy icon | Heroicons outline | Copy result button |

No illustration. No character art. No decorative fills.

---

## 7. Motion & Animation

All animations must respect `prefers-reduced-motion`. When active: use instant color transitions only, no scale or translate.

### 7.1 Letter Reveal (core satisfaction moment)

Triggered by correct word placement. Letters stagger one at a time.

| Property | Value |
|---|---|
| Stagger delay per letter | 150ms |
| Per-letter scale | 0.7 → 1.0, 200ms, spring ease (0.5 damping) |
| Cell background flash | `accent/gold-glow` → transparent, 300ms ease-out |
| Color | `text/disabled` → `accent/gold`, instant on reveal frame |

### 7.2 Wrong Flash

| Property | Value |
|---|---|
| Flash in | Instant color swap |
| Hold | 400ms |
| Return | ease-out fade to resting state |
| Life indicator | Scale-out 300ms simultaneously |

### 7.3 Slot Solved Celebration

| Step | Timing | Effect |
|---|---|---|
| 1. Flash bright | 0ms | bg → `state/correct` |
| 2. Hold | 600ms | — |
| 3. Settle | 400ms ease-out | bg → `state/correct-dim`, add left accent border |
| 4. Words shimmer | staggered 100ms | placed words pulse opacity 0.5 → 1.0 |

### 7.4 Word Card Removed

| Property | Value |
|---|---|
| Animation | scale 1.0 → 0.8 + opacity 1 → 0 |
| Duration | 300ms ease-in |

### 7.5 Screen Transitions

| Transition | Effect | Duration |
|---|---|---|
| Game → End Screen | Fade in overlay card | 400ms ease-in-out |
| End Screen → new puzzle | Fade out + fade in | 300ms each |

---

## 8. Figma Frame Inventory

Design these frames in order:

| Frame | Purpose |
|---|---|
| `Game/Default` | Fresh puzzle, no placements |
| `Game/Word-Selected` | One word card in Selected state |
| `Game/Mid-Puzzle` | 2 slots partially filled, 1 slot solved |
| `Game/One-Life-Left` | 2 lives lost |
| `Game/All-Solved` | All 4 slots solved before end screen |
| `EndScreen/Solved-3Lives` | Won with all lives |
| `EndScreen/Solved-1Life` | Won barely |
| `EndScreen/Failed` | 0 lives, retry locked |
| `Components/WordCard` | All 5 states |
| `Components/SlotPanel` | All 5 states |
| `Components/CharacterCell` | Hidden, Revealing, Revealed |
| `Components/LifeIndicator` | 3, 2, 1, 0 lives |

---

## 9. Accessibility Requirements

| Requirement | Spec |
|---|---|
| Contrast — body text | Minimum 4.5:1 (WCAG AA) |
| Contrast — large text (>18px bold) | Minimum 3:1 |
| Focus rings | `chrome/focus` 2px solid, 2px offset, all interactive elements |
| Colorblind mode | Add ✗ icon on wrong state; ✓ on solved. Never rely solely on red/green. |
| Text scaling | UI must not clip or overflow at system font scale 1.4× |
| Reduced motion | All scale/translate animations off; instant color transitions only |

---

## 10. What NOT to Design

- No background textures or gradients on panels
- No decorative typography (text shadows, outlines, glow on labels)
- No character art, mascots, or illustration
- No scrolling — entire game fits one screen
- No loading screens
- No color used purely decoratively — every color communicates state

---

*Implementation order after Figma review: design tokens → typography → word cards → slot panels → character cells → life indicators → end screens.*
