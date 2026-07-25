---
"@prescriptive/reativa": minor
---

Add the first batch of 20 more `@prescriptive/reativa` example implementations, so
these specs get a **Reativa** preview alongside the Xote one — matching the
demos in `website/src/Examples.res`.

- **elements**: `label`, `legend`, `logo`, `typography`
- **components**: `breadcrumb`, `button-group`, `card`, `empty-state`, `footer`,
  `input-group`, `list`, `pagination`, `stat`, `toolbar`
- **blocks**: `cta-section`, `faq`, `feature-grid`, `hero`, `pricing-table`,
  `testimonial`

Each is a plain composition over `Reativa.View` — reusing the existing `Button`,
`Badge`, `Avatar`, `Icon`, `IconButton`, `Separator`, `Input`, and `Link`
components — styled against `@prescriptive/tokens` so a re-theme cascades through
them exactly like the Xote implementations. `pagination` and `faq` are reactive
(active page / open item held in a signal). Registered in `Registry.mlx`'s
`example_for` / `example_ids` so the website surfaces a Reativa tab for each.
This brings reativa to 26 elements, 18 components, and 13 blocks.
