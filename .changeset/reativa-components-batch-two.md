---
"@prescriptive/reativa": minor
---

Add the second batch of 20 more `@prescriptive/reativa` example implementations —
the overlay, data, picker, and navigation components — so each spec gets a
**Reativa** preview alongside the Xote one, matching the demos in
`website/src/Examples.res`.

- **overlays & menus**: `alert-dialog`, `dropdown-menu`, `context-menu`,
  `popover`, `hover-card`, `sheet`, `drawer`, `toast`
- **data & pickers**: `table`, `data-table`, `chart`, `carousel`, `combobox`,
  `command`, `calendar`, `date-picker`
- **navigation**: `navbar`, `menubar`, `navigation-menu`, `sidebar`

These lean on `Reativa.View`'s reactive primitives: `View.show` for the
open/closed overlays (dismissed via the existing `Backdrop`), `View.for_` for
the live-filtered lists (`combobox`, `command`, `data-table`), `class_reactive`
for the selected-day / active-dot state (`calendar`, `date-picker`, `carousel`),
and a reactive `style` for the carousel track. `context-menu` and `hover-card`
use `View.On.on` for the `contextmenu` / `mouseenter` / `mouseleave` events.
Registered in `Registry.mlx`'s `example_for` / `example_ids`. This brings
reativa to 26 elements, 38 components, and 13 blocks.
