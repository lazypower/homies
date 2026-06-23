---
name: codex-loop
description: Orient for a pair-programming loop where Claude builds and Codex is the adversarial validator. Use when the user wants to build/harden a feature with Codex as the cross-model reviewer ("pair with codex", "build-break-assess", "have codex review/break this in a loop", "harden X with codex as the gate"). Installs the scope governor that keeps adversarial review from becoming maximalism.
---

# Codex Loop — Build / Break / Assess

You build. Codex breaks. You triage. This skill is the governor that keeps that
loop converging instead of grinding to exhaustion.

The loop is load-bearing in all three seats — but the **third seat (ASSESS) is the
one that's usually unstated and the one that fails.** Codex sharpens every edge; it
has no opinion on whether an edge is in scope. That judgment is yours and the
user's, and it must be made **explicit before round 1**, not discovered at round 9.

## Hard invariants (do not violate)

1. **Cross-model only.** The BREAK seat must be a *different model* — Codex via its
   CLI. Never let Claude (including Claude subagents/workflows) adversarially review
   Claude's own work. That blind spot is the entire reason for a combined front.
   - BUILD seat: Claude (workflows fine).
   - BREAK seat: **Codex CLI only** — it cannot run inside a Claude Workflow.
   - FIX seat: Claude, but fixes must address **Codex's** findings, not Claude self-review.
   - VERIFY/run-tests: either model (mechanical, not judgment).

2. **Iteration is not failure.** On a critical/safety feature built from a skinny
   spec, many rounds are *expected* — in a human org this might take 15–20 iterations.
   Do **not** narrate worst-case exits or pre-offer "is this worth it / should we
   defer" off-ramps while a sound loop is converging. It reads as anticipating
   failure. Report the round's findings + what you're driving, and keep going.
   Reserve a genuine "change course?" escalation for an *actual stall* (fixes
   repeatedly spawning fresh same-class P1s with no convergence) — not routine depth.

3. **Governed, not unbounded.** Iterating without panic AND installing a scope
   governor are complementary, not in tension. Triage out-of-model from round 1;
   checkpoint with the human ~every 5 rounds.

## Step 0 — Frame BEFORE round 1 (non-negotiable)

Write these down explicitly and confirm with the user. This is what was missing the
time this took 20 rounds.

- **Product promise**: what this feature is *for*, in one line.
- **Threat model — what's IN scope**: the **user surface area** — everything the tool
  exposes via CLI / runtime behavior. *Defend this.*
- **Threat model — what's OUT of scope**: **filesystem omnipotence.** An actor who
  can already write `$HOME` / owns the data dir can destroy it directly — hardening
  against every malicious local-FS arrangement is *bunker cosplay, not safety.*
- **Definition of done** = the exit criteria below, NOT "Codex can no longer invent
  an attack."

## Two modes — pick the center of gravity

The loop runs the same in both; what BUILD produces and how Codex BREAKs it differ.
Don't default to Mode B just because the examples are diff-shaped — pick the mode that
matches where the work actually is.

### Mode A — Design audit (pre-build, no code yet)  ← first-class, not a footnote

The subject is a plan / spec / architecture. Common maiden case: validate the design
*before* writing any code, so Codex attacks the idea, not a diff. This is also where
Step 0 pays off most — without a written frame, the adversary invents attacks against a
problem that may not exist (falsify your own premises by measurement *first*).

- BUILD = Claude drafts / refines the design or plan.
- BREAK = `codex exec` read-only, fed the Step-0 frame so it attacks the real boundary:
  ```bash
  codex exec "Adversarial design review — find where this PLAN fails; do not write code.
  Product promise: <...>. In scope: <user surface>. Out of scope: <FS-omnipotence /
  things we don't control>. Hunt for: silent data loss by design, states that don't
  fail closed, invariants the design can't hold, complexity disproportionate to threat."
  ```
- EXIT when the *design* has no silent-data-loss path, fails closed by construction, and
  complexity is proportional. Then graduate to Mode B for the implementation.

### Mode B — Build / break (a diff exists)

The subject is code. BUILD = implement/fix on a branch or worktree; BREAK = `codex review`:
```bash
codex review --base <base-branch>     # diff vs base branch (usual case)
codex review --uncommitted            # staged + unstaged + untracked
codex review --commit <sha>           # a single commit
```
Add a custom adversarial prompt to carry the frame (works on `review` or `exec`):
```bash
codex review --base <base-branch> "Adversarial review. Product promise: <...>.
In scope: user surface via CLI/runtime. Out of scope: an actor who already owns the
data dir. Hunt for reasonable CLI/user paths that silently destroy/corrupt data or
leave a state that does not fail closed."
```

Keep Codex in the BREAK seat in both modes — read-only, never let it fix.

## Running Codex (operational — learned the hard way)

- **Prefer the MCP path for BREAK — it makes hangs observable.** Run Codex via
  `codex mcp-server` (stdio) instead of raw `codex exec`/`codex review`. The MCP
  server streams `codex/event` notifications continuously (`task_started`,
  `agent_message_content_delta`, `token_count`, `task_complete`), so you get a
  live heartbeat instead of staring at 0 bytes. Use the bundled driver:
  ```bash
  python3 ~/.claude/skills/codex-loop/codex_break.py \
    --prompt-file <frame+ask>.txt --effort medium --silence 120 --wall 420
  ```
  It applies a **silence-based timeout** (kill only if *no event* for `--silence`
  seconds) plus a wall-clock backstop, prints heartbeats to stderr, and returns
  Codex's structured `content` on stdout. This converts a *blind* hang into an
  *observable* one — the exact "you go to sleep, it hangs, shit gets weird"
  failure. Resume a thread with `codex-reply` + the `threadId` if you need a
  follow-up without a cold start. (MCP doesn't make Codex internally more
  reliable; it makes a wedge *visible* so you stop waiting on it.)
