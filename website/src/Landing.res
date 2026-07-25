// The landing page for Prescriptive itself — and a live proof of the framework:
// it follows the `landing-page` spec's anatomy (hero → social proof → how it
// works → features → proof → FAQ → closing CTA → footer), it is composed from
// the spec components (`@prescriptive/xote`), and every surface is painted with
// the semantic token roles (bg-paper, text-ink, bg-action…), so picking a theme
// in the strip below re-skins the whole page live.
//
// One primary action, repeated at each decision point: "Get started".

let repo = "https://github.com/brnrdog/prescriptive"

// --- Catalogue figures, read from the generated registries so the page can't
// --- claim a number the catalogue doesn't back.
let inLayer = layer => SpecsData.all->Array.filter(a => a.layer == layer)
let count = layer => inLayer(layer)->Array.length->Int.toString
let specCount = SpecsData.all->Array.length->Int.toString
let traitCount = TraitsData.all->Array.length->Int.toString
let tokenCount =
  TokensData.all->Array.reduce(0, (n, g) => n + Array.length(g.tokens))->Int.toString
let themeCount = ThemesData.all->Array.length->Int.toString

// Where a layer links into the catalogue — its first spec.
let firstOf = layer =>
  switch inLayer(layer)->Array.get(0) {
  | Some(a) => "/a/" ++ a.id
  | None => "/"
  }

// The catalogue's front door: Button is the canonical first spec to read, with
// the first element as a fallback if it ever leaves the catalogue.
let entry = SpecsData.all->Array.some(a => a.id == "button") ? "/a/button" : firstOf("element")

// A real excerpt of the button spec's `## API` block — the contract an
// implementation (or an agent) is held to.
let contract = `{
  "props": [
    { "name": "variant", "type": "enum",
      "values": ["primary", "secondary",
                 "ghost", "destructive"],
      "default": "primary" },
    { "name": "size", "type": "enum",
      "values": ["sm", "md", "lg"] },
    { "name": "loading", "type": "boolean",
      "default": "false" }
  ],
  "slots": ["label", "leadingIcon", "trailingIcon"],
  "events": ["onActivate"],
  "a11y": {
    "role": "button",
    "keyboard": ["Enter", "Space"],
    "announces": ["disabled", "busy"]
  },
  "states": ["default", "hover", "focus-visible",
             "active", "disabled", "loading"],
  "tokens": ["color.action.*", "radius.md",
             "space.inline.*", "font.weight.medium"]
}`

// The semantic color roles a spec's contract is allowed to name. Each chip
// reads the live --ux-* variable, so a theme change repaints them in place.
let roles = [
  ("action", "--ux-color-action-default", "Primary action"),
  ("on-action", "--ux-color-action-onAction", "Text on an action"),
  ("action-subtle", "--ux-color-action-subtle", "Quiet action wash"),
  ("ink", "--ux-color-ink", "Body text"),
  ("muted", "--ux-color-muted", "Secondary text"),
  ("surface", "--ux-color-surface", "Raised surface"),
  ("paper", "--ux-color-paper", "Page background"),
  ("border", "--ux-color-border", "Hairlines"),
  ("status-success", "--ux-color-status-success", "Success"),
  ("status-danger", "--ux-color-status-danger", "Danger"),
]

// A full-width band with the page's reading measure inside it.
module Section = {
  @jsx.component
  let make = (~extraClass: string="", ~children: View.node) =>
    <section class={"mx-auto w-full max-w-6xl px-5 sm:px-8 " ++ extraClass}> {children} </section>
}

// Eyebrow + title + lede, the heading shape every band below repeats.
module Head = {
  @jsx.component
  let make = (~eyebrow: string, ~title: string, ~desc: string="") =>
    <div class="max-w-2xl">
      <p class="text-xs font-semibold uppercase tracking-widest text-muted">
        <View.Text> eyebrow </View.Text>
      </p>
      <h2 class="mt-3 text-3xl font-bold tracking-tight text-ink sm:text-4xl">
        <View.Text> title </View.Text>
      </h2>
      {desc == ""
        ? View.null()
        : <p class="mt-4 text-lg leading-relaxed text-muted"> <View.Text> desc </View.Text> </p>}
    </div>
}

