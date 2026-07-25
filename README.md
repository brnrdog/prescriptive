# Prescriptive

A catalogue of **UX specs** — reusable, technology-agnostic definitions of UI
patterns, written to be a shared source of truth for **humans and AI agents**.
They span the full experience: from the smallest interface element up to
complete pages and flows.

> A spec describes **what** a pattern _is_, **when** to use it, how it is
> **composed**, how it **behaves**, and how it stays **accessible** — without
> prescribing a framework, styling approach, or a single visual design.

That makes each spec portable across projects, contexts, and tech stacks while
keeping the meaning of the pattern consistent everywhere. A spec is a
_specification of intent and structure_, not an implementation — each project
maps specs onto its own tokens, framework, and visual language.

---

## Why this exists

Design systems and component libraries get re-invented on every project and
every stack. The visual skin and the framework change, but the underlying
_pattern_ — what a Button is, what a Navbar must do, what a Dashboard is for —
does not. Prescriptive captures those stable patterns once, so they can be:

- **Reused** across projects and stacks (React, Vue, SwiftUI, design tools, …).
- **Referenced** by AI agents as a source of truth when generating UI.
- **Composed** from small units into components and full pages.
- **Enforced** — the specs carry machine-readable contracts that tooling checks.
- **Versioned** so changes are explicit and traceable.

---

## Taxonomy: layers

Specs are organized into five **layers**, from the smallest unit to the complete
experience — one directory per layer, one Markdown file per spec.

| Layer         | Directory            | What it is | Examples |
| ------------- | -------------------- | ---------- | -------- |
| **Element**   | `specs/elements/`    | An indivisible UI unit with a single responsibility. | button, input, badge, avatar, checkbox, spinner |
| **Component** | `specs/components/`  | A self-contained pattern composed of elements. | navbar, card, form, dialog, data-table, tabs |
| **Block**     | `specs/blocks/`      | A page-level section composed toward one purpose. | hero, feature-grid, pricing-table, faq, cta-section |
| **Page**      | `specs/pages/`       | A full-screen spec composing components and blocks toward one goal. | landing-page, dashboard, sign-in, pricing, settings |
| **Flow**      | `specs/flows/`       | A multi-step journey across pages toward an outcome. | authentication, onboarding, checkout |

The layer of a spec is declared in its metadata (`layer:`) **and** reflected by
the directory it lives in. Alongside the layers, two cross-cutting catalogues
capture shared concerns once:

- **`traits/`** — reusable interaction contracts (`dismissible`, `focus-trap`,
  `anchored`, `roving-focus`, `typeahead`) that many specs reference instead of
  re-describing them.
- **`responsive/`** — the vocabulary of reflow patterns (`stack`,
  `collapse-to-menu`, `to-sheet`, `reflow-to-cards`, …) that specs bind to.

---

## The spec document

Every spec follows the **same document pattern** so it's predictable for readers
and machines. It has a YAML frontmatter block (schema:
[`schema/spec.schema.json`](schema/spec.schema.json)) and a fixed set of body
sections (template: [`templates/SPEC_TEMPLATE.md`](templates/SPEC_TEMPLATE.md)).

Beyond the human prose, an implementable spec carries **machine-readable
contracts** that the build validates:

- **`## API`** — a JSON contract naming the `props` (with types, enum values,
  defaults), `slots`, `events`, `a11y` (role, keyboard, announcements),
  `states`, the design-token `tokens` it consumes, and a `responsive` block
  (`container`, `minTarget`, and a `reflow` list bound to breakpoints).
- **`## Composition`** — a JSON block wiring each part to a `slot` with the
  `props` passed, so the composition graph is explicit.
- **`traits:`** frontmatter — the shared behaviors the spec exhibits.

These are what let an agent (or a component library) implement a spec **to a
contract** rather than improvising prop names, states, and accessibility.

---

## Packages

The repository is an npm-workspaces monorepo. The framework itself (the specs,
tokens, traits, responsive vocabulary, schema, templates) is the root package;
derived, consumable artifacts live under [`packages/`](packages/):

