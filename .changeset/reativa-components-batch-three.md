---
"@prescriptive/reativa": minor
---

Add the final batch of reativa example implementations, reaching **full parity**
with the Xote examples — every spec that has a Xote demo now has a matching
**Reativa** preview, mirroring `website/src/Examples.res`.

- **components**: `form`, `resizable`, `search`, `comment`
- **pages**: `dashboard`, `landing-page`, `pricing`, `settings`, `sign-in`
- **flows**: `authentication`, `checkout`, `onboarding`

`search` filters a list live with `View.for_`; `resizable` binds a range input
to a reactive `style` on both panels; `form` submits with `View.On.submit` +
`prevent_default` and reveals a success message via `View.show`; `sign-in` wires
a native checkbox through a reactive `checked` binding; the `authentication` and
`onboarding` flows step through their states from a single `step` signal.
Registered in `Registry.mlx`'s `example_for` / `example_ids`. reativa now covers
26 elements, 42 components, 13 blocks, 5 pages, and 3 flows — the same set Xote
implements.