// A dark code surface with a filename gutter — used for the contract and for
// the agent-skill setup.
module Code = {
  @jsx.component
  let make = (~label: string, ~code: string, ~extraClass: string="") =>
    <div
      class={"overflow-hidden rounded-2xl border border-neutral-800 bg-neutral-900 shadow-md " ++
      extraClass}>
      <div class="flex items-center gap-2 border-b border-neutral-800 px-4 py-2.5">
        <Icon name="align-left" size=#xs extraClass="text-neutral-500" />
        <span class="font-mono text-[11px] text-neutral-400"> <View.Text> label </View.Text> </span>
      </div>
      <pre class="overflow-x-auto p-4 text-[11px] leading-relaxed text-neutral-100 sm:text-xs">
        <code class="font-mono"> <View.Text> code </View.Text> </code>
      </pre>
    </div>
}

// The install line, click-to-copy.
module CopyCommand = {
  @jsx.component
  let make = (~cmd: string) => {
    let copied = Signal.make(false)
    <button
      class="group inline-flex items-center gap-3 rounded-xl border border-border bg-surface px-4 py-2.5 shadow-sm transition-colors hover:border-neutral-400"
      onClick={_ => {
        Ui.copyToClipboard(cmd)
        Signal.set(copied, true)
        Ui.setTimeout(() => Signal.set(copied, false), 1500)
      }}>
      <span class="font-mono text-sm text-ink"> <View.Text> {"$ " ++ cmd} </View.Text> </span>
      <span class="text-muted transition-colors group-hover:text-ink">
        <View.Show when_={Prop.signal(copied)} fallback={<Icon name="copy" size=#sm />}>
          <Icon name="check" size=#sm />
        </View.Show>
      </span>
    </button>
  }
}

// Pick a theme (and light/dark) right from the page — the same presets the
// settings panel applies, so the proof is immediate: nothing here is hardcoded.
module ThemeStrip = {
  @jsx.component
  let make = () => {
    let modeCls = dark =>
      Computed.make(() =>
        "inline-flex items-center gap-1.5 rounded-full px-3 py-1.5 text-xs font-medium transition-colors " ++ (
          Signal.get(Settings.darkMode) == dark
            ? "bg-action text-on-action"
            : "text-muted hover:text-ink"
        )
      )
    <div class="flex flex-wrap items-center gap-2">
      <View.For
        each={Prop.static(ThemesData.all)}
        by={t => t.id}
        render={t => {
          let cls = Computed.make(() =>
            "inline-flex items-center gap-2 rounded-full border px-3 py-1.5 text-xs font-medium transition-colors " ++ (
              Signal.get(Settings.presetSel) == t.id
                ? "border-action bg-action-subtle text-ink"
                : "border-border text-muted hover:border-neutral-400 hover:text-ink"
            )
          )
          <button class={Prop.signal(cls)} onClick={_ => Settings.applyPreset(t)}>
            <span class="flex -space-x-1" ariaHidden="true">
              <View.For
                each={Prop.static(t.swatches)}
                render={s =>
                  <span
                    class="size-3 rounded-full ring-1 ring-inset ring-neutral-400/40"
                    style={"background:" ++ s}
                  />}
              />
            </span>
            <View.Text> {t.label} </View.Text>
          </button>
        }}
      />
      <span class="ml-1 inline-flex items-center gap-0.5 rounded-full border border-border p-0.5">
        <button class={Prop.signal(modeCls(false))} onClick={_ => Settings.setDark(false)}>
          <Icon name="sun" size=#xs />
          <View.Text> "Light" </View.Text>
        </button>
        <button class={Prop.signal(modeCls(true))} onClick={_ => Settings.setDark(true)}>
          <Icon name="moon" size=#xs />
          <View.Text> "Dark" </View.Text>
        </button>
      </span>
    </div>
  }
}

// The hero's right-hand pane: real components, live and interactive, rendered
// from the same contracts the left-hand pane shows.
module LiveSurface = {
  @jsx.component
  let make = () => {
    let notify = Signal.make(true)
    let progress = Signal.make(72)
    <div class="preview-surface rounded-2xl border border-border p-5 shadow-sm">
      <div class="flex flex-wrap items-center gap-2">
        <Button size=#sm> <View.Text> "Primary" </View.Text> </Button>
        <Button variant=#secondary size=#sm> <View.Text> "Secondary" </View.Text> </Button>
        <Button variant=#ghost size=#sm> <View.Text> "Ghost" </View.Text> </Button>
        <Button variant=#primary size=#sm loading=true> <View.Text> "Loading" </View.Text> </Button>
      </div>
      <div class="mt-4 flex flex-wrap items-center gap-2">
        <Badge variant=#solid> <View.Text> "stable" </View.Text> </Badge>
        <Badge variant=#soft> <View.Text> "element" </View.Text> </Badge>
        <Badge variant=#outline> <View.Text> "v1.2.0" </View.Text> </Badge>
        <Avatar initials="AL" size="size-7 text-[10px]" />
      </div>
      <div class="mt-4"> <Switch checked={notify} label="Email me about releases" /> </div>
      <div class="mt-4"> <Progress value={progress} /> </div>
      <div class="mt-4">
        <Alert
          variant=#success
          title="Conformance passed"
          description="Every prop, trait, and token role matches the spec."
        />
      </div>
    </div>
  }
}

// The role palette, read straight from the live custom properties — the layer
// specs are allowed to name. Repaints itself when a theme is applied.
module RoleSwatches = {
  @jsx.component
  let make = () =>
    <div class={Ui.card ++ " p-5"}>
      <div class="flex items-center justify-between gap-3">
        <h3 class="text-sm font-semibold text-ink"> <View.Text> "Semantic roles" </View.Text> </h3>
        <span class="font-mono text-[11px] text-muted"> <View.Text> "tokens.json" </View.Text> </span>
      </div>
      <p class="mt-1 text-xs leading-relaxed text-muted">
        <View.Text>
          "What a contract may reference. Never a hex value — that's the theme's job."
        </View.Text>
      </p>
      <ul class="mt-4 space-y-2">
        <View.For
          each={Prop.static(roles)}
          render={role => {
            let (name, var, desc) = role
            <li class="flex items-center gap-3">
              <span
                class="size-6 shrink-0 rounded-md border border-border"
                style={"background: var(" ++ var ++ ")"}
              />
              <span class="font-mono text-xs text-ink"> <View.Text> name </View.Text> </span>
              <span class="ml-auto truncate text-xs text-muted"> <View.Text> desc </View.Text> </span>
            </li>
          }}
        />
      </ul>
    </div>
}

// One benefit card.
module Feature = {
  @jsx.component
  let make = (~icon: string, ~title: string, ~desc: string) =>
    <div class={Ui.card ++ " p-5"}>
      <span class="flex size-9 items-center justify-center rounded-lg bg-action-subtle text-action">
        <Icon name=icon size=#sm />
      </span>
      <h3 class="mt-4 text-sm font-semibold text-ink"> <View.Text> title </View.Text> </h3>
      <p class="mt-1.5 text-sm leading-relaxed text-muted"> <View.Text> desc </View.Text> </p>
    </div>
}

// A layer of the taxonomy: how many specs it holds, what it's for, and a way in.
module LayerCard = {
  @jsx.component
  let make = (~layer: string, ~title: string, ~desc: string) =>
    <Router.Link to={firstOf(layer)} class={Ui.cardInteractive ++ " group flex flex-col p-5"}>
      <div class="flex items-baseline justify-between gap-2">
        <span class="text-3xl font-bold tabular-nums tracking-tight text-ink">
          <View.Text> {count(layer)} </View.Text>
        </span>
        <span
          class={"inline-flex items-center rounded-md px-2 py-0.5 text-[10px] font-semibold uppercase tracking-wide " ++
          Ui.layerBadge(layer)}>
          <View.Text> layer </View.Text>
        </span>
      </div>
      <span class="mt-3 text-sm font-semibold text-ink"> <View.Text> title </View.Text> </span>
      <span class="mt-1 text-sm leading-relaxed text-muted"> <View.Text> desc </View.Text> </span>
      <span
        class="mt-3 inline-flex items-center gap-1 text-xs font-medium text-muted transition-colors group-hover:text-ink">
        <View.Text> "Open" </View.Text>
        <Icon name="arrow-right" size=#xs />
      </span>
    </Router.Link>
}

// The FAQ disclosures. Built on native `details`/`summary` so the expanded
// state, keyboard operation, and the announcement come from the platform — the
// `dismissible`-style state doesn't have to be re-implemented (or mis-announced)
// in script.
module Faq = {
  @jsx.component
  let make = (~items: array<(string, string)>) =>
    <div class="divide-y divide-border overflow-hidden rounded-2xl border border-border bg-surface">
      <View.For
        each={Prop.static(items)}
        render={item => {
          let (q, a) = item
          <details class="group">
            <summary
              class="flex cursor-pointer list-none items-center justify-between gap-4 px-5 py-4 transition-colors hover:bg-action-subtle focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-action [&::-webkit-details-marker]:hidden">
              <span class="text-sm font-medium text-ink"> <View.Text> q </View.Text> </span>
              <span class="text-muted transition-transform duration-200 group-open:rotate-180">
                <Icon name="chevron-down" size=#sm />
              </span>
            </summary>
            <p class="px-5 pb-4 text-sm leading-relaxed text-muted"> <View.Text> a </View.Text> </p>
          </details>
        }}
      />
    </div>
}

module Footer = {
  @jsx.component
  let make = () => {
    let internal = (to, label) =>
      <li>
        <Router.Link to class="text-sm text-muted transition-colors hover:text-ink">
          <View.Text> label </View.Text>
        </Router.Link>
      </li>
    let outbound = (href, label) =>
      <li>
        <a
          href
          target="_blank"
          class="text-sm text-muted transition-colors hover:text-ink">
          <View.Text> label </View.Text>
        </a>
      </li>
    let column = (title, children) =>
      <div>
        <h3 class="text-xs font-semibold uppercase tracking-widest text-muted">
          <View.Text> title </View.Text>
        </h3>
        <ul class="mt-3 space-y-2"> {children} </ul>
      </div>
    <footer class="border-t border-border bg-surface">
      <div class="mx-auto w-full max-w-6xl px-5 py-12 sm:px-8">
        <div class="grid gap-10 sm:grid-cols-2 lg:grid-cols-4">
          <div>
            <div class="flex items-center gap-2">
              <span
                class="flex size-7 items-center justify-center rounded-lg bg-action text-xs font-bold text-on-action">
                <View.Text> "P" </View.Text>
              </span>
              <span class="text-sm font-semibold tracking-tight text-ink">
                <View.Text> "Prescriptive" </View.Text>
              </span>
            </div>
            <p class="mt-3 max-w-xs text-sm leading-relaxed text-muted">
              <View.Text>
                "A technology-agnostic catalogue of UX specs — a shared source of truth for humans and AI agents."
              </View.Text>
            </p>
          </div>
          {column(
            "Catalogue",
            <>
              {internal(firstOf("element"), "Elements")}
              {internal(firstOf("component"), "Components")}
              {internal(firstOf("block"), "Blocks")}
              {internal(firstOf("page"), "Pages")}
              {internal(firstOf("flow"), "Flows")}
            </>,
          )}
          {column(
            "Explore",
            <>
              {internal("/guide", "Get started")}
              {internal("/showcase", "Examples")}
              {internal("/kitchen-sink", "Kitchen sink")}
              {internal("/tokens", "Design tokens")}
            </>,
          )}
          {column(
            "Project",
            <>
              {outbound(repo, "GitHub")}
              {outbound(repo ++ "/blob/main/skill/SKILL.md", "Agent Skill")}
              {outbound(repo ++ "/blob/main/CONTRIBUTING.md", "Contributing")}
              {outbound(repo ++ "/blob/main/CHANGELOG.md", "Changelog")}
              {outbound(repo ++ "/blob/main/LICENSE", "MIT License")}
            </>,
          )}
        </div>
        <div
          class="mt-10 flex flex-col gap-2 border-t border-border pt-6 text-xs text-muted sm:flex-row sm:items-center sm:justify-between">
          <span> <View.Text> "MIT licensed. Specs, tokens, and contracts are free to use." </View.Text> </span>
          <span class="inline-flex items-center gap-1.5">
            <View.Text> "Built with " </View.Text>
            <Link href="https://xote.dev" newTab=true variant=#muted> <View.Text> "Xote" </View.Text> </Link>
            <View.Text> " · themed by its own tokens" </View.Text>
          </span>
        </div>
      </div>
    </footer>
  }
}

@jsx.component
let make = () =>
  <div class="bg-paper">
    // ------------------------------------------------------------------ Hero --
    <div class="hero-wash border-b border-border">
      <Section extraClass="pb-16 pt-14 sm:pt-20">
        <div class="grid items-center gap-12 lg:grid-cols-[minmax(0,1fr)_minmax(0,1fr)]">
          <div class="min-w-0">
            <Badge variant=#outline>
              <View.Text> {"Open source · " ++ specCount ++ " specs · MIT"} </View.Text>
            </Badge>
            <h1
              class="mt-6 text-4xl font-bold leading-[1.05] tracking-tight text-ink sm:text-5xl lg:text-6xl">
              <View.Text> "Specify the pattern once." </View.Text>
              <br />
              <span class="text-muted"> <View.Text> "Implement it anywhere." </View.Text> </span>
            </h1>
            <p class="mt-6 max-w-xl text-lg leading-relaxed text-muted">
              <View.Text>
                "Prescriptive is a catalogue of UX specs — reusable, technology-agnostic definitions of UI patterns. Every pattern carries a machine-readable contract: props, slots, events, states, keyboard behavior, and the design tokens it consumes. People and AI agents build from the same source of truth."
              </View.Text>
            </p>
            <div class="mt-8 flex flex-wrap items-center gap-3">
              <Router.Link to="/guide">
                <Button variant=#primary size=#lg>
                  <View.Text> "Get started" </View.Text>
                  <Icon name="arrow-right" size=#sm />
                </Button>
              </Router.Link>
              <Router.Link to=entry>
                <Button variant=#secondary size=#lg>
                  <View.Text> "Browse the catalogue" </View.Text>
                </Button>
              </Router.Link>
              <Link
                href=repo
                newTab=true
                variant=#muted
                extraClass="inline-flex items-center gap-1.5 text-sm">
                <Icon name="github" size=#sm />
                <View.Text> "GitHub" </View.Text>
              </Link>
            </div>
            <div class="mt-6 flex flex-wrap items-center gap-3">
              <CopyCommand cmd="npm i prescriptive" />
              <span class="text-xs text-muted">
                <View.Text> "Specs, tokens, and contracts — no runtime." </View.Text>
              </span>
            </div>
          </div>
          <div class="min-w-0 space-y-3">
            <div class="flex items-center justify-between gap-3">
              <span class="text-xs font-semibold uppercase tracking-widest text-muted">
                <View.Text> "The contract" </View.Text>
              </span>
              <span class="hidden items-center gap-1 text-xs text-muted sm:inline-flex">
                <View.Text> "one spec" </View.Text>
                <Icon name="arrow-down" size=#xs />
                <View.Text> "any implementation" </View.Text>
              </span>
            </div>
            <Code label="specs/elements/button.md — ## API" code=contract />
            <div class="flex items-center justify-between gap-3 pt-1">
              <span class="text-xs font-semibold uppercase tracking-widest text-muted">
                <View.Text> "An implementation" </View.Text>
              </span>
              <span class="text-xs text-muted"> <View.Text> "live, and themeable" </View.Text> </span>
            </div>
            <LiveSurface />
          </div>
        </div>
      </Section>
    </div>

