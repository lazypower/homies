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

1. **Cross-model only.** The BREAK seat must be a *different model* — Codex via the
   MCP driver. Never let Claude (including Claude subagents/workflows) adversarially
   review Claude's own work. That blind spot is the entire reason for a combined front.
   - BUILD seat: Claude (workflows fine).
   - BREAK seat: **Codex only** (via `codex_break.py`) — it cannot run inside a Claude Workflow.
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
- BREAK = Codex read-only via the MCP driver (see "Running Codex"), fed the Step-0
  frame so it attacks the real boundary. Write the frame+ask to a file, then run:
  ```bash
  cat > /tmp/break.txt <<'EOF'
  Adversarial design review — find where this PLAN fails; do not write code.
  Product promise: <...>. In scope: <user surface>. Out of scope: <FS-omnipotence /
  things we don't control>. Hunt for: silent data loss by design, states that don't
  fail closed, invariants the design can't hold, complexity disproportionate to threat.
  EOF
  python3 ~/.claude/skills/codex-loop/codex_break.py \
    --prompt-file /tmp/break.txt --cwd <repo> --effort medium --silence 120 --wall 420
  ```
- EXIT when the *design* has no silent-data-loss path, fails closed by construction, and
  complexity is proportional. Then graduate to Mode B for the implementation.

### Mode B — Build / break (a diff exists)

The subject is code. BUILD = implement/fix on a branch or worktree. BREAK = Codex
reviewing the diff via the MCP driver, framed as an exec prompt against an **explicit
diff range**. Do NOT reach for `codex review --base <branch> "<prompt>"`: that form is
rejected by the CLI parser (see "Running Codex"), and `--base <branch>` on a worktree
diffs against the *current* branch tip, not the PR's branch point.

Compute the merge-base, write the frame, run the driver from the worktree:
```bash
cd <worktree>
MB=$(git merge-base HEAD <base-branch>)   # e.g. main; NOT the live branch tip
cat > /tmp/break.txt <<EOF
You are the BREAK seat in an adversarial code review. Read-only; do NOT write code.
Inspect the diff with:  git diff ${MB}..HEAD
Product promise: <...>. In scope: user surface via CLI/runtime. Out of scope: an actor
who already owns the data dir. Hunt for reasonable CLI/user paths that silently
destroy/corrupt data or leave a state that does not fail closed.
Report findings as: [P1|P2|P3] <one line> — <file>:<line>. Then stop.
EOF
python3 ~/.claude/skills/codex-loop/codex_break.py \
  --prompt-file /tmp/break.txt --cwd <worktree> --effort medium --silence 120 --wall 420
```

Keep Codex in the BREAK seat in both modes — read-only, never let it fix.

## Running Codex (operational — learned the hard way)

- **The MCP driver IS the BREAK path — use it for both modes, not as a fallback.**
  Run Codex via `codex mcp-server` (stdio) through the bundled driver:
  ```bash
  python3 ~/.claude/skills/codex-loop/codex_break.py \
    --prompt-file <frame+ask>.txt --cwd <repo-or-worktree> --effort medium --silence 120 --wall 420
  ```
  It streams `codex/event` heartbeats (`task_started`, `agent_message_content_delta`,
  `token_count`, `task_complete`) to stderr, applies a **silence-based timeout** (kill
  only if *no event* for `--silence`s) plus a wall backstop, and prints Codex's findings
  on stdout. Two reasons it's primary, not optional:
  1. **It carries the Step-0 frame.** The MCP `codex` tool takes a prompt. Raw
     `codex review --base <branch>` and `codex review --uncommitted` **reject a
     `[PROMPT]` argument** (`error: the argument '--base <BRANCH>' cannot be used with
     '[PROMPT]'` — the stdin `-` form is rejected too). So the raw review path *cannot*
     receive your adversarial frame at all; the MCP/exec path is the only one that can.
  2. **It makes hangs observable** — a live heartbeat instead of staring at 0 bytes,
     converting a *blind* hang into an *observable* one.
  `codex mcp-server` exposes only `codex` and `codex-reply` (there is **no `review`
  tool**), so a diff review is an exec prompt that runs `git diff <merge-base>..HEAD`
  itself. Resume a thread with `codex-reply` + the `threadId` for a follow-up without a
  cold start. (Validated 2026-06-29 against mono#44067: 26–73s, exit 0, reproduced the
  same P1s as a raw `codex review` while also carrying the frame.)
- **The reviewer runs in an isolated, capability-stripped `CODEX_HOME`.** The driver
  defaults `--codex-home ~/.codex-loop`, a minimal config the Codex desktop app never
  rewrites. It deliberately loads **no MCP servers and no connectors**: no `node_repl`
  (the computer-use / browser-control client), no marketplace plugins (browser, sites),
  and `[features] apps = false` to kill the hosted `codex_apps` connector
  (sites/deploy/documents). An autonomous adversarial reviewer reads code and runs
  read-only shell (`git diff`) — it does not control the machine, drive a browser, or
  deploy anything. Verified: a review under this home starts with `mcp_startup_complete`
  and **zero servers**. `auth.json` is symlinked to `~/.codex/auth.json` so token
  refreshes stay in sync. To add a capability back, edit `~/.codex-loop/config.toml`
  deliberately — never point the loop at the desktop app's `~/.codex`.
- **Always diff against the merge-base, never the live branch tip.** `--base main`
  (or a bare `git diff main`) on a worktree cut from an old main diffs against the
  *current* main tip — possibly hundreds of unrelated commits, an enormous bogus diff
  that churns for minutes and reads as a hang. Use `MB=$(git merge-base HEAD <base>)`
  and diff `${MB}..HEAD`. (On mono#44067 this was the difference between 12 files and
  855 files.)
- **Raw-shell fallback (only if the driver is unavailable).** `codex exec "<prompt>"`
  accepts a prompt and works; wrap it in `timeout 300` (background it; set any readiness
  watcher to the same bound), kill + retry **once** on timeout, then proceed on the
  tests. `codex review` does NOT take a custom prompt — run it bare against an explicit
  ref (`codex review --base <merge-base-sha>`) and accept its built-in review prompt.
  `codex exec` buffers all output until completion — 0 bytes mid-run is normal, not a
  hang; the timeout distinguishes them.
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
  ├─► BREAK        (Codex via MCP)  — both modes: codex_break.py against the diff/plan
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
