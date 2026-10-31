-- SPDX-License-Identifier: MPL-2.0
-- Bind only actual native boss events; no HP threshold, tag query or actor scan.
local M = {}
local source, packets, batches, installed = nil, {}, {}, {}
local disabled, report = false, function() end
local paths = {
    object = "/Script/CoherentUIGTPlugin.CoherentUIGTJSEvent:AddObject",
    dispatch = "/Script/CoherentUIGTPlugin.CoherentUIGTBaseComponent:TriggerJSEvent",
    batch = "/Game/uiresources/NormalHUDBP.NormalHUDBP_C:UpdateBossStat",
}
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
local function usable(s)
    return s and valid(s.hud) and s.hud.IsPageReady == true and s.hud.IsShowBossStat == true and
        valid(s.actor) and valid(s.attr) and address(s.actor.CharAttrComponent) == s.attrAddress and
        address(s.attr:GetOwner()) == s.actorAddress
end
local function protected(fn)
    return function(...)
        if disabled then return end
        local ok, err = pcall(fn, ...)
        if not ok then
            disabled, source, packets, batches = true, nil, {}, {}
            report("Boss integration disabled; fallback=accepted-overhead error=" .. tostring(err))
        end
        -- nil preserves native return values.
    end
end
local callbacks = {}
callbacks.object = function(context, parameter)
    local event, object = context:get(), parameter:get()
    local key = address(event)
    packets[key] = nil
    if key == "none" or not derived(object, "ActorComponent") then return end
    local actor = object:GetOwner()
    if not derived(actor, "GenesisCharacter") or address(actor.CharAttrComponent) ~= address(object) then return end
    local count = 0
    for _ in pairs(packets) do count = count + 1 end
    if count >= 64 then return end
    packets[key] = { actor = actor, attr = object, actorAddress = address(actor),
        attrAddress = address(object), wall = os.time() }
end
callbacks.dispatch = function(context, name, parameter)
    local event = parameter:get()
    local key, packet = address(event), packets[address(event)]
    packets[key] = nil
    if name:get():ToString() ~= "UpdateBossStat" then return end
    local component = context:get()
    if not derived(component, "ActorComponent") then return end
    local hud = component:GetOwner()
    if not derived(hud, "NormalHUDBP_C") or address(hud.CoherentUIGTHUD) ~= address(component) then return end
    if not packet or os.time() - packet.wall > 2 or address(hud.JsEventObject) ~= key then
        source = nil
        return
    end
    packet.hud = hud
    if not usable(packet) or packet.actor:IsPlayerControlled() then source = nil; return end
    -- Original HTML consumes three arguments. The scoped addon consumes this fourth
    -- identity argument; no native argument/HP/property is replaced.
    event:AddString("SEH1:" .. address(hud) .. ":" .. packet.actorAddress .. ":" .. packet.attrAddress)
    local hudKey = address(hud)
    local batch = batches[hudKey]
    if not batch then batch = {}; batches[hudKey] = batch end
    batch[packet.actorAddress] = packet
end
callbacks.batch = function(context)
    local hud = context:get()
    local key = address(hud)
    local batch = batches[key]
    batches[key] = nil
    local previous = source
    if source and address(source.hud) == key then source = nil end
    local count, candidate = 0, nil
    for _, entry in pairs(batch or {}) do count = count + 1; candidate = entry end
    if count == 1 and usable(candidate) then
        source = candidate
        if not previous or previous.actorAddress ~= candidate.actorAddress or address(previous.hud) ~= key then
            report("Boss source bound; bridge=SEH1 owner=" .. candidate.actor:GetFullName())
        end
    elseif count > 1 then report("Multiple boss sources in one native batch; fallback=accepted-overhead") end
end
function M.isBoss(actor)
    if disabled then return false end
    local ok, result = pcall(function()
        if not usable(source) then source = nil; return false end
        return address(actor) == source.actorAddress
    end)
    if not ok then source = nil; return false end
    return result
end
function M.poll(logOnce)
    report = logOnce
    if disabled then return end
    for key, path in pairs(paths) do
        if not installed[key] and valid(StaticFindObject(path)) then
            local ok, pre, post = pcall(RegisterHook, path, protected(callbacks[key]))
            if not ok or type(pre) ~= "number" or type(post) ~= "number" then
                disabled, source = true, nil
                report("Boss hook unavailable; fallback=accepted-overhead scope=" .. key)
                return
            end
            installed[key] = true
        end
    end
    if source and not usable(source) then source = nil end
    for key, entry in pairs(packets) do if os.time() - entry.wall > 2 then packets[key] = nil end end
end
-- Main setup shutdown: retain native registrations but make every owned callback
-- inert before restoring widgets/cancelling the timer. No UObject calls here.
function M.stop()
    disabled, source, packets, batches = true, nil, {}, {}
end
return M
