// App shell: a topbar with spotlight search (⌘K), a collapsible sidebar of every
// spec, and a router that renders the overview or a spec detail page.

open SpecsData

let byId = id => all->Array.find(a => a.id == id)
let existsId = id => all->Array.some(a => a.id == id)
let inLayer = layer => all->Array.filter(a => a.layer == layer)

// Behavior traits (cross-cutting interaction contracts).
let traitById = id => TraitsData.all->Array.find(t => t.id == id)
let specsWithTrait = tid => all->Array.filter(a => a.traits->Array.includes(tid))
let layerPlural = layer => layer ++ "s"
let docUrl = a =>
  "https://github.com/brnrdog/prescriptive/blob/main/specs/" ++
  layerPlural(a.layer) ++ "/" ++ a.id ++ ".md"

let matches = (a, q) =>
  q == "" ||
  a.title->String.toLowerCase->String.includes(q) ||
  a.id->String.includes(q) ||
  a.summary->String.toLowerCase->String.includes(q)

// Global UI state shared across the shell.
// Sidebar is an in-flow rail on desktop and a slide-over drawer on mobile;
// start open only when there's room for the rail.
let isDesktop: unit => bool = %raw(`() => window.innerWidth >= 1024`)
let sidebarOpen = Signal.make(isDesktop())
let spotlightOpen = Signal.make(false)

// The landing page is the marketing front door: it owns the full width and
// carries its own nav and footer, so the docs rail steps aside while it's up
// and returns as soon as you enter the catalogue.
let onLanding = () => Computed.make(() => Signal.get(Router.location()).pathname == "/")
let notLanding = () => Computed.make(() => Signal.get(Router.location()).pathname != "/")

module LayerBadge = {
  @jsx.component
  let make = (~layer) =>
    <span
      class={"inline-flex items-center rounded-md px-2 py-0.5 text-[10px] font-semibold uppercase tracking-wide " ++
      Ui.layerBadge(layer)}>
      <View.Text> {layer} </View.Text>
    </span>
}

module Status = {
  @jsx.component
  let make = (~status) => {
    let dot = switch status {
    | "stable" => "bg-status-success"
    | "draft" => "bg-status-warning"
    | _ => "bg-status-danger"
    }
    <span class="inline-flex items-center gap-1.5 text-xs text-muted">
      <span class={"size-1.5 rounded-full " ++ dot} />
      <View.Text> {status} </View.Text>
    </span>
  }
}

module Chip = {
  @jsx.component
  let make = (~id) => {
    let base = "inline-flex items-center rounded-full border px-2.5 py-1 text-xs transition-colors"
    if existsId(id) {
      <Router.Link
        to={"/a/" ++ id}
        class={base ++ " border-neutral-300 text-neutral-700 hover:border-neutral-900 hover:text-neutral-900"}>
        <View.Text> {id} </View.Text>
      </Router.Link>
    } else {
      <span class={base ++ " border-dashed border-neutral-200 text-neutral-400"}>
        <View.Text> {id} </View.Text>
      </span>
    }
  }
}

// Structured composition: each part wired to a slot, with the props passed and
// an optional note. Parts group under their slot name.
module Composition = {
  @jsx.component
  let make = (~parts: array<SpecsData.compPart>) => {
    // Distinct slot names, in first-seen order.
    let slots = []
    parts->Array.forEach(p =>
      if !(slots->Array.includes(p.slot)) {
        slots->Array.push(p.slot)
      }
    )
    <div class="mt-10">
      <h3 class="text-xs font-semibold uppercase tracking-wide text-neutral-500">
        <View.Text> "Composition" </View.Text>
      </h3>
      <div class="mt-3 space-y-4">
        <View.For
          each={Prop.static(slots)}
          render={slot => {
            let inSlot = parts->Array.filter(p => p.slot == slot)
            <div class="rounded-xl border border-neutral-200 bg-surface p-4 shadow-sm">
              <div class="font-mono text-xs uppercase tracking-wide text-neutral-400">
                <View.Text> slot </View.Text>
              </div>
              <ul class="mt-2 space-y-2">
                <View.For
                  each={Prop.static(inSlot)}
                  render={p =>
                    <li class="flex flex-wrap items-center gap-2 text-sm">
                      <Chip id={p.compRef} />
                      <View.For
                        each={Prop.static(p.props)}
                        render={pair => {
                          let (k, v) = pair
                          <code class="rounded bg-neutral-100 px-1.5 py-0.5 font-mono text-xs text-neutral-700">
                            <View.Text> {k ++ "=" ++ v} </View.Text>
                          </code>
                        }}
                      />
                      <View.Show when_={Prop.static(p.note != "")}>
                        <span class="text-xs text-neutral-500"> <View.Text> {p.note} </View.Text> </span>
                      </View.Show>
                    </li>}
                />
              </ul>
            </div>
          }}
        />
      </div>
    </div>
  }
}

module ChipRow = {
  @jsx.component
  let make = (~title, ~ids) =>
    if Array.length(ids) == 0 {
      View.null()
    } else {
      <div class="space-y-2">
        <h3 class="text-xs font-semibold uppercase tracking-wide text-neutral-500">
          <View.Text> {title} </View.Text>
        </h3>
        <div class="flex flex-wrap gap-1.5">
          <View.For each={Prop.static(ids)} render={id => <Chip id />} />
        </div>
      </div>
    }
}

module SidebarGroup = {
  @jsx.component
  let make = (~layer, ~title) => {
    let items = inLayer(layer)
    <div class="mb-4">
      <div class="mb-1 flex items-center justify-between px-2">
        <span class="text-xs font-semibold uppercase tracking-wide text-neutral-500">
          <View.Text> {title} </View.Text>
        </span>
        <span class="text-xs tabular-nums text-neutral-400"> <View.Text> {Array.length(items)->Int.toString} </View.Text> </span>
      </div>
      <ul class="space-y-0.5">
        <View.For
          each={Prop.static(items)}
          by={a => a.id}
          render={a => {
            let cls = Computed.make(() => {
              let active = Signal.get(Router.location()).pathname == "/a/" ++ a.id
              "block rounded-lg px-2 py-1.5 text-sm transition-colors " ++ (
                active ? "bg-action text-on-action" : "text-neutral-700 hover:bg-neutral-100"
              )
            })
            <li>
              <Router.Link to={"/a/" ++ a.id} class={Prop.signal(cls)}>
                <View.Text> {a.title} </View.Text>
              </Router.Link>
            </li>
          }}
        />
      </ul>
    </div>
  }
}

