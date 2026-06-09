# Loop Patterns

This directory contains documented, reusable loop patterns that have been (or can be) run in real environments.

Each pattern answers:
- What problem it solves
- Recommended scheduling
- Required skills / state shape
- Verification approach
- Human hand-off strategy
- Tool-specific notes (Grok, Claude Code, etc.)

## Current Patterns

- [pr-babysitter.md](./pr-babysitter.md) — Shepherd PRs from draft through review, CI, rebase, and merge.
- (More coming — contributions welcome)

## How to Use a Pattern

1. Copy the relevant skill(s) into your project (or publish as a plugin).
2. Set up the scheduling command (`/loop`, `scheduler_create`, GitHub Action, etc.).
3. Create the initial state file or Linear board view.
4. Start the loop.
5. Iterate on the loop definition based on what actually happens.

Good loops are boring and reliable. Start with one that runs every few hours or daily before going to sub-minute cadences.
