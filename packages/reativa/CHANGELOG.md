# @prescriptive/reativa

## 0.4.0

### Minor Changes

- 19d5252: Add the final batch of reativa example implementations, reaching **full parity**
  with the Xote examples — every spec that has a Xote demo now has a matching
  **Reativa** preview, mirroring `website/src/Examples.res`.

  - **components**: `form`, `resizable`, `search`, `comment`
  - **pages**: `dashboard`, `landing-page`, `pricing`, `settings`, `sign-in`
  - **flows**: `authentication`, `checkout`, `onboarding`

  `search` filters a list live with `View.for_`; `resizable` binds a range input
  to a reactive `style` on both panels; `form` submits with `View.On.submit` +
  `prevent_default` and reveals a success message via `View.show`; `sign-in` wires
  a native checkbox through a reactive `checked` binding; the `authentication` and
  `onboarding` flows step through their states from a single `step` signal.
  Registered in `Registry.mlx`'s `example_for` / `example_ids`. reativa now covers
  26 elements, 42 components, 13 blocks, 5 pages, and 3 flows — the same set Xote
  implements.

- 19d5252: Add the second batch of 20 more `@prescriptive/reativa` example implementations —
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

- c3d692e: Render the website's playground with reativa too. `Registry.mlx` gains
  `playground_for` — a knob-driven render of a single component for each of the 30
  specs the playground covers (`button`, `badge`, `avatar`, `alert`, `checkbox`,
  `switch`, `slider`, `progress`, `spinner`, `skeleton`, `separator`, `kbd`,
  `icon`, `icon-button`, `link`, `input`, `textarea`, `toggle`, `toggle-group`,
  `radio-group`, `aspect-ratio`, `scroll-area`, `input-otp`, `select`, `field`,
  `tooltip`, `tabs`, `accordion`, `collapsible`, `dialog`) — mirroring the Xote
  render functions prop for prop, with the generated contract types keeping the
  allowed values honest.

  Two new exports join the JS surface the website consumes:
  `mount_playground(specId, containerId, props)`, which renders a spec from the
  knob values the props panel currently holds, and `playground_ids`, so the site
  knows which specs reativa can drive.

### Patch Changes

- Updated dependencies [e646367]
  - @prescriptive/tokens@0.2.0

## 0.3.0

### Minor Changes

- 7c927c3: Add the first batch of 20 more `@prescriptive/reativa` example implementations, so
  these specs get a **Reativa** preview alongside the Xote one — matching the
  demos in `website/src/Examples.res`.

  - **elements**: `label`, `legend`, `logo`, `typography`
  - **components**: `breadcrumb`, `button-group`, `card`, `empty-state`, `footer`,
    `input-group`, `list`, `pagination`, `stat`, `toolbar`
  - **blocks**: `cta-section`, `faq`, `feature-grid`, `hero`, `pricing-table`,
    `testimonial`

  Each is a plain composition over `Reativa.View` — reusing the existing `Button`,
  `Badge`, `Avatar`, `Icon`, `IconButton`, `Separator`, `Input`, and `Link`
  components — styled against `@prescriptive/tokens` so a re-theme cascades through
  them exactly like the Xote implementations. `pagination` and `faq` are reactive
  (active page / open item held in a signal). Registered in `Registry.mlx`'s
  `example_for` / `example_ids` so the website surfaces a Reativa tab for each.
  This brings reativa to 26 elements, 18 components, and 13 blocks.

## 0.2.0

### Minor Changes

- e34848c: Add `@prescriptive/reativa` — the ReasonML/OCaml (reativa + Melange) sibling of
  `@prescriptive/xote`, as its own package.

  - Implements the same set `@prescriptive/xote` covers — 22 elements, 8 components, and
    7 blocks — in `.mlx` (JSX-for-OCaml) over `Reativa.View`, styled against
    `@prescriptive/tokens`, with the same behaviour and accessibility semantics as the
    Xote components.
  - Enum prop types (`variant`, `size`, …) are generated from the specs' `## API`
    contracts into `src/Contracts.ml` by `npm run contracts`, so the OCaml
    compiler enforces that the implementation can't drift from the spec — the same
    guarantee `@prescriptive/xote` has.
  - `src/Registry.mlx` renders one live example per spec and exports the JS surface
    the website's **Reativa** preview consumes (`mount_example`, `example_ids`,
    `built`). The website's example block now has two tab strips: one picks the
    view (Preview / Playground / Code) and one picks the implementation rendered in
    the preview (**Xote** or **Reativa**).
