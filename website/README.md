# Prescriptive — Website

An interactive catalogue for the specs in this repository. Browse every
spec in the sidebar and see a **live implementation rendered with
[Xote](https://xote.dev)** for each one.

## Stack

- **[Vite](https://vitejs.dev)** — dev server and bundler.
- **[ReScript](https://rescript-lang.org)** — typed language compiling to JS.
- **[Xote](https://xote.dev)** — fine-grained reactive UI library for ReScript,
  built on `rescript-signals`.
- **[Tailwind CSS](https://tailwindcss.com)** (v4) — utility styling.
- **Monochrome theme** — a single neutral (grayscale) palette; hierarchy comes
  from value, weight, and spacing rather than hue.

## How it works

```
tokens/tokens.json            (design tokens, one directory up)
        │  scripts/generate-tokens-css.mjs   (npm run tokens)
        ▼
src/tokens.generated.css      Tailwind @theme + --ux-* vars (drives the theme)

specs/**/*.md            (the specs, one directory up)
        │  scripts/generate-registry.mjs    (npm run registry)
        ▼
src/SpecsData.res        generated, typed list of every spec

src/Examples.res              a live Xote component per spec (`get`)
        │  scripts/generate-snippets.mjs    (npm run snippets)
        ▼
src/ExampleSource.res         each example's Xote source, shown under the preview
        │
        │  ../packages/reativa/src (Registry.mlx + components)
        │  scripts/generate-reativa-source.mjs  (npm run snippets:reativa)
        ▼
src/ReativaSource.res         the same examples' reativa (OCaml) source
        │
        ▼
src/App.res                   sidebar + router (Xote Router) + the example block
src/Playground.res            per-spec knobs + the live, knob-driven preview
src/{Button,Badge,Input,Field,Avatar,Switch,Spinner,Kbd,Separator,Backdrop,
     Link,IconButton}.res     reusable components, one per file, referenced
                              directly as <Button/> etc.
src/Ui.res                    shared monochrome class tokens + helpers
src/Main.res                  entry: Router.init + View.mountById
```

The `gen` steps (`npm run gen` = tokens + registry + snippets) run before every
build. Each **reusable component lives in its own file** and is used
directly — `Card`, `Dialog`, `Form`, `Navbar`, … compose the very same
`<Button>` (reused by ~18 examples), `<Badge>`, `<Input>`, `<Field>`,
`<Backdrop>`, etc., rather than re-implementing them. Element example pages are
thin showcases (`ButtonEx`, `BadgeEx`, …) built from the same components. Both
source generators prepend the component sources an example composes, so each
snippet stays self-contained and shows the reuse.

The **registry generator** reads the spec markdown frontmatter (plus the
first paragraph of each `## Intent`) and emits `src/SpecsData.res`. That
guarantees the sidebar always lists every spec in the collection.

Each spec's example is a small self-contained Xote component in
`Examples.res`; `Examples.get(id)` maps a spec `id` to its rendered node.
Specs without an example fall back to a graceful placeholder.

## The example block

Each detail page shows **one live surface**, never a preview/playground split:
where a spec declares knobs in `Playground.res`, the preview *is* the
knob-driven component with its props panel underneath; where it doesn't, the
preview is the spec's example. A single strip picks the implementation, and
everything on the page follows it — the preview, the knobs that drive it, and
the source shown by **Show source** (Xote's ReScript or reativa's OCaml).

## Xote / Reativa implementations

Every element, component, and block that `@prescriptive/xote` implements is **also**
implemented in OCaml with [reativa](https://github.com/brnrdog/reativa) — the
signal-based sibling of Xote — in the
[`@prescriptive/reativa`](../packages/reativa) package. One strip picks the
**implementation** — **Xote** or **Reativa** — and the whole block follows it, so
either library renders the same spec from the same design tokens, driven by the
same knobs, with its own source a click away. Switching keeps the props you
dialed in. A spec whose reativa implementation has no playground arm (or whose
bundle isn't built) falls back to its plain reativa example.

The reativa build is a self-contained Melange workspace, kept **separate** from
this ReScript/Vite build (it needs opam + melange, the website doesn't).
`npm run reativa` builds `@prescriptive/reativa` and copies its bundle to
`src/reativa.bundle.js`; a checked-in placeholder keeps the site compiling until
then. See [`packages/reativa/README.md`](../packages/reativa/README.md).

## Develop

```bash
npm install
npm run registry     # generate src/SpecsData.res from ../specs
npm run res:dev      # ReScript compiler in watch mode  (terminal 1)
npm run dev          # Vite dev server                  (terminal 2)
```

`npm run dev` also runs the registry + a one-off ReScript build first, so a
single `npm run dev` is enough for a quick look; use `res:dev` in parallel for
live recompilation while editing `.res` files.

## Build

```bash
npm run build        # registry → rescript → vite build  →  dist/
npm run preview      # serve the production build
```

## Deploy (GitHub Pages)

The site deploys automatically via
[`.github/workflows/deploy-pages.yml`](../.github/workflows/deploy-pages.yml)
on every push to the deploy branch that touches `website/`, `specs/`, or
the workflow itself. It builds with `BASE_PATH=/<repo>/`, adds a `404.html`
SPA fallback and `.nojekyll`, and publishes `website/dist`.

**One-time setup:** in the repository, go to **Settings → Pages** and set
**Source** to **GitHub Actions**. After the first successful run the site is
live at:

```
https://brnrdog.github.io/prescriptive/
```

Notes:

- The build injects the base path; `Router.init(~basePath=…)` reads Vite's
  `BASE_URL`, so client-side routing and deep links resolve under the subpath.
- Deep links (e.g. `/prescriptive/a/button`) are served through `404.html`
  (a copy of `index.html`), which boots the app and lets the router take over —
  the standard SPA pattern for a static host.
- For a custom domain / user site served from `/`, no base is needed; the same
  build works with `BASE_PATH=/` (the default).

## Verify (optional)

```bash
npm run smoke        # drives every /a/:id route in headless Chromium,
                     # asserting each renders with no console errors
```

Requires a Chromium available to `playwright-core`.

## Adding a live example

1. Add a `@jsx.component` module to `src/Examples.res`.
2. Register it in `Examples.get` under the spec's `id`.
3. Recompile — the detail page picks it up automatically.

Keep examples framework-idiomatic and monochrome: reach for the shared tokens in
`Ui.res` (`btnPrimary`, `inputBase`, `card`, …) so every example reads as one
system.