    // --------------------------------------------------------- Social proof --
    <Section extraClass="py-10">
      <LogoCloud
        heading="One contract, any stack"
        logos=["React", "Vue", "Svelte", "SwiftUI", "Flutter", "ReScript", "Web Components"]
      />
    </Section>

    // ------------------------------------------------------------- The trade --
    <Section extraClass="py-14">
      <Head
        eyebrow="Why"
        title="The skin changes. The pattern doesn't."
        desc="Design systems get re-invented on every project and every stack. The framework and the visual language change — but what a Button is, what a Dialog must do, and how a Data Table stays accessible do not. Prescriptive captures the durable part once."
      />
      <div class="mt-10 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        <Feature
          icon="target"
          title="A contract, not a suggestion"
          desc="Props with types, enum values, and defaults. Named slots, events, states, and the token roles consumed — as JSON your tooling can read."
        />
        <Feature
          icon="check-circle"
          title="Accessible by construction"
          desc="Every spec names its role, its keyboard map, and what must be announced. Shared behaviors are specified once and referenced, not re-derived."
        />
        <Feature
          icon="align-left"
          title="Composable in five layers"
          desc="Elements compose into components, components into blocks, blocks into pages, pages into flows — with the wiring made explicit."
        />
        <Feature
          icon="moon"
          title="Token-driven theming"
          desc="Specs bind to semantic roles — action, ink, surface, border, status — never to hex values. A re-theme is a token change, not a rewrite."
        />
        <Feature
          icon="zap"
          title="Built for agents"
          desc="Ship the bundled Agent Skill and your AI implements to the contract instead of improvising prop names, states, and keyboard behavior."
        />
        <Feature
          icon="lock"
          title="Drift fails the build"
          desc="Conformance checks verify props, trait claims, composition refs, token roles, and responsive behavior on every commit."
        />
      </div>
    </Section>

