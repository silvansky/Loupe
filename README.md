<p align="center">
  <img src="Docs/Assets/loupe-wordmark.svg" alt="Loupe" width="360">
</p>

Runtime E2E inspection and action harness for iOS Simulator apps.

Loupe injects a lightweight runtime into a simulator app, exposes UIKit and
accessibility state over localhost, and lets you mutate supported UIKit
properties live. Use it to inspect what is actually on screen, try a runtime UI
change, verify the effective value, then reflect the change back into source.

## Demo
https://github.com/user-attachments/assets/52471c43-ec43-4654-9477-b06413660734



## Install

```bash
brew tap heoblitz/loupe https://github.com/heoblitz/Loupe.git
brew install loupe
```

Install the Loupe agent skill:

```bash
loupe skills install
```

## Environment

Loupe is for iOS Simulator only; it does not run against physical devices.
It requires macOS with Xcode and iOS Simulator installed. Because Loupe uses
simulator runtime injection and host-side simulator input, Xcode and iOS
Simulator versions can affect compatibility. When multiple simulators are
booted, pass the exact simulator UDID.

## Start

Start from an agent context:

```text
Use Loupe to inspect a running iOS UI, compare it with the design guide, and improve implementation quality through iteration.
```

If you want direct CLI control:

```bash
loupe start --bundle-id com.example.App --device booted
loupe current
```

When multiple simulators are booted, pass an exact UDID. Loupe chooses an
available localhost port, records the runtime, and resolves later commands by
`--udid` or `--bundle-id`.

## Observe

```bash
loupe tree --udid <UDID> --accessibility --depth 3
loupe tree --udid <UDID> --view --depth 3
loupe current
loupe fetch <runtime-host>/snapshot --output snapshot.json
loupe inspect snapshot.json --test-id checkout.payButton
loupe compact snapshot.json
```

Use accessibility for targets and text. Use the view tree for layout, UIKit
properties, color, size, and mutation refs.

## Act

```bash
loupe tap --udid <UDID> --test-id checkout.payButton --expect-visible checkout.confirmation
loupe tap --udid <UDID> --ref n83
loupe tap --udid <UDID> --x 201 --y 274
loupe swipe --udid <UDID> --from 220,760 --to 220,190
loupe type "Ada" --udid <UDID>
```

## Mutate

```bash
loupe mutations --udid <UDID> --ref n42
loupe set --udid <UDID> --test-id checkout.title text "Runtime title" --output mutation.json
loupe set --udid <UDID> --test-id checkout.card backgroundColor --color '#ff3366'
loupe set --udid <UDID> --test-id checkout.card frame --rect 20,120,220,80
loupe set --udid <UDID> --test-id checkout.card frame --rect 20,120,220,80 --no-animate
loupe reflect mutation.json --source ./Sources
```

Runtime property mutations animate by default. Pass `--no-animate` for immediate
application or tune with `--duration`, `--delay`, and `--curve`.

## Layout

```bash
loupe constraints --udid <UDID> --test-id checkout.card --json
loupe set-constraint --udid <UDID> --id c0x123 constant 120
loupe deactivate-constraint --udid <UDID> --id c0x123
```

Loupe reports requested and effective values so layout-owned changes are visible
instead of silently accepted.

## Debug

```bash
loupe trace-summary /tmp/loupe-trace
loupe diff before-snapshot.json after-snapshot.json
loupe audit snapshot.json
loupe cleanup --dry-run
```

Failed actions write traces under the system temporary `loupe-traces` directory.

## Verify

```bash
scripts/verify-agent-work.sh
```

GitHub Actions runs the same command as the `Post-change E2E` check for pull
requests and `main` pushes.

## Docs

- [Status](Docs/Status.md)
- [Test Plan](Docs/TestPlan.md)
- [Runtime Communication](Docs/RuntimeCommunication.md)
- [Homebrew Distribution](Docs/Homebrew.md)
- [Development Homebrew Overlay](Docs/DevHomebrewOverlay.md)

## Inspiration

Loupe's simulator inspection and action direction is inspired by
[AXe](https://github.com/cameroncooke/AXe) and
[Baguette](https://github.com/tddworks/baguette).
