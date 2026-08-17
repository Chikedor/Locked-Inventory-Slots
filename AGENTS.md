# Repository instructions

## Project

- Mod: `Locked Inventory Slots`
- Installable directory: `locked_inventory_slots`
- Supported game version: `Fields of Mistria 1.0.3 (Steam build 24742087)`
- Supported MOMI/MMAPI version: `0.15.5`

Before changing code, read this file, `README.md`, `RESEARCH.md`, and the shared Fields of Mistria Modding Knowledge project. Do not rely on conclusions that only exist in another conversation.

## Rules

- Keep this mod independent from other mod repositories.
- Prefer authoritative structured game state over copied tables, predictions, or localized text parsing.
- Verify uncertain engine/MMAPI behavior from source, extracted assets, or runtime diagnostics.
- Preserve vanilla saves and progression unless the feature explicitly requires a documented change.
- Keep hooks and UI additions idempotent and restore vanilla properties changed temporarily.
- Add targeted opt-in diagnostics before guessing at intermittent bugs.
- When the work verifies a reusable Fields of Mistria or MOMI/MMAPI finding, update the sibling `Modding Knowledge/` base automatically without waiting for a separate request. Include versions and evidence, and report the update in the final handoff.
- Keep mod-specific findings in this repository's `RESEARCH.md`; never copy or publish the shared knowledge base as part of this mod.
- Run MOMI strict lint and required compile checks, then test the supported scenario in game.
- Commit and push every known-good milestone to GitHub.
- If an approach fails, return to the previous known-good commit and try another approach.

## Completion

A change is complete only when the supported scenario works in game, validation passes, documentation matches reality, and the known-good state is committed and published.