    // ------------------------------------------------------------ The layers --
    <div class="border-y border-border bg-surface/40">
      <Section extraClass="py-14">
        <Head
          eyebrow="The catalogue"
          title="From the smallest unit to the whole journey"
          desc="One directory per layer, one Markdown file per spec — declared in the spec's metadata and checked by the build."
        />
        <div class="mt-10 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          <LayerCard
            layer="element"
            title="Elements"
            desc="Indivisible units with a single responsibility — button, input, badge, avatar."
          />
          <LayerCard
            layer="component"
            title="Components"
            desc="Self-contained patterns composed of elements — dialog, tabs, form, data-table."
          />
          <LayerCard
            layer="block"
            title="Blocks"
            desc="Page-level sections built toward one purpose — hero, pricing-table, FAQ."
          />
          <LayerCard
            layer="page"
            title="Pages"
            desc="Full-screen specs composing components and blocks — dashboard, sign-in, pricing."
          />
          <LayerCard
            layer="flow"
            title="Flows"
            desc="Multi-step journeys toward an outcome — authentication, onboarding, checkout."
          />
          <div class={Ui.card ++ " flex flex-col justify-between gap-4 p-5"}>
            <div>
              <h3 class="text-sm font-semibold text-ink">
                <View.Text> "Cross-cutting catalogues" </View.Text>
              </h3>
              <p class="mt-1.5 text-sm leading-relaxed text-muted">
                <View.Text>
                  {traitCount ++
                  " shared behaviors (focus-trap, dismissible, roving-focus…) and a reflow vocabulary every spec binds to, so a dialog and a drawer don't each re-describe the same rules."}
                </View.Text>
              </p>
            </div>
            <div class="flex flex-wrap gap-2">
              <View.For
                each={Prop.static(TraitsData.all)}
                by={t => t.id}
                render={t =>
                  <Router.Link
                    to={"/t/" ++ t.id}
                    class="inline-flex items-center rounded-full border border-border px-2.5 py-0.5 text-xs text-muted transition-colors hover:border-neutral-400 hover:text-ink">
                    <View.Text> {t.id} </View.Text>
                  </Router.Link>}
              />
            </div>
          </div>
        </div>
      </Section>
    </div>

