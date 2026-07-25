---
"@prescriptive/reativa": minor
---

Render the website's playground with reativa too. `Registry.mlx` gains
`playground_for` — a knob-driven render of a single component for each of the 30
specs the playground covers (`button`, `badge`, `avatar`, `alert`, `checkbox`,
`switch`, `slider`, `progress`, `spinner`, `skeleton`, `separator`, `kbd`,
`icon`, `icon-button`, `link`, `input`, `textarea`, `toggle`, `toggle-group`,
`radio-group`, `aspect-ratio`, `scroll-area`, `input-otp`, `select`, `field`,
`tooltip`, `tabs`, `accordion`, `collapsible`, `dialog`) — mirroring the Xote
render functions prop for prop, with the generated contract types keeping the
allowed values honest.

Two new exports join the JS surface the website consumes:
`mount_playground(specId, containerId, props)`, which renders a spec from the
knob values the props panel currently holds, and `playground_ids`, so the site
knows which specs reativa can drive.
