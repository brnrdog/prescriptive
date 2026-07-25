---
"@prescriptive/reativa": patch
---

Fix special characters rendering as mojibake in the reativa components. Text
like em dashes, ellipses, checkmarks and the collapsible/select carets was
written as UTF-8 byte escapes in plain OCaml string literals (`"\xe2\x80\x94"`),
which Melange emits one byte per JS code unit — so the browser showed `â€"`
instead of `—`. Every affected literal now uses Melange's js-quoted string
(`{js|—|js}`), which compiles to a real JavaScript string.