    // ---------------------------------------------------------- How it works --
    <Section extraClass="py-14">
      <Head
        eyebrow="How it works"
        title="Three steps from pattern to production"
      />
      <div class="mt-10">
        <Steps
          steps=[
            (
              "Browse",
              "Find the pattern in the catalogue. Read its intent, its contract, and the live example — then decide if it's the right one.",
            ),
            (
              "Take the contract",
              "Props, slots, events, states, accessibility, and token roles, as JSON your build tooling or your agent can consume.",
            ),
            (
              "Implement and verify",
              "Build it in your stack against the contract, then let the conformance checks catch any drift before it ships.",
            ),
          ]
        />
      </div>
    </Section>

    // ---------------------------------------------------------- Agent Skill --
    <div class="border-y border-border bg-surface/40">
      <Section extraClass="py-14">
        <div class="grid items-center gap-10 lg:grid-cols-2">
          <div class="min-w-0">
            <Head
              eyebrow="For AI agents"
              title="Hand your agent the specs, not a screenshot"
              desc="The catalogue compiles into an Agent Skill: every contract, trait, token, and reflow pattern as structured reference. The agent looks up the pattern, reads its contract, and implements to it — in whatever framework you're working in."
            />
            <div class="mt-6 flex flex-wrap items-center gap-3">
              <Link
                href={repo ++ "/blob/main/skill/SKILL.md"}
                newTab=true
                extraClass="inline-flex items-center gap-1.5 text-sm font-medium">
                <View.Text> "Read the skill" </View.Text>
                <Icon name="external-link" size=#xs />
              </Link>
              <Router.Link to="/guide">
                <Button variant=#secondary size=#sm> <View.Text> "Get started" </View.Text> </Button>
              </Router.Link>
            </div>
          </div>
          <Code
            label="add the skill to your agent"
            code=`npm i @prescriptive/skill

# drop it into your agent's skills directory
cp -r node_modules/@prescriptive/skill \\
      .claude/skills/prescriptive

# then just ask
> build the settings page from the spec`
          />
        </div>
      </Section>
    </div>

