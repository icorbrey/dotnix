---
name: rust
description: Load this skill for non-trivial work in a Cargo workspace. Covers what is genuinely peculiar to Cargo as an agent encounters it — keeping the build cache from exploding into tens of gigabytes, the workspace-deps feature-flag transit gotcha, and the architectural rule for keeping CLI-bearing crates testable. The general engineering-discipline rules (oracles, testing domains, evidence) live in `rigor`; the commit-shaping rules live in `jujutsu`.
---

# Routinely Rigorous Rust for Robots

Cargo's defaults make some choices that are wrong-by-default for any non-trivial
workspace, and a few of those choices are easy for an agent to walk into
without noticing. This skill covers the Rust-specific hygiene; the more general
engineering-discipline rules (oracle replication, testing-domain classification,
evidence discipline) are in `rigor`, and the commit-shaping rules are in
`jujutsu`.

Core themes:

- **Cargo build cache grows without bound.** Every `tests/*.rs` becomes a
  separate binary; `build.rs` invalidates incrementally; old artifacts never
  garbage-collect. Six rules disarm it.
- **`--no-default-features` doesn't transit workspace deps.** Default-on
  features silently re-enable through dependents unless `default-features =
  false` at workspace root.
- **Compile-time metadata via env vars, not `build.rs`.** Use `option_env!` +
  shell hook.
- **Decisions in core, rendering in CLI.** Typed outcome enums in core; CLI
  formats them. Keeps CLI testable.

You already know `cargo`, `clippy`, `rustfmt`, `nextest`, `proptest`,
`thiserror`. This document is about Cargo-specific *traps* and the small set of
architectural rules that make a Cargo workspace cheap to iterate on as it grows.

## Cargo build caches are stupid

Cargo's defaults produce tens-of-gigabyte `target/` directories:

- **Every `tests/*.rs` is a separate binary** statically linking
  crate-under-test plus dev deps. Ten test files × four crates = forty
  multi-hundred-MB binaries.
- **Every `build.rs` runs on invalidation** without garbage collection. Cascades
  re-compiles.
- **Never deletes stale artifacts.** Old rlib hashes accumulate indefinitely.
- **`incremental/` grows without bound.** Pure waste in CI fresh-build
  environments.

Fixes (apply at bring-up):

1. **One integration-test binary, workspace-wide.** Add a dedicated
   crate (e.g. `crates/integration-tests/`) whose `tests/integration.rs`
   is the only top-level test file across the entire workspace.
   Sub-suites become `mod` declarations in that file with their bodies in
   `tests/integration/<topic>.rs`. See [matklad's "Delete Cargo Integration
   Tests"] for the rationale.
2. **Zero `build.rs`.** When you need compile-time metadata (a build
   SHA, an embedded asset), reach for `option_env!("MY_BUILD_REV")` plus
   `const_format::concatcp!` and have the build environment (a flake's
   `shellHook`, a CI step) set the variable. Reach for `include_bytes!` for
   embedded files. The cases that genuinely require a build script are rare and
   should be a deliberate design decision, not a default.
3. **No `examples/`, no doctests.** Both compile as separate binaries. Set
   `doctest = false` in each crate's `[lib]` section; do not add an `examples/`
   directory. A snippet worth testing is worth promoting to a real test in the
   integration crate.
4. **Workspace-deduplicated dependencies.** Declare every external dep exactly
   once in the root `[workspace.dependencies]` and reference it from member
   crates with `workspace = true`. This prevents linking multiple versions of
   the same crate.
5. **`cargo-sweep` on a cadence.** Cargo will never delete stale artefacts
   itself. `cargo sweep --time 14` periodically drops anything untouched for
   two weeks.
6. **`CARGO_INCREMENTAL=0` in CI.** Every CI lane should export this; the
   incremental cache is pure waste in fresh-build environments. Keep it on
   locally for iteration speed.

## `default-features = false` does not transit workspace deps

Cargo footgun: `--no-default-features` at workspace root **does not** override
`default-features = true` on intra-workspace deps. If one crate defaults a
system-library feature on and a sibling depends without `default-features
= false`, `cargo build --workspace --no-default-features` *still* pulls the
feature transitively — build fails when library absent.

The fix is to set `default-features = false` on every internal-crate declaration
in `[workspace.dependencies]`:

```toml
[workspace.dependencies]
my-core   = { path = "crates/core",   default-features = false }
my-daemon = { path = "crates/daemon", default-features = false }
my-cli    = { path = "crates/cli",    default-features = false }
```

Crates needing defaults can flip `default-features = true` in their own
`[dependencies]`. Makes dependence explicit. Default is "off, except where
deliberate."

**Verify:** After touching `[features]` or internal deps, build with
`--workspace --no-default-features --all-targets` locally before committing.
Feature bugs usually caught by CI lacking system libraries; catch on branch, not
in review.

## Decisions in core, rendering in the CLI

The architectural rule (referenced briefly in `rigor` § *Note open vs.
closed testing domains*) is, for Rust: **anything that can be decided without
printing belongs in a core/library crate, returns a typed outcome enum, and
prints nothing; the CLI crate is a thin formatter over those outcomes.** The
compiler-checked test of whether you got the boundary right is whether the
core function has any `eprintln!`/`println!` in it — it should have none — and
whether the CLI's `match` arms pick between *renderings* of an outcome rather
than between *operations*.

Enforcement:

- **`match` arm with `eprintln!` is wrong.** Lift decision into core return
  type as enum variant. CLI renders it. "Ambiguous" case is `Ambiguous { chosen,
  alternatives }`, not a print.
- **Errors carry structure.** Variant-rich enums (`StoreError`, `CliError`) let
  UIs map failures to recovery. "User did wrong with remediation" is its own
  variant, not `Config(String)`.
- **No interactive prompts in core.** Break under piping, add modal state,
  non-CLI UIs can't reuse. Emit `Ambiguous`-style outcome; let UI surface choice.
- **Progress as structured events.** `ProgressEvent` enum streamed to UI. Keeps
  core pure, renderers independent.

Compiler test: core compiles without `std::io` or tests produce no stray bytes
= no decisions hiding in renderers. Removing `eprintln!` requires new outcome
variant? Variant was the missing decision.

## Quick reference

| Situation                                       | What to actually do                                                                                                        |
| ----------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| Embedded compile-time metadata                  | `option_env!(...)` plus `const_format::concatcp!`; do *not* add a `build.rs`                                               |
| New workspace, first `[workspace.dependencies]` | `default-features = false` on every internal-crate entry; build with `--no-default-features --all-targets` to verify       |
| New cross-crate integration test                | Add it as a `mod` under `crates/integration-tests/tests/integration/`; do *not* add a top-level `tests/*.rs` anywhere else |
| Decision-bearing CLI command                    | Pure resolver in core returning a typed outcome enum; CLI subcommand is a thin formatter                                   |
| `match` arm with `eprintln!` inside it          | Extract the decision into a typed outcome enum in core; CLI dispatches on the variant                                      |
| Generic `Config(String)` error variant          | Replace with a named structural variant; `String` is squashing a real outcome                                              |
| `target/` is dozens of GB                       | `cargo sweep --time 14`; verify there's only one top-level `tests/*.rs` in the workspace; check no `build.rs` crept in     |
| Touched any `[features]` or internal dep entry  | Build `--workspace --no-default-features --all-targets` locally before committing                                          |