module TraitsGroup = {
  @jsx.component
  let make = () => {
    let items = TraitsData.all
    <div class="mb-4">
      <div class="mb-1 flex items-center justify-between px-2">
        <span class="text-xs font-semibold uppercase tracking-wide text-neutral-500">
          <View.Text> "Behaviors" </View.Text>
        </span>
        <span class="text-xs tabular-nums text-neutral-400"> <View.Text> {Array.length(items)->Int.toString} </View.Text> </span>
      </div>
      <ul class="space-y-0.5">
        <View.For
          each={Prop.static(items)}
          by={t => t.id}
          render={t => {
            let cls = Computed.make(() => {
              let active = Signal.get(Router.location()).pathname == "/t/" ++ t.id
              "block rounded-lg px-2 py-1.5 text-sm transition-colors " ++ (
                active ? "bg-action text-on-action" : "text-neutral-700 hover:bg-neutral-100"
              )
            })
            <li>
              <Router.Link to={"/t/" ++ t.id} class={Prop.signal(cls)}>
                <View.Text> {t.title} </View.Text>
              </Router.Link>
            </li>
          }}
        />
      </ul>
    </div>
  }
}

module Sidebar = {
  @jsx.component
  let make = () => {
    // The rail is mounted once for the whole session and every state it has —
    // hidden on the landing page, collapsed, open — is expressed as a class.
    // Gating it on `View.Show` instead would rebuild its DOM on every
    // navigation (the condition re-renders its children whenever the route
    // signal fires, even when the condition itself is unchanged), and a rebuilt
    // <nav> starts back at scrollTop 0.
    let cls = Computed.make(() => {
      // Mobile: fixed drawer that slides in from the left below the topbar.
      // Desktop (lg): an in-flow rail that collapses its width.
      let base = "fixed bottom-0 left-0 top-14 z-40 w-64 shrink-0 overflow-hidden border-r border-neutral-200 bg-neutral-50 transition-transform duration-200 ease-out lg:static lg:top-0 lg:transition-[width] "
      let state = Signal.get(sidebarOpen)
        ? "translate-x-0 lg:w-64"
        : "-translate-x-full lg:w-0 lg:translate-x-0"
      let landing = Signal.get(Router.location()).pathname == "/"
      landing ? "hidden " ++ base ++ state : base ++ state
    })
    <aside class={Prop.signal(cls)}>
      <nav class="h-full w-64 overflow-y-auto p-2">
        {
          let link = (to, label) => {
            let cls = Computed.make(() => {
              let active = Signal.get(Router.location()).pathname == to
              "block rounded-lg px-2 py-1.5 text-sm font-medium transition-colors " ++ (
                active ? "bg-action text-on-action" : "text-neutral-700 hover:bg-neutral-100"
              )
            })
            <Router.Link to class={Prop.signal(cls)}> <View.Text> label </View.Text> </Router.Link>
          }
          <div class="mb-4 space-y-0.5">
            {link("/guide", "Get Started")}
            {link("/showcase", "Examples")}
            {link("/kitchen-sink", "Kitchen Sink")}
            {link("/tokens", "Design Tokens")}
          </div>
        }
        <SidebarGroup layer="element" title="Elements" />
        <SidebarGroup layer="component" title="Components" />
        <SidebarGroup layer="block" title="Blocks" />
        <SidebarGroup layer="page" title="Pages" />
        <SidebarGroup layer="flow" title="Flows" />
        <TraitsGroup />
      </nav>
    </aside>
  }
}

module Topbar = {
  @jsx.component
  let make = () => {
    let landing = onLanding()
    let docs = notLanding()
    // On the landing page the rail is hidden, so its toggle gives way to the
    // marketing nav.
    let navLink = (to, label) =>
      <Router.Link to class="text-sm text-muted transition-colors hover:text-ink">
        <View.Text> label </View.Text>
      </Router.Link>
    <header class="flex h-14 shrink-0 items-center gap-3 border-b border-neutral-200 bg-surface px-3">
      <View.Show when_={Prop.signal(docs)}>
        <IconButton label="Toggle sidebar" onClick={_ => Signal.update(sidebarOpen, v => !v)}>
          <Icon name="menu" />
        </IconButton>
      </View.Show>
      <Router.Link to="/" class="flex items-center gap-2 sm:pl-1">
        <span class="flex size-7 items-center justify-center rounded-lg bg-action text-xs font-bold text-on-action"> <View.Text> "P" </View.Text> </span>
        <span class="hidden text-sm font-semibold tracking-tight text-neutral-900 sm:block"> <View.Text> "Prescriptive" </View.Text> </span>
      </Router.Link>
      <View.Show when_={Prop.signal(landing)}>
        <nav class="hidden items-center gap-5 pl-4 md:flex">
          {navLink("/guide", "Get started")}
          {navLink("/a/button", "Specs")}
          {navLink("/showcase", "Examples")}
          {navLink("/tokens", "Tokens")}
        </nav>
      </View.Show>
      <div class="flex flex-1 justify-center">
        <button
          class="flex w-full min-w-0 max-w-sm items-center gap-2 rounded-lg border border-neutral-200 bg-neutral-50 px-3 py-1.5 text-sm text-neutral-400 transition-colors hover:bg-neutral-100"
          onClick={_ => Signal.set(spotlightOpen, true)}>
          <Icon name="search" size=#sm />
          <span class="flex-1 truncate text-left"> <View.Text> "Search specs…" </View.Text> </span>
          <span class="hidden sm:block"> <Kbd> <View.Text> "⌘K" </View.Text> </Kbd> </span>
        </button>
      </div>
      <Link
        href="https://github.com/brnrdog/prescriptive"
        variant=#muted
        newTab=true
        extraClass="hidden items-center gap-1.5 text-sm sm:inline-flex">
        <Icon name="github" size=#sm />
        <View.Text> "GitHub" </View.Text>
      </Link>
      <Settings.Trigger />
    </header>
  }
}

