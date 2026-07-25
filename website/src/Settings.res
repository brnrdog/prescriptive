// Live theme settings. The whole site is driven by the design tokens compiled to
// CSS custom properties (see tokens.generated.css), so re-theming at runtime is
// just overriding those variables on :root. Presets and per-token edits share one
// path→value override store, persisted in localStorage and re-applied on load.

// --- Raw DOM / storage helpers -------------------------------------------------
let setVar: (string, string) => unit = %raw(`(k, v) => document.documentElement.style.setProperty(k, v)`)
let removeVar: string => unit = %raw(`(k) => document.documentElement.style.removeProperty(k)`)
let store: (string, string) => unit = %raw(`(k, v) => { try { localStorage.setItem(k, v) } catch (e) {} }`)
let read: string => string = %raw(`(k) => { try { return localStorage.getItem(k) || "" } catch (e) { return "" } }`)
let reload: unit => unit = %raw(`() => location.reload()`)
let readOr = (k, d) => {
  let v = read(k)
  v == "" ? d : v
}

// --- Token override store (path → value) ---------------------------------------
// Shared by the preset picker and the Design Tokens editor. Editing overrides the
// token's Tailwind theme var (cascades site-wide) and its --ux-* mirror.
let getOverrides: unit => Dict.t<string> = %raw(`() => { try { return JSON.parse(localStorage.getItem("ux.tokenOverrides") || "{}") } catch (e) { return {} } }`)
let saveOverrides: Dict.t<string> => unit = %raw(`(o) => { try { localStorage.setItem("ux.tokenOverrides", JSON.stringify(o)) } catch (e) {} }`)

let tokenByPath = path => {
  let found = ref(None)
  TokensData.all->Array.forEach(g =>
    g.tokens->Array.forEach(t =>
      if t.path == path {
        found := Some(t)
      }
    )
  )
  found.contents
}

let applyVars = (t: TokensData.token, value) => {
  setVar(t.uxVar, value)
  if t.themeVar != "" {
    setVar(t.themeVar, value)
  }
}

// Bumped when a preset/mode/reset changes many tokens at once, so the Design
// Tokens editor can re-read each control's current value. Not bumped on a single
// in-editor edit (that control already holds what the user typed).
let overridesVersion = Signal.make(0)
let bumpOverrides = () => Signal.update(overridesVersion, v => v + 1)

// The value currently in effect for a token: its own override if any; otherwise
// — for an alias like `{color.neutral.900}` — whatever its target currently
// resolves to (so a semantic role reflects a change to the ramp it points at);
// otherwise the generated default.
let rec currentValue = (t: TokensData.token) =>
  switch getOverrides()->Dict.get(t.path) {
  | Some(v) => v
  | None =>
    if t.raw != "" {
      let ref = t.raw->String.slice(~start=1, ~end=String.length(t.raw) - 1)
      switch tokenByPath(ref) {
      | Some(target) => currentValue(target)
      | None => t.value
      }
    } else {
      t.value
    }
  }

let applyToken = (t: TokensData.token, value) => {
  applyVars(t, value)
  let o = getOverrides()
  o->Dict.set(t.path, value)
  saveOverrides(o)
}

let applyByPath = (path, value) =>
  switch tokenByPath(path) {
  | Some(t) => applyToken(t, value)
  | None => ()
  }

let loadTokenOverrides = () => {
  let o = getOverrides()
  o
  ->Dict.toArray
  ->Array.forEach(((path, v)) =>
    switch tokenByPath(path) {
    | Some(t) => applyVars(t, v)
    | None => ()
    }
  )
}

// Remove every current override's inline vars and clear the store.
let clearOverrides = () => {
  let o = getOverrides()
  o
  ->Dict.keysToArray
  ->Array.forEach(path =>
    switch tokenByPath(path) {
    | Some(t) =>
      removeVar(t.uxVar)
      if t.themeVar != "" {
        removeVar(t.themeVar)
      }
    | None => ()
    }
  )
  saveOverrides(Dict.make())
}

// --- Presets -------------------------------------------------------------------
// A preset is a named bundle of token overrides. Tinting the neutral ramp
// cascades through the semantic roles (which alias it) so the whole site — chrome
// and components — re-themes cohesively; a couple also override a semantic role
// directly. Applying one replaces any current overrides.
// The themes themselves live in the framework (tokens/themes.json) and are
// generated into ThemesData — this module just applies them.

// --- State ---------------------------------------------------------------------
// A theme (palette identity) and a light/dark mode are orthogonal: the mode
// overlay is applied on top of the chosen theme.
let open_ = Signal.make(false)
let presetSel = Signal.make(readOr("ux.preset", "monochrome"))
let darkMode = Signal.make(readOr("ux.mode", "light") == "dark")

