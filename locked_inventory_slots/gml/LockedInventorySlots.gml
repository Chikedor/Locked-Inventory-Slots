#macro LOCKED_INVENTORY_SLOTS_MOD "locked_inventory_slots"
#macro LOCKED_INVENTORY_SLOTS_VERSION "0.2.0"
#macro LOCKED_INVENTORY_SLOTS_CONFIG_VERSION 2
#macro LOCKED_INVENTORY_SLOTS_SAVE_VERSION 2
#macro LOCKED_INVENTORY_SLOTS_CONTROLLER_BINDING "GAMEPAD_LEFT_STICK"

function locked_inventory_slots_runtime() {
    if (global[$ "__locked_inventory_slots"] == undefined) {
        global.__locked_inventory_slots = {
            registered: false,
            initialized: false,
            config: undefined,
            locked_slots: [],
            storage_locks: [],
            wrapped_inventory: undefined,
            normalized_inventory: undefined,
            original_sort: undefined,
            sort_in_progress: false,
            player_menu: undefined,
            wrapped_input_menu: undefined,
            original_input_check: undefined,
            toolbar_menu: undefined,
            pending_storage_menu: undefined,
            storage_menu: undefined,
            storage_key: undefined,
            storage_inventory: undefined,
            storage_original_sort: undefined,
            storage_input_menu: undefined,
            storage_original_input_check: undefined,
            controller_binding_registered: false,
        };
    }
    return global.__locked_inventory_slots;
}

function locked_inventory_slots_config() {
    var _rt = locked_inventory_slots_runtime();
    if (_rt.config != undefined) {
        return _rt.config;
    }
    var _source = mmapi_config_load(LOCKED_INVENTORY_SLOTS_MOD);
    if (!is_struct(_source)) {
        _source = {};
    }
    var _source_version = _source[$ "__config_version"];
    if (_source_version != 1 && _source_version != LOCKED_INVENTORY_SLOTS_CONFIG_VERSION) {
        _source = {};
    }
    var _controller_binding = _source_version == 1
        ? LOCKED_INVENTORY_SLOTS_CONTROLLER_BINDING
        : mmapi_config_get(
            _source,
            "controller_toggle_binding",
            LOCKED_INVENTORY_SLOTS_CONTROLLER_BINDING
        );
    if (!is_string(_controller_binding) || mmapi_hotkey_binding_from_name(_controller_binding) == undefined) {
        _controller_binding = LOCKED_INVENTORY_SLOTS_CONTROLLER_BINDING;
    }
    _rt.config = {
        enabled: mmapi_config_bool(_source, "enabled", true),
        show_lock_border: mmapi_config_bool(
            _source,
            "show_lock_border",
            mmapi_config_bool(_source, "show_lock_icon", true)
        ),
        protect_from_sort: mmapi_config_bool(_source, "protect_from_sort", true),
        controller_toggle_binding: _controller_binding,
        debug_logging: mmapi_config_bool(_source, "debug_logging", false),
    };
    mmapi_config_write(LOCKED_INVENTORY_SLOTS_MOD, LOCKED_INVENTORY_SLOTS_CONFIG_VERSION, _rt.config);
    return _rt.config;
}

function locked_inventory_slots_debug(_message) {
    if (locked_inventory_slots_config().debug_logging) {
        mmapi_log_info(LOCKED_INVENTORY_SLOTS_MOD, "[LIS] " + _message);
        mmapi_log_flush(LOCKED_INVENTORY_SLOTS_MOD);
    }
}

function locked_inventory_slots_is_locked(_index) {
    return is_real(_index)
        && _index >= 0
        && array_contains(locked_inventory_slots_runtime().locked_slots, floor(_index));
}

function locked_inventory_slots_lock(_index) {
    _index = floor(_index);
    if (_index < 0 || locked_inventory_slots_is_locked(_index)) {
        return false;
    }
    array_push(locked_inventory_slots_runtime().locked_slots, _index);
    locked_inventory_slots_debug("Locked slot " + string(_index));
    return true;
}

