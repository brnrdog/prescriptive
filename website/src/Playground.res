// Interactive API playground: tweak a spec's contract props and watch the
// live implementation re-render. Each spec that is backed by a reusable
// library component declares its tweakable knobs (mirroring the prop names,
// enum values, and defaults of its `## API` contract) plus a render function
// that maps the knob state onto the real component. The preview re-instantiates
// through `View.Value` whenever any knob changes.

type control =
  | Enum(array<string>)
  | Bool
  | Text
  | Num({min: int, max: int})

type knob = {
  prop: string,
  control: control,
  init: string,
}

type def = {
  knobs: array<knob>,
  render: (string => string) => View.node,
}

// Knob constructors.
let enum = (prop, values, init) => {prop, control: Enum(values), init}
let bool_ = (prop, init) => {prop, control: Bool, init: init ? "true" : "false"}
let text = (prop, init) => {prop, control: Text, init}
let num = (prop, ~min, ~max, init) => {prop, control: Num({min, max}), init: Int.toString(init)}

// Read helpers for render functions.
let isTrue = v => v == "true"
let toInt = (v, fallback) => v->Int.fromString->Option.getOr(fallback)

// ------------------------------------------------------------------- Knobs --
// One definition per spec whose live example is a contract-backed component.

let buttonDef = {
  knobs: [
    text("label", "Button"),
    enum("variant", ["primary", "secondary", "ghost", "destructive"], "primary"),
    enum("size", ["sm", "md", "lg"], "md"),
    bool_("disabled", false),
    bool_("loading", false),
  ],
  render: get => {
    let variant = switch get("variant") {
    | "secondary" => #secondary
    | "ghost" => #ghost
    | "destructive" => #destructive
    | _ => #primary
    }
    let size = switch get("size") {
    | "sm" => #sm
    | "lg" => #lg
    | _ => #md
    }
    <Button variant size disabled={isTrue(get("disabled"))} loading={isTrue(get("loading"))}>
      <View.Text> {get("label")} </View.Text>
    </Button>
  },
}

let badgeDef = {
  knobs: [text("label", "Badge"), enum("variant", ["solid", "soft", "outline"], "solid")],
  render: get => {
    let variant = switch get("variant") {
    | "soft" => #soft
    | "outline" => #outline
    | _ => #solid
    }
    <Badge variant> <View.Text> {get("label")} </View.Text> </Badge>
  },
}

let avatarDef = {
  knobs: [text("initials", "AL"), enum("size", ["sm", "md", "lg", "xl"], "md")],
  render: get => {
    let size = switch get("size") {
    | "sm" => "size-8 text-xs"
    | "lg" => "size-12 text-base"
    | "xl" => "size-14 text-lg"
    | _ => "size-10 text-sm"
    }
    <Avatar initials={get("initials")} size />
  },
}

let alertDef = {
  knobs: [
    enum("variant", ["info", "success", "warning", "danger"], "info"),
    text("title", "Heads up"),
    text("description", "Your trial ends in 3 days."),
  ],
  render: get => {
    let variant = switch get("variant") {
    | "success" => #success
    | "warning" => #warning
    | "danger" => #danger
    | _ => #info
    }
    <div class="w-full max-w-md">
      <Alert variant title={get("title")} description={get("description")} />
    </div>
  },
}

let checkboxDef = {
  knobs: [
    text("label", "Subscribe"),
    text("description", "Get product updates by email."),
    bool_("indeterminate", false),
    bool_("disabled", false),
  ],
  render: get => {
    let checked = Signal.make(true)
    <Checkbox
      checked
      label={get("label")}
      description={get("description")}
      indeterminate={isTrue(get("indeterminate"))}
      disabled={isTrue(get("disabled"))}
    />
  },
}

let switchDef = {
  knobs: [text("label", "Airplane mode"), bool_("disabled", false)],
  render: get => {
    let checked = Signal.make(true)
    <Switch checked label={get("label")} disabled={isTrue(get("disabled"))} />
  },
}

let sliderDef = {
  knobs: [num("step", ~min=1, ~max=25, 1), bool_("disabled", false)],
  render: get => {
    let value = Signal.make(40)
    <div class="w-64">
      <Slider value step={toInt(get("step"), 1)} disabled={isTrue(get("disabled"))} />
    </div>
  },
}

