---
name: rigor
description: Load this skill at the start of any engineering session that involves writing tests, replicating reference behaviour from an oracle (a paper, an upstream tool, a wire format), responding to a user message that contains URLs or file paths, or making claims that could be verified against an artifact. Language-agnostic agent-discipline rules; supplements per-stack skills like `rust`.
---

# Honest Work for Honest Robots

When you do engineering work without rigor, the failures share a shape: you
claim knowledge or progress that you do not actually have. You answer a question
about a link by extrapolating from its title rather than reading it. You write
a test that prints `ok` because nothing was attempted. You replicate a published
preprocessing recipe by approximating its constants because the approximation
looked cleaner. You enumerate the wrong testing strategy for the input domain
and miss whole classes of bug.

Each of these is detectable, none is malicious, and all of them are cheap to
disarm in advance. This skill is the disarming kit. It is language-agnostic and
applies to any engineering task in any stack; per-stack skills (like `rust`)
build on top of it for the tooling-specific moves.

Core themes:

- **Knowing requires evidence.** Fetch links, read files, look up references
  before responding.
- **Replicate byte-exact.** Match authoritative behavior precisely; pin sources
  by hash.
- **Tests must discriminate.** Every test fails when the behavior it verifies
  breaks.
- **Match test strategy to domain.** Closed domains get exhaustive tables; open
  domains get property tests.

## Oracles are uniquely powerful

When the work is to **replicate behaviour that already exists somewhere
authoritative** — a published algorithm's preprocessing recipe, a canonical
constant table, a wire format, the way an upstream tool formats output — that
authoritative source is your **oracle**. An oracle converts the work from
"design something correct" into "match something correct", which is enormously
cheaper and enormously more verifiable.

Use oracles aggressively:

- **Replicate byte-exact.** If the oracle says `(x − 127.5) / 128.0`, write that
  — not `(x − 128) / 128` because it looked cleaner. Tiny drifts are the class of
  bug type systems cannot catch.
- **Pin by content hash.** For file oracles (model artifacts, reference
  datasets, binaries), commit the sha256 so future builders recover exact bytes.
  Named oracles drift.
- **Preserve disagreements.** Two oracles for the same pipeline often disagree
  (`/ 128.0` vs `/ 127.5`). The disagreement is load-bearing; comment both
  sources, don't unify.
- **Cross-check implementations.** Alternative ports or independent
  implementations reveal which oracle you're actually replicating vs. what
  documentation claims.

Where there is no obvious external oracle, look for the testable analogue: a
property that any correct implementation must satisfy (a normaliser produces
unit output; a serialiser round-trips; suppression suppresses, never invents).
Those are oracles too — internal ones — and they belong in property tests (see
below).

The anti-pattern is the project-name oracle: "we are replacing X, so X is the
oracle." Almost always the real oracles are the *upstream sources X itself
was built against* — published constants, canonical preprocessing, wire-format
specifications. Replicating X uncritically replicates X's bugs.

## Note open vs. closed testing domains

The first question to ask about any new test is: **what is the domain of inputs
the code under test must handle correctly, and is that domain enumerable in a
reasonable time?**

See the broader framing in [*On Tests and Perceptual Domain Modeling*]. The
operational version:

[*On Tests and Perceptual Domain Modeling*]: https://isaaccorbrey.com/ramblings/on-tests-and-perceptual-domain-modeling

- A **closed domain** has a small, enumerable set of meaningful inputs —
  the variants of an enum, the bytes of an opcode table, the eight cardinal
  directions, the formats a CLI accepts. Closed domains get **exhaustive table
  tests**. One row per meaningful input, expected output in the second column.
  If you find yourself reaching for a random-input loop over a closed domain,
  you are doing it wrong; enumerate.
- An **open domain** is too big to enumerate but admits **invariants** that any
  correct output must satisfy. Examples: any bytestring through a serialiser
  must round-trip; any image dimensions through a resize must preserve aspect
  ratio within tolerance; any sequence of bounding boxes through non-maximum
  suppression must produce a subset of the input where no two outputs exceed the
  IoU threshold. Open domains get **property-based tests**. Write the invariant;
  let the generator produce the inputs.