module Spotlight = {
  @jsx.component
  let make = () => {
    let q = Signal.make("")
    let active = Signal.make(0)
    let results = Computed.make(() => {
      let s = Signal.get(q)->String.toLowerCase
      all->Array.filter(a => matches(a, s))
    })
    // Reset + focus the input whenever the palette opens.
    Effect.run(() => {
      if Signal.get(spotlightOpen) {
        Signal.set(q, "")
        Signal.set(active, 0)
        Ui.focusById("spotlight-input")
      }
      None
    })
    let navigate = a => {
      Signal.set(spotlightOpen, false)
      Router.push("/a/" ++ a.id, ())
    }
    let onKey = e =>
      switch Ui.eventKey(e) {
      | "ArrowDown" =>
        Ui.preventDefault(e)
        Signal.update(active, i => {
          let n = Signal.get(results)->Array.length
          n == 0 ? 0 : mod(i + 1, n)
        })
      | "ArrowUp" =>
        Ui.preventDefault(e)
        Signal.update(active, i => {
          let n = Signal.get(results)->Array.length
          n == 0 ? 0 : mod(i - 1 + n, n)
        })
      | "Enter" =>
        switch Signal.get(results)->Array.get(Signal.get(active)) {
        | Some(a) => navigate(a)
        | None => ()
        }
      | "Escape" => Signal.set(spotlightOpen, false)
      | _ => ()
      }
    let empty = Computed.make(() => Signal.get(results)->Array.length == 0)
    <View.Show when_={Prop.signal(spotlightOpen)}>
      <div class="fixed inset-0 z-50 flex items-start justify-center p-4 pt-[12vh]">
        <div class="absolute inset-0 bg-neutral-900/40" onClick={_ => Signal.set(spotlightOpen, false)} />
        <div class="relative z-10 w-full max-w-lg overflow-hidden rounded-2xl border border-neutral-200 bg-surface shadow-lg">
          <div class="flex items-center gap-2 border-b border-neutral-100 px-4">
            <span class="text-neutral-400"> <Icon name="search" size=#sm /> </span>
            <input
              id="spotlight-input"
              class="w-full bg-transparent py-3.5 text-sm focus:outline-none"
              placeholder="Search specs…"
              onInput={e => {
                Signal.set(q, Ui.inputValue(e))
                Signal.set(active, 0)
              }}
              onKeyDown={onKey}
            />
            <Kbd> <View.Text> "esc" </View.Text> </Kbd>
          </div>
          <ul class="max-h-80 overflow-y-auto p-2">
            <View.For
              each={Prop.signal(results)}
              by={a => a.id}
              render={a => {
                let cls = Computed.make(() => {
                  let sel = switch Signal.get(results)->Array.get(Signal.get(active)) {
                  | Some(x) => x.id == a.id
                  | None => false
                  }
                  "flex w-full cursor-pointer items-center justify-between gap-3 rounded-lg px-3 py-2 text-left text-sm transition-colors " ++ (
                    sel ? "bg-action text-on-action" : "text-neutral-700 hover:bg-neutral-100"
                  )
                })
                <li>
                  <button class={Prop.signal(cls)} onClick={_ => navigate(a)}>
                    <span> <View.Text> {a.title} </View.Text> </span>
                    <span class="text-xs opacity-60"> <View.Text> {a.layer} </View.Text> </span>
                  </button>
                </li>
              }}
            />
            <View.Show when_={Prop.signal(empty)}>
              <li class="px-3 py-8 text-center text-sm text-neutral-400"> <View.Text> "No specs found" </View.Text> </li>
            </View.Show>
          </ul>
        </div>
      </div>
    </View.Show>
  }
}

module Guide = {
  module Section = {
    @jsx.component
    let make = (~title: string, ~children: View.node) =>
      <section class="mt-12">
        <h2 class="text-xl font-bold tracking-tight text-neutral-900"> <View.Text> title </View.Text> </h2>
        <div class="mt-3 space-y-4 text-[15px] leading-relaxed text-neutral-600"> {children} </div>
      </section>
  }

  // A labelled definition row (term + description), used for layers/anatomy.
  module Def = {
    @jsx.component
    let make = (~term: string, ~meta: string="", ~children: View.node) =>
      <div class="flex flex-col gap-1 border-t border-neutral-200 py-3 sm:flex-row sm:gap-4">
        <div class="flex w-40 shrink-0 items-baseline gap-2">
          <span class="font-mono text-sm font-medium text-neutral-900"> <View.Text> term </View.Text> </span>
          <View.Show when_={Prop.static(meta != "")}>
            <span class="text-xs tabular-nums text-neutral-400"> <View.Text> meta </View.Text> </span>
          </View.Show>
        </div>
        <div class="flex-1 text-sm text-neutral-600"> {children} </div>
      </div>
  }

  let count = layer => inLayer(layer)->Array.length->Int.toString

  @jsx.component
  let make = () =>
    <div class="mx-auto max-w-3xl px-5 sm:px-8 py-14">
      <Badge variant=#outline> <View.Text> "Get started" </View.Text> </Badge>
      <h1 class="mt-5 text-4xl font-bold tracking-tight text-neutral-900">
        <View.Text> "Prescriptive" </View.Text>
      </h1>
      <p class="mt-4 text-lg leading-relaxed text-neutral-600">
        <View.Text>
          "A technology-agnostic catalogue of UI patterns — for people and AI agents. Each spec defines the "
        </View.Text>
        <em class="text-neutral-900"> <View.Text> "idea" </View.Text> </em>
        <View.Text>
          " of a pattern — its structure, behavior, and accessibility — as a contract you implement in any stack. Stop re-deriving prop names, states, and keyboard behavior every time; implement to the spec."
        </View.Text>
      </p>

      <Section title="Why">
        <p>
          <View.Text>
            "Most UI is rebuilt from scratch on every project and every framework, and the accessibility and edge cases are reinvented (often incompletely) each time. Prescriptive captures the durable part — what a pattern "
          </View.Text>
          <em class="text-neutral-900"> <View.Text> "is" </View.Text> </em>
          <View.Text>
            " — once, so the framework-specific implementation is a faithful rendering of a known-good contract rather than a guess."
          </View.Text>
        </p>
      </Section>

