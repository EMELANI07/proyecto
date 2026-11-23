---
name: AgroAudit Console
colors:
  surface: '#031427'
  surface-dim: '#031427'
  surface-bright: '#2a3a4f'
  surface-container-lowest: '#000f21'
  surface-container-low: '#0b1c30'
  surface-container: '#102034'
  surface-container-high: '#1b2b3f'
  surface-container-highest: '#26364a'
  on-surface: '#d3e4fe'
  on-surface-variant: '#dbc2b0'
  inverse-surface: '#d3e4fe'
  inverse-on-surface: '#213145'
  outline: '#a38c7c'
  outline-variant: '#554336'
  surface-tint: '#ffb77d'
  primary: '#ffb77d'
  on-primary: '#4d2600'
  primary-container: '#d97707'
  on-primary-container: '#432100'
  inverse-primary: '#904d00'
  secondary: '#4edea3'
  on-secondary: '#003824'
  secondary-container: '#00a572'
  on-secondary-container: '#00311f'
  tertiary: '#adc6ff'
  on-tertiary: '#002e6a'
  tertiary-container: '#4d8eff'
  on-tertiary-container: '#00285d'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#ffdcc3'
  primary-fixed-dim: '#ffb77d'
  on-primary-fixed: '#2f1500'
  on-primary-fixed-variant: '#6e3900'
  secondary-fixed: '#6ffbbe'
  secondary-fixed-dim: '#4edea3'
  on-secondary-fixed: '#002113'
  on-secondary-fixed-variant: '#005236'
  tertiary-fixed: '#d8e2ff'
  tertiary-fixed-dim: '#adc6ff'
  on-tertiary-fixed: '#001a42'
  on-tertiary-fixed-variant: '#004395'
  background: '#031427'
  on-background: '#d3e4fe'
  surface-variant: '#26364a'
typography:
  headline-xl:
    fontFamily: Inter
    fontSize: 36px
    fontWeight: '700'
    lineHeight: 44px
    letterSpacing: -0.02em
  headline-xl-mobile:
    fontFamily: Inter
    fontSize: 26px
    fontWeight: '700'
    lineHeight: 32px
    letterSpacing: -0.01em
  headline-lg:
    fontFamily: Inter
    fontSize: 28px
    fontWeight: '600'
    lineHeight: 36px
    letterSpacing: -0.015em
  headline-lg-mobile:
    fontFamily: Inter
    fontSize: 22px
    fontWeight: '600'
    lineHeight: 28px
  headline-sm:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
  body-lg:
    fontFamily: Inter
    fontSize: 15px
    fontWeight: '400'
    lineHeight: 22px
  body-sm:
    fontFamily: Inter
    fontSize: 13px
    fontWeight: '400'
    lineHeight: 18px
  label-code-lg:
    fontFamily: JetBrains Mono
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: -0.01em
  label-code-sm:
    fontFamily: JetBrains Mono
    fontSize: 11px
    fontWeight: '500'
    lineHeight: 14px
    letterSpacing: 0.02em
  metric-display:
    fontFamily: JetBrains Mono
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 36px
    letterSpacing: -0.03em
rounded:
  sm: 0.125rem
  DEFAULT: 0.25rem
  md: 0.375rem
  lg: 0.5rem
  xl: 0.75rem
  full: 9999px
spacing:
  gutter: 0.75rem
  gutter-desktop: 1rem
  margin: 0.75rem
  margin-desktop: 1.5rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 0.75rem
  space-lg: 1.25rem
  space-xl: 2rem
---

## Brand & Style

This design system serves as an industrial, high-precision telemetry and audit environment for live livestock digital twin auctions across Sonora, Chihuahua, and Sinaloa. The operational identity fuses telemetry-grade SCADA instrumentation with robust field logistics: austere slate grounds, precise status-luminescent accents, and tabular rigor.

The aesthetic blends **Modern Industrial / Technical Console** with **Utility-First Brutalism**. Visual weight prioritizes zero-latency situational awareness, deterministic data state tracking (SINIIGA certifications, auction sequence continuity, millisecond-precision logical clocks, and live weight scaling), and complete auditability. Every view minimizes decorative noise in favor of stark contrast, tactile state verification, and strict operational clarity under bright corral floodlights or low-light remote operations control rooms.

## Colors

The system uses a dark-first industrial hierarchy built to resist visual fatigue during long auction sessions while providing unambiguous, instantaneous state recognition:

- **Base Foundations:** Surfaces sit on deep slate layers (`#0B0F19` canvas, `#0F172A` root panels, and `#1E293B` elevated containers). Borders delineate partitions with crisp, low-lit steel (`#334155`).
- **Primary (Tierra / Cuero Ámbar - `#D97706` / `#B45309`):** Designates active lot focus, user-triggered bidding controls, and core operational highlights.
- **Secondary (Validations & Sanitary Registry - `#10B981` / `#059669`):** Reserved for certified sanitary validations, cleared SINIIGA ear-tag telemetry, active health paperwork, and synchronized consensus states.
- **Tertiary (Technical Sync & Logical Clock - `#3B82F6`):** Identifies active WebSocket feeds, sub-millisecond timestamps, network heartbeats, and digital twin state replication.
- **State Semantics:**
  - **Alert / Gap (`#EF4444`):** Missing sequence blocks, rejected cattle lots, biometric anomalies, or scale discrepancies.
  - **Warning / Review (`#F59E0B`):** Quarantined lots, fluctuating weights, or pending inspector sign-offs.
  - **Text Layers:** Primary technical text in pure contrast `#F8FAFC`, secondary telemetry labels in `#94A3B8`, and disabled/muted registers in `#475569`.

## Typography

The type system implements a strict dual-engine schema:

