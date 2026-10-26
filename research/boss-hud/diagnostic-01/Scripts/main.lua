-- SPDX-License-Identifier: MPL-2.0
-- Research only. Observe native calls; never set a UObject property or return a hook override.
local ID = "boss-link-diagnostic-01"
local PREFIX = "BOSS_LINK_DIAGNOSTIC"
local active, pending, lines = true, false, 0
local started = os.time()
local hooks, failed, huds, widgets, packets = {}, {}, {}, {}, {}
local query, querySerial, dispatchSerial = nil, 0, 0
local lastDispatch, lastHeartbeat = {}, 0
local paths = {
    query = "/Script/Genesis.GameGlobal:GetSceneGameCharacterWithTag",
    object = "/Script/CoherentUIGTPlugin.CoherentUIGTJSEvent:AddObject",
    dispatch = "/Script/CoherentUIGTPlugin.CoherentUIGTBaseComponent:TriggerJSEvent",
    batch = "/Game/uiresources/NormalHUDBP.NormalHUDBP_C:UpdateBossStat",
    overhead = "/Game/MainContent/Template/UMG/MeterOnHead2.MeterOnHead2_C:Tick",
}
local function emit(event, fields)
    if not active then return end
    lines = lines + 1
    if lines > 1200 then
        print(PREFIX .. " event=STOP reason=line-limit id=" .. ID .. "\n")
        active = false
        return
    end
    print(PREFIX .. " event=" .. event .. " wall=" .. os.time() .. " " .. (fields or "") .. "\n")
end
local function valid(o) return o ~= nil and o:IsValid() end
local function addr(o) return valid(o) and tostring(o:GetAddress()) or "none" end
local function text(s) return string.format("%q", tostring(s)) end
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
local function once(key, event, fields)
    if failed[key] then return end
    failed[key] = true
    emit(event, fields)
end
local function guard(key, fn)
    return function(...)
        if not active or failed["callback-" .. key] then return end
        local ok, err = pcall(fn, ...)
        if not ok then
            once("callback-" .. key, "ERROR", "scope=" .. key .. " action=observer-disabled error=" .. text(err))
        end
        -- Deliberately no returned value: the native result must remain untouched.
    end
end
local function identity(actor)
    assert(derived(actor, "GenesisCharacter"), "source is not GenesisCharacter")
    local attr = actor.CharAttrComponent
    assert(derived(attr, "ActorComponent"), "CharAttrComponent is not ActorComponent")
    local owner = attr:GetOwner()
    assert(addr(owner) == addr(actor), "attribute component owner mismatch")
    return { actor = addr(actor), attr = addr(attr) }
end
local function snapshot(actor)
    local id = identity(actor)
    local attr = actor.CharAttrComponent
    local hp, maximum = attr.HP, attr.MaxHP
    assert(type(hp) == "number" and type(maximum) == "number", "HP/MaxHP properties unavailable")
    assert(hp == hp and maximum == maximum and math.abs(hp) < math.huge and
        math.abs(maximum) < math.huge, "invalid health sample")
    return { actor = id.actor, attr = id.attr, hp = hp, maximum = maximum,
        name = actor.DisplayName:ToString(), full = actor:GetFullName() }
end
local function fields(s)
    return "actor=" .. s.actor .. " attr=" .. s.attr .. " hp=" .. s.hp .. " max=" .. s.maximum ..
        " name=" .. text(s.name) .. " full=" .. text(s.full)
end
local function hudState(hud)
    assert(type(hud.IsShowBossStat) == "boolean" and type(hud.IsPageReady) == "boolean",
        "HUD state fields unavailable")
    return "shown=" .. tostring(hud.IsShowBossStat) .. " ready=" .. tostring(hud.IsPageReady)
end
local function remember(map, key, object, limit)
    if map[key] then return end
    local count = 0
    for _ in pairs(map) do count = count + 1 end
    assert(count < limit, "live object limit exceeded")
    map[key] = { object = object }