      <Section title="The layers">
        <p> <View.Text> "Specs are organized from the smallest primitives up to whole journeys." </View.Text> </p>
        <div>
          <Def term="element" meta={count("element")}> <View.Text> "Indivisible primitives — button, input, badge, avatar, checkbox." </View.Text> </Def>
          <Def term="component" meta={count("component")}> <View.Text> "Composed, interactive units — dialog, tabs, select, form, data-table, navbar." </View.Text> </Def>
          <Def term="block" meta={count("block")}> <View.Text> "Page-level sections — hero, pricing-table, feature-grid, testimonial." </View.Text> </Def>
          <Def term="page" meta={count("page")}> <View.Text> "Full routes — dashboard, settings, sign-in, pricing." </View.Text> </Def>
          <Def term="flow" meta={count("flow")}> <View.Text> "Multi-step journeys — authentication, onboarding, checkout." </View.Text> </Def>
        </div>
      </Section>

      <Section title="What's in a spec">
        <p>
          <View.Text> "Open " </View.Text>
          <Router.Link to="/a/button" class="text-neutral-900 underline decoration-neutral-300 underline-offset-4 hover:decoration-neutral-900"> <View.Text> "Button" </View.Text> </Router.Link>
          <View.Text> " to see the shape every spec follows:" </View.Text>
        </p>
        <div>
          <Def term="Intent"> <View.Text> "The problem it solves and when to use it (or reach for a different spec)." </View.Text> </Def>
          <Def term="API"> <View.Text> "A machine-readable contract: props (with types, allowed values, defaults), slots, events, accessibility (role, keyboard, announcements), states, and the design-token roles it consumes." </View.Text> </Def>
          <Def term="Traits"> <View.Text> "Shared behaviors it exhibits (dismissible, focus-trap, …)." </View.Text> </Def>
          <Def term="Composition"> <View.Text> "The parts it is built from, each wired to a slot with the props passed." </View.Text> </Def>
          <Def term="Spec"> <View.Text> "The full written specification — anatomy, states, variants, accessibility, do/don't." </View.Text> </Def>
          <Def term="Example"> <View.Text> "A live, interactive implementation with its source." </View.Text> </Def>
        </div>
      </Section>

      <Section title="Behaviors">
        <p> <View.Text> "Cross-cutting interaction contracts many specs share, so a dialog and a drawer don't each re-describe focus trapping." </View.Text> </p>
        <div>
          <View.For
            each={Prop.static(TraitsData.all)}
            render={t =>
              <Def term={t.id}>
                <Router.Link to={"/t/" ++ t.id} class="text-neutral-700 hover:text-neutral-900"> <View.Text> {t.summary} </View.Text> </Router.Link>
              </Def>}
          />
        </div>
      </Section>

      <Section title="Design tokens & theming">
        <p>
          <View.Text>
            "Everything is styled against a shared token system — a monochrome ramp plus semantic roles (action, status, ink, surface, border). Components bind to the "
          </View.Text>
          <em class="text-neutral-900"> <View.Text> "roles" </View.Text> </em>
          <View.Text> ", not hardcoded colors, so a re-theme is just changing token values. Try the " </View.Text>
          <Router.Link to="/tokens" class="text-neutral-900 underline decoration-neutral-300 underline-offset-4 hover:decoration-neutral-900"> <View.Text> "live token editor" </View.Text> </Router.Link>
          <View.Text> " or the theme presets (the " </View.Text>
          <Icon name="settings" size=#sm extraClass="inline align-text-bottom" />
          <View.Text> " in the top bar), with light and dark modes." </View.Text>
        </p>
      </Section>

      <Section title="How to use it">
        <p class="font-medium text-neutral-900"> <View.Text> "1 · Browse" </View.Text> </p>
        <p> <View.Text> "Find the pattern in the sidebar (or press ⌘K). Read its intent, contract, and spec; play with the live example." </View.Text> </p>
        <p class="pt-2 font-medium text-neutral-900"> <View.Text> "2 · Consume" </View.Text> </p>
        <p>
          <View.Text> "Install the package (" </View.Text>
          <code class="rounded bg-neutral-100 px-1.5 py-0.5 font-mono text-[13px] text-neutral-800"> <View.Text> "npm i prescriptive" </View.Text> </code>
          <View.Text> ") to read the specs, tokens, and contracts in your build tooling — or add the bundled " </View.Text>
          <Link href="https://github.com/brnrdog/prescriptive/blob/main/skill/SKILL.md" newTab=true> <View.Text> "Agent Skill" </View.Text> </Link>
          <View.Text> " so an AI implements to the contracts for you." </View.Text>
        </p>
        <p class="pt-2 font-medium text-neutral-900"> <View.Text> "3 · Implement" </View.Text> </p>
        <p> <View.Text> "For each pattern: match the contract's prop names, enum values, and defaults; handle every state; honor the accessibility and trait keyboard contracts; reuse the specs it composes. Render it in your framework and style it with the token roles." </View.Text> </p>
      </Section>

      <div class="mt-12 flex flex-wrap gap-3 border-t border-neutral-200 pt-8">
        <Router.Link to="/a/button">
          <Button variant=#primary> <View.Text> "Browse specs" </View.Text> </Button>
        </Router.Link>
        <Router.Link to="/tokens">
          <Button variant=#secondary> <View.Text> "Design tokens" </View.Text> </Button>
        </Router.Link>
        <Link href="https://github.com/brnrdog/prescriptive" newTab=true variant=#muted extraClass="inline-flex items-center gap-1.5 self-center text-sm">
          <Icon name="github" size=#sm />
          <View.Text> "GitHub" </View.Text>
        </Link>
      </div>
    </div>
}

module Preview = {
  @jsx.component
  let make = (~id) =>
    switch Examples.get(id) {
    | Some(node) =>
      <div class="preview-surface flex min-h-48 items-center justify-center rounded-2xl border border-neutral-200 p-10 shadow-sm">
        {node}
      </div>
    | None =>
      <div class="flex min-h-48 flex-col items-center justify-center gap-2 rounded-2xl border border-dashed border-neutral-300 p-10 text-center">
        <span class="text-sm font-medium text-neutral-600"> <View.Text> "Live example coming soon" </View.Text> </span>
        <span class="max-w-xs text-xs text-neutral-400">
          <View.Text> "The written specification is complete. An interactive Xote implementation for this spec is on the way." </View.Text>
        </span>
      </div>
    }
}

