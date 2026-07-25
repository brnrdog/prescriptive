// Bridges the reativa (OCaml + Melange) component implementations into the
// ReScript/Xote website. The components live in the @prescriptive/reativa package
// (packages/reativa/src/*.mlx) and are compiled + bundled to
// website/src/reativa.bundle.js by `npm run reativa`.
//
// Until that bundle is built, a checked-in placeholder stands in with
// `built = false`, so the site still compiles and selecting "Reativa" renders a
// short build hint instead of the live components.

@module("./reativa.bundle.js") external built: bool = "built"
@module("./reativa.bundle.js") external exampleIds: array<string> = "example_ids"
@module("./reativa.bundle.js") external playgroundIds: array<string> = "playground_ids"
@module("./reativa.bundle.js")
external mountExampleRaw: (string, string) => unit = "mount_example"
@module("./reativa.bundle.js")
external mountPlaygroundRaw: (string, string, array<(string, string)>) => unit = "mount_playground"

// The specs that have a reativa implementation — these get a "Reativa" preview
// alongside the Xote one. Sourced from the bundle so the two never drift.
let ids = exampleIds
let has = id => ids->Array.includes(id)

// The specs whose reativa implementation also renders from the playground's
// knobs. A spec with an example but no playground arm keeps its plain example
// when "Reativa" is selected.
let hasPlayground = id => playgroundIds->Array.includes(id)

// The dom ids of the containers the reativa runtime mounts into. The example and
// the playground get their own, so a spec can host both without collision.
let containerId = id => "reativa-example-" ++ id
let playgroundContainerId = id => "reativa-playground-" ++ id

// Mount a spec's reativa example into its container. Deferred a tick so the
// Xote-rendered container node is in the DOM before reativa looks it up.
let mount = id => Ui.setTimeout(() => mountExampleRaw(id, containerId(id)), 0)

// Mount a spec's reativa playground, rendered from the knob values the control
// strip currently holds. Called again on every knob change — reativa rebuilds
// the component from scratch, mirroring how the Xote playground re-instantiates
// its render function.
let mountPlayground = (id, props) =>
  Ui.setTimeout(() => mountPlaygroundRaw(id, playgroundContainerId(id), props), 0)
