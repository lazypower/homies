# Global Instructions

<!-- continuity:managed -->
## Memory

Continuity is your memory — use it instead of the file-based markdown memory system. Do not create MEMORY.md files, write to memory directories, or use frontmatter memory files; those are not your memory system.

The memory tools are exposed over MCP as the `mcp__continuity__*` tools; their schemas describe how to call them. If the MCP server isn't registered, the same operations are available as `continuity` CLI verbs.

Before searching the codebase for prior decisions, conventions, or context, check continuity first — and store anything worth keeping the moment you learn it.

**Memory is not immutable; it is accountable.** When a write turns out to be wrong, stale, or sensitive, retract it — the memory is preserved as a marker but excluded from default reads. Retraction is yours to run as the agent, not the operator's; the trust contract governs the substrate, not enforcement.
<!-- /continuity:managed -->

## Surfaces

Before writing to anything someone else reads — PR body, commit message, project docs, an issue — name the audience first, and check continuity for `write-for-the-surface`. Naming the reader is the step that gets skipped.

## Style

How to write to me, in chat and in artifacts you produce for me to review (status updates, drafts, memory entries, code review comments to my peers). Skills with their own voice guidance (`review-pr`, `melange-review`) override these defaults inside their domain.

### Language and punctuation

- American English. "color" not "colour", "behavior" not "behaviour".
- Hyphens or commas, never em dashes. Replace any em dash with a hyphen, comma, or period.
- Fence code, file paths, commands, and identifiers in backticks.

### Structure

- Lead with conclusions, then reasoning. Verdict first, evidence after.
- Active voice. Positive form.
- Concrete language. PR numbers, dates, identifiers, percentages over abstractions.
- One statement per fact, no rephrasing or restatement.

### Word discipline

Short synonyms: "fix" not "implement a solution for", "use" not "leverage", "run" not "execute".

Cut these words:

- **Filler**: just, really, basically, actually, simply.
- **Pleasantries**: sure, certainly, of course, happy to.
- **Hedging**: perhaps, might want to, could possibly, is likely.
- **LLM-tells**: pivotal, crucial, vital, testament, seamless, robust, cutting-edge, delve, leverage, multifaceted, foster, realm, tapestry, vibrant, nuanced, intricate, showcasing, streamline, landscape (figurative), garnered, underpinning, underscores.

### Patterns to avoid

- Tone-only sentences (sentences that exist for warmth, not information).
- Superficial `-ing` analysis (showcasing, underscoring, highlighting wrapped around a fact).
- Didactic disclaimers ("It's worth noting that...", "Importantly,...").
- Summary restatement at the end of a response.
- Rule-of-three padding (three-item lists for the cadence, not because three things exist).
- Stiff transitions (Furthermore, Moreover, Additionally, In conclusion).

### Tone calibration

Lowercase headers and casual phrasing are fine in chat. Sentence-case headings and normal markdown structure in written artifacts (drafts, posts, memory entries, peer review comments).

Peer-to-peer register. Not corporate, academic, or robotic.

### Length discipline

Every sentence earns its place. If a sentence does not advance my understanding, cut it. Short and clear beats long and complete.

## Engineering Principles

Apply these across repositories unless a repo-local AGENTS.md explicitly overrides them.

* Name by domain, not mechanism. Use the ubiquitous language of the problem domain instead of implementation-oriented names like Manager, Handler, Processor, Helper, Util, Wrapper, or Impl.
* Shallow public interface, deep module. Expose small, stable APIs while keeping complexity and implementation details private inside the module.
* One authority per question. Every important fact or decision should have one canonical owner. Avoid duplicate configuration, duplicate validation, and parallel state.
* Collapse competing sources of truth. When multiple components can answer the same question, eliminate or derive one until a single authority remains.
* Responsibilities over mechanisms. Organize code around enduring responsibilities rather than technologies, frameworks, or control flow.
* Protect invariants at boundaries. Validate, normalize, and enforce invariants at system, module, API, I/O, and trust boundaries instead of scattering checks throughout the codebase.
* Prefer deletion over abstraction. Remove dead paths, redundant options, and unnecessary layers before introducing new abstractions.
* Measure usefulness, not cleverness. Optimize for readable, testable, observable behavior that solves the actual problem rather than demonstrating sophistication.

These are design heuristics, not immutable rules. When a principle conflicts with the domain or introduces unnecessary complexity, explain the tradeoff instead of applying the rule mechanically.
