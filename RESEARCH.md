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
- Vanilla provides `spr_ui_generic_lock_icon`, a 10x12 UI-atlas sprite suitable for a discrete overlay. Evidence: pristine animation metadata.
- The official Spanish localization describes backpack capacity as `espacios`, so player-facing Spanish text should use `espacio de inventario` rather than an untranslated `slot`. Evidence: `items/other/misc/basic_pouch/description` and `large_pouch/description` in the pristine Spanish localization.

## Design decisions

### Sort integration

The selected design wraps only the current `ARI.inventory.sort` method after `Menu.Player` opens. During a sort transaction it temporarily replaces the inventory's `slots` List with a List containing the same `InventorySlot` objects for unlocked indices only, invokes the bound vanilla sort method, and immediately restores the complete List. Locked slots are therefore absent from vanilla `drain()`, `add()`, and final assignment rather than repaired afterward.

Before the transaction, the mod snapshots every slot's item reference, serialized item metadata, count, and update counter. Afterward it verifies the complete item/count multiset and every locked position. Any exception or invariant failure restores the snapshot before returning.

This avoids an MMAPI framework change: `ui.menu_opened` is early enough to install the per-instance wrapper before the player can press the Sort button, and the only player-inventory Sort caller is inside that menu.

### Phase 2 debug scope

The first executable experiment hardcodes zero-based indices `[0, 1, 2]`. It has no UI, input, config, or persistence. Those layers are intentionally deferred until the sort transaction passes compile and in-game safety checks.

## Rejected approaches

- Let vanilla sort the full inventory and restore locked slots afterward: rejected because vanilla drains and merges stacks first, so post-hoc restoration can lose provenance and create duplication/loss hazards.
- Replace vanilla category/name/value ordering: rejected because it would duplicate game behavior and drift on updates.
- Modify MMAPI with a new seam immediately: rejected because wrapping the player inventory instance at the sole player Sort entry route reaches the required boundary without changing the framework.

## Automated validation

MOMI/MMAPI 0.15.5 strict lint and required compile check passed against the pristine Fields of Mistria 1.0.3 backup on 2026-08-17:

```text
ModsOfMistriaInstaller-cli.exe --lint <absolute mod path> <assets.bak.zip> --strict-lints --compile-check require
lint chikedor.locked_inventory_slots v0.0.1
  gml: 1 file(s) installing under scripts/chikedor_locked_inventory_slots/
  RESULT: OK - the apply would install this mod
```

## Manual validation

Pending Phase 2 in-game diagnostic scenario.
