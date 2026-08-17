# Technical research notes

## Supported versions

- Fields of Mistria: 1.0.3, Steam build 24742087
- MOMI/MMAPI: 0.15.5, tag `v0.15.5`, commit `9b90ee213309e7aaca5870ac43272682b6f595ad`

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