    // ----------------------------------------------------------- Theme proof --
    <Section extraClass="py-14">
      <div class="grid gap-10 lg:grid-cols-[minmax(0,1fr)_22rem]">
        <div class="min-w-0">
          <Head
            eyebrow="Design tokens"
            title="Change a token, re-skin everything"
            desc="Specs describe structure and behavior, never pixels and hues. The concrete values live in W3C DTCG tokens and reach components as semantic roles. Pick a theme — this whole page follows it."
          />
          <div class="mt-6"> <ThemeStrip /> </div>
          <div class="mt-6 flex flex-wrap items-center gap-3">
            <Router.Link to="/tokens">
              <Button variant=#secondary>
                <View.Text> "Edit the tokens live" </View.Text>
                <Icon name="arrow-right" size=#sm />
              </Button>
            </Router.Link>
            <Router.Link to="/kitchen-sink">
              <Button variant=#ghost> <View.Text> "See every component" </View.Text> </Button>
            </Router.Link>
          </div>
          <dl class="mt-8 grid grid-cols-2 gap-4 sm:grid-cols-4">
            <View.For
              each={Prop.static([
                (specCount, "specs"),
                (traitCount, "behaviors"),
                (tokenCount, "design tokens"),
                (themeCount, "themes"),
              ])}
              render={pair => {
                let (value, label) = pair
                <div class={Ui.card ++ " p-4"}>
                  <dt class="text-xs text-muted"> <View.Text> label </View.Text> </dt>
                  <dd class="mt-1 text-2xl font-bold tabular-nums tracking-tight text-ink">
                    <View.Text> value </View.Text>
                  </dd>
                </div>
              }}
            />
          </dl>
        </div>
        <div class="min-w-0 lg:pt-2"> <RoleSwatches /> </div>
      </div>
    </Section>

