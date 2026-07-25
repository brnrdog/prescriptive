# @prescriptive/skill

## 0.1.1

### Patch Changes

- e646367: Redesign the predefined themes so the presets look like current products rather
  than tinted washes of one hue.

  The old presets pushed their hue through the whole neutral ramp — indigo
  surfaces, indigo borders, indigo text — which read as monochromatic and dated,
  and left steps 300–600 as the unrelated warm grays of the baseline. Every theme
  is now built the way modern product palettes are: **the ramp stays close to
  gray, and saturation is spent on the accent, status, and chart roles.** The
  theme's hue survives in surfaces and text only as a few percent of chroma.

  - **Twelve themes**, each with a `description` of what it is for: `monochrome`,
    `graphite`, `indigo`, `azure`, `ocean`, `forest`, `violet`, `plum`, `coral`,
    `sunset`, `editorial`, `terminal`. `vibrant` and `candy` are gone; `graphite`,
    `azure`, `violet` and `plum` are new.
  - **Complete ramps.** Each theme defines all twelve neutral steps on a shared
    OKLCH lightness ladder, so no theme mixes its own tint with baseline grays and
    every theme has the same contrast structure.
  - **Categorical chart sets.** Themes now set `color.chart.1…6` to six
    distinguishable hues rotated off their own, instead of inheriting the
    grayscale ramp where every series looked alike.
  - **Dark mode that works.** The `dark` mode overlay puts `surface` a step
    _above_ `paper` (so cards read as raised, as they do in light mode), re-tunes
    every status color for a dark page, and swaps the shadows for near-black ones
    — a 5%-alpha warm gray was invisible on a dark surface. Each theme's own
    `dark` block re-tints those surfaces to its hue and lifts its accent.
  - **Tinted shadows, per-theme type and radii.** Ambient shadows carry a hint of
    the theme's hue; `graphite` and `editorial` invert to a light accent fill in
    dark mode, and `terminal`'s signal-green fill carries a dark label.
  - **AA by construction.** Accents, status colors, and chart series are derived
    from the contrast requirement itself, so ink/paper, muted/surface,
    label/accent-fill, status/paper and series/paper all clear WCAG AA in both
    modes. The baseline `color.status.*` values move with them (`success` and
    `warning` previously failed AA as text on `paper`).