module NotFound = {
  @jsx.component
  let make = () =>
    <div class="mx-auto max-w-3xl px-5 sm:px-8 py-16">
      <h1 class="text-2xl font-bold text-neutral-900"> <View.Text> "Spec not found" </View.Text> </h1>
      <Router.Link to="/" class="mt-4 inline-flex items-center gap-1.5 text-sm underline underline-offset-4">
        <Icon name="arrow-left" size=#sm />
        <View.Text> "Back to overview" </View.Text>
      </Router.Link>
    </div>
}

module ExampleBlock = {
  @jsx.component
  let make = (~a: spec) => {
    // One live surface per spec, plus its source on demand. A single strip picks
    // the implementation (Xote or reativa) and everything follows it: the
    // preview, the playground knobs that drive it, and the source shown below.
    // Specs with a playground get the knob-driven preview right in the surface —
    // the preview and the playground are the same thing, never two tabs.
    let impl = Signal.make("xote")
    let showCode = Signal.make(false)
    let copied = Signal.make(false)
    let full = Signal.make(false)
    let hasExample = Examples.get(a.id)->Option.isSome
    let hasReativa = ReativaExamples.has(a.id)
    let playground = Playground.get(a.id)
    // Xote is the default, and the only choice for a spec with no reativa
    // implementation.
    let isXote = Computed.make(() => !hasReativa || Signal.get(impl) == "xote")
    let isReativa = Computed.make(() => !Signal.get(isXote))
    // The source of whichever implementation is selected.
    let source = Computed.make(() =>
      (Signal.get(isXote) ? ExampleSource.get(a.id) : ReativaSource.get(a.id))->Option.getOr("")
    )
    let hasSource =
      ExampleSource.get(a.id)->Option.isSome || ReativaSource.get(a.id)->Option.isSome
    let sourceMissing = Computed.make(() => Signal.get(source) == "")
    let sourceLang = Computed.make(() => Signal.get(isXote) ? "ReScript · Xote" : "OCaml · reativa")
    // A knob-driven preview needs the selected implementation to have a
    // playground — reativa's also needs its bundle to be built.
    let knobDriven = Computed.make(() =>
      switch playground {
      | None => false
      | Some(_) =>
        Signal.get(isXote) || (ReativaExamples.built && ReativaExamples.hasPlayground(a.id))
      }
    )
    // Otherwise the surface shows the spec's plain example, for the selected
    // implementation.
    let plainXote = Computed.make(() => !Signal.get(knobDriven) && Signal.get(isXote))
    let plainReativa = Computed.make(() => !Signal.get(knobDriven) && Signal.get(isReativa))
    // The playground is shown/hidden by class rather than by `View.Show`: a
    // component node is lazy, so re-rendering it would rebuild the panel and
    // throw away the props you dialed in when switching implementations.
    let panelCls = Computed.make(() => Signal.get(knobDriven) ? "" : "hidden")
    // Segmented-control button classes for the implementation strip.
    let implCls = target =>
      Computed.make(() =>
        "rounded-md px-3 py-1 text-xs font-medium transition-colors " ++ (
          Signal.get(impl) == target
            ? "bg-action text-on-action"
            : "text-neutral-600 hover:text-neutral-900"
        )
      )
    // Fullscreen renders the Xote example, so offer it only for that one.
    let canFullscreen = Computed.make(() => hasExample && Signal.get(isXote))
    // Close fullscreen on Escape while it is open.
    Effect.run(() => Signal.get(full) ? Some(Ui.onEscape(() => Signal.set(full, false))) : None)
    // While the plain reativa example is showing, imperatively mount the
    // OCaml/Melange example into its container (the reativa runtime owns that
    // subtree).
    Effect.run(() => {
      if Signal.get(plainReativa) && ReativaExamples.built {
        ReativaExamples.mount(a.id)
      }
      None
    })
    <div class="mt-10">
      <div class="mb-3 flex flex-wrap items-center justify-between gap-3">
        {hasReativa
          ? <div class="inline-flex items-center gap-1 rounded-lg border border-neutral-200 bg-neutral-50 p-0.5">
              <button class={Prop.signal(implCls("xote"))} onClick={_ => Signal.set(impl, "xote")}>
                <View.Text> "Xote" </View.Text>
              </button>
              <button
                class={Prop.signal(implCls("reativa"))} onClick={_ => Signal.set(impl, "reativa")}>
                <View.Text> "Reativa" </View.Text>
              </button>
            </div>
          : View.null()}
        <div class="flex items-center gap-3">
          {hasSource
            ? <Button variant=#secondary size=#sm onClick={_ => Signal.update(showCode, v => !v)}>
                <View.Show
                  when_={Prop.signal(showCode)}
                  fallback={<span class="inline-flex items-center gap-1.5">
                    <Icon name="chevron-down" size=#sm />
                    <View.Text> "Show source" </View.Text>
                  </span>}>
                  <span class="inline-flex items-center gap-1.5">
                    <Icon name="chevron-up" size=#sm />
                    <View.Text> "Hide source" </View.Text>
                  </span>
                </View.Show>
              </Button>
            : View.null()}
          <View.Show when_={Prop.signal(canFullscreen)}>
            <Button variant=#secondary size=#sm onClick={_ => Signal.set(full, true)}>
              <Icon name="maximize" size=#sm />
              <View.Text> "Fullscreen" </View.Text>
            </Button>
          </View.Show>
          <a
            class="text-xs text-neutral-400 underline underline-offset-4 hover:text-neutral-700"
            href={docUrl(a)}
            target="_blank">
            <View.Text> "Read the spec" </View.Text>
            <Icon name="external-link" size=#xs extraClass="ml-1 inline align-text-bottom" />
          </a>
        </div>
      </div>
      {switch playground {
      | Some(def) =>
        <div class={Prop.signal(panelCls)}>
          <Playground.Panel id={a.id} def useReativa={isReativa} />
        </div>
      | None => View.null()
      }}
      <View.Show when_={Prop.signal(plainXote)}>
        <Preview id={a.id} />
      </View.Show>
      {hasReativa
        ? <View.Show when_={Prop.signal(plainReativa)}>
            {ReativaExamples.built
              ? // The reativa runtime mounts the OCaml/Melange example here.
                <div class="preview-surface flex min-h-48 items-center justify-center rounded-2xl border border-neutral-200 p-10 shadow-sm">
                  <div id={ReativaExamples.containerId(a.id)} />
                </div>
              : <div class="flex min-h-48 flex-col items-center justify-center gap-2 rounded-2xl border border-dashed border-neutral-300 p-10 text-center">
                  <span class="text-sm font-medium text-neutral-600">
                    <View.Text> "Reativa preview not built" </View.Text>
                  </span>
                  <span class="max-w-sm text-xs text-neutral-400">
                    <View.Text>
                      "This spec also has an OCaml + Melange (reativa) implementation. Run npm run reativa in website/ to compile it and render it here, alongside the Xote version."
                    </View.Text>
                  </span>
                </div>}
          </View.Show>
        : View.null()}
      {hasSource
        ? <View.Show when_={Prop.signal(showCode)}>
            <div class="relative mt-3">
              <div class="absolute left-4 top-3 z-10 font-mono text-[11px] text-neutral-500">
                <View.Text> {sourceLang} </View.Text>
              </div>
              <button
                class="absolute right-2 top-2 z-10 inline-flex items-center gap-1 rounded-lg border border-neutral-700 bg-neutral-800 px-2 py-1 text-xs text-neutral-200 transition-colors hover:bg-neutral-700"
                onClick={_ => {
                  Ui.copyToClipboard(Signal.get(source))
                  Signal.set(copied, true)
                  Ui.setTimeout(() => Signal.set(copied, false), 1500)
                }}>
                <View.Show
                  when_={Prop.signal(copied)}
                  fallback={<span class="inline-flex items-center gap-1">
                    <Icon name="copy" size=#xs />
                    <View.Text> "Copy" </View.Text>
                  </span>}>
                  <Icon name="check" size=#xs />
                  <View.Text> "Copied" </View.Text>
                </View.Show>
              </button>
              <pre
                class="max-h-[32rem] overflow-auto rounded-2xl border border-neutral-800 bg-neutral-900 p-4 pt-9 text-xs leading-relaxed text-neutral-100">
                <code class="font-mono">
                  <View.Show
                    when_={Prop.signal(sourceMissing)}
                    fallback={<View.Text> {source} </View.Text>}>
                    <View.Text>
                      "No source for this implementation yet — switch implementations to see the other one."
                    </View.Text>
                  </View.Show>
                </code>
              </pre>
            </div>
          </View.Show>
        : View.null()}
      <View.Show when_={Prop.signal(full)}>
        <div class="fixed inset-0 z-50 flex flex-col bg-surface">
          <div class="flex h-14 shrink-0 items-center justify-between border-b border-neutral-200 px-4">
            <span class="text-sm font-medium text-neutral-900"> <View.Text> {a.title ++ " — example"} </View.Text> </span>
            <Button variant=#secondary size=#sm onClick={_ => Signal.set(full, false)}>
              <Icon name="x" size=#sm />
              <View.Text> "Close" </View.Text>
            </Button>
          </div>
          <div class="preview-surface flex flex-1 items-center justify-center overflow-auto p-12">
            {switch Examples.get(a.id) {
            | Some(node) => node
            | None => View.null()
            }}
          </div>
        </div>
      </View.Show>
    </div>
  }
}

