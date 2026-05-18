# Loupe

Runtime E2E inspection and action harness for iOS Simulator apps.

## Install

```bash
brew tap heoblitz/loupe https://github.com/heoblitz/Loupe.git
brew install loupe
```

The Homebrew formula installs AXe as a dependency for runtime actions.

## Launch

```bash
loupe doctor
loupe injector-path

loupe launch \
  --bundle-id dev.loupe.example \
  --device booted \
  --inject
```

When `--inject` is used without `LOUPE_PORT`, Loupe assigns and records a stable
localhost port for that simulator. Later commands can use `--udid` without
passing `--host`.

```bash
loupe launch --bundle-id dev.loupe.example --device <UDID> --inject
loupe runtime --udid <UDID>
```

Use `--env LOUPE_PORT=<port>` only when you need a fixed port.

## Inspect

```bash
loupe fetch http://127.0.0.1:8765/snapshot --output snapshot.json
loupe compact snapshot.json
loupe runtimes
loupe tree --udid booted --view --depth 3
loupe tree snapshot.json --accessibility --test-id checkout.payButton --depth 2
loupe query snapshot.json --test-id checkout.payButton
loupe query snapshot.json --tree accessibility --test-id checkout.payButton
loupe accessibility snapshot.json
loupe inspect snapshot.json --test-id checkout.payButton
loupe subtree snapshot.json --test-id checkout.form --depth 3
loupe audit snapshot.json
loupe wait-for-visible --host http://127.0.0.1:8765 --test-id checkout.payButton --timeout 5
loupe wait-for-gone --host http://127.0.0.1:8765 --test-id checkout.loading
loupe wait-for-value --host http://127.0.0.1:8765 --test-id checkout.switch --key uiKit.switch.isOn --equals true
```

## Act

```bash
loupe tap --host http://127.0.0.1:8765 --udid booted --test-id checkout.payButton --expect-visible checkout.confirmation
loupe tap --udid booted --ref n83
loupe tap --udid booted --x 201 --y 274
loupe swipe --udid booted --from 220,760 --to 220,190 --width 438 --height 954
loupe drag --udid booted --from 4,430 --to 390,430 --duration 0.8
loupe type "Ada" --udid booted
loupe screenshot --udid booted --output screen.png
```

## Record

```bash
loupe record start checkout-flow --host http://127.0.0.1:8765
loupe record stop --host http://127.0.0.1:8765
loupe recordings

loupe replay checkout-flow \
  --host http://127.0.0.1:8765 \
  --udid booted \
  --width 438 \
  --height 954
```

Use `--udid <UDID>` on `runtime`, `logs`, `record`, and `recording` when you
want Loupe to verify that the host belongs to the expected simulator.

`loupe tap` intentionally does not accept text selectors. Use stable
`accessibilityIdentifier` / `testID`, a Loupe `ref`, or explicit coordinates.
Failed runtime actions automatically save a trace under `/tmp/loupe-traces`.

## Verify

```bash
swift test
Examples/LoupeExample/run-injected.sh
Examples/LoupeExample/run-runtime-e2e.sh
Examples/LoupeExample/run-axe-scenarios.sh
Examples/LoupeExample/run-bookmark-e2e.sh
Examples/LoupeExample/run-loupe-driven-ui-test.sh
```

Current status and design notes live in `Docs/Status.md`, `Docs/TestPlan.md`,
`Docs/RuntimeCommunication.md`, and `Docs/Homebrew.md`.
