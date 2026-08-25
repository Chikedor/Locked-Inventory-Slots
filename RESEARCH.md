# Technical research notes

## Supported versions

- Fields of Mistria: 1.0.4, Steam build 24820767
- MOMI/MMAPI: 0.15.6, tag `v0.15.6`, commit `288d843a57df4ee7c7bab224925fde1ce54d1bf4`

## Player-visible objective

Allow individual player-inventory positions to opt out of the vanilla Sort operation without blocking manual movement, use, consumption, equipment, or selection. Quick Stack and chest transfer behavior are out of scope for the first release.

## Verified contracts

- `ARI.inventory` is a `__Inventory` whose `slots` field is a `List` of `InventorySlot` objects. Each slot carries a stable zero-based `index`, `item`, `count`, `updates`, and an `inventory` reference. Evidence: pristine 1.0.3 `GameplaySystems/Inventory/Inventory.gml`.
- `PlayerMenu.sort_icon` invokes `ARI.inventory.sort()` directly. The only other inventory sort caller is `StorageMenu`, where it targets the local chest inventory. Evidence: complete search of the pristine 1.0.3 GML tree.
- `__Inventory.sort()` drains every visible slot, re-adds the drained `LiveItem` values through vanilla `add()` (thereby applying vanilla stack compatibility), sorts `[item, count]` pairs, and writes them back to the same slot objects. Evidence: pristine 1.0.3 `Inventory.gml`.
- Player inventory expansion calls `ARI.inventory.resize(new_inventory_size)` in increments of 10. Existing `InventorySlot` objects remain and new positions receive their actual zero-based index. Evidence: pristine `Player/AriFsm.gml` and `Inventory.gml`.
- MMAPI 0.15.5 exposes UI menu/item/toolbar hooks and per-save sidecars, but no inventory-sort filter or guard. Evidence: the v0.15.5 `seams.toml` catalog and MMAPI hook documentation.
- `mmapi_modsave_register` stores plain JSON payloads in a per-save sidecar selected from the vanilla save path; it does not modify the vanilla save. Evidence: v0.15.5 `mmapi_modsave.gml` and API reference.
- Vanilla's player inventory squares are 22x22 nine-slices and toolbar squares are 20x20 sprites. The native `spr_ui_inventory_slot_outline_hovered` is 26x26, so it deliberately extends two logical pixels beyond each edge. Evidence: pristine `InventoryMenu.gml`, `ToolbarMenu.gml`, and animation metadata.
- The official Spanish localization describes backpack capacity as `espacios`, so player-facing Spanish text should use `espacio de inventario` rather than an untranslated `slot`. Evidence: `items/other/misc/basic_pouch/description` and `large_pouch/description` in the pristine Spanish localization.

## Design decisions

### Sort integration

The selected design wraps only the current `ARI.inventory.sort` method after `Menu.Player` opens. During a sort transaction it temporarily replaces the inventory's `slots` List with a List containing the same `InventorySlot` objects for unlocked indices only, invokes the bound vanilla sort method, and immediately restores the complete List. Locked slots are therefore absent from vanilla `drain()`, `add()`, and final assignment rather than repaired afterward.

Before the transaction, the mod snapshots every slot's item reference, serialized item metadata, count, and update counter. Afterward it verifies the complete item/count multiset and every locked position. Any exception or invariant failure restores the snapshot before returning.

This avoids an MMAPI framework change: `ui.menu_opened` is early enough to install the per-instance wrapper before the player can press the Sort button, and the only player-inventory Sort caller is inside that menu.

### Phase 2 debug scope

The first executable experiment hardcodes zero-based indices `[0, 1, 2]`. It has no UI, input, config, or persistence. Those layers are intentionally deferred until the sort transaction passes compile and in-game safety checks.

That experiment passed in game. Version 0.1.0 replaces the debug array with one mod-owned `locked_slots` array, exposes bounded lock/unlock/toggle helpers, and uses MMAPI's per-save sidecar.

### UI and input