// Corner radius is a third orthogonal axis, like the light/dark mode: a chosen
// preset overrides the whole `radius.*` ramp on top of the current theme.
// `default` keeps whatever radii the theme itself defines.
let radiusSel = Signal.make(readOr("ux.radius", "default"))
let radiusPresets = [
  ("sharp", "Sharp", "0.1875rem", [
    ("radius.sm", "0.125rem"), ("radius.md", "0.1875rem"), ("radius.lg", "0.25rem"),
    ("radius.xl", "0.375rem"), ("radius.2xl", "0.5rem"), ("radius.3xl", "0.625rem"),
  ]),
  ("default", "Default", "0.5rem", []),
  ("rounded", "Rounded", "0.875rem", [
    ("radius.sm", "0.5rem"), ("radius.md", "0.75rem"), ("radius.lg", "1rem"),
    ("radius.xl", "1.5rem"), ("radius.2xl", "2rem"), ("radius.3xl", "2.5rem"),
  ]),
  ("round", "Round", "1.25rem", [
    ("radius.sm", "0.875rem"), ("radius.md", "1.125rem"), ("radius.lg", "1.5rem"),
    ("radius.xl", "2rem"), ("radius.2xl", "2.5rem"), ("radius.3xl", "3rem"),
  ]),
]
let radiusById = id => radiusPresets->Array.find(((rid, _, _, _)) => rid == id)
let applyRadius = () =>
  switch radiusById(Signal.get(radiusSel)) {
  | Some((_, _, _, tokens)) => tokens->Array.forEach(((path, v)) => applyByPath(path, v))
  | None => ()
  }

let themeById = id => ThemesData.all->Array.find(t => t.id == id)

// Tell the browser which scheme is active so native UI (scrollbars, form
// controls) matches; custom scrollbar styling in styles.css follows the tokens.
let setColorScheme: string => unit = %raw(`(v) => { document.documentElement.style.colorScheme = v }`)
let syncColorScheme = () => setColorScheme(Signal.get(darkMode) ? "dark" : "light")

let applyTheme = (t: ThemesData.theme, dark) => {
  clearOverrides()
  t.tokens->Array.forEach(((path, v)) => applyByPath(path, v))
  if dark {
    // Generic dark inversion, then the theme's own hue-tinted dark surfaces.
    ThemesData.darkMode->Array.forEach(((path, v)) => applyByPath(path, v))
    t.darkTokens->Array.forEach(((path, v)) => applyByPath(path, v))
  }
  // Corner radius overlay sits on top of the theme's own radii.
  applyRadius()
  Signal.set(presetSel, t.id)
  Signal.set(darkMode, dark)
  setColorScheme(dark ? "dark" : "light")
  store("ux.preset", t.id)
  store("ux.mode", dark ? "dark" : "light")
  bumpOverrides()
}

// Pick a theme, keeping the current mode.
let applyPreset = t => applyTheme(t, Signal.get(darkMode))

// Flip the mode, keeping the current theme.
let setDark = dark =>
  switch themeById(Signal.get(presetSel)) {
  | Some(t) => applyTheme(t, dark)
  | None => ()
  }

// Pick a corner-radius preset, keeping the current theme and mode. Rebuilds the
// override set so switching back to `default` cleanly restores the theme radii.
let setRadius = id => {
  Signal.set(radiusSel, id)
  store("ux.radius", id)
  switch themeById(Signal.get(presetSel)) {
  | Some(t) => applyTheme(t, Signal.get(darkMode))
  | None => applyRadius()
  }
}

// Reset everything (theme + mode + per-token edits) back to the framework defaults.
let resetTokens = () => {
  clearOverrides()
  Signal.set(presetSel, "monochrome")
  Signal.set(darkMode, false)
  Signal.set(radiusSel, "default")
  store("ux.preset", "monochrome")
  store("ux.mode", "light")
  store("ux.radius", "default")
  bumpOverrides()
}
let resetTokensAndReload = () => {
  resetTokens()
  reload()
}

// A preset stored by an older release may name a theme that no longer ships. Its
// token overrides are still in localStorage, so the site would come up wearing a
// palette the picker can't show — and the mode/corner controls, which re-apply
// the current theme, would do nothing. Drop it back to the baseline on boot.
let dropStalePreset = () =>
  switch themeById(Signal.get(presetSel)) {
  | Some(_) => ()
  | None => resetTokens()
  }

// --- UI ------------------------------------------------------------------------
module Trigger = {
  @jsx.component
  let make = () =>
    <IconButton label="Theme settings" onClick={_ => Signal.update(open_, v => !v)}>
      <Icon name="settings" />
    </IconButton>
}