module Detail = {
  @jsx.component
  let make = (~id) =>
    switch byId(id) {
    | None => <NotFound />
    | Some(a) =>
      <div class="mx-auto max-w-3xl px-5 sm:px-8 py-12">
        <nav class="flex items-center gap-2 text-xs text-neutral-400">
          <Router.Link to="/" class="hover:text-neutral-700"> <View.Text> "Overview" </View.Text> </Router.Link>
          <span> <View.Text> "/" </View.Text> </span>
          <span class="capitalize"> <View.Text> {layerPlural(a.layer)} </View.Text> </span>
          <span> <View.Text> "/" </View.Text> </span>
          <span class="text-neutral-700"> <View.Text> {a.title} </View.Text> </span>
        </nav>
        <div class="mt-4 flex flex-wrap items-center gap-3">
          <h1 class="text-3xl font-bold tracking-tight text-neutral-900"> <View.Text> {a.title} </View.Text> </h1>
          <LayerBadge layer={a.layer} />
          <Status status={a.status} />
          <span class="font-mono text-xs text-neutral-400"> <View.Text> {"v" ++ a.version} </View.Text> </span>
        </div>
        <p class="mt-4 text-lg leading-relaxed text-neutral-700"> <View.Text> {a.summary} </View.Text> </p>
        <View.Show when_={Prop.static(Array.length(a.tags) > 0)}>
          <div class="mt-4 flex flex-wrap gap-1.5">
            <View.For
              each={Prop.static(a.tags)}
              render={t => <Badge variant=#soft> <View.Text> {t} </View.Text> </Badge>}
            />
          </div>
        </View.Show>
        <View.Show when_={Prop.static(Array.length(a.traits) > 0)}>
          <div class="mt-3 flex flex-wrap items-center gap-1.5">
            <span class="text-xs font-medium text-neutral-400"> <View.Text> "Behaviors" </View.Text> </span>
            <View.For
              each={Prop.static(a.traits)}
              render={tid =>
                <Router.Link
                  to={"/t/" ++ tid}
                  class="inline-flex items-center rounded-full border border-neutral-300 bg-surface px-2.5 py-0.5 text-xs font-medium text-neutral-700 transition-colors hover:border-neutral-900 hover:text-neutral-900">
                  <View.Text> {tid} </View.Text>
                </Router.Link>}
            />
          </div>
        </View.Show>

        <ExampleBlock a />

        {switch a.api {
        | Some(api) => <ApiTable api />
        | None => View.null()
        }}

        <View.Show when_={Prop.static(a.spec != "")}>
          <SpecBody html={a.spec} />
        </View.Show>

        {Array.length(a.composition) > 0
          ? <Composition parts={a.composition} />
          : View.null()}

        <div class="mt-10 grid gap-6 sm:grid-cols-3">
          {Array.length(a.composition) > 0
            ? View.null()
            : <ChipRow title="Composed of" ids={a.composedOf} />}
          <ChipRow title="Used by" ids={a.usedBy} />
          <ChipRow title="Related" ids={a.related} />
        </div>
      </div>
    }
}

module TraitDetail = {
  @jsx.component
  let make = (~id) =>
    switch traitById(id) {
    | None => <NotFound />
    | Some(t) =>
      <div class="mx-auto max-w-3xl px-5 sm:px-8 py-12">
        <nav class="flex items-center gap-2 text-xs text-neutral-400">
          <Router.Link to="/" class="hover:text-neutral-700"> <View.Text> "Overview" </View.Text> </Router.Link>
          <span> <View.Text> "/" </View.Text> </span>
          <span> <View.Text> "Behaviors" </View.Text> </span>
          <span> <View.Text> "/" </View.Text> </span>
          <span class="text-neutral-700"> <View.Text> {t.title} </View.Text> </span>
        </nav>
        <div class="mt-4 flex flex-wrap items-center gap-3">
          <h1 class="text-3xl font-bold tracking-tight text-neutral-900"> <View.Text> {t.title} </View.Text> </h1>
          <span
            class="inline-flex items-center rounded-md border border-dashed border-neutral-300 px-2 py-0.5 text-[10px] font-semibold uppercase tracking-wide text-neutral-500">
            <View.Text> "behavior" </View.Text>
          </span>
        </div>
        <p class="mt-4 text-lg leading-relaxed text-neutral-700"> <View.Text> {t.summary} </View.Text> </p>
        <View.Show when_={Prop.static(Array.length(t.keys) > 0)}>
          <div class="mt-4 flex flex-wrap items-center gap-1.5">
            <span class="text-xs font-medium text-neutral-400"> <View.Text> "Required keys" </View.Text> </span>
            <View.For
              each={Prop.static(t.keys)}
              render={k => <Kbd> <View.Text> k </View.Text> </Kbd>}
            />
          </div>
        </View.Show>

        <View.Show when_={Prop.static(t.spec != "")}>
          <SpecBody html={t.spec} />
        </View.Show>

        <div class="mt-10">
          <ChipRow title="Exhibited by" ids={specsWithTrait(id)->Array.map(a => a.id)} />
        </div>
      </div>
    }
}

// The design-token editor — every token the framework defines, generated from
// tokens.json (TokensData) and editable live. Editing overrides the token's
// Tailwind theme var (cascading through every utility) and its --ux-* mirror;
// samples read the --ux-* var so they update as you type. Changes persist.
module Tokens = {
  // Preview of a token, reading its live --ux-* var so it reflects edits.
  module Sample = {
    @jsx.component
    let make = (~t: TokensData.token) => {
      let v = "var(" ++ t.uxVar ++ ")"
      switch t.sample {
      | "radius" => <div class="size-10 shrink-0 border-2 border-neutral-900 bg-neutral-100" style={"border-radius: " ++ v} />
      | "space" =>
        <div class="flex h-10 w-20 shrink-0 items-center">
          <div class="h-4 rounded-sm bg-neutral-900" style={"width: " ++ v} />
        </div>
      | "shadow" => <div class="size-10 shrink-0 rounded-md border border-neutral-100 bg-surface" style={"box-shadow: " ++ v} />
      | "border" => <div class="size-10 shrink-0 rounded-md border-solid border-neutral-900 bg-neutral-50" style={"border-width: " ++ v} />
      | "font-family" => <span class="w-10 shrink-0 text-2xl text-neutral-900" style={"font-family: " ++ v}> <View.Text> "Ag" </View.Text> </span>
      | "font-size" => <span class="flex h-10 w-10 shrink-0 items-center text-neutral-900" style={"font-size: " ++ v}> <View.Text> "Ag" </View.Text> </span>
      | "font-weight" => <span class="w-10 shrink-0 text-2xl text-neutral-900" style={"font-weight: " ++ v}> <View.Text> "Ag" </View.Text> </span>
      | _ => <span class="flex size-10 shrink-0 items-center justify-center rounded-md bg-neutral-100 font-mono text-[10px] text-neutral-500"> <View.Text> {t.value} </View.Text> </span>
      }
    }
  }

