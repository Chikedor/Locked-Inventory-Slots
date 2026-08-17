# Locked Inventory Slots

Locked Inventory Slots lets individual player-inventory positions opt out of Fields of Mistria's vanilla **Sort** operation. A lock belongs to the position, not the item: you can still move, replace, use, equip, consume, or discard its contents manually.

The mod does not replace the inventory or implement a custom category/order algorithm. It gives vanilla Sort only the unlocked positions, so locked stacks and locked empty spaces never enter its drain, merge, or reorder pass.

## Requirements

- Fields of Mistria 1.0.3, Steam build 24742087
- MOMI/MMAPI 0.15.5 or newer

Version 0.1.0 was built, compile-validated, and tested in game with the versions above.

## Installation

1. Install MOMI/MMAPI and follow its setup instructions for Fields of Mistria.
2. Copy only the `locked_inventory_slots` directory into the game's `mods` directory.
3. Confirm that `mods/locked_inventory_slots/manifest.json` exists directly at that path.
4. Run MOMI and apply the mod.
5. Start the game and load a save.

## Using the mod

Open the vanilla Inventory page, then hold **Shift** and **right-click** an inventory space to lock or unlock it. A vanilla-style yellow border appears around the space.

- The position remains fully interactive.
- Moving or replacing the item does not move the lock.
- An empty locked position stays empty when Sort runs.
- Locked toolbar positions are protected by the same rule and display the same indicator.
- Sort behaves exactly as vanilla when no positions are locked.

### Screenshots

![Locked positions in the Inventory page](docs/images/locked-inventory.png)

![The same locked positions in the toolbar](docs/images/locked-toolbar.png)

### Controller

Focus a space in the Inventory page and press **left shoulder + west face button** (Xbox-position names: `LB + X`). The default device-agnostic MMAPI binding is:

```text
GAMEPAD_LEFT_SHOULDER+GAMEPAD_X
```

On Nintendo-layout controllers, the printed face-button label may differ because MMAPI's `A/B/X/Y` names refer to Xbox button positions. The binding can be changed in the config file.

## Persistence

Locks are stored per save in MMAPI's JSON sidecar under:

```text
%LOCALAPPDATA%/FieldsOfMistria/mod_data/locked_inventory_slots/saves/
```

The vanilla save is never modified. When the backpack expands, existing valid locks remain and the newly added positions start unlocked. Invalid/out-of-range saved indices are discarded after the player inventory is available.

## Configuration

MMAPI creates:

```text
%LOCALAPPDATA%/FieldsOfMistria/mod_data/locked_inventory_slots/locked_inventory_slots.json
```

Available options:

| Option | Default | Effect |
| --- | --- | --- |
| `enabled` | `true` | Enables locking, indicators, and Sort protection. |
| `show_lock_border` | `true` | Shows the yellow border. Protection remains active when hidden. The old `show_lock_icon` option is migrated automatically. |
| `protect_from_sort` | `true` | Makes vanilla Sort exclude locked positions. |
| `controller_toggle_binding` | `GAMEPAD_LEFT_SHOULDER+GAMEPAD_X` | MMAPI binding used on the focused inventory space. |
| `debug_logging` | `false` | Logs bounded Sort transactions and invariant results. |

Restart the game after editing the config.

## Compatibility and limitations

- Only the player inventory's vanilla **Sort** operation is changed.
- Quick Stack, chest sorting, transfers, and automatic item acquisition keep their vanilla behavior.
- A mod that replaces `PlayerMenu`, `InventoryMenu.input_check`, or the player inventory's `sort` method may conflict.
- The safety transaction verifies the complete item/quantity/metadata multiset and every locked position. An exception or mismatch restores the pre-Sort snapshot and writes an error.
- English and Spanish (Spain) strings are included. The Spanish wording follows vanilla's use of “espacios” for backpack capacity.

## Uninstallation

1. Close the game.
2. Remove `mods/locked_inventory_slots`.
3. Run MOMI again to reapply the remaining mods.

The per-save sidecars are harmless if left behind. Delete `mod_data/locked_inventory_slots` only if you also want to erase saved locks and configuration.

---

# Locked Inventory Slots — Español

Locked Inventory Slots permite excluir espacios concretos del inventario del jugador de la operación vanilla **Ordenar**. El bloqueo pertenece a la posición, no al objeto: puedes mover, sustituir, usar, equipar, consumir o tirar su contenido manualmente.

El mod no sustituye el inventario ni crea un algoritmo de ordenación propio. La función vanilla recibe únicamente los espacios desbloqueados; los espacios bloqueados, incluso vacíos, nunca entran en su proceso de vaciado, apilado u ordenación.

## Requisitos

- Fields of Mistria 1.0.3, compilación 24742087 de Steam
- MOMI/MMAPI 0.15.5 o posterior

## Instalación y uso

1. Copia únicamente `locked_inventory_slots` dentro de la carpeta `mods` del juego.
2. Ejecuta MOMI y aplica el mod.
3. Abre la página vanilla de Inventario.
4. Mantén **Mayús** y haz **clic derecho** sobre un espacio para bloquearlo o desbloquearlo.

Un borde amarillo de estilo vanilla rodea cada espacio bloqueado, tanto en el menú como en la barra. El espacio sigue permitiendo todas las acciones manuales. Para mando, enfoca un espacio y usa **botón superior izquierdo + botón de cara izquierdo** (`LB + X` según posiciones Xbox).

Los bloqueos se guardan por partida en un archivo auxiliar de MMAPI y nunca modifican destructivamente el guardado vanilla. Las ampliaciones de mochila conservan los bloqueos existentes y crean los espacios nuevos desbloqueados.

Quick Stack, cofres, transferencias y otras automatizaciones conservan su comportamiento vanilla en esta versión. Para desinstalar, cierra el juego, elimina `mods/locked_inventory_slots` y vuelve a aplicar los demás mods con MOMI.
