// PLACEHOLDER — not the real bundle.
//
// The reativa (OCaml + Melange) Prescriptive components live in the @prescriptive/reativa
// package (packages/reativa/src/*.mlx). Building them needs the OCaml toolchain
// (opam + melange), which isn't part of the ReScript/Vite website build, so this
// checked-in stub keeps the site building and the "Reativa" tab present (showing
// a build hint) until the real bundle is generated.
//
// To generate the real bundle (overwrites this file):
//
//     cd website && npm run reativa
//
// which builds @prescriptive/reativa and copies its dist/reativa.bundle.js here.
// See packages/reativa/README.md for the toolchain setup.

export const built = false;
export const example_ids = [
  "aspect-ratio", "avatar", "badge", "button", "checkbox", "icon", "icon-button",
  "input", "input-otp", "kbd", "link", "progress", "radio-group", "scroll-area",
  "separator", "skeleton", "slider", "spinner", "switch", "textarea", "toggle",
  "toggle-group", "accordion", "alert", "collapsible", "dialog", "field", "select",
  "tabs", "tooltip", "announcement-bar", "contact-section", "logo-cloud",
  "newsletter", "page-header", "stat-grid", "steps",
];
export const playground_ids = [
  "button", "badge", "avatar", "alert", "checkbox", "switch", "slider", "progress",
  "spinner", "skeleton", "separator", "kbd", "icon", "icon-button", "link", "input",
  "textarea", "toggle", "toggle-group", "radio-group", "aspect-ratio", "scroll-area",
  "input-otp", "select", "field", "tooltip", "tabs", "accordion", "collapsible",
  "dialog",
];
export function mount_example(_specId, _containerId) {
  /* no-op until the Melange bundle is built */
}
export function mount_playground(_specId, _containerId, _props) {
  /* no-op until the Melange bundle is built */
}
