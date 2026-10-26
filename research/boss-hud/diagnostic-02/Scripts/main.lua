-- SPDX-License-Identifier: MPL-2.0
-- Research only: observe native boss HUD visibility across player death/respawn.
local ID, PREFIX = "boss-link-diagnostic-02", "BOSS_LINK_DIAGNOSTIC"
local active, pending, lines = true, false, 0
local started, heartbeat, dispatches = os.time(), 0, 0
local huds, packets, hooks, errors = {}, {}, {}, {}
local paths = {
    object = "/Script/CoherentUIGTPlugin.CoherentUIGTJSEvent:AddObject",
    boolean = "/Script/CoherentUIGTPlugin.CoherentUIGTJSEvent:AddBool",
    dispatch = "/Script/CoherentUIGTPlugin.CoherentUIGTBaseComponent:TriggerJSEvent",
    batch = "/Game/uiresources/NormalHUDBP.NormalHUDBP_C:UpdateBossStat",
}
local function emit(event, fields)
    if not active then return end
    lines = lines + 1
    if lines > 600 then
        print(PREFIX .. " event=STOP id=" .. ID .. " reason=line-limit\n")
        active = false
        return
    end
    print(PREFIX .. " event=" .. event .. " wall=" .. os.time() .. " " .. (fields or "") .. "\n")
end
local function quoted(value) return string.format("%q", tostring(value)) end
local function valid(o) return o ~= nil and o:IsValid() end
local function address(o) return valid(o) and tostring(o:GetAddress()) or "none" end
local function derived(o, name)
    if not valid(o) then return false end
    local cls = o:GetClass()
    for _ = 1, 32 do
        if not valid(cls) then return false end
        if cls:GetFName():ToString() == name then return true end
        cls = cls:GetSuperStruct()
    end
    return false
end
local function reject(scope, err)
    if errors[scope] then return end
    errors[scope] = true
    emit("REJECT", "scope=" .. quoted(scope) .. " action=sample-skipped error=" .. quoted(err))
end
local function safe(scope, fn)
    return function(...)
        if not active then return end
        local ok, err = pcall(fn, ...)
        if not ok then reject(scope, err) end
        -- Never return a hook override; a rejected sample does not disable later samples.
    end
end
local function remember(hud)
    assert(derived(hud, "NormalHUDBP_C"), "unexpected HUD class")
    local key = address(hud)
    if not huds[key] then
        local count = 0
        for _ in pairs(huds) do count = count + 1 end
        assert(count < 8, "HUD observation limit exceeded")
        huds[key] = { object = hud }
    end
    return huds[key], key
end
local function state(hud)
    assert(type(hud.IsShowBossStat) == "boolean" and type(hud.IsPageReady) == "boolean",
        "HUD state fields unavailable")
    return "shown=" .. tostring(hud.IsShowBossStat) .. " ready=" .. tostring(hud.IsPageReady)
end
local function packet(event, value)
    local key = address(event)
    if key == "none" then return end
    packets[key] = nil
    local count = 0
    for _ in pairs(packets) do count = count + 1 end
    assert(count < 64, "pending event limit exceeded")
    value.wall = os.time()
    packets[key] = value
end
local callbacks = {}
callbacks.boolean = function(context, parameter)
    local event = context:get()
    packets[address(event)] = nil
    local value
    if type(parameter) == "boolean" then value = parameter else value = parameter:get() end
    assert(type(value) == "boolean", "AddBool argument is not boolean")
    packet(event, { kind = "visibility", value = value })
end
callbacks.object = function(context, parameter)
    local event, object = context:get(), parameter:get()
    packets[address(event)] = nil
    if not derived(object, "ActorComponent") then return end
    local actor = object:GetOwner()
    if not derived(actor, "GenesisCharacter") or address(actor.CharAttrComponent) ~= address(object) then return end
    packet(event, { kind = "source", actor = actor, attr = object,
        actorAddress = address(actor), attrAddress = address(object) })
