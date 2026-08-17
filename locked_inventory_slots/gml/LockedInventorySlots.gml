#macro LOCKED_INVENTORY_SLOTS_MOD "locked_inventory_slots"
#macro LOCKED_INVENTORY_SLOTS_VERSION "0.0.1"

function locked_inventory_slots_runtime() {
    if (global[$ "__locked_inventory_slots"] == undefined) {
        global.__locked_inventory_slots = {
            registered: false,
            wrapped_inventory: undefined,
            original_sort: undefined,
            sort_in_progress: false,
            debug_locked_slots: [0, 1, 2],
        };
    }
    return global.__locked_inventory_slots;
}

function locked_inventory_slots_is_debug_locked(_index) {
    var _locks = locked_inventory_slots_runtime().debug_locked_slots;
    for (var _i = 0; _i < array_length(_locks); _i++) {
        if (_locks[_i] == _index) {
            return true;
        }
    }
    return false;
}

function locked_inventory_slots_snapshot(_inventory) {
    var _snapshot = [];
    for (var _i = 0; _i < _inventory.size(); _i++) {
        var _slot = _inventory.slot(_i);
        array_push(_snapshot, {
            item: _slot.item,
            item_json: _slot.item == undefined ? undefined : json_stringify(_slot.item.serialize()),
            count: _slot.count,
            updates: _slot.updates,
        });
    }
    return _snapshot;
}

function locked_inventory_slots_restore_snapshot(_inventory, _snapshot) {
    var _size = min(_inventory.size(), array_length(_snapshot));
    for (var _i = 0; _i < _size; _i++) {
        var _slot = _inventory.slot(_i);
        var _saved = _snapshot[_i];
        _slot.item = _saved.item;
        _slot.count = _saved.count;
        _slot.updates = _saved.updates + 1;
    }
}

function locked_inventory_slots_totals(_inventory) {
    var _totals = Map();
    for (var _i = 0; _i < _inventory.size(); _i++) {
        var _slot = _inventory.slot(_i);
        if (_slot.item != undefined && _slot.count > 0) {
            var _key = json_stringify(_slot.item.serialize());
            _totals.set(_key, _totals.get_or(_key, 0) + _slot.count);
        }
    }
    return _totals;
}

function locked_inventory_slots_totals_match(_before, _after) {
    var _before_keys = _before.keys();
    var _after_keys = _after.keys();
    if (array_length(_before_keys) != array_length(_after_keys)) {
        return false;
    }
    for (var _i = 0; _i < array_length(_before_keys); _i++) {
        var _key = _before_keys[_i];
        if (!_after.contains_key(_key) || _before.get(_key) != _after.get(_key)) {
            return false;
        }
    }
    return true;
}

function locked_inventory_slots_locked_match(_inventory, _snapshot) {
    for (var _i = 0; _i < _inventory.size(); _i++) {
        if (!locked_inventory_slots_is_debug_locked(_i)) {
            continue;
        }
        var _slot = _inventory.slot(_i);
        var _saved = _snapshot[_i];
        var _item_json = _slot.item == undefined ? undefined : json_stringify(_slot.item.serialize());
        if (_slot.item != _saved.item || _slot.count != _saved.count || _item_json != _saved.item_json) {
            return false;
        }
    }
    return true;
}

function locked_inventory_slots_sort_inventory() {
    var _rt = locked_inventory_slots_runtime();
    if (_rt.sort_in_progress || self != _rt.wrapped_inventory) {
        return method_call(_rt.original_sort, []);
    }

    _rt.sort_in_progress = true;
    var _all_slots = self.slots;
    var _snapshot = locked_inventory_slots_snapshot(self);
    var _before_totals = locked_inventory_slots_totals(self);
    var _sortable = List();
    for (var _i = 0; _i < self.size(); _i++) {
        if (!locked_inventory_slots_is_debug_locked(_i)) {
            _sortable.push(self.slot(_i));
        }
    }

    mmapi_log_info(LOCKED_INVENTORY_SLOTS_MOD, "[LIS] Sort requested; debug locked slots: [0,1,2]");

    if (_sortable.is_empty()) {
        _rt.sort_in_progress = false;
        mmapi_log_info(LOCKED_INVENTORY_SLOTS_MOD, "[LIS] No sortable slots; inventory unchanged");
        mmapi_log_flush(LOCKED_INVENTORY_SLOTS_MOD);
        return;
    }

    var _sort_error = undefined;
    self.slots = _sortable;
    try {
        method_call(_rt.original_sort, []);
    } catch (_err) {
        _sort_error = _err;
    }
    self.slots = _all_slots;

    var _valid = _sort_error == undefined
        && locked_inventory_slots_totals_match(_before_totals, locked_inventory_slots_totals(self))
        && locked_inventory_slots_locked_match(self, _snapshot);

    if (!_valid) {
        locked_inventory_slots_restore_snapshot(self, _snapshot);
        var _reason = _sort_error == undefined ? "inventory invariant mismatch" : string(_sort_error);
        mmapi_log_error(LOCKED_INVENTORY_SLOTS_MOD, "[LIS] Sort aborted and snapshot restored: " + _reason);
    } else {
        mmapi_log_info(LOCKED_INVENTORY_SLOTS_MOD, "[LIS] Inventory invariant check: PASS");
    }

    _rt.sort_in_progress = false;
    mmapi_log_flush(LOCKED_INVENTORY_SLOTS_MOD);
}

function locked_inventory_slots_install_sort_wrapper(_inventory) {
    var _rt = locked_inventory_slots_runtime();
    if (_rt.wrapped_inventory == _inventory) {
        return;
    }
    _rt.wrapped_inventory = _inventory;
    _rt.original_sort = _inventory.sort;
    _inventory.sort = method(_inventory, locked_inventory_slots_sort_inventory);
}

function locked_inventory_slots_on_menu_opened(_ctx) {
    if (_ctx.kind == Menu.Player) {
        locked_inventory_slots_install_sort_wrapper(ARI.inventory);
    }
}

function locked_inventory_slots_register() {
    var _rt = locked_inventory_slots_runtime();
    if (_rt.registered) {
        return;
    }
    _rt.registered = true;
    mmapi_on("ui.menu_opened", locked_inventory_slots_on_menu_opened);
}

function locked_inventory_slots_tick() {
    locked_inventory_slots_register();
}

mmapi_mod_declare(LOCKED_INVENTORY_SLOTS_MOD, LOCKED_INVENTORY_SLOTS_VERSION);
mmapi_register(locked_inventory_slots_tick);
