# Actions And Mutations

Use this only when the task needs input, trace proof, mutation, self-sizing, or
source reflection.

## Action Shapes

```bash
$LOUPE act tap --host <host> --snapshot <snapshot.json> --ref n21 --udid <sim-udid> --trace-dir <trace-dir>
$LOUPE act tap --host <host> --x 201 --y 274 --width 438 --height 954 --udid <sim-udid> --trace-dir <trace-dir>
$LOUPE act swipe --host <host> --from 219,760 --to 219,190 --udid <sim-udid> --trace-dir <trace-dir>
$LOUPE act drag --host <host> --from 350,240 --to 80,240 --udid <sim-udid> --trace-dir <trace-dir>
$LOUPE act type "example text" --host <host> --udid <sim-udid> --trace-dir <trace-dir>
$LOUPE act wait value --host <host> --test-id feed.list --key uiKit.scrollView.contentOffset.y --equals 80 --output <wait.json>
$LOUPE debug trace summary <trace-dir>
```

Use one fresh trace directory per attempt.

## Proof Rules

- Refs are snapshot-scoped. Recapture before acting when the screen may have
  changed, or pass `--snapshot` when acting on a saved ref.
- Prove action results with trace summary/diff plus fresh report, screenshot,
  query, node, content offset, log, default, focus, or state evidence.
- System permission alerts are outside the app runtime tree. Use screenshot or
  host/simulator evidence; do not claim an app query tapped the alert.
- `act type` writes into the current selection; focusing can select existing
  text, so typing may replace instead of append. Traces redact requested input,
  so prove the final value with a fresh report/query/node and never raw
  secrets.
- Secure inputs may still query as `textField`; prove security with
  `uiKit.textField.isSecureTextEntry` and redacted text/value evidence.
- `act wait`, `act drag`, and `debug scroll` need explicit postconditions:
  selector, key or coordinates, output/trace path, expected state, and fresh
  after-proof.
- iOS/tvOS simulators use native HID. macOS tap is AppKit control activation.
  watchOS, visionOS, and custom SwiftUI surfaces may correctly fail unless
  trace/screenshot/report/probe/state evidence proves otherwise.

## Mutations

```bash
$LOUPE ui mutations --host <host>
$LOUPE ui set --host <host> --snapshot <snapshot.json> --ref n21 textColor --color '#ff3366' --no-animate --output <set.json>
$LOUPE ui set --host <host> --test-id cell.title layout.hugging.horizontal 260 --try-self-sizing --no-animate
$LOUPE ui set-many --host <host> --refs n21,n22 alpha --number 0.5 --trace-dir <trace-dir>
$LOUPE ui reflect <set.json> --source <source-root> --output <reflect.json>
```

- `ui mutations` lists live capabilities; it does not take a selector.
- Prefer stable `testID`; use `ref` only from the current screen or with the
  source snapshot for saved-ref mapping.
- Dynamic table/collection cells can reuse refs. Mutate a current ref
  immediately, save the mutation response, inspect requested/effective state,
  and reflect that exact output.
- Use `--no-animate` for deterministic verification. Frame and Auto Layout
  mutations are probes until a fresh `ui node` confirms effective state.
- `--try-self-sizing` is conservative. `applied` means Loupe invalidated a
  supported list context; skip reasons such as `collection_layout_sizing_unknown`
  or `delegate_size_for_item_owns_cell_size` are bounded results.
- `ui reflect` returns ranked source hints, not an automatic patch. Empty
  candidates or weak bridge hints can be correct; compare them with the
  observed hierarchy before patching.