end
callbacks.dispatch = function(context, nameParameter, eventParameter)
    local event = eventParameter:get()
    local eventAddress = address(event)
    local value = packets[eventAddress]
    packets[eventAddress] = nil -- Every dispatch consumes any previous packet for its event.
    local name = nameParameter:get():ToString()
    if name ~= "UpdateBossStat" and name ~= "ToggleDisplayBossStat" then return end
    local component = context:get()
    assert(derived(component, "ActorComponent"), "sender is not ActorComponent")
    local hud = component:GetOwner()
    local entry, key = remember(hud)
    assert(address(hud.CoherentUIGTHUD) == address(component), "HUD sender mismatch")
    assert(valid(event), "event is no longer valid")
    assert(value and os.time() - value.wall <= 2, "missing current native event packet")
    if name == "ToggleDisplayBossStat" then
        assert(value.kind == "visibility" and type(value.value) == "boolean", "missing AddBool payload")
        -- This native function uses a LOCAL JS event, not hud.JsEventObject.
        emit("VISIBILITY", "hud=" .. key .. " payload_shown=" .. tostring(value.value) ..
            " " .. state(hud) .. " previous_actor=" .. (entry.source and entry.source.actorAddress or "none"))
        return
    end
    assert(value.kind == "source" and address(hud.JsEventObject) == eventAddress, "boss source event mismatch")
    assert(valid(value.actor) and valid(value.attr), "boss source expired")
    assert(address(value.actor.CharAttrComponent) == value.attrAddress and
        address(value.attr:GetOwner()) == value.actorAddress, "boss source owner mismatch")
    local sourceState = "actor=" .. value.actorAddress .. " attr=" .. value.attrAddress ..
        " name=" .. quoted(value.actor.DisplayName:ToString())
    entry.source = value
    dispatches = dispatches + 1
    if sourceState ~= entry.sourceState or os.time() - (entry.lastDispatch or 0) >= 5 then
        emit("SOURCE", "hud=" .. key .. " dispatch=" .. dispatches .. " " .. state(hud) .. " " .. sourceState)
        entry.sourceState, entry.lastDispatch = sourceState, os.time()
    end
end
callbacks.batch = function(context) remember(context:get()) end
local function sampleHUD(key, entry)
    local hud = entry.object
    if not valid(hud) then
        emit("HUD_REMOVED", "hud=" .. key .. " previous_actor=" .. (entry.source and entry.source.actorAddress or "none"))
        huds[key] = nil
        return
    end
    local observed = state(hud)
    local source = entry.source
    if source then
        local actorValid, attrValid = valid(source.actor), valid(source.attr)
        local ownerMatches = attrValid and address(source.attr:GetOwner()) == source.actorAddress
        observed = observed .. " last_actor=" .. source.actorAddress .. " actor_valid=" .. tostring(actorValid) ..
            " attr_valid=" .. tostring(attrValid) .. " owner_matches=" .. tostring(ownerMatches)
    else
        observed = observed .. " last_actor=none"
    end
    if observed ~= entry.state then
        emit("HUD_STATE", "hud=" .. key .. " " .. observed)
        entry.state = observed
    end
end
local function install(key)
    if hooks[key] or errors["install-" .. key] then return end
    if not valid(StaticFindObject(paths[key])) then return end
    local ok, pre, post = pcall(RegisterHook, paths[key], safe(key, callbacks[key]))
    if not ok or type(pre) ~= "number" or type(post) ~= "number" then
        reject("install-" .. key, ok and "hook IDs unavailable" or pre)
        return
    end
    hooks[key] = true
    emit("HOOK", "scope=" .. key .. " path=" .. quoted(paths[key]))
end
local function poll()
    if os.time() - started >= 1800 then
        emit("STOP", "reason=30-minute-limit")
        active = false
        return
    end
    for key in pairs(paths) do
        local ok, err = pcall(install, key)
        if not ok then reject("install-" .. key, err) end
    end
    for key, entry in pairs(huds) do
        local ok, err = pcall(sampleHUD, key, entry)
        if not ok then reject("hud-" .. key, err) end -- Never stop other HUDs or heartbeat.
    end
    for key, value in pairs(packets) do
        if os.time() - value.wall > 2 then packets[key] = nil end
    end
    if os.time() - heartbeat >= 10 then
        local states, count = {}, 0
        for key in pairs(paths) do
            states[#states + 1] = key .. "=" .. (errors["install-" .. key] and "error" or hooks[key] and "hooked" or "waiting")
        end
        for _ in pairs(huds) do count = count + 1 end
        table.sort(states)
        emit("HEARTBEAT", "huds=" .. count .. " dispatches=" .. dispatches .. " " .. table.concat(states, " "))
        heartbeat = os.time()
    end
end
emit("START", "id=" .. ID .. " mode=observe-only scenario=player-death-respawn max_seconds=1800 max_lines=600")
LoopAsync(1000, function()
    if not active then return true end
    if pending then return false end
    pending = true
    local ok, err = pcall(ExecuteInGameThread, function()
        local success, failure = pcall(poll)
        pending = false
        if not success then reject("scheduler-sample", failure) end
    end)
    if not ok then pending = false; reject("game-thread-queue", err) end
    return false
end)
