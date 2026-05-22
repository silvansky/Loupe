# Contributing

Keep changes small and tied to the issue, experiment, or CLI behavior being
improved.

Before opening a pull request, run:

```bash
scripts/verify-agent-work.sh
```

GitHub Actions runs the same post-change harness for pull requests and `main`
pushes.

If local simulator state blocks runtime E2E, include the failing command,
simulator device, and observed error in the pull request.