    // ------------------------------------------------------------------- FAQ --
    <div class="border-y border-border bg-surface/40">
      <Section extraClass="py-14">
        <div class="grid gap-10 lg:grid-cols-[minmax(0,22rem)_minmax(0,1fr)]">
          <div class="min-w-0">
            <Head eyebrow="FAQ" title="Questions, answered" />
            <p class="mt-4 text-sm leading-relaxed text-muted">
              <View.Text> "Everything else is in the " </View.Text>
              <Router.Link
                to="/guide"
                class="text-ink underline decoration-neutral-300 underline-offset-4 hover:decoration-neutral-900">
                <View.Text> "guide" </View.Text>
              </Router.Link>
              <View.Text> " — or open an issue on " </View.Text>
              <Link href=repo newTab=true> <View.Text> "GitHub" </View.Text> </Link>
              <View.Text> "." </View.Text>
            </p>
          </div>
          <Faq
            items=[
              (
                "Is this a component library?",
                "No — it's the layer above one. Prescriptive defines the patterns and their contracts; a component library is one implementation of them. @prescriptive/xote is the reference implementation, and yours can be another.",
              ),
              (
                "Does it lock me into a framework?",
                "No. A spec names structure, behavior, and accessibility — never a framework, a styling approach, or a single visual design. The same spec maps onto React, Vue, SwiftUI, or a design tool.",
              ),
              (
                "How is this different from a design system?",
                "A design system is a specific system for a specific product: its visual language, its components, its code. Prescriptive is the technology-agnostic definition underneath — the part that stays true when the skin and the stack change.",
              ),
              (
                "What keeps implementations honest?",
                "The contracts are machine-readable, so the build checks them: props and enum values, trait claims, composition references, token roles, and responsive behavior. Drift fails CI rather than shipping quietly.",
              ),
              (
                "How do AI agents use it?",
                "The catalogue is compiled into an Agent Skill. The agent looks the pattern up by id, reads its contract and traits, and implements to it — so you get the accessibility and the states you'd have had to spell out yourself.",
              ),
              (
                "Can I contribute a spec?",
                "Yes. Copy the template, fill in the metadata and every section (including the API contract), keep the id, filename, and layer in sync, and bump the versions and changelog.",
              ),
            ]
          />
        </div>
      </Section>
    </div>

