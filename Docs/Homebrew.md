# Homebrew Distribution

Loupe should be distributed as a Homebrew tap formula.

## User Install

```bash
brew tap heoblitz/loupe https://github.com/heoblitz/Loupe.git
brew install loupe
```

`loupe` does not require a separate simulator action CLI. The Homebrew formula
builds the Loupe CLI and injector; runtime actions use Loupe's native HID
backend.

## Tap Layout

The current repository can be tapped directly with an explicit URL. If we later
want the shorter `brew tap heoblitz/loupe` command, publish the same formula in
the conventional tap repository:

```text
heoblitz/homebrew-loupe
└── Formula
    └── loupe.rb
```

The canonical formula source in this repo is `Formula/loupe.rb`.

## Release Checklist

1. Make the source archive public and immutable.
2. Tag the release, for example `v0.1.0`.
3. Replace the formula `sha256` with the release archive checksum.
4. Run:

```bash
brew tap heoblitz/loupe https://github.com/heoblitz/Loupe.git
brew audit --strict --online heoblitz/loupe/loupe
brew install --build-from-source heoblitz/loupe/loupe
brew test heoblitz/loupe/loupe
```

## Current Status

`v0.1.0` is public and the formula checksum is set. The formula has been
build-verified with a local archive; run the tap install command above after
pushing formula changes to verify the public tap path end to end.