- Each indicator is the native transparent 26x26 `spr_ui_inventory_slot_outline_hovered`, centered and scaled to the exact dimensions of its vanilla parent (22x22 in the inventory and 20x20 in the toolbar). Its transparent center preserves the item. Toolbar construction leaves its square sprite dimensions at 0x0 until the first think pass, so the toolbar helper supplies the verified vanilla size of 20 explicitly instead of reading the node during save application. A bounded in-game trace confirmed `locks=[1,2,0,29]`, `border_enabled=true`, and `square_size=0x0` before this correction. Two exact-size alternatives were discarded rather than extended: a custom render callback failed at load because the compiled runtime treated `draw_set_color` as a missing instance field, while an opaque `spr_ui_generic_box_hovered` nine-slice covered items.
- The Player Inventory's bound `input_check` method is wrapped per menu instance. Only `Shift + InputId.PickUpOne` is intercepted; all other calls invoke the original bound method unchanged.
- Controller toggling uses MMAPI's device-agnostic compound binding registry. The callback acts only while the Player inventory pilot is active and reads the focused node's vanilla `index` blackboard value.
- Toolbar overlays update from the bounded `ui.menu_refreshed` edge and after an explicit toggle; the mod does not scan inventory contents every frame.
- Applying a per-save sidecar immediately refreshes any already-created toolbar nodes. This is required because the persistent toolbar can be constructed before the save-specific lock array is available.

### Backpack growth

Sidecar indices are validated structurally at load, then normalized once against the actual `ARI.inventory.size()` when the Player menu becomes available. This prevents a stale out-of-range index from becoming a lock if a new backpack row is added later. The live lock array is not resized when the inventory grows, so all newly constructed positions start unlocked.

## Rejected approaches

- Let vanilla sort the full inventory and restore locked slots afterward: rejected because vanilla drains and merges stacks first, so post-hoc restoration can lose provenance and create duplication/loss hazards.
- Replace vanilla category/name/value ordering: rejected because it would duplicate game behavior and drift on updates.
- Modify MMAPI with a new seam immediately: rejected because wrapping the player inventory instance at the sole player Sort entry route reaches the required boundary without changing the framework.

## Automated validation

MOMI/MMAPI 0.15.5 strict lint and required compile check passed against the pristine Fields of Mistria 1.0.3 backup on 2026-08-17 for both the 0.0.1 Sort experiment and the 0.1.0 player-facing build:

```text
ModsOfMistriaInstaller-cli.exe --lint <absolute mod path> <assets.bak.zip> --strict-lints --compile-check require
lint chikedor.locked_inventory_slots v0.0.1
  gml: 1 file(s) installing under scripts/chikedor_locked_inventory_slots/
  RESULT: OK - the apply would install this mod
```

The v0.1.0 run likewise listed one GML file and returned `RESULT: OK`. A real apply composed and compiled 100 MMAPI/seamed files plus the GML file for each of the three installed mods, installed the English fiddle data and Spanish localization, and reported `3 mod(s) installed`.

## Manual validation

On 2026-08-17, the 0.0.1 diagnostic build ran against Fields of Mistria 1.0.3 with the first three zero-based positions excluded. Pressing vanilla Sort emitted:

```text
[LIS] Sort requested; debug locked slots: [0,1,2]
[LIS] Inventory invariant check: PASS
```

The check covered the full serialized item/count multiset and exact identity/content for all three locked positions. The transaction was repeated and passed again.

The v0.1.0 player-facing build was then tested in game. The user confirmed lock/unlock, protected vanilla Sort, manual item interaction, per-save persistence, locked empty positions, Spanish UI, and the final exact-size yellow indicators in both the Inventory page and toolbar. The toolbar trace proved that its persistent nodes can exist with `square_size=0x0` during save application; supplying the verified 20x20 vanilla size fixed the invisible indicator without a per-frame scan. Final screenshots are retained under `docs/images/`.

## Fields of Mistria 1.0.4 compatibility investigation

Investigated on 2026-08-19 against Fields of Mistria 1.0.4, Steam build 24820767. Steam installed a fresh vanilla `assets.zip` with SHA-256 `e55ef6bcaa7430008a6fcae7980ef06ca6912bb10431c177807b366a0fc5a450`; the existing `assets.bak.zip` was still the 1.0.3 archive and was deliberately left untouched.