- **Raw-shell fallback: wrap every invocation in a timeout.** If you must use
  `codex exec`/`codex review` directly, they hang on roughly 1 in 3 calls — zero
  output, never returns. Always run as `timeout 300 codex exec …` (background it;
  set any readiness watcher to the same bound). On timeout, kill + retry **once**;
  if it hangs again, proceed on the tests. `codex exec` buffers all output until
  completion — 0 bytes mid-run is normal, not proof of a hang; the timeout is what
  distinguishes them. (The MCP path above removes this ambiguity — prefer it.)
- **One BREAK per phase; tests are the gate.** Run Codex once per phase, triage,
  fix, then PROVE the fixes with your own tests (unit + integration). Do **not**
  reflexively re-run Codex to "confirm" — that compounds the hang cost and walks
  straight into the never-dry-adversary trap. Re-invoke Codex only when a fix is
  non-trivial or changes the security surface. Codex's silence is not evidence;
  a passing adversarial-case test is.
- **Cross-model still holds:** the BREAK seat is Codex, never a Claude subagent.

## The loop

```
Step 0  FRAME      (Claude + user)  — product promise + threat model + done
  │
  ├─► BUILD        (Claude)         — Mode A: draft design   | Mode B: implement / fix
  │
  ├─► BREAK        (Codex CLI)      — Mode A: codex exec      | Mode B: codex review
  │
  ├─► ASSESS       (Claude)         — triage every finding through the rubric
  │
  └─► loop until exit criteria hold; HARD CHECKPOINT at ~5 rounds
```

## ASSESS — the triage rubric

Codex output is **input, not a mandate.** Bucket every finding:

1. **Correctness / safety defect** (data loss, broken invariant, security on the
   in-scope surface) → **FIX. Non-negotiable.**
2. **Design-direction opinion** → weigh against product intent + bounded scope →
   **accept / defer-and-flag / decline.** A real-but-out-of-current-scope pivot gets
   *flagged as a separate decision, not folded* into a correctness branch.
3. **Out-of-model** (theoretical attacker with `$HOME` write; operator bypasses the
   CLI to mutate files — *unless the CLI caused it*) → **DOCUMENT / REJECT.** Do this
   from round 1.
4. **Volume / repetition** of findings → a **smell, not a checklist.** Step back and
   ask if the *design* is wrong; don't patch round after round.
5. **Taste / nits** → batch or skip.

## The scope governor

**HARD CAP ~5 adversarial rounds.** This is a *brake, not a status report.* At the
cap you **stop by default** and bring the human a checkpoint; continuing to round 6+
requires **explicit user go-ahead**, not operator momentum. "Keep going while
converging" (invariant #2) governs rounds *within* the cap — it is **not** a license
to ride past it because each round still improves something. If you find yourself at
round 6+ without having asked, the governor has already failed.

Checkpoint payload:
- remaining findings (each classified — see protocol below)
- accepted fixes
- rejected out-of-scope threats (and why)
- **complexity delta** — how much cleverness this added
- whether the feature **still matches the original user promise**

### Checkpoint decision protocol (resolves disputed findings)

The exit criteria are judgment calls, so a determined adversary can keep reframing
"reasonable" while ASSESS keeps replying "out of scope" — a vibes stalemate. Break it
by forcing every remaining finding into exactly one bucket, **with a named owner**:

| Bucket | Meaning | Owner |
|---|---|---|
| `fix-now` | in-scope correctness/safety defect | Claude (this round) |
| `prove-with-test` | claimed risk on existing behavior → convert to a passing test | Claude |
| `document-boundary` | out-of-model; record why and move on | Claude + user |
| `separate-decision` | real but a product/scope pivot → its own ticket, not folded in | **user** |

**Default stop rule:** the loop exits when every in-scope **P1/P2** defect has either a
landed fix or a red→green test, and no finding remains unclassified. A finding BREAK
calls "still exploitable" that ASSESS calls "out of scope" is **not** left open — it
resolves into `document-boundary` or `separate-decision`, with the user as tiebreaker
on the latter. Disagreement forces a *classification*, never another round.

### Exit criteria (stop when these hold — NOT when the adversary runs dry)

1. No reasonable CLI / user-path can **silently destroy data.**
2. Unexpected states **fail closed.**
3. **Complexity stays proportional to the threat model.**

### Complexity-as-risk

**Safety features become unsafe when they get too clever.** A rising complexity delta
is itself a risk signal — each added cleverness spawns its own findings (a crash-safety
marker becomes a new attack surface; a clever cross-platform lock-bridge breaks the
very migrations it guards). When a fix is more intricate than the threat it answers,
the simpler design is usually the safer one. Prefer deleting cleverness over hardening it.

## Anti-patterns (caught the hard way)

- Treating every Codex note as must-fix → 4+ wasted rounds and near-misses where a
  design pivot almost folded into a correctness branch.
- Running to round 20 because "Codex can still invent an attack." Ghosts. Stop at the
  exit criteria.
- Hedging about "trajectory" / pre-offering defer ramps 3 rounds in. Hold the line.
- Letting Claude review Claude's own work and calling it adversarial.
- Discovering the threat-model boundary informally at round 9 instead of writing it
  at Step 0.
- Reading frustration into a neutral operational observation and pre-apologizing —
  another face of anticipating failure. Take the observation literally, fix the
  mechanism (e.g. the timeout), skip the emotional read.

## After the loop

Record what was learned in continuity (`continuity remember`) — convergence point,
any threat-model boundary refinements, and complexity decisions worth carrying forward.