    // ---------------------------------------------------------- Closing CTA --
    <Section extraClass="py-16">
      <div class="rounded-3xl bg-action px-6 py-14 text-center text-on-action sm:px-12">
        <h2 class="mx-auto max-w-2xl text-3xl font-bold tracking-tight sm:text-4xl">
          <View.Text> "Build your next interface to a contract." </View.Text>
        </h2>
        <p class="mx-auto mt-4 max-w-xl text-base leading-relaxed opacity-80">
          <View.Text>
            "Read the guide, pick a pattern, and implement it in your stack — or hand the specs to your agent and review the result."
          </View.Text>
        </p>
        <div class="mt-8 flex flex-wrap items-center justify-center gap-3">
          <Router.Link to="/guide">
            <Button variant=#secondary size=#lg>
              <View.Text> "Get started" </View.Text>
              <Icon name="arrow-right" size=#sm />
            </Button>
          </Router.Link>
          <a
            href=repo
            target="_blank"
            class="inline-flex items-center gap-1.5 rounded-lg px-4 py-2.5 text-base font-medium underline decoration-current/40 underline-offset-4 transition-opacity hover:opacity-80">
            <Icon name="github" size=#sm />
            <View.Text> "Star on GitHub" </View.Text>
          </a>
        </div>
        <p class="mt-6 text-xs opacity-70">
          <View.Text> {"MIT licensed · " ++ specCount ++ " specs · no runtime dependency"} </View.Text>
        </p>
      </div>
    </Section>

    <Footer />
  </div>
