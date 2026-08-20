# Locked Inventory Slots

Locked Inventory Slots lets individual player-inventory positions opt out of Fields of Mistria's vanilla **Sort** operation. A lock belongs to the position, not the item: you can still move, replace, use, equip, consume, or discard its contents manually.

The mod does not replace the inventory or implement a custom category/order algorithm. It gives vanilla Sort only the unlocked positions, so locked stacks and locked empty spaces never enter its drain, merge, or reorder pass.

## Requirements

- Fields of Mistria 1.0.4, Steam build 24820767
- MOMI/MMAPI 0.15.6 or newer

Version 0.1.1 was built and compile-validated with the versions above. It is a compatibility-only update; the inventory and UI contracts used by version 0.1.0 are unchanged in game 1.0.4.

## Installation

1. Install MOMI/MMAPI and follow its setup instructions for Fields of Mistria.
2. Copy only the `locked_inventory_slots` directory into the game's `mods` directory.
3. Confirm that `mods/locked_inventory_slots/manifest.json` exists directly at that path.
4. Run MOMI and apply the mod.
5. Start the game and load a save.

## Using the mod

Open the vanilla Inventory page, then hold **Shift** and **right-click** an inventory space to lock or unlock it. A vanilla-style yellow border appears around the space.

- Locks belong to inventory positions, not items. Moving or replacing an item does not move its lock.
- Locked positions remain fully interactive: items can still be moved, replaced, equipped, used, consumed, or discarded manually.
- The lock affects only the player inventory's vanilla **Sort** command. A locked stack stays in its exact position, and a locked empty position stays empty during Sort.
- Unlocked positions are still sorted by the original vanilla algorithm, including its normal stack merging and ordering.
- If every available position is locked, Sort leaves the inventory unchanged.
- The same locks and yellow borders appear on the corresponding toolbar page. Toolbar pages A, B, and C map to the matching groups of ten inventory positions.
- Locks can be toggled only from the Inventory page, not directly from the toolbar.
- A successful toggle plays the normal UI click sound.
- With no locks—or with protection disabled—Sort runs exactly as vanilla.

### Screenshots

![Locked positions in the Inventory page](docs/images/locked-inventory.png)

![The same locked positions in the toolbar](docs/images/locked-toolbar.png)

### Controller

Focus a space in the Inventory page and press **left shoulder + west face button** (Xbox-position names: `LB + X`). The default device-agnostic MMAPI binding is:

```text
GAMEPAD_LEFT_SHOULDER+GAMEPAD_X
```

The binding works only while an inventory space is focused on the Player Inventory page. On Nintendo-layout controllers, the printed face-button label may differ because MMAPI's `A/B/X/Y` names refer to Xbox button positions. The binding can be changed in the config file; an invalid value falls back to the default.

## Persistence

Locks are stored per save in MMAPI's JSON sidecar under:

```text
%LOCALAPPDATA%/FieldsOfMistria/mod_data/locked_inventory_slots/saves/
```

The vanilla save is never modified. Each save has its own lock layout. When the backpack expands, existing valid locks remain and newly added positions start unlocked. Duplicate, malformed, and out-of-range saved indices are discarded after the player inventory is available.

## Configuration

MMAPI creates:

```text
%LOCALAPPDATA%/FieldsOfMistria/mod_data/locked_inventory_slots/locked_inventory_slots.json
```

Available options:

| Option | Default | Effect |
| --- | --- | --- |
| `enabled` | `true` | Master switch. When disabled, toggling, indicators, and Sort protection are inactive; saved locks are retained. |
| `show_lock_border` | `true` | Shows the yellow border. Locks and Sort protection remain active when it is hidden. The old `show_lock_icon` option is migrated automatically. |
| `protect_from_sort` | `true` | Excludes locked positions from vanilla Sort. When disabled, locks remain saved and visible but do not affect Sort. |
| `controller_toggle_binding` | `GAMEPAD_LEFT_SHOULDER+GAMEPAD_X` | Device-agnostic MMAPI binding used on the focused inventory space. Invalid bindings fall back to the default. |
| `debug_logging` | `false` | Writes bounded lock and Sort diagnostics, including successful invariant checks, to the mod log. |

Restart the game after editing the config.

## Compatibility and limitations

- Only the player inventory's vanilla **Sort** operation is changed.
- Quick Stack, chest sorting, transfers, crafting/consumption, and automatic item acquisition keep their vanilla behavior. A position lock is not a general item-protection or favorite-item system.
- A mod that replaces `PlayerMenu`, `InventoryMenu.input_check`, or the player inventory's `sort` method may conflict.
- Sort protection snapshots the inventory, gives vanilla Sort only the unlocked slot objects, then verifies the complete item/quantity/metadata multiset and every locked position. An exception or mismatch restores the pre-Sort snapshot and writes an error.
- Debug output is stored under `%LOCALAPPDATA%/FieldsOfMistria/mod_data/locked_inventory_slots/logs/` when logging is enabled. Safety errors are logged even when debug logging is disabled.
- English and Spanish (Spain) localization data are included. The Spanish wording follows vanilla's use of “espacios” for backpack capacity.

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

- Fields of Mistria 1.0.4, compilación 24820767 de Steam
- MOMI/MMAPI 0.15.6 o posterior

