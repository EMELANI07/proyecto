# Muestra de interfaz 
Muestra que me dio GoogleStitch como muestra de la interfaz que podria usar para el proyecto.
[DESIGN.md](https://github.com/user-attachments/files/34455032/DESIGN.md)
---
name: AgroAuction Enterprise
colors:
  surface: '#0e1511'
  surface-dim: '#0e1511'
  surface-bright: '#343b36'
  surface-container-lowest: '#09100c'
  surface-container-low: '#161d19'
  surface-container: '#1a211d'
  surface-container-high: '#242c27'
  surface-container-highest: '#2f3632'
  on-surface: '#dde4dd'
  on-surface-variant: '#bbcabf'
  inverse-surface: '#dde4dd'
  inverse-on-surface: '#2b322d'
  outline: '#86948a'
  outline-variant: '#3c4a42'
  surface-tint: '#4edea3'
  primary: '#4edea3'
  on-primary: '#003824'
  primary-container: '#10b981'
  on-primary-container: '#00422b'
  inverse-primary: '#006c49'
  secondary: '#ffb68e'
  on-secondary: '#532200'
  secondary-container: '#ab4c00'
  on-secondary-container: '#ffe2d5'
  tertiary: '#b9c7e0'
  on-tertiary: '#233144'
  tertiary-container: '#95a4bb'
  on-tertiary-container: '#2c3a4e'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#6ffbbe'
  primary-fixed-dim: '#4edea3'
  on-primary-fixed: '#002113'
  on-primary-fixed-variant: '#005236'
  secondary-fixed: '#ffdbca'
  secondary-fixed-dim: '#ffb68e'
  on-secondary-fixed: '#331200'
  on-secondary-fixed-variant: '#763300'
  tertiary-fixed: '#d5e3fd'
  tertiary-fixed-dim: '#b9c7e0'
  on-tertiary-fixed: '#0d1c2f'
  on-tertiary-fixed-variant: '#3a485c'
  background: '#0e1511'
  on-background: '#dde4dd'
  surface-variant: '#2f3632'
typography:
  display-auction:
    fontFamily: JetBrains Mono
    fontSize: 48px
    fontWeight: '700'
    lineHeight: 52px
    letterSpacing: -0.04em
  headline-xl:
    fontFamily: Space Grotesk
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 38px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Space Grotesk
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 30px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Space Grotesk
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  body-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
  data-mono-lg:
    fontFamily: JetBrains Mono
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 24px
    letterSpacing: -0.02em
  data-mono-md:
    fontFamily: JetBrains Mono
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 18px
    letterSpacing: -0.01em
  data-mono-sm:
    fontFamily: JetBrains Mono
    fontSize: 11px
    fontWeight: '500'
    lineHeight: 14px
    letterSpacing: 0.02em
  label-caps:
    fontFamily: Space Grotesk
    fontSize: 11px
    fontWeight: '700'
    lineHeight: 14px
    letterSpacing: 0.08em
rounded:
  sm: 0.125rem
  DEFAULT: 0.25rem
  md: 0.375rem
  lg: 0.5rem
  xl: 0.75rem
  full: 9999px
spacing:
  gutter: 0.75rem
  margin: 1rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 0.75rem
  space-lg: 1.25rem
  space-xl: 2rem
---

## Brand & Style

This design system establishes a high-performance, mission-critical operational interface for live cattle auctions and livestock transaction auditing. It fuses the analytical discipline of financial trading terminals with the physical authority of agricultural enterprise management. The target audience includes livestock auctioneers, ring clerks, feedlot procurement directors, and compliance audit officers working in high-tempo, data-dense environments.

The visual ethos blends **Modern Enterprise Operational Minimalism** with targeted **Tactile Financial Realism**:
- **Tone & Atmosphere:** Authoritative, razor-sharp, resilient, and audit-ready. The atmosphere is that of an institutional trading floor engineered for field operations.
- **Visual Weight:** Deep zinc and charcoal surfaces set an undistracted baseline, punctuated by harness-leather saddle accents, crisp tabular matrices, and instantaneous visual cues for ring bidding actions.
- **Real-Time Priority:** Micro-interactions emphasize definitive transactional certainty: zero ambiguity between accepted bids, outbid states, lot reservations, and hammer strikes.

## Colors

The palette is engineered for prolonged operational focus under varied lighting conditions, minimizing eye fatigue during continuous 8-hour live ring sessions while establishing an unambiguous chromatic hierarchy for bids, weights, and lot state machines.

- **Primary (`#10B981` — Emerald Operational):** Signals affirmative transactional states: active ring lots, highest bid confirmed, floor bid increments, hammer drop closures, and healthy network synchronization.
- **Secondary (`#B45309` — Saddle Leather / Warm Amber):** Evokes the cattle trading heritage without pastiche. Serves as a tactile brand accent for lot badges, seller identifiers, premium pedigree markings, and reserve price thresholds.
- **Tertiary (`#334155` — Slate Iron):** Anchors secondary structural elements, column headers, docked control panels, and inactive metadata tags.
- **Neutral Framework:**
  - Base Canvas (`#090D10`): Deepest slate-charcoal ground.
  - Surface Level 1 (`#0F151B`): Shell cards and main table matrices.
  - Surface Level 2 (`#161F27`): Active input drawers, lot inspection modules, and bid control strips.
  - Border Tone (`#222F3D`): Hairline dividers maintaining strict tabular structure.
- **State Semantics:**
  - **Accepted / Floor Confirmed:** `#10B981` (Emerald).
  - **Pending / In-Ring Counter / Warning:** `#F59E0B` (Amber Alert).
  - **Rejected / Withdrawn / Outbid:** `#EF4444` (Crimson Terminal).
  - **Audit Log / Historical Ledger:** `#64748B` (Muted Slate).

## Typography

Typography enforces a strict division between editorial structure, narrative metadata, and quantitative transaction figures:

1. **Display & Structural Titles (`Space Grotesk`):** Delivers clean industrial geometry suitable for cattle categories, breed classifications, seller dossiers, and module mastheads.
2. **Body & Descriptive Readouts (`Inter`):** Powers observational remarks, health status notes, sanitary cert details, and seller terms with maximum micro-legibility.
3. **Tabular & Monospace Engine (`JetBrains Mono`):** Non-negotiable for all monetary values (currency/cwt/kg), live scale readouts, head counts, lot identifiers (e.g., `LOT-0482-B`), bid increment deltas, and timestamped bitácora ledger rows. Tabular numerals ensure figures never shift horizontally during high-speed real-time increments.

## Layout & Spacing

Designed for operational density across multi-monitor ring desk setups (primarily 1080p, 1440p, and 4K field terminals):

- **Grid Architecture:** 16-column continuous fluid layout at desktop widths (`≥ 1440px`), compressing to an 8-column layout on tablet field devices (`≥ 768px`).
- **Screen Density Strategy:** Compact spacing scale calibrated to present complete lot dossiers, live video/ring feeds, live bidding ladders, and audit ledgers simultaneously above the fold. 
- **Zonal Partitioning:**
  - **Left Rail (4 cols):** Live ring lot status, scale integration readout, biological indicators (breed, avg weight, vaccine status).
  - **Center Deck (8 cols):** Primary bid board, real-time bid increment triggers, current high bidder, reserve margin tracking.
  - **Right Rail (4 cols):** The immutable audit log (`p65_bitacora`) chronologically appending all bids, clerk overrides, paddle assignments, and hammer announcements.
- **Adaptation Rules:** Under low-resolution tablet operations, the Center Deck gains full priority; the audit log collapses into an off-canvas drawer accessed via a persistent badge.

## Elevation & Depth

This system avoids floating cloud shadows, utilizing **Tonal Architectural Stacking with Laser-Cut Low-Contrast Outlines** to preserve high visual discipline in low-light auction rings:

- **Level 0 (Arena Floor):** `#090D10` base workspace canvas.
- **Level 1 (Docked Containers):** `#0F151B` enclosed within a solid `1px` border of `#222F3D`. Zero elevation blur.
- **Level 2 (Active Bidding Pods / Selected Lots):** `#161F27` framed with a high-contrast hairline border (`#334155`). When a lot is actively taking bids, the container acquires an internal `1px` inset halo of `rgba(16, 185, 129, 0.4)`.
- **Level 3 (Modal Overrides & Hammer Dropped Confirmatory):** `#1E293B` raised with an ambient drop: `0px 12px 32px -4px rgba(0, 0, 0, 0.75)`, banded by an absolute 2px keyline colored by the transaction outcome (Emerald for Sold, Amber for No Sale/Reserve Unmet).
- **Audit Timeline Indicator:** Features an unbroken continuous hairline vertical line (`#1E293B`) through which glowing indicator nodes (`#10B981`, `#EF4444`, `#F59E0B`) puncture the surface plane.

## Shapes

The interface embraces a precise, utilitarian tool aesthetic (`roundedness: 1`):
- Default containers, control inputs, table rows, and metric widgets utilize a firm `0.25rem` (4px) corner radius.
- System modals, docked operational decks, and live camera feed frames scale to `rounded-lg` at `0.5rem` (8px).
- Audit trail nodes, paddle number chips, and biological classification badges maintain structural, slightly softened rectangles (`0.25rem`) rather than stadium pills, reinforcing the enterprise financial demeanor.

## Components

### 1. Bidding & Action Buttons
- **Primary Live Hammer Button (`Accept Bid`):** Emerald `#10B981` solid ground, jet-black text, bold tabular typography showing the next auto-calculated increment. Subtle inset top-edge highlight for tactile presence. 
- **Clerk Quick-Increment Steppers:** Dark slate background `#1E293B`, high-contrast text, monospace delta labels (`+$25`, `+$50`, `+$100`). Instantaneous `:active` scale change to `0.98` with no layout shift.
- **Pass / Reject / Withdraw:** Crimson `#EF4444` outline button with a transparent background that fills to crimson upon double-tap confirmation to prevent accidental ring cancellations.

### 2. Tabular Data Tables & Lot Grids
- **Header:** Sticky top, Space Grotesk `label-caps`, uppercase, muted slate `#64748B`, with hairline border underneath.
- **Rows:** Dense 36px height. Alternating row background `rgba(255, 255, 255, 0.015)`. Numbers right-aligned using `JetBrains Mono`.
- **Selection State:** Active ring lot highlighted with a solid 3px left border accent in `#10B981` or `#B45309`.

### 3. Metric & Scale Display Cards
- **Weight Scale Card:** Massive tabular numeric readout in `JetBrains Mono` connected directly to the certified digital livestock scale. Includes a dynamic "Scale Settled" status pip (flashing Amber when moving, solid Emerald when stable).
- **Price Per Unit Matrix:** Side-by-side computation of Gross Lot Price alongside Per-Pound / Per-Kilogram rates rendered in `data-mono-md`.

### 4. Chips & Metadata Badges
- **Paddle Identifier (`PADDLE-###`):** High-contrast badge with `#161F27` background, `#F8FAFC` text, and a `#B45309` (leather brown) boundary line.
- **Health & Breed Chips:** Monochromatic muted slate containers with color-coded dot prefixes designating vaccination status, export grade, or pedigree registry.

### 5. Audit Trail Ledger (`p65_bitacora`)
- High-density chronological feed. Every action records:
  - Exact millisecond timestamp (`HH:mm:ss.SSS`).
  - Terminal operator / Clerk ID.
  - Action category (`BID_INC`, `HAMMER_FALL`, `WEIGHT_CAPTURE`, `LOT_WITHDRAWN`).
  - Prior value vs. new value differential.
- Visual connector line linking sequential ring events with color-keyed status nodes.

### 6. Form Fields & Quick-Entry Inputs
- Dense 32px height, sharp 4px corners, `#0F151B` fill, `#222F3D` border. Focus state yields crisp 1px Emerald `#10B981` outline with zero ring spread blur. Numeric fields default to monospace font and auto-select on focus for rapid keypad entry.
