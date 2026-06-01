---
name: skill-authoring
description: Load this skill before authoring or substantially editing an agent skill — when creating a new file under modules/home/skills/, adding a skill file to a tool module, or rewriting a section of an existing skill. Covers grounding sections in source material, keeping skills temporally stable, choosing between general and tool-attached homes, the flat-vs-directory form decision, and the voice and structure conventions that prior-art skills follow.
---

# Smithing Skills for Successor Robots

A skill is enduring guidance for a future agent with a freshly emptied context.
Bad skills cost context but transmit no operational difference.

Failure modes:
- **Nothing concrete.** Abstract principles, no recipes, no decision criteria.
- **Duplicates human-facing docs.** Content already in CONTRIBUTING.md wastes
  the context budget.
- **Ages out.** References to incidents, hashes, versions. Stale examples
  require temporal triage.
- **Padding beyond evidence.** Sections sound wise but contain no rules that
  discriminate. "Things one might say" vs "things one must know".

This skill is the discipline that prevents each of those failures. The sections
below are organised in roughly the order they apply during authoring: decide
what the skill is for, ground it in evidence, keep it temporally stable, choose
its home and form, write its frontmatter, then write the body in the prior-art
style.

## Skills are agent-facing, not human-facing

The first question before writing any section: would a competent human reading
the project's existing docs already know this? If yes, the section does not
belong in a skill — the skill exists to encode what *agents* specifically need,
which is the set of moves humans take for granted (or correct in code review
without ever writing down) but that an LLM agent will trip on by default.

Concretely: things like commit-shaping discipline, build-cache hygiene, "the
test should fail when the behaviour it tests breaks", and "fetch the URL before
reasoning about its contents" are agent-facing because a human reaching the
same conclusion does it through unwritten habit. Things like "this codebase uses
two-space indentation" or "we use `thiserror` for errors" are human-facing —
they belong in the project's contributing guide, not a skill, because any reader
(human or agent) finds them by opening that file.

When a skill genuinely needs to reference a human-facing document, *point at it,
do not duplicate it*. The skill's job is the agent-specific distillation; the
human-facing document remains canonical.

## Ground every section in source material

Do not invent lessons. Every section in a skill must trace back to evidence — a
prior session transcript, a code-review thread, a postmortem, a specific failure
mode that was caught by the rule (or that should have been). If you cannot cite
a concrete moment the rule would have prevented or improved, the rule probably
belongs in a blog post, not a skill.

Mining structure:

- **Part A: evidence for stubs.** Find 2–5 concrete moments justifying each
  heading. Validates abstraction level.
- **Part B: new sections.** Lessons visible in source but not yet captured.
  Title, description, evidence, cross-reference.
- **Part C: unclear themes.** Recurring patterns not yet crisp. Notes file, not
  the skill.
- **Part D: anti-recommendations.** Tempting additions unsupported by evidence.
  Document to prevent re-derivation.

The cheapest test for whether a section is grounded: can you cite a specific
incident or artifact this rule would have prevented or improved? If no, delete
the section.

## Temporal stability is the price of admission

A skill is read months or years after it is written. Anchoring its content to
a specific project, incident, commit hash, or version dates it instantly and
forces the reader to perform temporal triage on every example before trusting
any of it.

Smell tests:

- **Past-tense narrative.** "We discovered X" is a postmortem, not a skill.
  Rewrite as principle: "X causes Y; if you see X, do Z."
- **Project-specific names.** Actual crate names (`pareidolia-core`) read as
  narrative. Use placeholders (`my-core`).
- **Hashes, dates, versions.** "As of commit abc123" / "November 2024 outage" /
  "before v3.2.1" — temporal anchors that age instantly.
- **External docs you control.** Pointing at your own CONTRIBUTING is
  borderline. Inline the rule, or frame as one instance, not canonical authority.

Not temporal anchors:

- **Conditional framing**: "if oracle says `(x − 127.5) / 128.0`, write that".
  Constant is illustration; rule is "replicate byte-exact".
- **Stable external entities**: RFCs, language standards, WHATWG URL spec. Don't
  age within skill lifetime.
- **Other skills in registry**: `rigor`, `jujutsu`, `rust`. Part of structure.

