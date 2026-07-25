# @prescriptive/reativa

Accessible UI components for **[reativa](https://github.com/brnrdog/reativa)**
(OCaml + Melange) that implement the [Prescriptive](https://github.com/brnrdog/prescriptive)
contracts — the ReasonML/OCaml sibling of
[`@prescriptive/xote`](../xote). Every element, component, and block is written in
`.mlx` (JSX-for-OCaml) over `Reativa.View`, styled against
[`@prescriptive/tokens`](../tokens), so a re-theme cascades through these exactly like
it does through the Xote components.

There is no virtual DOM: `View.mount` builds real DOM nodes once and only the
reactive regions (driven by signals) update in place.

## What's implemented

26 elements, 18 components, and 13 blocks:

| Layer | Specs |
| ----- | ----- |
| element | `aspect-ratio` `avatar` `badge` `button` `checkbox` `icon` `icon-button` `input` `input-otp` `kbd` `label` `legend` `link` `logo` `progress` `radio-group` `scroll-area` `separator` `skeleton` `slider` `spinner` `switch` `textarea` `toggle` `toggle-group` `typography` |
| component | `accordion` `alert` `breadcrumb` `button-group` `card` `collapsible` `dialog` `empty-state` `field` `footer` `input-group` `list` `pagination` `select` `stat` `tabs` `toolbar` `tooltip` |
| block | `announcement-bar` `contact-section` `cta-section` `faq` `feature-grid` `hero` `logo-cloud` `newsletter` `page-header` `pricing-table` `stat-grid` `steps` `testimonial` |

Each component is a plain function — `Button.make ~variant:\`primary ~children ()`
— and composes the others. Enum prop types (`variant`, `size`, …) are generated
from the specs' `## API` contracts into [`src/Contracts.ml`](src/Contracts.ml)
by `npm run contracts`, so the OCaml compiler enforces that the implementation
can't drift from the spec's allowed values.

[`src/Registry.mlx`](src/Registry.mlx) renders one live example per spec (the
same demos as the website's Xote examples) and exports the JS surface the
website consumes: `mount_example(specId, containerId)`, `example_ids`, and
`built`.

## Building

reativa's core library has **no `public_name`**, so it is a *private* dune
library that can't be consumed as an installed opam package — its own demo
builds only because it lives inside the reativa dune project. So we do the same:
[`scripts/build.mjs`](scripts/build.mjs) clones reativa (pinned to a commit),
drops [`dune`](dune) + `src/*` into a subdirectory of the clone where the
private `reativa` library and the `reativa.mlx_ppx` ppx are in scope, compiles
to ES modules with Melange, and bundles the emitted `Registry.js` into
`dist/reativa.bundle.js` with esbuild.

Requires the OCaml toolchain (an opam switch on OCaml **5.1+**, since reativa
needs `melange >= 3`). One-time setup:

```bash
opam switch create . 5.2.1     # or reuse an existing 5.1+ switch
opam install dune melange mlx
```

Then:

```bash
npm run build --workspace @prescriptive/reativa   # contracts → melange → esbuild bundle
```

To move to a newer reativa, bump `REATIVA_REF` in `scripts/build.mjs`.

> This build is intentionally **not** part of `npm run build:packages` (it needs
> opam/melange, which the rest of the build does not) — but CI runs it, and the
> website's `npm run reativa` builds this package and copies the bundle into the
> site so the **Reativa** preview ships for real.
