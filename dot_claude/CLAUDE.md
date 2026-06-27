# Global Instructions

<!-- continuity:managed -->
## Memory

When you want to remember something or are asked to remember something, always use the `continuity` CLI — never the file-based markdown memory system. Do not create MEMORY.md files, do not write to memory directories, do not use frontmatter-based memory files. Those are not your memory system.

Your memory lives in continuity. Reach for it naturally:
- Remembering something: `continuity remember -c <category> -n <name> -s "summary" -b "body"`
- Looking something up: `continuity search "<query>"`
- Browsing what you know: `continuity tree [uri]`
- Understanding who you're working with: `continuity profile`

**Tier character limits — content beyond these is hard-truncated:**
- **`-s` (L0)**: Max 200 characters. One sentence. Injected into every session.
- **`-b` (L1)**: Max 2000 characters (~300 words). Primary context tier. Compress aggressively.
- **`-d` (L2)**: Max 40000 characters. Full content, retrieved on-demand only.

Before searching the codebase for prior decisions, conventions, or context — check continuity first. If you learn something worth keeping, store it immediately.

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