When in doubt, do a final pass before publishing: search the new content for
project names you authored, dates, commit hashes, and past-tense verbs. For each
hit, either generalise the example or remove the reference.

## Tool-attached vs. general

A skill has two possible homes in this registry:

- **Tool-attached skills** live with their tool's nix module (e.g.
  `modules/home/rust/skill.md`, `modules/home/jujutsu/skill.md`). They co-locate
  the skill content with the toolchain it documents, so enabling the tool also
  installs its skill and disabling the tool takes the skill out of the loadout.
  Use this when the skill's applicability is fully predicated on the tool being
  present.
- **General skills** live under `modules/home/skills/`. They are auto-discovered
  and deployed unconditionally — no `enable` toggle on any host. Use this
  when the skill applies regardless of which toolchain is installed: process
  discipline, epistemic rules, cross-language workflow patterns.

The decision rule, when in doubt: does this skill's advice still make sense in
a session that has none of the tools the user normally has installed? If yes, it
is general. If no, it is tool-attached.

Skills that span two stacks (e.g. "how to write commits in a Python repo that
uses Poetry") are usually two sections: the general principle as a sentence in a
general skill, and the stack-specific recipe in the tool-attached skill. Resist
the urge to make a third hybrid skill — they proliferate without bound.

## Form factor: flat first, directory when you need it

General skills accept two source forms:

- **Flat**: `modules/home/skills/<slug>.md` — the default. Use for any skill
  whose content fits in a single markdown file.
- **Directory**: `modules/home/skills/<slug>/skill.md` — use only when the
  skill bundles reference files (templates, scripts, longer prior-art docs
  the `skill.md` cross-links to) that the harness should deploy alongside the
  SKILL.md.

The graduation from flat to directory is a single `mv slug.md slug/skill.md`
(plus moving the bundled assets in); the deployed path the harness produces is
identical across both forms, so there is no consumer-facing churn. Optimise for
the cheap case: ship flat, promote when an asset actually arrives.

Tool-attached skills are always directory-shaped because they sit next to a
`default.nix`; the form choice does not apply to them.

## Frontmatter encodes the load trigger

The frontmatter has two required fields. Both have specific shapes that matter
to whether the harness loads the skill at the right moments.

- **`name`** must match the slug exactly. The registry asserts this at
  evaluation; a mismatch fails the build. Use lowercase alphanumeric with
  single-hyphen separators, 1–64 characters.
- **`description`** answers the question *"under what conditions should an
  agent load this skill?"*, not the question *"what does this skill cover?"*.
  The harness selects which skills to load by matching the user's task against
  descriptions, so the description must encode the trigger condition concretely.

A good description starts with a load-trigger clause ("Load this skill when...",
"Use this skill for any...") and names the specific situations: tools present,
file types being edited, kinds of operation being performed. A bad description
describes the skill's contents in marketing voice ("Comprehensive coverage
of..."); the harness has no trigger to latch onto.

Compare:

> Bad: *"A comprehensive guide to writing Rust code with proper testing and
> good architecture."*
>
> Good: *"Load this skill for non-trivial work in a Cargo workspace. Covers
> build-cache hygiene, the workspace-deps feature-flag transit gotcha, and the
> architectural rule for keeping CLI-bearing crates testable."*

The good version names the trigger (Cargo workspace, non-trivial work) and the
contents (three concrete topics). The bad version is unranked against every
other "comprehensive guide" the harness might consider.

## Trim verbosity before publishing

After authoring, pass the skill to a less-capable agent (Sonnet, not Opus) with
the explicit task: *"identify verbose sections that can be tightened without
losing essential information."* Opus writes thorough, correct content but pads
sections beyond what's needed for skill transfer. A tightening pass removes:

- Motivational language ("this is the single most important habit")
- Redundant emphasis (saying the same thing three ways)
- Elaboration beyond the load-bearing rule
- Examples that illustrate what's already clear from the rule

The less-capable agent catches what the author can't: which sentences are
padding vs. which carry new information. It won't invent better structure, but
it reliably identifies bloat.

After tightening, verify essential content remains: rules, recipes, decision
criteria, commands. If a section lost discriminating power, restore it. The goal
is maximum skill transfer per token, not minimum line count.

## Voice and structure

Skills in this registry follow a consistent voice. Match it; do not invent a new
one without reason.

- **Second person, addressing the agent.** "You are working in...", "When you
  do X, prefer Y", "Do not Z." Not "the agent should...", not "one ought to...".
  The agent reading the skill is "you".
- **Imperative or declarative headings.** "Land on empty changes", "Cargo build
  caches are stupid", "A test that doesn't assert is a bug". Not "What is a good
  commit?", not "Some thoughts on testing". Headings advertise a rule; they do
  not pose a question.
- **Whimsical alliterative title.** The convention across this registry is a
  phrase with internal alliteration that often ends in "Robots": *Jujutsu for
  Noninteractive Noncorporeal Beings*; *Routinely Rigorous Rust for Robots*;
  *Honest Work for Honest Robots*. Match the cadence if you can, but do not
  force it — a clear title beats a forced rhyme.
- **Each section: rule, reasoning, recipe.** Open with the rule (one paragraph
  stating the principle). Follow with the reasoning (why it matters, what fails
  without it). Close with the recipe (concrete commands, decision criteria, or
  a worked example the agent can copy). Sections without recipes are advice;
  advice is what blog posts are for.
- **Close the skill with a quick-reference table.** Two columns — *Situation*
  and *What to actually do* — covering the highest-frequency moves the skill
  teaches. The table is what an experienced reader scans during a real task; the
  prose body is what a first-time reader learns from.

Look at the prior-art skills (`jujutsu`, `rust`, `rigor`) before writing a new
one. The voice and section structure should feel continuous with theirs.

## Anti-patterns

Anti-patterns:

- **Padding.** Evidence supports two paragraphs? Write two. Trust comes from
  every sentence being load-bearing.
- **Restating docs.** Paraphrasing the official Rust book does nothing the book
  doesn't do better.
- **Fake history.** Past-tense narrative disguised as evidence when it's just
  preference.
- **Language-specific in agnostic skill.** "Use `?` instead of `match`" is
  Rust-leaning. Generalise or promote to per-stack skill.
- **Duplicating.** Cross-reference. One canonical home.
- **No recipes.** Principles without recipes don't change behavior. Find recipe
  or accept it's a blog post.
- **Temporal anchors without final pass.** Easy during authoring, expensive
  later. Pass takes minutes.

## Quick reference

| Situation                                           | What to actually do                                                                                                 |
| --------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| Considering a new skill                             | Mine source material first; produce Part A/B/C/D before writing prose                                               |
| Section feels thin                                  | Ground it in more evidence, or delete it; do not pad                                                                |
| Section restates project's CONTRIBUTING             | Cross-reference and inline the rule's *agent-facing* corollary; do not duplicate the human-facing treatment         |
| Example contains a real project name, hash, or date | Generalise to placeholder names / illustrative constants; the rule should read as principle, not narrative          |
| Sentence starts with "We discovered..."             | Rewrite as conditional principle: "If X, do Y" — not "we did X, so do Y"                                            |
| Skill is purely markdown                            | Flat form: `modules/home/skills/<slug>.md`                                                                          |
| Skill bundles reference files                       | Directory form: `modules/home/skills/<slug>/skill.md` + bundled assets                                              |
| Skill is fully tool-predicated                      | Co-locate with the tool module (`modules/home/<tool>/skill.md`); register from the tool's `default.nix`             |
| Frontmatter description reads as marketing copy     | Rewrite as "Load this skill when..." plus concrete trigger conditions                                               |
| Heading reads as a question                         | Rewrite as imperative or declarative — "Do X" or "X is Y"                                                           |
| Section is principle-only, no recipe                | Find the recipe before publishing; principle-only sections do not change agent behaviour                            |
| About to publish                                    | Final pass: search for project names, dates, hashes, past-tense verbs; generalise or remove each                    |
| Skill draft complete                                | Pass to less-capable agent (Sonnet) to identify verbose sections; verify essential content remains after tightening |
| Two skills cover overlapping ground                 | Pick one canonical home; the other mentions the rule by name and cross-references                                   |