  module Row = {
    @jsx.component
    let make = (~t: TokensData.token) => {
      // The control reflects the value currently in effect (preset/mode/edit),
      // re-reading when a preset bumps the override version.
      let live = Computed.make(() => {
        Signal.get(Settings.overridesVersion)->ignore
        Settings.currentValue(t)
      })
      <div class="flex items-center gap-3 rounded-xl border border-neutral-200 bg-surface p-3 shadow-sm transition-colors hover:border-neutral-300">
        {t.sample == "color"
          ? <input
              type_="color"
              value={Prop.signal(live)}
              onInput={e => Settings.applyToken(t, Ui.inputValue(e))}
              class="size-11 shrink-0 cursor-pointer rounded-lg border border-neutral-200 bg-transparent"
            />
          : <Sample t />}
        <div class="min-w-0 flex-1">
          <div class="font-mono text-sm text-neutral-900"> <View.Text> {t.name} </View.Text> </div>
          <View.Show when_={Prop.static(t.raw != "")}>
            <div class="font-mono text-xs text-neutral-300"> <View.Text> {t.raw} </View.Text> </div>
          </View.Show>
          <View.Show when_={Prop.static(t.description != "")}>
            <div class="mt-0.5 text-xs text-neutral-500"> <View.Text> {t.description} </View.Text> </div>
          </View.Show>
        </div>
        <View.Show when_={Prop.static(t.sample != "color")}>
          <input
            type_="text"
            value={Prop.signal(live)}
            onInput={e => Settings.applyToken(t, Ui.inputValue(e))}
            class="w-24 shrink-0 rounded-md border border-neutral-300 px-2 py-1 text-right font-mono text-xs text-neutral-700 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-neutral-900"
          />
        </View.Show>
      </div>
    }
  }

