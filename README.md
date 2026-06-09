# Loop Engineering

**Loop engineering is replacing yourself as the person who prompts the agent. You design the system that does it instead.**

A loop is a recursive goal: you define a purpose and the AI iterates (often with sub-agents, verification, and external state) until the goal is complete or the loop decides to hand off to you.

This is the emerging practice of moving from "I prompt → agent responds → I prompt again" to "I design the autonomous system that discovers work, assigns it, verifies results, and drives progress."

## Why This Matters

For years the primary interface was a good prompt plus manual back-and-forth. That model is shifting.

Peter Steinberger:  
> “You shouldn’t be prompting coding agents anymore. You should be designing loops that prompt your agents.”

Boris Cherny (Head of Claude Code at Anthropic):  
> “I don’t prompt Claude anymore. I have loops running that prompt Claude and figuring out what to do. My job is to write loops.”

The leverage point has moved from crafting individual prompts to designing the control systems that orchestrate agents over time.

## The Five Building Blocks + Memory

A robust loop needs these five capabilities, plus persistent external memory (because the model forgets between runs — the repo does not).

| Primitive          | Job in the Loop                          | Why It Matters |
|--------------------|------------------------------------------|----------------|
| **Automations / Scheduling** | Discovery + triage on a cadence         | Turns one-off runs into recurring systems (`/loop`, scheduled tasks, GitHub Actions, hooks) |
| **Worktrees**      | Safe parallel execution                  | Multiple agents working on the same repo without file collisions |
| **Skills**         | Persistent project knowledge             | `SKILL.md` (or equivalent) so the agent doesn't re-derive conventions, constraints, and "why we do it this way" every run |
| **Plugins & Connectors** | Reach into your real tools            | MCP-based connectors to Linear, Slack, GitHub, databases, APIs so the loop can *act* (open PRs, update tickets, notify) |
| **Sub-agents**     | Maker / checker split                    | One agent (or team) explores/implements; a different one verifies. Critical when the loop runs while you're not watching |

**+ Memory / State**  
A durable spine outside any single conversation: a markdown file, Linear board, JSON state, or dedicated project tracker. The loop reads what was tried, what passed, what is still open.

Both Claude Code and OpenAI Codex have converged on versions of all five primitives. The shape of a good loop is becoming somewhat tool-agnostic.

## What One Loop Actually Looks Like

A typical daily loop (inspired by patterns described by Addy Osmani and practiced by teams at Anthropic/OpenAI):

1. An automation runs on a schedule (e.g. every morning or every 30m).
2. It calls a **triage skill** that reads recent CI failures, open issues, commits, Slack threads, etc.
3. Findings are written to external state (markdown or Linear).
4. For worthwhile items:
   - Open an isolated **worktree**.
   - Spawn a sub-agent (implementer) to draft a fix.
   - Spawn a second sub-agent (reviewer/verifier) against project skills + tests.
5. Connectors open/update the PR and ticket.
6. Anything the loop cannot confidently handle lands in a human triage inbox.
7. The state file acts as the memory spine for the next run.

You designed the loop once. You are not the one prompting every micro-step.

## Loop Engineering with Grok Build TUI

The Grok TUI already ships excellent native support for these primitives (this is one reason the concept feels natural here).

**Core tools:**
- `/loop [interval] <prompt>` — the primary user-facing scheduling command (e.g. `/loop 5m Check CI and report new failures`).
- Lower-level scheduler: `scheduler_create`, `scheduler_list`, `scheduler_delete` (supports `recurring`, `durable`, `fireImmediately`).
- `monitor` tool — real-time event streaming (the streaming counterpart to discrete `/loop` checks).
- Background tasks + `Ctrl+G` demote + queue pane (`Ctrl+;`).
- Subagents with `isolation: "worktree"` for safe parallelism.
- Skills (`SKILL.md` + scripts/references).
- MCP servers for connectors.
- Persistent todos + state files for memory.

**Example Grok-native loops people run today:**
- PR babysitting: `/loop 5m /pr-babysit check`
- Continuous test / deploy monitoring
- Daily triage + self-scheduled follow-ups
- Post-merge sweepers and stale PR pruners

See the `examples/grok/` directory and the background-tasks documentation in the Grok user guide for patterns.

## Getting Started

1. Identify a recurring pain (CI noise, PR shepherding, daily triage, post-incident fixes, etc.).
2. Turn the workflow into a **skill** first (write down the intent once).
3. Wrap it with `/loop` or `scheduler_create`.
4. Add verification (sub-agent reviewer or explicit "done" condition checked by a separate model).
5. Add state (a `STATE.md` or Linear integration via MCP).
6. Add connectors so the loop can act, not just suggest.
7. Run it. Watch it. Refine the loop design, not the individual prompts.

Start small. One reliable loop that saves you 15 minutes a day is more valuable than an ambitious one that burns tokens and trust.

## Patterns

See the `patterns/` directory for reusable, documented loop patterns:

- `pr-babysitter` — shepherd PRs through review, rebase, CI, and merge
- `daily-triage` — morning scan of issues, commits, CI, and Slack
- `ci-sweeper` — react to failing checks and propose minimal fixes
- `post-merge-cleanup` — tech debt, deprecations, and follow-ups after merges

Each pattern includes:
- The scheduling primitive
- Required skills
- State shape
- Verification strategy
- Failure modes and human hand-off

## Caveats (Important)

Loop engineering amplifies judgment — both good and bad.

- **Token costs** can explode with sub-agents and long-running loops. Monitor usage.
- **Verification is still on you.** "Done" is a claim until a human confirms the code works and is understandable. Unattended loops make unattended mistakes.
- **Comprehension debt** grows faster. The more code ships without deep human review, the larger the gap between what exists and what you actually grasp.
- **Cognitive surrender** is the comfortable trap. Designing the loop is the cure when done with judgment; it is the accelerant when used to avoid thinking.
- Two people can run the exact same loop and get opposite results. The loop doesn't know the difference. You do.

Addy Osmani:  
> “Build the loop. But build it like someone who intends to stay the engineer, not just the person who presses go.”

Prompting agents directly is still effective. The goal is the right balance.

## Philosophy

Loop engineering is not about removing the human. It is about moving the human to the highest-leverage position: designing the system, encoding good judgment into skills and verifiers, and deciding what should remain under human control.

The best loops are boring, reliable, and transparent. They surface interesting work to you instead of hiding it.

## Sources & Further Reading

- Addy Osmani – [Loop Engineering](https://addyosmani.com/blog/loop-engineering/) (primary synthesis this repo draws from)
- The X thread: https://x.com/addyosmani/status/2064127981161959567
- Boris Cherny (Anthropic, Head of Claude Code) statements on loops, `/loop`, `/goal`, and "I don't prompt Claude anymore"
- Related concepts: Agent Harness Engineering and the Factory Model (Osmani)

## Contributing

This repo aims to be the practical, living reference for loop engineering.

- Share real patterns that have run in production (even small ones).
- Improve the primitives table with new tool capabilities.
- Add tool-specific guides (Grok, Claude Code, Codex, custom harnesses).
- Document failure modes and how good loop design mitigates them.

Pull requests and issues that treat this as engineering (not hype) are very welcome.

## License

MIT

---

*This repository was created as a concrete representation of the loop engineering concept discussed in the Addy Osmani thread and related Anthropic commentary. It is intentionally practical and tool-aware.*