end
local function overheadFor(actorAddress)
    local result = {}
    for key, item in pairs(widgets) do
        local w = item.object
        if not valid(w) then widgets[key] = nil
        elseif addr(w.Avatar) == actorAddress then
            assert(derived(w.HPBar, "ProgressBar"), "overhead HPBar missing")
            result[#result + 1] = " widget=" .. key .. " percent=" .. tostring(w.HPBar.Percent) ..
                " locked=" .. tostring(w.IsLockShowing)
        end
    end
    table.sort(result)
    return #result, table.concat(result, " ;")
end
local callbacks = {}
callbacks.query = function(_, tag, outCharacters, finalFlag)
    if tag:get():ToString() ~= "Boss" then return end
    assert(type(finalFlag:get()) == "boolean", "Boss query final flag is not boolean")
    if finalFlag:get() then return end -- Only the exact inspected call form is relevant here.
    local members, order, count = {}, {}, 0
    outCharacters:get():ForEach(function(index, value)
        count = count + 1
        assert(count <= 32, "Boss query output exceeds research limit")
        local s = identity(value:get())
        members[s.actor] = s.attr
        order[#order + 1] = tostring(index) .. ":" .. s.actor .. ":" .. s.attr
    end)
    querySerial = querySerial + 1
    local signature = table.concat(order, ",")
    if not query or query.signature ~= signature then
        emit("QUERY", "query=" .. querySerial .. " count=" .. count .. " order=" .. text(signature))
    end
    query = { serial = querySerial, members = members, signature = signature, wall = os.time() }
end
callbacks.object = function(context, parameter)
    local event, object = context:get(), parameter:get()
    local key = addr(event)
    if key == "none" then return end
    -- Every AddObject invalidates any earlier source for this same event object.
    packets[key] = nil
    if not derived(object, "ActorComponent") then return end
    local actor = object:GetOwner()
    if not derived(actor, "GenesisCharacter") or addr(actor.CharAttrComponent) ~= addr(object) then return end
    local count = 0
    for _ in pairs(packets) do count = count + 1 end
    assert(count < 64, "pending JS-event limit exceeded")
    packets[key] = { actor = actor, attr = addr(object), query = query, wall = os.time() }
end
callbacks.dispatch = function(context, eventName, eventParameter)
    local event = eventParameter:get()
    local key = addr(event)
    local packet = packets[key]
    packets[key] = nil -- Consumed for every event, including unrelated UI events.
    if eventName:get():ToString() ~= "UpdateBossStat" then return end
    local component = context:get()
    assert(derived(component, "ActorComponent"), "sender is not ActorComponent")
    local hud = component:GetOwner()
    assert(derived(hud, "NormalHUDBP_C"), "unexpected boss-event HUD owner")
    assert(addr(hud.CoherentUIGTHUD) == addr(component), "HUD component identity mismatch")
    remember(huds, addr(hud), hud, 4)
    dispatchSerial = dispatchSerial + 1
    assert(valid(event) and addr(hud.JsEventObject) == key, "HUD JS-event identity mismatch")
    if not packet or os.time() - packet.wall > 2 or not valid(packet.actor) then
        emit("INCOMPLETE", "dispatch=" .. dispatchSerial .. " reason=no-current-attribute-packet hud=" .. addr(hud))
        return
    end
    local s = snapshot(packet.actor)
    assert(s.attr == packet.attr, "event source changed before dispatch")
    local count, overhead = overheadFor(s.actor)
    local member = "unknown"
    local q = 0
    local packetQuery = packet.query
    if packetQuery and os.time() - packetQuery.wall <= 2 then
        q = packetQuery.serial
        member = tostring(packetQuery.members[s.actor] == s.attr)
    end
    -- This is engine-side dispatch order, not proof of JS delivery/render order.
    local state = "hud=" .. addr(hud) .. " component=" .. addr(component) ..
        " " .. hudState(hud) ..
        " " .. fields(s) .. " query_member=" .. member .. " overhead_count=" .. count .. overhead
    local previous = lastDispatch[addr(hud)]
    if not previous or previous.state ~= state or os.time() - previous.wall >= 5 then
        emit("DISPATCH", "dispatch=" .. dispatchSerial .. " query=" .. q .. " js_event=" .. key .. " " .. state)
        lastDispatch[addr(hud)] = { state = state, wall = os.time() }
    end
end
callbacks.batch = function(context)
    local hud = context:get()
    assert(derived(hud, "NormalHUDBP_C"), "unexpected UpdateBossStat context")
    remember(huds, addr(hud), hud, 4)
end
callbacks.overhead = function(context)
    local w = context:get()
    assert(derived(w, "MeterOnHead2_C"), "unexpected overhead context")
    remember(widgets, addr(w), w, 128)
end
local function install(key)
    if hooks[key] or failed["install-" .. key] then return end
    if not valid(StaticFindObject(paths[key])) then return end
    local fn = guard(key, callbacks[key])
    local ok, pre, post = pcall(function()
        if key == "query" then
            return RegisterHook(paths[key], function() end, fn) -- Native query output: post only.
        end
        return RegisterHook(paths[key], fn) -- Native pre / Blueprint post, per UE4SS contract.
    end)
    if not ok then
        once("install-" .. key, "ERROR", "scope=" .. key .. " action=hook-disabled error=" .. text(pre))
        return
    end
    if type(pre) ~= "number" or type(post) ~= "number" then
        failed["callback-" .. key] = true
        once("install-" .. key, "ERROR", "scope=" .. key .. " action=hook-disabled reason=missing-hook-ids")
        return
    end
    hooks[key] = { pre = pre, post = post }
    emit("HOOK", "scope=" .. key .. " path=" .. text(paths[key]))
end
local poll = guard("poll", function()
    if os.time() - started >= 1800 then
        emit("STOP", "reason=30-minute-limit")
        active = false
        return
    end
    for key in pairs(paths) do install(key) end
    for key, item in pairs(huds) do
        local hud = item.object
        if not valid(hud) then
            emit("HUD_REMOVED", "hud=" .. key)
            huds[key], lastDispatch[key] = nil, nil
        else
            local state = hudState(hud)
            if state ~= item.state then
                emit("HUD", "hud=" .. key .. " " .. state)
                item.state = state
            end
        end
    end
    for key, item in pairs(widgets) do
        local w = item.object
        if not valid(w) or not derived(w.Avatar, "GenesisCharacter") then
            emit("OVERHEAD_REMOVED", "widget=" .. key)
            widgets[key] = nil
        else
            local s = snapshot(w.Avatar)
            local member = "unknown"
            if query and os.time() - query.wall <= 2 then member = tostring(query.members[s.actor] == s.attr) end
            local state = fields(s) .. " query_member=" .. member .. " percent=" .. tostring(w.HPBar.Percent) ..
                " locked=" .. tostring(w.IsLockShowing)
            if item.state ~= state then
                emit("OVERHEAD", "widget=" .. key .. " " .. state)
                item.state = state
            end
        end
    end
    for key, packet in pairs(packets) do
        if os.time() - packet.wall > 2 then packets[key] = nil end
    end
    if os.time() - lastHeartbeat >= 15 then
        local states = {}
        for key in pairs(paths) do
            states[#states + 1] = key .. "=" .. ((failed["callback-" .. key] or failed["install-" .. key]) and "error" or hooks[key] and "hooked" or "waiting")
        end
        table.sort(states)
        emit("HEARTBEAT", "dispatches=" .. dispatchSerial .. " queries=" .. querySerial .. " " .. table.concat(states, " "))
        lastHeartbeat = os.time()
    end
end)
emit("START", "id=" .. ID .. " mode=observe-only max_seconds=1800 max_lines=1200")
LoopAsync(1000, function()
    if not active or failed["callback-poll"] then return true end
    if pending then return false end
    pending = true
    ExecuteInGameThread(function() poll(); pending = false end)
    return false
end)