1. **Inter (Structural Text & UI):** Directs macro-navigation, modal headers, lot taxonomy, and metadata descriptors. Its neutral geometric skeleton maintains legibility at high data density without crowding panels.
2. **JetBrains Mono (Deterministic Telemetry):** Governs all critical live values: SINIIGA national IDs (12-digit tags), weight metrics (`kg/cabeza`), block sequence IDs (`seq: 0x8F4A`), NTP-synced auction timestamps (`hh:mm:ss.SSS`), and bid currency counters.

Strict tabular figures (`font-variant-numeric: tabular-nums`) must be active across all monospace output to prevent layout jitter during real-time scalar updates.

## Layout & Spacing

The layout operates on a compact 4px technical grid, tuned specifically for multi-channel data ingestion and split-second operational monitoring.

- **Grid Strategy:** A fluid 12-column grid system governs large operational control displays (workstations and arena terminals), collapsing into a stacked, high-density single-column layout on field tablets and ruggedized phones.
- **Breakpoints:**
  - `Mobile / Rugged Handheld (<768px)`: Single-column stream. Margins at `0.75rem`. Real-time stream and active lot pin to the top viewport; sequence audit logs drop into collapsible bottom sheets.
  - `Tablet / Field Inspector (768px - 1199px)`: Split 8/4 layout. Primary video and live telemetry occupy 8 columns; validation, bidding, and sanitary checklists occupy 4 columns.
  - `Desktop / Command Post (>=1200px)`: Three-zone dashboard (3-col lot queue, 6-col live twin arena stream + telemetry, 3-col ledger and sequence auditor). Gutter at `1rem`, outer margins at `1.5rem`.
- **Rhythm Rules:** Dense data layouts use `space-xs` (4px) and `space-sm` (8px) between metric label-value pairs. Structural component padding defaults to `space-md` (12px) to maximize visible data payload above the fold.

## Elevation & Depth

To preserve real-time legibility and avoid visual latency, this design system rejects heavy blurs, diffusion shadows, and skeuomorphic gradients in favor of **structural containment through tonal tiers and razor-sharp border strokes**:

- **Tier 0 (Root Ground - `#0B0F19`):** Application canvas and inactive gutters.
- **Tier 1 (Surface Panels - `#0F172A` with 1px border `#1E293B`):** Static layout grids, historical feeds, and collapsed logs.
- **Tier 2 (Active Operational Units - `#1E293B` with 1px border `#334155`):** Live cattle weight meters, SINIIGA detail cards, and inspector interaction trays.
- **Tier 3 (Modals, Overlays & Urgent Interrupts - `#1E293B` with 1px border `#475569`):** Elevated overlays utilizing an ambient hard shadow: `0 8px 0 0 rgba(0, 0, 0, 0.45)`.
- **Telemetry Glow Embellishment:** Selected active cards (such as the Live Ring lot or triggered sequence alarms) adopt a subtle `1px` high-contrast outer glow using their respective semantic color at 25% opacity (e.g., `0 0 0 1px #D97706`).

## Shapes

The design system enforces a **Soft Technical (Level 1)** geometric standard. Containers, input fields, badges, and action bars use a disciplined `0.25rem` (4px) corner radius. Structural group cards use `0.5rem` (8px). 

Circular or pill geometry is strictly prohibited except for binary online/offline status beacons (`w-2 h-2 rounded-full`). This preserves the precision aesthetic of industrial oscilloscopes and telemetry consoles, preventing wasted whitespace in high-density tables.

## Components

### Buttons & Operational Triggers
- **Primary Bid / Confirm Action:** Background `#D97706`, text `#0F172A`, font `Inter` 600. Minimal border, sharp hover state shifting to `#B45309`, active state inset by 1px.
- **Emergency Halt / Quorum Interruption:** High-contrast outline `#EF4444`, background `rgba(239, 68, 68, 0.1)`, text `#F8FAFC`.
- **Secondary / Utility Controls:** Slate background `#1E293B`, 1px border `#334155`, text `#94A3B8`. Hover introduces text `#F8FAFC` and border `#64748B`.

### Audit Badges & Telemetry Chips
- Rendered in `JetBrains Mono` label-code-sm (`11px`).
- Pad: `2px 6px`, radius `4px`.
- **Validated / SINIIGA OK:** Background `rgba(16, 185, 129, 0.12)`, border `1px solid #059669`, text `#34D399`.
- **Sequence Gap / Alert:** Background `rgba(239, 68, 68, 0.15)`, border `1px solid #DC2626`, text `#F87171`. Pulse indicator optional.
- **Sync / Replicating:** Background `rgba(59, 130, 246, 0.12)`, border `1px solid #2563EB`, text `#60A5FA`.

### Input Fields & Search Bars
- Background `#0F172A`, 1px border `#334155`, text `#F8FAFC`, placeholder `#475569`.
- Focus state switches border to `#D97706` with no soft outer glow, preserving crisp borders. Text inputs for SINIIGA tags, lot indexes, and scale overrides default to monospace format.

### Compact Data Cards & Live Twin Containers
- High-density containers with header partitions: upper section houses the livestock category (e.g., *Novillo Brangus de Exportación*), origin ranch (e.g., *Hermosillo, SON*), and SINIIGA identifier; lower compartment reveals weight telemetry, current bid index, and sequence hash.
- Card partition lines use 1px solid `#1E293B`.

### Sequence Ledger & Millisecond Audit Log
- Monospace rows with alternating micro-shading (`#0F172A` to `#131D31`).
- Columns align strictly: Timestamp (`ISO-8601 .SSS`), Event Code, Actor ID, Delta Weight, Consensus Verification Signature.
- Sequence gaps are automatically flanked by warning horizontal delimiters with red micro-stripes (`#EF4444`).