The mod's direct vanilla dependencies remain compatible at source level. `Inventory.gml`, `PlayerMenu.gml`, `InventoryMenu.gml`, `ToolbarMenu.gml`, and `Node.gml` are byte-identical between the pristine 1.0.3 and 1.0.4 archives. `AriFsm.gml` changed only to remove three unrelated mines-run statistics blocks; its player-inventory resize behavior is unchanged. The relevant inventory-outline and toolbar UI assets are also byte-identical.

Publication is blocked by the installer framework rather than this mod. Official MOMI/MMAPI 0.15.5 (`v0.15.5`, commit `9b90ee213309e7aaca5870ac43272682b6f595ad`, Windows x64 CLI SHA-256 `49a14873fe0262db617f80212f2f06bd22833a22f446b573cad4ca876e7c7e57`) fails strict seam staging against 1.0.4 before mod compilation:

```text
seam 'dungeon_floor_bracket': anchor matched 0x in assets/gml/scripts/GameplaySystems/Dungeon/enter_dungeon.gml (expected 1)
```

At the time of that first investigation, no newer official release or prerelease existed. Official `main` commit `01e83d892e93c74dbd39602ce98c6c1ccb9e19b5` still contained the incompatible anchor, so version 0.1.0 was kept as the last known-good 1.0.3 release.

### Resolution with MOMI/MMAPI 0.15.6

Official MOMI/MMAPI 0.15.6 was published with a 1.0.4 re-anchor for `dungeon_floor_bracket` and no hook changes. On 2026-08-20, the official Windows x64 CLI (SHA-256 `2d97a7754dc14bad3e7220a85d20e5684aac083c88dacf93f8b393d1f89ce3ac`) passed strict lint and required compilation for Locked Inventory Slots 0.1.1 against the pristine 1.0.4 backup:

```text
lint chikedor.locked_inventory_slots v0.1.1
  gml: 1 file(s) installing under scripts/chikedor_locked_inventory_slots/
  RESULT: OK - the apply would install this mod
```

Because every directly relied-on game and UI contract was unchanged, version 0.1.1 is a compatibility-only release. Its minimum installer version is 0.15.6; no behavioral code rewrite was required.

## Controller binding conflict and version 0.1.2

Player feedback on 2026-08-25 exposed a conflict in the original `GAMEPAD_LEFT_SHOULDER+GAMEPAD_X` default. Pristine Fields of Mistria 1.0.4 maps the left bumper to both `InputId.MenuTabLeft` and `InputId.ToolbarIncUp`; `JournalMenu` reacts to `MenuTabLeft` while the Inventory page is open. The west face button maps to `InputId.PickUpOne`, which `InventoryMenu.input_check` also reads directly. MMAPI 0.15.6 consumes a compound binding's trigger only inside its own hotkey registry, not from the game's separate `INPUT` bindings, so the chord cannot suppress either vanilla action.

Version 0.1.2 changes the default to `GAMEPAD_LEFT_STICK` (L3). The pristine Inventory, Player, Journal, and Toolbar menu sources do not handle `InputId.Ride`, whose default controller binding is the left-stick click; the mod callback remains gated to the active Player Inventory pilot. An initial same-schema comparison against the exact legacy text did not migrate the live config and was discarded. The verified design increments the config schema to 2: schema-1 files retain all Boolean options but reset the controller binding once to L3, while schema-2 custom bindings are preserved normally.

MOMI 0.15.6 strict lint and required compilation passed version 0.1.2 against the pristine Fields of Mistria 1.0.4 build-24820767 backup. A real apply compiled 103 framework/seamed files and one GML file for each of the three locally enabled mods, then installed Locked Inventory Slots 0.1.2 successfully. The repository source, installed mod copy, and final archive entry shared SHA-256 `4226d1399d12cbe557daac5d9a675514f3736fd74b8b51e40749322fa17feb5a`; the final `assets.zip` SHA-256 was `a451044a2931c3eb9a546e0db4b6d8c9b8d4610b160bdfaa2d110b6d96b5a962`.

The live schema-1 config containing the shipped `GAMEPAD_LEFT_SHOULDER+GAMEPAD_X` value migrated to schema 2 with `GAMEPAD_LEFT_STICK`, while `enabled`, `show_lock_border`, `protect_from_sort`, and `debug_logging` retained their prior values. The user then confirmed in game that pressing L3 on a focused Inventory position toggles its lock border without changing the Journal/toolbar page or moving the item.