  @jsx.component
  let make = () =>
    <div class="mx-auto max-w-3xl px-5 sm:px-8 py-12">
      <nav class="flex items-center gap-2 text-xs text-neutral-400">
        <Router.Link to="/" class="hover:text-neutral-700"> <View.Text> "Overview" </View.Text> </Router.Link>
        <span> <View.Text> "/" </View.Text> </span>
        <span class="text-neutral-700"> <View.Text> "Design Tokens" </View.Text> </span>
      </nav>
      <div class="mt-4 flex flex-wrap items-start justify-between gap-3">
        <h1 class="text-3xl font-bold tracking-tight text-neutral-900"> <View.Text> "Design Tokens" </View.Text> </h1>
        <Button variant=#secondary size=#sm onClick={_ => Settings.resetTokensAndReload()}>
          <View.Text> "Reset all" </View.Text>
        </Button>
      </div>
      <p class="mt-4 text-lg leading-relaxed text-neutral-600">
        <View.Text> "The primitives every spec is built on — generated from the framework's " </View.Text>
        <Link href="https://github.com/brnrdog/prescriptive/blob/main/tokens/tokens.json" newTab=true>
          <View.Text> "tokens.json" </View.Text>
        </Link>
        <View.Text> ". Edit any value below and watch it cascade through the whole site — the theme is driven entirely by these. Changes persist locally." </View.Text>
      </p>

      <View.For
        each={Prop.static(TokensData.all)}
        render={g =>
          <section class="mt-10">
            <h2 class="text-lg font-semibold tracking-tight text-neutral-900 capitalize"> <View.Text> {g.group} </View.Text> </h2>
            <p class="mt-1 text-sm text-neutral-500"> <View.Text> {g.description} </View.Text> </p>
            <div class="mt-4 grid gap-3 sm:grid-cols-2">
              <View.For each={Prop.static(g.tokens)} render={t => <Row t />} />
            </div>
          </section>}
      />
    </div>
}

// A single-page contact sheet: every element and component rendered live in a
// masonry mosaic. Each tile frames the spec's real example and links to its
// full detail page. Purely a gallery view — the examples stay interactive.
module KitchenSink = {
  module Tile = {
    @jsx.component
    let make = (~a: spec) =>
      <div class={Ui.card ++ " mb-4 break-inside-avoid overflow-hidden transition-colors hover:border-neutral-300"}>
        <div class="preview-surface flex max-h-72 min-h-36 items-center justify-center overflow-hidden p-6">
          {switch Examples.get(a.id) {
          | Some(node) => node
          | None =>
            <span class="text-xs text-neutral-400"> <View.Text> "Spec only" </View.Text> </span>
          }}
        </div>
        <div class="flex items-center justify-between gap-2 border-t border-neutral-200 bg-surface px-3 py-2">
          <Router.Link
            to={"/a/" ++ a.id}
            class="min-w-0 flex-1 truncate text-sm font-medium text-neutral-800 underline-offset-4 hover:text-neutral-900 hover:underline">
            <View.Text> {a.title} </View.Text>
          </Router.Link>
          <span class="shrink-0"> <LayerBadge layer={a.layer} /> </span>
        </div>
      </div>
  }

  @jsx.component
  let make = () => {
    // Elements first, then components — the two layers the library covers.
    let items = Array.concat(inLayer("element"), inLayer("component"))
    let count = layer => inLayer(layer)->Array.length->Int.toString
    <div class="mx-auto max-w-6xl px-5 sm:px-8 py-12">
      <nav class="flex items-center gap-2 text-xs text-neutral-400">
        <Router.Link to="/" class="hover:text-neutral-700"> <View.Text> "Overview" </View.Text> </Router.Link>
        <span> <View.Text> "/" </View.Text> </span>
        <span class="text-neutral-700"> <View.Text> "Kitchen Sink" </View.Text> </span>
      </nav>
      <div class="mt-4 flex flex-wrap items-end justify-between gap-3">
        <h1 class="text-3xl font-bold tracking-tight text-neutral-900"> <View.Text> "Kitchen Sink" </View.Text> </h1>
        <span class="text-sm tabular-nums text-neutral-500">
          <View.Text> {count("element") ++ " elements · " ++ count("component") ++ " components"} </View.Text>
        </span>
      </div>
      <p class="mt-4 max-w-2xl text-lg leading-relaxed text-neutral-600">
        <View.Text> "Every element and component rendered live on one page. Tiles stay interactive — click a title to open its full spec and contract." </View.Text>
      </p>
      <div class="mt-8 columns-1 gap-4 sm:columns-2 lg:columns-3 2xl:columns-4">
        <View.For each={Prop.static(items)} by={a => a.id} render={a => <Tile a />} />
      </div>
    </div>
  }
}

@jsx.component
let make = () => {
  // Global ⌘K opens the spotlight search.
  Effect.run(() => Some(Ui.onCmdK(() => Signal.set(spotlightOpen, true))))
  // Re-apply any persisted preset / per-token overrides on startup, after
  // discarding a preset that names a theme this release no longer ships.
  Effect.run(() => {
    Settings.dropStalePreset()
    Settings.loadTokenOverrides()
    Settings.syncColorScheme()
    None
  })
  // On mobile, close the drawer whenever the route changes.
  Effect.run(() => {
    Signal.get(Router.location())->ignore
    if !isDesktop() {
      Signal.set(sidebarOpen, false)
    }
    None
  })
  let routes = Router.routes([
    {pattern: "/", render: _ => <Landing />},
    {pattern: "/guide", render: _ => <Guide />},
    {pattern: "/showcase", render: _ => <Showcase />},
    {pattern: "/kitchen-sink", render: _ => <KitchenSink />},
    {pattern: "/tokens", render: _ => <Tokens />},
    {pattern: "/a/:id", render: params => <Detail id={params->Dict.get("id")->Option.getOr("")} />},
    {pattern: "/t/:id", render: params => <TraitDetail id={params->Dict.get("id")->Option.getOr("")} />},
  ])
  // The docs rail (and its mobile scrim) belong to the catalogue, not to the
  // landing page.
  let scrim = Computed.make(() =>
    Signal.get(sidebarOpen) && Signal.get(Router.location()).pathname != "/"
  )
  <div class="flex h-screen flex-col">
    <Topbar />
    <div class="flex min-h-0 flex-1">
      <Sidebar />
      // Dim the page behind the mobile drawer.
      <View.Show when_={Prop.signal(scrim)}>
        <div
          class="fixed inset-0 top-14 z-30 bg-neutral-900/40 lg:hidden"
          onClick={_ => Signal.set(sidebarOpen, false)}
        />
      </View.Show>
      <main class="min-w-0 flex-1 overflow-y-auto"> {routes} </main>
    </div>
    <Spotlight />
    <Settings.Panel />
  </div>
}
