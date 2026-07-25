// Generates src/ReativaSource.res — the OCaml (Melange + mlx) source of every
// reativa example, keyed by spec id — so a detail page can show the source of
// whichever implementation is selected, not just the Xote one.
//
// The counterpart of generate-snippets.mjs: that one extracts the Xote examples
// from website/src/Examples.res, this one extracts the reativa examples from
// packages/reativa/src/Registry.mlx. Both keep the implementation as the single
// source of truth and only lift it into a ReScript string table.
//
// Any reativa component an example composes (Button, Badge, …) is prepended,
// dependency-ordered, so each snippet is self-contained and shows the reuse.
import { readFileSync, writeFileSync, readdirSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const srcDir = join(here, "..", "src");
const pkgDir = join(here, "..", "..", "packages", "reativa", "src");
const registrySrc = readFileSync(join(pkgDir, "Registry.mlx"), "utf8");
const outFile = join(srcDir, "ReativaSource.res");

// Every component module in the package, by module name (Button.mlx → Button).
// Registry itself is the file we extract examples from, and Contracts/Icons/Ui
// are generated or shared plumbing rather than components — leave them out, the
// way the Xote generator leaves out Contracts.res and Ui.res.
const SKIP = new Set(["Registry", "Contracts", "Icons", "Ui"]);
const componentFiles = {};
for (const name of readdirSync(pkgDir)) {
  const m = name.match(/^([A-Z]\w*)\.(mlx|ml)$/);
  if (m && !SKIP.has(m[1])) componentFiles[m[1]] = name;
}

// Read a component module and drop the plumbing that only makes sense in the
// package: the blanket warning attribute, the leading doc comment, and the
// `open Reativa*` lines every module repeats.
function componentBody(name) {
  const raw = readFileSync(join(pkgDir, componentFiles[name]), "utf8");
  const lines = raw.split("\n");
  let i = 0;
  const skippable = (l) => l.trim() === "" || l.startsWith("[@@@warning") || l.startsWith("open ");
  // Leading attribute / blank lines.
  while (i < lines.length && skippable(lines[i])) i++;
  // Leading doc comment block.
  if (lines[i]?.startsWith("(*")) {
    while (i < lines.length && !lines[i].includes("*)")) i++;
    i++;
  }
  while (i < lines.length && skippable(lines[i])) i++;
  return lines.slice(i).join("\n").trimEnd();
}
const componentSrc = Object.fromEntries(
  Object.keys(componentFiles).map((n) => [n, componentBody(n)]),
);

// Registry's local module aliases (`module Link_ = Link` — it captures this
// package's Link before `open Reativa` shadows it with the Router's), so a
// reference through the alias still resolves to the component it points at.
const aliases = {};
for (const m of registrySrc.matchAll(/^module\s+(\w+)\s*=\s*(\w+)\s*$/gm)) {
  if (componentSrc[m[2]]) aliases[m[1]] = m[2];
}

// Module names referenced as `Name.make` in a chunk of code, alias-resolved.
function refs(text) {
  const found = new Set();
  for (const m of text.matchAll(/\b([A-Z]\w*)\.make\b/g)) {
    const name = aliases[m[1]] ?? m[1];
    if (componentSrc[name]) found.add(name);
  }
  return [...found];
}

// The alias lines an example needs, so a snippet that calls `Link_.make` also
// shows where `Link_` comes from.
function aliasLines(code) {
  return Object.entries(aliases)
    .filter(([alias]) => new RegExp(`\\b${alias}\\.make\\b`).test(code))
    .map(([alias, target]) => `module ${alias} = ${target}`);
}

// Dependency-ordered closure of the components an example needs.
function collect(seed) {
  const seen = new Set();
  const order = [];
  const visit = (name) => {
    if (seen.has(name) || !componentSrc[name]) return;
    seen.add(name);
    for (const dep of refs(componentSrc[name])) visit(dep);
    order.push(name);
  };
  seed.forEach(visit);
  return order;
}

const indent = (t) => t.split("\n").map((l) => (l.length ? "  " + l : l)).join("\n");
const wrapComponent = (name) => `module ${name} = struct\n${indent(componentSrc[name])}\nend`;

// Every top-level `let <name> ... =` binding in Registry.mlx, sliced from its
// `let` to the line before the next top-level `let`/comment banner.
const bindings = {};
{
  const starts = [];
  for (const m of registrySrc.matchAll(/^let\s+([a-z_][\w']*)/gm)) starts.push([m[1], m.index]);
  const boundary = /^(let\s|\(\*)/m;
  for (const [name, start] of starts) {
    const rest = registrySrc.slice(start + 1);
    const next = rest.search(boundary);
    bindings[name] = registrySrc.slice(start, next === -1 ? undefined : start + 1 + next).trimEnd();
  }
}

// The local helpers the inline example compositions lean on, prepended when an
// example actually uses one so the snippet stands alone.
const HELPERS = ["txt", "el"];
const usesHelper = (code, name) => new RegExp(`(^|[^\\w'])${name}(\\s|\\()`, "m").test(code);

// Map spec id -> example binding name from the `example_for` match.
const idToBinding = {};
for (const m of registrySrc.matchAll(/\|\s*"([^"]+)"\s*->\s*(\w+)\s*\(\)/g)) {
  idToBinding[m[1]] = m[2];
}

const s = (v) => JSON.stringify(v); // valid ReScript string literal

const arms = Object.entries(idToBinding)
  .filter(([, binding]) => bindings[binding])
  .map(([id, binding]) => {
    const code = bindings[binding];
    const parts = collect(refs(code)).map(wrapComponent);
    const alias = aliasLines(code);
    if (alias.length) parts.push(alias.join("\n"));
    for (const h of HELPERS) {
      if (usesHelper(code, h) && bindings[h]) parts.push(bindings[h]);
    }
    parts.push(code);
    return `  | ${s(id)} => Some(${s(parts.join("\n\n"))})`;
  })
  .join("\n");

const out = `// GENERATED FILE — do not edit by hand.
// Run \`npm run snippets:reativa\` (scripts/generate-reativa-source.mjs) to regenerate.
// Source is extracted verbatim from packages/reativa/src (Registry.mlx and the
// components its examples compose).

let get = (id: string): option<string> =>
  switch id {
${arms}
  | _ => None
  }
`;

writeFileSync(outFile, out);
console.log(
  `Wrote ${arms.split("\n").filter(Boolean).length} reativa snippets to ${outFile}`,
);