| Package | What it is |
| ------- | ---------- |
| **`prescriptive`** (root) | The spec catalogue + design tokens — the source of truth every package below is generated from. |
| **[`@prescriptive/tokens`](packages/tokens)** | The design tokens as ready-to-use artifacts: CSS custom properties, a **Tailwind v4 preset**, `[data-theme]`/`[data-mode]` overlays, and a typed JS export. |
| **[`@prescriptive/xote`](packages/xote)** | Accessible [Xote](https://xote.dev)/ReScript components implementing the specs. Their prop types are generated from each spec's `## API`, so the compiler enforces they can't drift. Styled via `@prescriptive/tokens`. |
| **[`@prescriptive/reativa`](packages/reativa)** | The same catalogue implemented for [reativa](https://github.com/brnrdog/reativa) (OCaml + Melange) — the ReasonML/OCaml sibling of `@prescriptive/xote`. Written in `.mlx` over `Reativa.View` (no virtual DOM), prop types likewise generated from each spec's `## API`, styled via `@prescriptive/tokens`. |
| **[`skill/`](skill/)** | An **Agent Skill** — the specs, traits, tokens, and responsive vocabulary compiled into a reference an AI coding agent loads to implement UI to the contracts. |

Each package is generated from the framework source, so nothing downstream can
drift from the specs. See each package's README for usage.

`@prescriptive/reativa` builds through Melange and so needs an OCaml toolchain
(opam switch on OCaml 5.1+); it is kept out of `npm run build:packages` for that
reason and built on its own (`npm run build --workspace @prescriptive/reativa`),
which CI does. See [`packages/reativa/README.md`](packages/reativa/README.md).

---

## Versioning

The framework uses **[Semantic Versioning](https://semver.org/)** at two levels,
tracked in [`package.json`](package.json) and [`CHANGELOG.md`](CHANGELOG.md).

- **Collection version** — MAJOR for a breaking change to the document pattern
  or schema (or removing a spec); MINOR for a new spec or compatible
  schema/template addition; PATCH for clarifications and fixes.
- **Per-spec version** — each spec carries its own `version` under the same
  rules, scoped to that one document. The `status` field tracks lifecycle:
  `draft`, `stable`, `deprecated`.

---

## Guarantees (build gates)

Because the specs are structured, the build **checks** them (`npm run checks` in
`website/`, run in CI). Drift fails the build:

- **conformance** — every mapped component implements its contract's props/enums.
- **conformance:traits** — every trait claim is backed by the required keys.
- **conformance:composition** — every composition `ref` resolves and every
  `slot` is declared.
- **conformance:tokens** — every token role a contract references exists.
- **conformance:responsive** — every spec declares `responsive`, with a known
  pattern and a real breakpoint.

---

## Repository layout

```
prescriptive/                        # root workspace = the `prescriptive` spec + tokens source
├── specs/                    # the catalogue, one file per spec
│   ├── elements/  components/  blocks/  pages/  flows/
├── traits/                   # shared interaction contracts
├── responsive/               # reflow-pattern vocabulary (patterns.json)
├── tokens/                   # design tokens (W3C DTCG) + themes.json
├── schema/                   # JSON Schemas (spec, api, trait)
├── templates/                # SPEC_TEMPLATE.md — the document pattern to copy
├── skill/                    # the distributable Agent Skill
├── packages/
│   ├── tokens/               # @prescriptive/tokens  (CSS vars, Tailwind preset, JS)
│   ├── xote/                 # @prescriptive/xote    (Xote/ReScript components)
│   └── reativa/              # @prescriptive/reativa (reativa/OCaml + Melange components)
├── website/                  # interactive catalogue (Vite + ReScript + Xote)
├── INDEX.md                  # generated registry of every spec
└── CHANGELOG.md
```

See [`INDEX.md`](INDEX.md) for the full, current list of specs.

---

## Design tokens

Specs describe _structure and behavior_ and avoid pixels and hues on purpose.
The concrete values — color, type, spacing, radius, elevation, motion,
breakpoints — live in [`tokens/`](tokens/) in the standard
**[W3C Design Tokens (DTCG) format](https://www.w3.org/community/design-tokens/)**,
with ready-made themes in [`themes.json`](tokens/themes.json). Consume them as
CSS variables, a Tailwind preset, or a JS object via
[`@prescriptive/tokens`](packages/tokens). See [`tokens/README.md`](tokens/README.md).

## Website

An interactive catalogue lives in [`website/`](website/): it lists every spec,
renders a **live example** of each, shows the API contract and responsive
behavior, and lets you retheme the whole site live from the design tokens. Each
example can be switched between the two **implementations** — `@prescriptive/xote`
(ReScript) and `@prescriptive/reativa` (OCaml) — so you can compare the rendered
result and the source side by side. Built with Vite, ReScript,
[Xote](https://xote.dev), and Tailwind CSS. See
[`website/README.md`](website/README.md) to run it.

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md). In short: copy the template, fill in
the metadata and every section (including the `## API` contract for
implementable specs), keep the `id`/filename/layer in sync, and bump the
versions and changelog.

## License

[MIT](LICENSE).