## Instalación y uso

1. Instala MOMI/MMAPI siguiendo sus instrucciones para Fields of Mistria.
2. Copia únicamente la carpeta `locked_inventory_slots` dentro de la carpeta `mods` del juego.
3. Comprueba que `mods/locked_inventory_slots/manifest.json` exista exactamente en esa ruta.
4. Ejecuta MOMI y aplica el mod.
5. Inicia el juego y carga una partida.

Abre la página vanilla de Inventario, mantén **Mayús** y haz **clic derecho** sobre un espacio para bloquearlo o desbloquearlo. Un clic correcto reproduce el sonido habitual de la interfaz.

### Qué hace cada bloqueo

- El bloqueo pertenece a la posición, no al objeto. Mover o sustituir el objeto no desplaza el bloqueo.
- La posición sigue siendo completamente interactiva: puedes mover, sustituir, equipar, usar, consumir o tirar su contenido manualmente.
- El bloqueo afecta únicamente a **Ordenar** en el inventario del jugador. Una pila bloqueada conserva su posición exacta y un espacio vacío bloqueado permanece vacío durante Ordenar.
- Los espacios desbloqueados siguen usando el algoritmo vanilla, incluido su apilado y orden habituales.
- Si todos los espacios disponibles están bloqueados, Ordenar no modifica el inventario.
- Los mismos bloqueos aparecen con borde amarillo en la página correspondiente de la barra. Las páginas A, B y C corresponden a los grupos de diez posiciones del inventario.
- Los bloqueos solo se pueden cambiar desde la página de Inventario, no directamente desde la barra.
- Si no hay bloqueos o la protección está desactivada, Ordenar funciona exactamente como en el juego vanilla.

### Mando

Enfoca un espacio en la página de Inventario y pulsa **botón superior izquierdo + botón de cara izquierdo** (`LB + X` según posiciones Xbox). El binding predeterminado de MMAPI es:

```text
GAMEPAD_LEFT_SHOULDER+GAMEPAD_X
```

En mandos con distribución Nintendo, la etiqueta impresa puede ser distinta porque los nombres `A/B/X/Y` de MMAPI indican posiciones Xbox. El binding se puede cambiar en la configuración; un valor inválido vuelve al predeterminado.

## Persistencia

Los bloqueos se guardan por partida en:

```text
%LOCALAPPDATA%/FieldsOfMistria/mod_data/locked_inventory_slots/saves/
```

El mod nunca modifica el guardado vanilla. Cada partida conserva su propia distribución. Al ampliar la mochila, los bloqueos válidos existentes se mantienen y las posiciones nuevas empiezan desbloqueadas. Los índices duplicados, inválidos o fuera del tamaño real se descartan.

## Configuración

MMAPI crea `%LOCALAPPDATA%/FieldsOfMistria/mod_data/locked_inventory_slots/locked_inventory_slots.json`. Reinicia el juego después de editarlo.

| Opción | Predeterminado | Efecto |
| --- | --- | --- |
| `enabled` | `true` | Interruptor general. Al desactivarlo no se puede alternar bloqueos y se ocultan los indicadores y la protección; los bloqueos guardados se conservan. |
| `show_lock_border` | `true` | Muestra el borde amarillo. Ocultarlo no desactiva los bloqueos ni su protección. Migra automáticamente la antigua opción `show_lock_icon`. |
| `protect_from_sort` | `true` | Excluye de Ordenar las posiciones bloqueadas. Al desactivarlo, los bloqueos siguen guardados y visibles, pero Ordenar no los respeta. |
| `controller_toggle_binding` | `GAMEPAD_LEFT_SHOULDER+GAMEPAD_X` | Binding MMAPI para alternar el espacio enfocado con mando. |
| `debug_logging` | `false` | Escribe diagnósticos limitados de bloqueos, operaciones de Ordenar y comprobaciones de integridad. |

## Compatibilidad, seguridad y límites

- Solo cambia la operación vanilla **Ordenar** del inventario del jugador.
- Quick Stack, la ordenación de cofres, transferencias, fabricación/consumo y adquisición automática conservan su comportamiento vanilla. No es un sistema general de favoritos o protección de objetos.
- Puede entrar en conflicto con otro mod que sustituya `PlayerMenu`, `InventoryMenu.input_check` o el método `sort` del inventario del jugador.
- Antes de Ordenar crea una instantánea, entrega al algoritmo vanilla únicamente las posiciones desbloqueadas y después verifica el conjunto completo de objetos, cantidades y metadatos, además de cada posición bloqueada. Si ocurre una excepción o una discrepancia, restaura la instantánea y registra el error.
- Los diagnósticos se guardan en `%LOCALAPPDATA%/FieldsOfMistria/mod_data/locked_inventory_slots/logs/`. Los errores de seguridad se registran aunque `debug_logging` esté desactivado.
- Incluye datos de localización en inglés y español de España.

## Desinstalación

1. Cierra el juego.
2. Elimina `mods/locked_inventory_slots`.
3. Ejecuta MOMI otra vez para volver a aplicar los demás mods.

Los archivos auxiliares por partida no causan ningún problema si permanecen ahí. Elimina `mod_data/locked_inventory_slots` únicamente si también quieres borrar todos los bloqueos guardados y la configuración.