function locked_inventory_slots_unlock(_index) {
    _index = floor(_index);
    var _locks = locked_inventory_slots_runtime().locked_slots;
    if (!array_contains(_locks, _index)) {
        return false;
    }
    array_delete(_locks, array_pos(_locks, _index), 1);
    locked_inventory_slots_debug("Unlocked slot " + string(_index));
    return true;
}

function locked_inventory_slots_toggle(_index) {
    var _changed = locked_inventory_slots_is_locked(_index)
        ? locked_inventory_slots_unlock(_index)
        : locked_inventory_slots_lock(_index);
    if (_changed) {
        locked_inventory_slots_update_visible_indicators();
        TANGO.play("SoundEffects/UI/UIClick");
    }
    return _changed;
}

function locked_inventory_slots_copy_valid_indices(_source, _limit=1000) {
    var _copy = [];
    if (!is_array(_source)) {
        return _copy;
    }
    for (var _i = 0; _i < array_length(_source); _i++) {
        var _index = _source[_i];
        if (is_real(_index)
            && _index >= 0
            && _index == floor(_index)
            && _index < _limit
            && !array_contains(_copy, _index))
        {
            array_push(_copy, _index);
        }
    }
    return _copy;
}

function locked_inventory_slots_storage_key(_node) {
    if (!is_struct(_node)) {
        return undefined;
    }
    var _grid = _node[$ "parent_grid"];
    var _prototype = _node[$ "prototype"];
    if (!is_struct(_grid)
        || !is_struct(_prototype)
        || !is_struct(_prototype[$ "interaction_chest"])
        || !_prototype.interaction_chest.belongs_to_ari
        || _prototype.interaction_chest.shipping_bin)
    {
        return undefined;
    }
    var _dyn_index = _grid[$ "dyn_index"];
    return string(_grid.location_id)
        + ":" + (_dyn_index == undefined ? "none" : string(_dyn_index))
        + ":" + string(_node.top_left_x)
        + ":" + string(_node.top_left_y)
        + ":" + string(_node.object_id);
}

function locked_inventory_slots_storage_record(_key, _create=false) {
    if (!is_string(_key)) {
        return undefined;
    }
    var _records = locked_inventory_slots_runtime().storage_locks;
    for (var _i = 0; _i < array_length(_records); _i++) {
        if (_records[_i].key == _key) {
            return _records[_i];
        }
    }
    if (!_create) {
        return undefined;
    }
    var _record = { key: _key, locked_slots: [] };
    array_push(_records, _record);
    return _record;
}

function locked_inventory_slots_storage_is_locked(_key, _index) {
    var _record = locked_inventory_slots_storage_record(_key);
    return is_real(_index)
        && _index >= 0
        && _record != undefined
        && array_contains(_record.locked_slots, floor(_index));
}

function locked_inventory_slots_storage_toggle(_key, _index) {
    if (!is_string(_key) || !is_real(_index) || _index < 0) {
        return false;
    }
    _index = floor(_index);
    var _record = locked_inventory_slots_storage_record(_key, true);
    if (array_contains(_record.locked_slots, _index)) {
        array_delete(_record.locked_slots, array_pos(_record.locked_slots, _index), 1);
        locked_inventory_slots_debug("Unlocked storage slot " + string(_index) + " at " + _key);
    } else {
        array_push(_record.locked_slots, _index);
        locked_inventory_slots_debug("Locked storage slot " + string(_index) + " at " + _key);
    }
    locked_inventory_slots_update_visible_indicators();
    TANGO.play("SoundEffects/UI/UIClick");
    return true;
}

function locked_inventory_slots_save_collect() {
    var _rt = locked_inventory_slots_runtime();
    var _storage_copy = [];
    for (var _i = 0; _i < array_length(_rt.storage_locks); _i++) {
        var _record = _rt.storage_locks[_i];
        var _locks = locked_inventory_slots_copy_valid_indices(_record.locked_slots);
        if (is_string(_record.key) && array_length(_locks) > 0) {
            array_push(_storage_copy, { key: _record.key, locked_slots: _locks });
        }
    }
    return {
        version: LOCKED_INVENTORY_SLOTS_SAVE_VERSION,
        locked_slots: locked_inventory_slots_copy_valid_indices(_rt.locked_slots),
        storage_locks: _storage_copy,
    };
}