module Panel = {
  @jsx.component
  let make = () => {
    // Close on Escape while open.
    Effect.run(() =>
      if Signal.get(open_) {
        Some(Ui.onEscape(() => Signal.set(open_, false)))
      } else {
        None
      }
    )
    <View.Show when_={Prop.signal(open_)}>
      <Backdrop onClose={() => Signal.set(open_, false)} />
      <div class="fixed right-3 top-16 z-40 w-72 rounded-2xl border border-border bg-surface p-4 shadow-lg">
        <div class="flex items-center justify-between">
          <h2 class="text-sm font-semibold text-ink"> <View.Text> "Theme" </View.Text> </h2>
          {
            // Light / dark mode toggle — orthogonal to the theme.
            let seg = dark => Computed.make(() =>
              "rounded-md px-2 py-0.5 text-xs font-medium transition-colors " ++ (
                Signal.get(darkMode) == dark
                  ? "bg-action text-on-action"
                  : "text-muted hover:text-ink"
              )
            )
            <div class="flex items-center gap-0.5 rounded-lg border border-border p-0.5">
              <button class={Prop.signal(seg(false))} onClick={_ => setDark(false)}>
                <span class="inline-flex items-center gap-1.5">
                  <Icon name="sun" size=#sm />
                  <View.Text> "Light" </View.Text>
                </span>
              </button>
              <button class={Prop.signal(seg(true))} onClick={_ => setDark(true)}>
                <span class="inline-flex items-center gap-1.5">
                  <Icon name="moon" size=#sm />
                  <View.Text> "Dark" </View.Text>
                </span>
              </button>
            </div>
          }
        </div>

        <div class="mt-3 grid grid-cols-3 gap-2">
          <View.For
            each={Prop.static(ThemesData.all)}
            render={p => {
              let cls = Computed.make(() =>
                "flex flex-col items-center gap-1.5 rounded-xl border p-2 transition-colors " ++ (
                  Signal.get(presetSel) == p.id
                    ? "border-neutral-900 bg-action-subtle"
                    : "border-border hover:bg-action-subtle"
                )
              )
              <button class={Prop.signal(cls)} onClick={_ => applyPreset(p)}>
                // One chip shape for every theme: equal segments of surface,
                // accent, and ink, so the palettes are comparable at a glance.
                <span class="flex h-6 w-full overflow-hidden rounded-full ring-1 ring-black/10">
                  <View.For
                    each={Prop.static(p.swatches)}
                    render={c => <span class="flex-1" style={"background-color: " ++ c} />}
                  />
                </span>
                <span class="text-[11px] font-medium text-ink"> <View.Text> {p.label} </View.Text> </span>
              </button>
            }}
          />
        </div>

        {
          // What the selected palette is for — each theme carries its own note.
          let desc = Computed.make(() =>
            switch themeById(Signal.get(presetSel)) {
            | Some(t) => t.description
            | None => ""
            }
          )
          // Fixed height so switching themes doesn't shuffle the controls below.
          <p class="mt-2 min-h-8 text-[11px] leading-snug text-muted">
            <View.Text> {Prop.signal(desc)} </View.Text>
          </p>
        }

        // Corner radius — an orthogonal overlay on top of the theme.
        <div class="mt-4">
          <div class="mb-1.5 text-xs font-medium text-muted"> <View.Text> "Corners" </View.Text> </div>
          <div class="grid grid-cols-4 gap-2">
            <View.For
              each={Prop.static(radiusPresets)}
              render={p => {
                let (rid, label, preview, _) = p
                let cls = Computed.make(() =>
                  "flex flex-col items-center gap-1.5 rounded-xl border p-2 transition-colors " ++ (
                    Signal.get(radiusSel) == rid
                      ? "border-neutral-900 bg-action-subtle"
                      : "border-border hover:bg-action-subtle"
                  )
                )
                <button class={Prop.signal(cls)} onClick={_ => setRadius(rid)}>
                  <span
                    class="size-6 border-2 border-neutral-900 bg-surface"
                    style={"border-top-left-radius: " ++ preview ++ "; border-bottom-right-radius: " ++ preview}
                  />
                  <span class="text-[10px] font-medium text-ink"> <View.Text> label </View.Text> </span>
                </button>
              }}
            />
          </div>
        </div>

        <button
          class="mt-4 block text-xs text-muted underline decoration-neutral-300 underline-offset-2 hover:text-ink"
          onClick={_ => {
            Signal.set(open_, false)
            Router.push("/tokens", ())
          }}>
          <span class="inline-flex items-center gap-1.5">
            <View.Text> "Edit individual tokens" </View.Text>
            <Icon name="arrow-right" size=#sm />
          </span>
        </button>

        <div class="mt-4 flex items-center justify-between border-t border-border pt-3">
          <Button variant=#ghost size=#sm onClick={_ => resetTokens()}>
            <View.Text> "Reset" </View.Text>
          </Button>
          <span class="flex items-center gap-1 text-xs text-muted">
            <Kbd> <View.Text> "esc" </View.Text> </Kbd>
            <View.Text> "to close" </View.Text>
          </span>
        </div>
      </div>
    </View.Show>
  }
}
