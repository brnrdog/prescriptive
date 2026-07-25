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

The full set `@prescriptive/xote` covers — 26 elements, 42 components, 13 blocks,
5 pages, and 3 flows:

| Layer | Specs |
| ----- | ----- |
| element | `aspect-ratio` `avatar` `badge` `button` `checkbox` `icon` `icon-button` `input` `input-otp` `kbd` `label` `legend` `link` `logo` `progress` `radio-group` `scroll-area` `separator` `skeleton` `slider` `spinner` `switch` `textarea` `toggle` `toggle-group` `typography` |
| component | `accordion` `alert` `alert-dialog` `breadcrumb` `button-group` `calendar` `card` `carousel` `chart` `collapsible` `combobox` `command` `comment` `context-menu` `data-table` `date-picker` `dialog` `drawer` `dropdown-menu` `empty-state` `field` `footer` `form` `hover-card` `input-group` `list` `menubar` `navbar` `navigation-menu` `pagination` `popover` `resizable` `search` `select` `sheet` `sidebar` `stat` `table` `tabs` `toast` `toolbar` `tooltip` |
| block | `announcement-bar` `contact-section` `cta-section` `faq` `feature-grid` `hero` `logo-cloud` `newsletter` `page-header` `pricing-table` `stat-grid` `steps` `testimonial` |
| page | `dashboard` `landing-page` `pricing` `settings` `sign-in` |
| flow | `authentication` `checkout` `onboarding` |

Each component is a plain function — `Button.make ~variant:\`primary ~children ()`
— and composes the others. Enum prop types (`variant`, `size`, …) are generated
from the specs' `## API` contracts into [`src/Contracts.ml`](src/Contracts.ml)
by `npm run contracts`, so the OCaml compiler enforces that the implementation
can't drift from the spec's allowed values.

[`src/Registry.mlx`](src/Registry.mlx) renders one live example per spec (the
same demos as the website's Xote examples), plus a knob-driven `playground_for`
render of a single component per spec — the reativa side of the website's
playground, so its props panel drives this implementation as readily as the Xote
one. It exports the JS surface the website consumes:
`mount_example(specId, containerId)`, `example_ids`,
`mount_playground(specId, containerId, props)`, `playground_ids`, and `built`.

## Non-ASCII text

An OCaml `string` is a byte sequence, and Melange emits it one byte per JS code
unit — so a plain literal holding a non-ASCII character (whether typed directly
or escaped as `"\xe2\x80\x94"`) reaches the browser as mojibake (`â€"` instead
of `—`). Write any user-visible text carrying an em dash, ellipsis, checkmark,
caret, bullet, or similar with Melange's js-quoted string, which compiles to a
real JavaScript string:

```ocaml
txt {js|Saving…|js}
```

The rewrite applies to *expression* position only. A js-quoted literal used as a
**pattern** is still the raw UTF-8 bytes and will never match, so compare
against a binding instead of matching on it:

```ocaml
let yes = {js|✓|js} in
if v = yes then (* … *)
```

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