function locked_inventory_slots_save_apply(_data) {
    var _rt = locked_inventory_slots_runtime();
    _rt.locked_slots = [];
    _rt.storage_locks = [];
    _rt.normalized_inventory = undefined;
    if (is_struct(_data)
        && (_data[$ "version"] == 1 || _data[$ "version"] == LOCKED_INVENTORY_SLOTS_SAVE_VERSION)
        && is_array(_data[$ "locked_slots"]))
    {
        _rt.locked_slots = locked_inventory_slots_copy_valid_indices(_data.locked_slots);
        if (_data.version == LOCKED_INVENTORY_SLOTS_SAVE_VERSION
            && is_array(_data[$ "storage_locks"]))
        {
            for (var _i = 0; _i < array_length(_data.storage_locks); _i++) {
                var _record = _data.storage_locks[_i];
                if (!is_struct(_record) || !is_string(_record[$ "key"])) {
                    continue;
                }
                var _locks = locked_inventory_slots_copy_valid_indices(_record[$ "locked_slots"]);
                if (array_length(_locks) > 0
                    && locked_inventory_slots_storage_record(_record.key) == undefined)
                {
                    array_push(_rt.storage_locks, { key: _record.key, locked_slots: _locks });
                }
            }
        }
    }
    locked_inventory_slots_update_visible_indicators();
}

function locked_inventory_slots_normalize_for_inventory(_inventory) {
    var _rt = locked_inventory_slots_runtime();
    if (_rt.normalized_inventory == _inventory) {
        return;
    }
    _rt.normalized_inventory = _inventory;
    var _valid = [];
    for (var _i = 0; _i < array_length(_rt.locked_slots); _i++) {
        var _index = _rt.locked_slots[_i];
        if (_index < _inventory.size()) {
            array_push(_valid, _index);
        }
    }
    _rt.locked_slots = _valid;
}

