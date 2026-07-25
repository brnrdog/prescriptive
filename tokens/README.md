# Design Tokens

The **shared, technology-agnostic design decisions** behind the specs —
color, type, spacing, radius, elevation, motion — defined once so every
implementation can stay visually consistent.

Specs describe a pattern's _structure and behavior_ in words and
deliberately avoid pixels and hues. Tokens are the other half: the concrete,
named values a project plugs in. Together they let the same pattern render
consistently across projects and stacks.

## Format

Tokens live in [`tokens.json`](tokens.json) in the
**[W3C Design Tokens (DTCG) format](https://www.w3.org/community/design-tokens/)** —
the emerging interchange standard, readable by a growing set of tools (Style
Dictionary, Tokens Studio, etc.).

- Each token is an object with a `$value` (and inherits `$type` from its group).
- Aliases reference another token with `{group.token}` syntax, e.g.
  `"ink": { "$value": "{color.neutral.900}" }`.

```jsonc
"color": {
  "$type": "color",
  "neutral": { "900": { "$value": "#171717" }, ... },
  "ink":     { "$value": "{color.neutral.900}" }
}
```

## Categories

| Group         | What it holds |
| ------------- | ------------- |
| `color`       | A single grayscale `neutral` ramp (0–1000) plus semantic aliases: `ink`, `paper`, `surface`, `muted`, `border`, `accent`, `accentContrast`. **Semantic roles** the spec contracts bind to: `action` (`default`/`hover`/`subtle`/`onAction`), `status` (`info`/`success`/`warning`/`danger`), and `chart` (`1`–`6`). Monochrome by design — hierarchy comes from value, not hue; retheme by pointing these roles at brand hues. |
| `font`        | `family` (sans/mono), `weight`, `size` scale, `lineHeight`. |
| `space`       | Spacing scale for padding, margin, and gaps, plus semantic `inline` padding (`sm`/`md`/`lg`) for controls. |
| `radius`      | Corner radii, `none` → `full`. |
| `borderWidth` | Hairline / thick. |
| `shadow`      | Elevation `sm` / `md` / `lg`. |
| `duration`    | Motion timings. |
| `zIndex`      | Stacking order for overlays, modals, toasts. |
| `breakpoint`  | Minimum viewport widths where layouts may adapt (`sm` 40rem → `2xl` 96rem). Spec API `responsive` contracts reference these ids (see [`responsive/`](../responsive/)), so "small screen" has a shared, concrete meaning. |

## Consuming tokens

Because tokens are plain, standard JSON, any project can adopt them:

- **This website** — [`website/scripts/generate-tokens-css.mjs`](../website/scripts/generate-tokens-css.mjs)
  reads `tokens.json` and emits a Tailwind `@theme` block (so utilities like
  `bg-neutral-900`, `font-sans`, and `rounded-lg` resolve from the tokens) plus
  a `:root` mirror of every token as a `--ux-*` custom property. Change a value
  here and the whole site re-themes.
- **Other stacks** — feed `tokens.json` to Style Dictionary or an equivalent to
  emit CSS variables, SCSS, Swift, Kotlin, JS objects, etc.

## Building a component library on the tokens

The generated `@theme` exposes the semantic roles as ordinary Tailwind utilities,
so a new component library just uses these classes and re-themes for free — no
hardcoded grays. Aliases stay live (`--color-action: var(--color-neutral-900)`),
so overriding a base token cascades through everything that references it.

| Role | Utilities | Use for |
| ---- | --------- | ------- |
| `action` / `action-hover` / `action-subtle` / `on-action` | `bg-action`, `hover:bg-action-hover`, `bg-action-subtle`, `text-on-action`, `ring-action` | interactive controls (buttons, toggles, focus rings) |
| `status-{info,success,warning,danger}` | `bg-status-danger`, `text-status-success`, `border-status-warning` | feedback (alerts, toasts, validation) |
| `ink` / `muted` | `text-ink`, `text-muted` | primary and secondary text |
| `surface` / `paper` / `border` | `bg-surface`, `bg-paper`, `border-border` | cards, page background, dividers |
| `chart-1…6` | `bg-chart-1`, `text-chart-2` | categorical data series |
| `neutral-0…1000` | `bg-neutral-900`, `text-neutral-500` | raw ramp when no role fits |

For example, the reference `Button` composes `bg-action text-on-action
hover:bg-action-hover`, and `Alert` uses `border-status-danger` — so editing the
`action` or `status.danger` token re-themes every button or alert instantly.

## Theming

To re-skin an implementation, override token values — most usefully the
`color.neutral` ramp (which the semantic roles alias by default) or the semantic
roles themselves (`color.action.*`, `color.status.*`) for finer control.
Swapping the ramp for a tinted palette restyles everything downstream without
touching a single spec or component.

### Themes (presets)

[`themes.json`](./themes.json) ships ready-made themes and light/dark modes.

- **Themes** (`themes` array) carry the palette identity — the full neutral ramp,
  one accent, status colors, a categorical chart set, radii, type, and shadows —
  as a map of token path → value. Included: `monochrome`, `graphite`, `indigo`,
  `azure`, `ocean`, `forest`, `violet`, `plum`, `coral`, `sunset`, `editorial`,
  `terminal`. Each carries a one-line `description` of what it is for.
- **Modes** (`modes` object) are orthogonal light/dark variants applied on top of
  *any* theme. `dark` swaps in a dark ramp — with `surface` a step *above* `paper`
  so cards read as raised — and re-tunes status colors and shadows for a dark
  page, while the theme's radii and font are preserved; each theme's own `dark`
  block then re-tints those surfaces to its hue and lifts its accent. So every
  theme has a coherent dark variant for free.

The palettes follow one rule: **ramps stay close to gray, and saturation is spent
on the accent, status, and chart roles.** A theme's hue survives in its ramp only
as a faint tint (a few percent of chroma), so surfaces and text read as neutral
and the accent is the only loud thing on the page — the way current product UIs
are built. Ramps are generated in OKLCH on a shared lightness ladder, so every
theme has the same contrast structure, and every pair a component depends on
(ink/paper, muted/surface, label/accent fill, status/paper, series/paper) meets
WCAG AA. The one deliberate exception: on a dark page `status.danger` sits bright
enough to read as text (4.5:1), which leaves a white label on a danger *fill* at
~3.9:1 — AA for UI text at that size, and the better trade for the role's most
common use.

The website's picker is generated from this file
(`website/scripts/generate-themes.mjs`), and every theme and mode override path
is validated against the tokens (`npm run conformance:tokens`).
