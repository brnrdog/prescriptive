# @prescriptive/reativa

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