function locked_inventory_slots_normalize_storage(_key, _inventory) {
    var _record = locked_inventory_slots_storage_record(_key);
    if (_record != undefined) {
        _record.locked_slots = locked_inventory_slots_copy_valid_indices(
            _record.locked_slots,
            _inventory.size()
        );
    }
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

function locked_inventory_slots_locked_match(_inventory, _snapshot, _locks) {
    for (var _i = 0; _i < _inventory.size(); _i++) {
        if (!array_contains(_locks, _i)) {
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

function locked_inventory_slots_run_protected_sort(_inventory, _original_sort, _locks, _label) {
    var _rt = locked_inventory_slots_runtime();
    var _cfg = locked_inventory_slots_config();
    if (_rt.sort_in_progress) {
        return method_call(_original_sort, []);
    }
    if (!_cfg.enabled || !_cfg.protect_from_sort || array_length(_locks) == 0) {
        return method_call(_original_sort, []);
    }

    _rt.sort_in_progress = true;
    var _all_slots = _inventory.slots;
    var _snapshot = locked_inventory_slots_snapshot(_inventory);
    var _before_totals = locked_inventory_slots_totals(_inventory);
    var _sortable = List();
    for (var _i = 0; _i < _inventory.size(); _i++) {
        if (!array_contains(_locks, _i)) {
            _sortable.push(_inventory.slot(_i));
        }
    }
    locked_inventory_slots_debug(
        _label + " Sort requested; locked=" + json_stringify(_locks)
        + "; sortable=" + string(_sortable.count())
    );
    if (_sortable.is_empty()) {
        _rt.sort_in_progress = false;
        locked_inventory_slots_debug("No sortable slots; inventory unchanged");
        return;
    }

    var _sort_error = undefined;
    _inventory.slots = _sortable;
    try {
        method_call(_original_sort, []);
    } catch (_err) {
        _sort_error = _err;
    }
    _inventory.slots = _all_slots;
    var _valid = _sort_error == undefined
        && locked_inventory_slots_totals_match(_before_totals, locked_inventory_slots_totals(_inventory))
        && locked_inventory_slots_locked_match(_inventory, _snapshot, _locks);
    if (!_valid) {
        locked_inventory_slots_restore_snapshot(_inventory, _snapshot);
        var _reason = _sort_error == undefined ? "inventory invariant mismatch" : string(_sort_error);
        mmapi_log_error(
            LOCKED_INVENTORY_SLOTS_MOD,
            "[LIS] " + _label + " Sort aborted and snapshot restored: " + _reason
        );
    } else {
        locked_inventory_slots_debug(_label + " inventory invariant check: PASS");
    }
    _rt.sort_in_progress = false;
}

function locked_inventory_slots_sort_inventory() {
    var _rt = locked_inventory_slots_runtime();
    if (self != _rt.wrapped_inventory) {
        return method_call(_rt.original_sort, []);
    }
    return locked_inventory_slots_run_protected_sort(
        self,
        _rt.original_sort,
        _rt.locked_slots,
        "Player"
    );
}

function locked_inventory_slots_sort_storage() {
    var _rt = locked_inventory_slots_runtime();
    if (self != _rt.storage_inventory || _rt.storage_original_sort == undefined) {
        return;
    }
    var _record = locked_inventory_slots_storage_record(_rt.storage_key);
    return locked_inventory_slots_run_protected_sort(
        self,
        _rt.storage_original_sort,
        _record == undefined ? [] : _record.locked_slots,
        "Storage"
    );
}

function locked_inventory_slots_install_sort_wrapper(_inventory) {
    var _rt = locked_inventory_slots_runtime();
    locked_inventory_slots_normalize_for_inventory(_inventory);
    if (_rt.wrapped_inventory == _inventory) {
        return;
    }
    _rt.wrapped_inventory = _inventory;
    _rt.original_sort = _inventory.sort;
    _inventory.sort = method(_inventory, locked_inventory_slots_sort_inventory);
}

function locked_inventory_slots_install_storage_sort_wrapper(_inventory, _key) {
    var _rt = locked_inventory_slots_runtime();
    _rt.storage_inventory = _inventory;
    _rt.storage_key = _key;
    _rt.storage_original_sort = _inventory.sort;
    locked_inventory_slots_normalize_storage(_key, _inventory);
    _inventory.sort = method(_inventory, locked_inventory_slots_sort_storage);
}

function locked_inventory_slots_add_ui_indicator(_nodes, _locked, _target_size=undefined) {
    var _border = _nodes[$ "lis_lock_border"];
    if (_border == undefined || _border.freed) {
        _border = ANCHOR.sprite(_nodes.square)
            .set_sprite(spr_ui_inventory_slot_outline_hovered)
            .set_align(Align.Center, Align.Middle)
            .set_xy(0, 0)
            .set_z(_nodes.item.get_z() - 10);
        _nodes[$ "lis_lock_border"] = _border;
    }
    var _cfg = locked_inventory_slots_config();
    var _size = _target_size == undefined
        ? min(_nodes.square.get_width(), _nodes.square.get_height())
        : _target_size;
    var _scale = _size / 26;
    _border.set_scale(_scale, _scale);
    _border.set_enabled(_cfg.enabled && _cfg.show_lock_border && _locked);
    return _border;
}

function locked_inventory_slots_update_player_indicators(_menu) {
    if (_menu == undefined || _menu.inventory == undefined) {
        return;
    }
    var _slots = _menu.inventory.slots;
    for (var _i = 0; _i < array_length(_slots); _i++) {
        locked_inventory_slots_add_ui_indicator(_slots[_i], locked_inventory_slots_is_locked(_i));
    }
}

function locked_inventory_slots_update_toolbar_indicators(_menu) {
    if (_menu == undefined || !is_array(_menu.slots)) {
        return;
    }
    for (var _i = 0; _i < array_length(_menu.slots); _i++) {
        var _inventory_index = _i + (10 * _menu.page);
        locked_inventory_slots_add_ui_indicator(
            _menu.slots[_i],
            locked_inventory_slots_is_locked(_inventory_index),
            20
        );
    }
}

function locked_inventory_slots_update_storage_indicators(_menu, _key) {
    if (_menu == undefined || _menu.left_menu == undefined || !is_array(_menu.left_menu.slots)) {
        return;
    }
    for (var _i = 0; _i < array_length(_menu.left_menu.slots); _i++) {
        locked_inventory_slots_add_ui_indicator(
            _menu.left_menu.slots[_i],
            locked_inventory_slots_storage_is_locked(_key, _i),
            20
        );
    }
}

function locked_inventory_slots_update_visible_indicators() {
    var _rt = locked_inventory_slots_runtime();
    locked_inventory_slots_update_player_indicators(_rt.player_menu);
    locked_inventory_slots_update_toolbar_indicators(_rt.toolbar_menu);
    locked_inventory_slots_update_storage_indicators(_rt.storage_menu, _rt.storage_key);
}

function locked_inventory_slots_handle_input(_index) {
    var _rt = locked_inventory_slots_runtime();
    if (locked_inventory_slots_config().enabled
        && keyboard_check(ord("Z"))
        && INPUT.pressed(InputId.PickUpOne))
    {
        locked_inventory_slots_toggle(_index);
        return;
    }
    method_call(_rt.original_input_check, [_index]);
}

function locked_inventory_slots_install_input_wrapper(_menu) {
    var _rt = locked_inventory_slots_runtime();
    var _inventory_menu = _menu.inventory;
    if (_rt.wrapped_input_menu == _inventory_menu) {
        return;
    }
    _rt.wrapped_input_menu = _inventory_menu;
    _rt.original_input_check = _inventory_menu.input_check;
    _inventory_menu.input_check = method(_inventory_menu, locked_inventory_slots_handle_input);
}

function locked_inventory_slots_handle_storage_input(_index) {
    var _rt = locked_inventory_slots_runtime();
    if (locked_inventory_slots_config().enabled
        && keyboard_check(ord("Z"))
        && INPUT.pressed(InputId.PickUpOne))
    {
        locked_inventory_slots_storage_toggle(_rt.storage_key, _index);
        return;
    }
    method_call(_rt.storage_original_input_check, [_index]);
}

function locked_inventory_slots_install_storage_input_wrapper(_menu) {
    var _rt = locked_inventory_slots_runtime();
    _rt.storage_input_menu = _menu.left_menu;
    _rt.storage_original_input_check = _menu.left_menu.input_check;
    _menu.left_menu.input_check = method(_menu.left_menu, locked_inventory_slots_handle_storage_input);
}

function locked_inventory_slots_storage_cleanup() {
    var _rt = locked_inventory_slots_runtime();
    if (_rt.storage_inventory != undefined && _rt.storage_original_sort != undefined) {
        _rt.storage_inventory.sort = _rt.storage_original_sort;
    }
    if (_rt.storage_input_menu != undefined && _rt.storage_original_input_check != undefined) {
        _rt.storage_input_menu.input_check = _rt.storage_original_input_check;
    }
    _rt.pending_storage_menu = undefined;
    _rt.storage_menu = undefined;
    _rt.storage_key = undefined;
    _rt.storage_inventory = undefined;
    _rt.storage_original_sort = undefined;
    _rt.storage_input_menu = undefined;
    _rt.storage_original_input_check = undefined;
}

function locked_inventory_slots_try_setup_storage() {
    var _rt = locked_inventory_slots_runtime();
    var _menu = _rt.pending_storage_menu;
    if (_menu == undefined || _rt.storage_menu == _menu) {
        return;
    }
    if (_menu[$ "node"] == undefined
        || _menu[$ "left"] == undefined
        || _menu[$ "left_menu"] == undefined
        || _menu[$ "left_pilot"] == undefined
        || !is_array(_menu.left_menu[$ "slots"]))
    {
        return;
    }
    var _key = locked_inventory_slots_storage_key(_menu.node);
    if (_key == undefined) {
        _rt.pending_storage_menu = undefined;
        return;
    }
    locked_inventory_slots_install_storage_sort_wrapper(_menu.left, _key);
    locked_inventory_slots_install_storage_input_wrapper(_menu);
    _rt.storage_menu = _menu;
    _rt.pending_storage_menu = undefined;
    locked_inventory_slots_update_storage_indicators(_menu, _key);
    mmapi_log_info(LOCKED_INVENTORY_SLOTS_MOD, "[LIS] Storage lock controls ready at " + _key);
    mmapi_log_flush(LOCKED_INVENTORY_SLOTS_MOD);
}

function locked_inventory_slots_on_controller_toggle() {
    var _rt = locked_inventory_slots_runtime();
    if (!locked_inventory_slots_config().enabled) {
        return;
    }
    var _pilot = ANCHOR.get_active_pilot();
    if (_rt.player_menu != undefined && _pilot == _rt.player_menu.inventory_pilot) {
        var _node = _rt.player_menu.inventory_pilot.get();
        if (_node != undefined && _node.blackboard.contains_key("index")) {
            locked_inventory_slots_toggle(_node.board_get("index"));
        }
        return;
    }
    if (_rt.storage_menu != undefined && _pilot == _rt.storage_menu.left_pilot) {
        var _node = _rt.storage_menu.left_pilot.get();
        if (_node != undefined && _node.blackboard.contains_key("index")) {
            locked_inventory_slots_storage_toggle(_rt.storage_key, _node.board_get("index"));
        }
    }
}

function locked_inventory_slots_on_menu_opened(_ctx) {
    var _rt = locked_inventory_slots_runtime();
    if (_ctx.kind == Menu.Player) {
        _rt.player_menu = _ctx.menu;
        locked_inventory_slots_install_sort_wrapper(ARI.inventory);
        locked_inventory_slots_install_input_wrapper(_ctx.menu);
        locked_inventory_slots_update_player_indicators(_ctx.menu);
    } else if (_ctx.kind == Menu.Toolbar) {
        _rt.toolbar_menu = _ctx.menu;
        locked_inventory_slots_update_toolbar_indicators(_ctx.menu);
    } else if (_ctx.kind == Menu.Storage) {
        _rt.pending_storage_menu = _ctx.menu;
    }
}

function locked_inventory_slots_on_menu_closed(_ctx) {
    var _rt = locked_inventory_slots_runtime();
    if (_ctx.kind == Menu.Player && _rt.player_menu == _ctx.menu) {
        _rt.player_menu = undefined;
        _rt.wrapped_input_menu = undefined;
        _rt.original_input_check = undefined;
    } else if (_ctx.kind == Menu.Toolbar && _rt.toolbar_menu == _ctx.menu) {
        _rt.toolbar_menu = undefined;
    } else if (_ctx.kind == Menu.Storage
        && (_rt.pending_storage_menu == _ctx.menu || _rt.storage_menu == _ctx.menu))
    {
        locked_inventory_slots_storage_cleanup();
    }
}

function locked_inventory_slots_on_menu_refreshed(_ctx) {
    if (_ctx.kind == Menu.Toolbar) {
        locked_inventory_slots_runtime().toolbar_menu = _ctx.menu;
        locked_inventory_slots_update_toolbar_indicators(_ctx.menu);
    }
}

function locked_inventory_slots_register() {
    var _rt = locked_inventory_slots_runtime();
    if (_rt.registered) {
        return;
    }
    _rt.registered = true;
    mmapi_on("ui.menu_opened", locked_inventory_slots_on_menu_opened);
    mmapi_on("ui.menu_closed", locked_inventory_slots_on_menu_closed);
    mmapi_on("ui.menu_refreshed", locked_inventory_slots_on_menu_refreshed);
    mmapi_modsave_register(
        LOCKED_INVENTORY_SLOTS_MOD,
        locked_inventory_slots_save_collect,
        locked_inventory_slots_save_apply
    );
}

function locked_inventory_slots_tick() {
    var _rt = locked_inventory_slots_runtime();
    if (!_rt.initialized) {
        _rt.initialized = true;
        var _cfg = locked_inventory_slots_config();
        var _binding = mmapi_hotkey_binding_from_name(_cfg.controller_toggle_binding);
        if (_binding != undefined) {
            mmapi_hotkey_register_binding(_binding, locked_inventory_slots_on_controller_toggle);
            _rt.controller_binding_registered = true;
        }
        locked_inventory_slots_debug("Ready");
    }
    locked_inventory_slots_try_setup_storage();
}

mmapi_mod_declare(LOCKED_INVENTORY_SLOTS_MOD, LOCKED_INVENTORY_SLOTS_VERSION);
locked_inventory_slots_register();
mmapi_register(locked_inventory_slots_tick);