let progressDef = {
  knobs: [num("value", ~min=0, ~max=100, 30), bool_("indeterminate", false)],
  render: get => {
    let value = Signal.make(toInt(get("value"), 30))
    <div class="w-64">
      <Progress value indeterminate={isTrue(get("indeterminate"))} />
    </div>
  },
}

let spinnerDef = {
  knobs: [enum("size", ["sm", "md", "lg"], "sm")],
  render: get => {
    let size = switch get("size") {
    | "md" => "size-6"
    | "lg" => "size-8"
    | _ => "size-4"
    }
    <Spinner size />
  },
}

let skeletonDef = {
  knobs: [enum("shape", ["text", "circle", "rect"], "text")],
  render: get => {
    let (shape, extraClass) = switch get("shape") {
    | "circle" => (#circle, "size-10")
    | "rect" => (#rect, "h-16 w-40")
    | _ => (#text, "w-40")
    }
    <Skeleton shape extraClass />
  },
}

let separatorDef = {
  knobs: [enum("orientation", ["horizontal", "vertical"], "horizontal")],
  render: get =>
    switch get("orientation") {
    | "vertical" =>
      <div class="flex items-center gap-3 text-sm text-neutral-700">
        <span> <View.Text> "Home" </View.Text> </span>
        <Separator orientation=#vertical />
        <span> <View.Text> "Docs" </View.Text> </span>
      </div>
    | _ =>
      <div class="w-64 text-sm text-neutral-700">
        <p> <View.Text> "Above the line" </View.Text> </p>
        <Separator extraClass="my-3" />
        <p> <View.Text> "Below the line" </View.Text> </p>
      </div>
    },
}

let kbdDef = {
  knobs: [text("keys", "⌘K")],
  render: get => <Kbd> <View.Text> {get("keys")} </View.Text> </Kbd>,
}

let iconDef = {
  knobs: [
    enum(
      "name",
      ["search", "edit", "trash", "settings", "star", "heart", "download", "calendar", "info"],
      "star",
    ),
    enum("size", ["xs", "sm", "md", "lg", "xl"], "md"),
  ],
  render: get => {
    let size = switch get("size") {
    | "xs" => #xs
    | "sm" => #sm
    | "lg" => #lg
    | "xl" => #xl
    | _ => #md
    }
    <span class="text-neutral-800"> <Icon name={get("name")} size label={get("name")} /> </span>
  },
}

let iconButtonDef = {
  knobs: [enum("variant", ["ghost", "solid"], "ghost"), text("label", "Edit")],
  render: get => {
    let variant = switch get("variant") {
    | "solid" => #solid
    | _ => #ghost
    }
    <IconButton variant label={get("label")}> <Icon name="edit" /> </IconButton>
  },
}

let linkDef = {
  knobs: [
    text("label", "Getting-started guide"),
    enum("variant", ["default", "muted"], "default"),
    bool_("newTab", false),
  ],
  render: get => {
    let variant = switch get("variant") {
    | "muted" => #muted
    | _ => #default
    }
    <Link href="#" variant newTab={isTrue(get("newTab"))}>
      <View.Text> {get("label")} </View.Text>
    </Link>
  },
}

let inputDef = {
  knobs: [
    enum("type", ["text", "email", "password", "search"], "text"),
    text("placeholder", "you@example.com"),
  ],
  render: get =>
    <div class="w-64"> <Input type_={get("type")} placeholder={get("placeholder")} /> </div>,
}

let textareaDef = {
  knobs: [text("placeholder", "Write something…"), num("rows", ~min=2, ~max=8, 4)],
  render: get => {
    let value = Signal.make("")
    <div class="w-64">
      <Textarea value placeholder={get("placeholder")} rows={toInt(get("rows"), 4)} />
    </div>
  },
}

let toggleDef = {
  knobs: [bool_("disabled", false)],
  render: get => {
    let pressed = Signal.make(true)
    <Toggle pressed disabled={isTrue(get("disabled"))}>
      <span class="italic"> <View.Text> "B" </View.Text> </span>
    </Toggle>
  },
}

let toggleGroupDef = {
  knobs: [enum("type", ["single", "multiple"], "single"), bool_("disabled", false)],
  render: get => {
    let value = Signal.make(["center"])
    let type_ = switch get("type") {
    | "multiple" => #multiple
    | _ => #single
    }
    <ToggleGroup
      type_
      value
      options=[("left", "Left"), ("center", "Center"), ("right", "Right")]
      disabled={isTrue(get("disabled"))}
    />
  },
}

let radioGroupDef = {
  knobs: [
    text("legend", "Shipping speed"),
    enum("orientation", ["vertical", "horizontal"], "vertical"),
    bool_("disabled", false),
  ],
  render: get => {
    let value = Signal.make("express")
    let orientation = switch get("orientation") {
    | "horizontal" => #horizontal
    | _ => #vertical
    }
    <RadioGroup
      value
      options=[
        ("standard", "Standard", "3–5 business days"),
        ("express", "Express", "1–2 business days"),
        ("overnight", "Overnight", "Next business day"),
      ]
      legend={get("legend")}
      orientation
      disabled={isTrue(get("disabled"))}
      extraClass="max-w-sm"
    />
  },
}

let aspectRatioDef = {
  knobs: [enum("ratio", ["16/9", "4/3", "1/1", "21/9"], "16/9")],
  render: get => {
    let ratio = get("ratio")
    <div class="w-56">
      <AspectRatio ratio extraClass="rounded-lg bg-neutral-200">
        <div class="flex h-full items-center justify-center text-sm font-medium text-neutral-500">
          <View.Text> {ratio} </View.Text>
        </div>
      </AspectRatio>
    </div>
  },
}

let scrollAreaDef = {
  knobs: [enum("orientation", ["vertical", "horizontal", "both"], "vertical")],
  render: get => {
    let orientation = switch get("orientation") {
    | "horizontal" => #horizontal
    | "both" => #both
    | _ => #vertical
    }
    let rows = Array.fromInitializer(~length=24, i =>
      "Row " ++ Int.toString(i + 1) ++ " — the quick brown fox jumps over the lazy dog"
    )
    <ScrollArea orientation extraClass="h-44 w-64 rounded-md border border-neutral-200">
      <ul class="w-max divide-y divide-neutral-100 text-sm">
        <View.For
          each={Prop.static(rows)}
          render={r =>
            <li class="whitespace-nowrap px-3 py-2 text-neutral-700">
              <View.Text> {r} </View.Text>
            </li>}
        />
      </ul>
    </ScrollArea>
  },
}

let inputOtpDef = {
  knobs: [num("length", ~min=4, ~max=8, 6), bool_("disabled", false)],
  render: get => {
    let code = Signal.make("")
    <InputOtp value=code length={toInt(get("length"), 6)} disabled={isTrue(get("disabled"))} />
  },
}

let selectDef = {
  knobs: [bool_("disabled", false)],
  render: get => {
    let value = Signal.make("Medium")
    <Select
      value
      options=["Small", "Medium", "Large", "Extra large"]
      disabled={isTrue(get("disabled"))}
    />
  },
}

let fieldDef = {
  knobs: [text("label", "Work email"), text("hint", "We'll only use this to contact you.")],
  render: get =>
    <div class="w-64">
      <Field label={get("label")} for_="pg-field" hint={get("hint")}>
        <Input id="pg-field" type_="email" placeholder="you@example.com" />
      </Field>
    </div>,
}

let tooltipDef = {
  knobs: [text("content", "Add to library")],
  render: get =>
    <div class="flex h-24 items-center justify-center">
      <Tooltip content={get("content")}>
        <Button variant=#secondary> <View.Text> "Hover me" </View.Text> </Button>
      </Tooltip>
    </div>,
}

let tabsDef = {
  knobs: [enum("orientation", ["horizontal", "vertical"], "horizontal")],
  render: get => {
    let value = Signal.make("account")
    let orientation = switch get("orientation") {
    | "vertical" => #vertical
    | _ => #horizontal
    }
    <div class="w-80">
      <Tabs value orientation tabs=[("account", "Account"), ("password", "Password"), ("team", "Team")] />
    </div>
  },
}

let accordionDef = {
  knobs: [enum("type", ["single", "multiple"], "single"), bool_("collapsible", true)],
  render: get => {
    let value = Signal.make(["what"])
    let type_ = switch get("type") {
    | "multiple" => #multiple
    | _ => #single
    }
    <div class="w-full max-w-md">
      <Accordion
        type_
        collapsible={isTrue(get("collapsible"))}
        value
        items=[
          ("what", "What is a spec?", "A technology-agnostic definition of a UI pattern."),
          ("framework", "Is it tied to a framework?", "No. Each spec maps onto any stack."),
          ("contribute", "Can I contribute?", "Yes — copy the template and open a pull request."),
        ]
      />
    </div>
  },
}

let collapsibleDef = {
  knobs: [text("label", "Show details")],
  render: get => {
    let open_ = Signal.make(false)
    <Collapsible open_ label={get("label")}>
      <View.Text> "Secondary content revealed on demand, pushing the layout below it." </View.Text>
    </Collapsible>
  },
}

let dialogDef = {
  knobs: [text("title", "Edit profile"), text("description", "Make changes and save when you're done.")],
  render: get => {
    let open_ = Signal.make(false)
    <div class="relative flex h-64 w-full max-w-lg items-center justify-center">
      <Button variant=#primary onClick={_ => Signal.set(open_, true)}>
        <View.Text> "Open dialog" </View.Text>
      </Button>
      <Dialog open_ title={get("title")} description={get("description")}>
        <div class="mt-5 flex justify-end gap-2">
          <Button variant=#secondary onClick={_ => Signal.set(open_, false)}>
            <View.Text> "Cancel" </View.Text>
          </Button>
          <Button variant=#primary onClick={_ => Signal.set(open_, false)}>
            <View.Text> "Save" </View.Text>
          </Button>
        </div>
      </Dialog>
    </div>
  },
}

let get = (id: string): option<def> =>
  switch id {
  | "button" => Some(buttonDef)
  | "badge" => Some(badgeDef)
  | "avatar" => Some(avatarDef)
  | "alert" => Some(alertDef)
  | "checkbox" => Some(checkboxDef)
  | "switch" => Some(switchDef)
  | "slider" => Some(sliderDef)
  | "progress" => Some(progressDef)
  | "spinner" => Some(spinnerDef)
  | "skeleton" => Some(skeletonDef)
  | "separator" => Some(separatorDef)
  | "kbd" => Some(kbdDef)
  | "icon" => Some(iconDef)
  | "icon-button" => Some(iconButtonDef)
  | "link" => Some(linkDef)
  | "input" => Some(inputDef)
  | "textarea" => Some(textareaDef)
  | "toggle" => Some(toggleDef)
  | "toggle-group" => Some(toggleGroupDef)
  | "radio-group" => Some(radioGroupDef)
  | "aspect-ratio" => Some(aspectRatioDef)
  | "scroll-area" => Some(scrollAreaDef)
  | "input-otp" => Some(inputOtpDef)
  | "select" => Some(selectDef)
  | "field" => Some(fieldDef)
  | "tooltip" => Some(tooltipDef)
  | "tabs" => Some(tabsDef)
  | "accordion" => Some(accordionDef)
  | "collapsible" => Some(collapsibleDef)
  | "dialog" => Some(dialogDef)
  | _ => None
  }

// ------------------------------------------------------------------- Panel --
// The playground UI: a live preview that re-instantiates on every knob change,
// above a control strip generated from the knob definitions. The preview renders
// whichever implementation is selected — the Xote `render` above, or the reativa
// one mounted into a container the reativa runtime owns (`useReativa`). The
// knobs are shared: both implementations read the same knob state, so switching
// implementations keeps the props you dialed in.

module Panel = {
  @jsx.component
  let make = (~id: string, ~def: def, ~useReativa: Signal.t<bool>) => {
    let initial = def.knobs->Array.map(k => (k.prop, k.init))
    let state = Signal.make(initial)
    let valueOf = (vals, prop) =>
      vals
      ->Array.find(((n, _)) => n == prop)
      ->Option.map(((_, v)) => v)
      ->Option.getOr("")
    let setKnob = (prop, v) =>
      Signal.update(state, vals => vals->Array.map(((n, old)) => n == prop ? (n, v) : (n, old)))
    let current = prop => Computed.make(() => valueOf(Signal.get(state), prop))
    // Re-mount the reativa playground on every knob change (and when it becomes
    // the selected implementation) — reativa rebuilds the component from the
    // knob values, the way `View.Value` re-instantiates the Xote render below.
    let reativaKnobs = ReativaExamples.built && ReativaExamples.hasPlayground(id)
    Effect.run(() => {
      let vals = Signal.get(state)
      if Signal.get(useReativa) && reativaKnobs {
        ReativaExamples.mountPlayground(id, vals)
      }
      None
    })
    <div>
      <div
        class="preview-surface flex min-h-48 items-center justify-center rounded-t-2xl border border-neutral-200 p-10 shadow-sm">
        <View.Show
          when_={Prop.signal(useReativa)}
          fallback={<View.Value
            value={Prop.signal(state)}
            render={vals => def.render(prop => valueOf(vals, prop))}
          />}>
          // The reativa runtime mounts the knob-driven component here.
          <div id={ReativaExamples.playgroundContainerId(id)} />
        </View.Show>
      </div>
      <div class="rounded-b-2xl border border-t-0 border-neutral-200 bg-neutral-50 p-4">
        <div class="mb-3 flex items-center justify-between">
          <span class="text-xs font-semibold uppercase tracking-wide text-neutral-500">
            <View.Text> "Props" </View.Text>
          </span>
          <button
            class="text-xs text-neutral-400 underline underline-offset-4 transition-colors hover:text-neutral-700"
            onClick={_ => Signal.set(state, initial)}>
            <View.Text> "Reset" </View.Text>
          </button>
        </div>
        <div class="grid gap-x-6 gap-y-4 sm:grid-cols-2">
          <View.For
            each={Prop.static(def.knobs)}
            by={k => k.prop}
            render={k => {
              let cur = current(k.prop)
              <div class="flex flex-col gap-1.5">
                <span class="font-mono text-xs text-neutral-500"> <View.Text> {k.prop} </View.Text> </span>
                {switch k.control {
                | Enum(values) =>
                  <div class="flex flex-wrap gap-1">
                    <View.For
                      each={Prop.static(values)}
                      render={v => {
                        let cls = Computed.make(() =>
                          "rounded-md border px-2 py-1 font-mono text-xs transition-colors " ++ (
                            Signal.get(cur) == v
                              ? "border-transparent bg-action text-on-action"
                              : "border-neutral-300 bg-surface text-neutral-600 hover:border-neutral-400 hover:text-neutral-900"
                          )
                        )
                        <button class={Prop.signal(cls)} onClick={_ => setKnob(k.prop, v)}>
                          <View.Text> {v} </View.Text>
                        </button>
                      }}
                    />
                  </div>
                | Bool => {
                    let track = Computed.make(() =>
                      "relative inline-flex h-5 w-9 items-center rounded-full transition-colors " ++ (
                        Signal.get(cur) == "true" ? "bg-action" : "bg-neutral-300"
                      )
                    )
                    let dot = Computed.make(() =>
                      "inline-block size-4 transform rounded-full bg-surface shadow transition-transform " ++ (
                        Signal.get(cur) == "true" ? "translate-x-4" : "translate-x-0.5"
                      )
                    )
                    <button
                      type_="button"
                      role="switch"
                      class={Prop.signal(track)}
                      onClick={_ =>
                        setKnob(
                          k.prop,
                          valueOf(Signal.get(state), k.prop) == "true" ? "false" : "true",
                        )}>
                      <span class={Prop.signal(dot)} />
                    </button>
                  }
                | Text =>
                  <input
                    type_="text"
                    value={Prop.signal(cur)}
                    onInput={e => setKnob(k.prop, Ui.inputValue(e))}
                    class="w-full rounded-md border border-neutral-300 bg-surface px-2.5 py-1.5 text-sm text-neutral-800 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-neutral-900"
                  />
                | Num({min, max}) =>
                  <div class="flex items-center gap-3">
                    <input
                      type_="range"
                      min={Int.toString(min)}
                      max={Int.toString(max)}
                      value={Prop.signal(cur)}
                      onInput={e => setKnob(k.prop, Ui.inputValue(e))}
                      class="w-full accent-neutral-900"
                    />
                    <span class="w-8 text-right font-mono text-xs tabular-nums text-neutral-600">
                      <View.Text> {cur} </View.Text>
                    </span>
                  </div>
                }}
              </div>
            }}
          />
        </div>
      </div>
    </div>
  }
}