The hinge: would the test catch a bug that a unit test wouldn't? If yes, write
the property/integration test *instead of* the unit test, not in addition.
No coverage-for-coverage's-sake. A test that does not justify itself by
discriminating real behaviour from broken behaviour is debt.

**The operational corollary: write the property test the same change that
introduces the encoder.** Every new pure encoder, decoder, or transformer earns
a property test alongside it, not in a follow-up cleanup change. If you cannot
state an invariant the new function must satisfy in 1–3 lines, you do not yet
understand what you wrote.

Property-based testing notes:

- **Bound input domains.** Tighten ranges (`0..1024 bytes`, `1..2048 px`) until
  properties run in milliseconds. Expensive tests get skipped.
- **Read shrunk failures first.** The minimal counterexample is usually the
  whole explanation.

The closely related architectural rule — **decisions belong in types, not in
`match` arms that print** — is the type-level analogue of this same discipline:
pick a typed shape that names every meaningful case rather than collapsing
them into prose. Whenever you find yourself emitting user-visible text inside a
`match` arm that picks between *operations* (rather than between *renderings* of
the same outcome), the `match` is a decision and belongs behind a typed outcome
enum the caller can dispatch on. Stack-specific skills (e.g. `rust`) cover the
worked examples.

## A test that doesn't assert is a bug

A test that "passes" without exercising the behaviour it claims to verify is
worse than no test — it consumes attention, transmits false confidence, and
hides regressions. Two failure modes show up across ecosystems:

**1. The silently-skipped resource-gated test.** Tests depending on external
resources (device, model file, network) often skip when absent. Hazard: when
*all* resources are absent, the loop completes and reports "ok" — a no-op, not
a pass.

Fix:

- **Counter-assert.** Increment a counter inside the loop, check at end: `assert
  ran >= 1, "no candidate resource available"`.
- **Visible skips.** Print `warning: resource unavailable; skipping (set
  $RESOURCE_PATH to exercise)`. Use runner's no-capture flag to show warnings.

**2. The trivially-passable assertion.** Tests that only check return types pass
whether correct or stubbed. Mutation testing detects these — replace function
bodies with defaults; surviving mutants are tests that don't test.

Root cause: tests should verify **observable outcomes** ("parser produced
expected token", "embedding has unit L2 norm"), not tautologies. If you can't
state the outcome in one sentence, the test won't discriminate.

## Don't bluff on what you haven't read

When the user references a URL, file, or artifact, **fetch/read it before
responding.** Extrapolating from titles is the most credibility-eroding mistake
— users know what it actually says.

Discipline:

- **URL → fetch.** Webfetch is fast and free.
- **File path → read.** Same principle, lower cost.
- **Hash/issue/symbol → look up.** `gh issue view`, `jj show`, grep. Don't
  pattern-match and proceed.

**Demonstrate you read it.** Quote something specific. Without proof, you're
gambling the user won't check; they always do.

## Quick reference

| Situation                                        | What to actually do                                                                                                                              |
| ------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| Replicating an upstream behaviour                | Find the oracle (constants, canonical preprocessing, sample fixtures); replicate byte-exact; pin its sha256                                      |
| New encoder, decoder, or pure transformer        | Land it with at least one property-test invariant in the same change                                                                             |
| Small enumerable input domain                    | Exhaustive table test; do not use property-based testing for closed domains                                                                      |
| Resource-gated test (hardware, network, fixture) | Counter-assert at least one execution ran; gate with `#[ignore]` / decorator / env-var; runner's no-capture flag; `warning:` prefix on each skip |
| Test that just "passes"                          | Ask whether it would fail if the function were stubbed to "not implemented"; if not, sharpen the assertion or delete the test                    |
| User pasted a link, file path, or hash           | Fetch / read / look it up before responding; cite something specific that proves you did                                                         |
| Two oracles for the same pipeline disagree       | Keep both; comment the disagreement; do not unify                                                                                                |
| `match` arm with `eprintln!` inside it           | Extract the decision into a typed outcome enum; let the renderer dispatch                                                                        |
