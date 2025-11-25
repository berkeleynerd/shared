# Repository Guidelines

## Project Structure & Module Organization
- `gnatstudio_shared.gpr` is the canonical project file containing shared compiler/linker switches used by GNAT Studio LSP crates; treat it as the entry point for builds.
- `config/` hosts generated configs for the `shared`, `shared_build`, and `gps_shared` crates (`*.gpr`, `*.ads`, `*.h`). Do not hand-edit them; adjust via `alire.toml` or regeneration instead.
- `alire.toml` defines the crate metadata, dependencies (`gnatcoll`), and exposed externals such as `BUILD` and `LIBRARY_TYPE`; `alire/` holds generated packaging metadata.
- `README.md`, `LICENSE`, and `NOTICE` provide intent and legal context for this draft split-out crate.

## Build, Test, and Development Commands
- `alr build -- -P gnatstudio_shared.gpr` — resolve dependencies with Alire and build using the default externals.
- `BUILD=Production OS=osx Enable_LTO=true gprbuild -P gnatstudio_shared.gpr` — example release build toggling OS/build/LTO; set `Enable_Gperftools=true` to link the profiler; set `GPS_OBJECTS_ROOT=/tmp/gps/` to keep artifacts out-of-tree.
- `gprclean -P gnatstudio_shared.gpr` — remove objects/libs; run before switching externals so stale outputs do not leak into reviews.

## Coding Style & Naming Conventions
- Ada 2022 is enforced (`-gnat2022`); follow GNAT defaults with 3-space indentation and aligned named associations.
- Use UpperCamelCase for packages/types (`Shared_Config`), Title_Case_With_Underscores for constants (`Crate_Version`), and `Enable_*` for boolean switches.
- Leave `config/*.ads` and `config/*.h` untouched (they carry `pragma Style_Checks (Off)` because they are generated); regenerate rather than reformatting.

## Testing Guidelines
- No standalone test suite exists here; a successful build is the acceptance gate.
- Validate at least `Debug` (development) and `Production` (shipping) builds when altering flags; mirror the externals used by downstream crates to catch switch regressions early.

## Commit & Pull Request Guidelines
- Keep commits short and imperative (e.g., `Add LICENSE and NOTICE`), mirroring the existing history.
- PRs should state motivation, externals/targets built (e.g., `BUILD=Production`, `OS=osx`), and any profiling/LTO settings used. Include the exact commands run (`alr build`, `gprclean`).
- Update docs (`README.md`, this guide, and any `project-files` lists) when adjusting layout or preparing the crate for standalone publication.

## Security & Configuration Tips
- Avoid hard-coded absolute paths; prefer environment-controlled externals (`GPS_OBJECTS_ROOT`, `OS`, `LIBRARY_TYPE`).
- Keep build artifacts (`obj`, `lib`) out of commits; start reviews from a clean tree to avoid leaking host-specific outputs.
