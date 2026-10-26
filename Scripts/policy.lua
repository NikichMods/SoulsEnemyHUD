local M = {}
local function clamp(v) return math.max(0, math.min(1, v)) end
local function smooth(v) v=clamp(v); return v*v*(3-2*v) end

function M.width(maxHP,c)
    if type(maxHP)~="number" or maxHP<=0 or maxHP~=maxHP then return c.width end
    local w=c.width*(maxHP/c.referenceHP)^c.widthExponent
    return math.floor(math.max(c.minWidth,math.min(c.maxWidth,w))/2+0.5)*2
end

function M.damage(s,now,current,maximum,c)
    if type(current)~="number" or type(maximum)~="number" or maximum<=0 or
       current~=current or maximum~=maximum then return nil end
    current=math.max(0,math.min(maximum,current))
    if s.damageTime and now<s.damageTime then
        s.damagePrevious=nil; s.damageLastHit=nil; s.damageSum=0
    end
    if s.damagePrevious~=nil and s.damageMax==maximum and current<s.damagePrevious then
        if not s.damageLastHit or now-s.damageLastHit>c.comboWindow then s.damageSum=0 end
        s.damageSum=(s.damageSum or 0)+(s.damagePrevious-current)
        s.damageLastHit=now
    elseif s.damageMax and s.damageMax~=maximum then
        s.damageLastHit=nil; s.damageSum=0
    end
    s.damagePrevious=current; s.damageMax=maximum; s.damageTime=now
    local elapsed=s.damageLastHit and now-s.damageLastHit or math.huge
    local alpha=1-smooth((elapsed-c.damageHold)/c.damageFade)
    return {sum=math.floor((s.damageSum or 0)+0.5),alpha=alpha}
end

function M.new()
    return { alpha=0, tail=1, lastHit=-math.huge }
end

function M.step(s, now, hp, locked, c)
    if type(now)~="number" or type(hp)~="number" or hp~=hp then return nil end
    hp=clamp(hp)
    if s.now and now<s.now then
        s.previous=nil; s.lastHit=-math.huge; s.alpha=0; s.tail=hp; s.shown=false
        s.fadeStart=now; s.fadeFrom=0; s.tailFrom=hp
    end
    s.now=now
    if s.previous==nil then s.tail=hp end
    if s.previous and hp<s.previous-0.000001 then
        s.tailFrom=math.max(s.tail,s.previous)
        s.lastHit=now
    elseif s.previous and hp>s.previous+0.000001 then
        s.tail=hp; s.tailFrom=hp
    end
    if s.tailFrom and hp<s.tail then
        local t=smooth((now-s.lastHit-c.trailHold)/c.trailFade)
        s.tail=math.max(hp,s.tailFrom+(hp-s.tailFrom)*t)
    else s.tail=hp end
    local show=(locked==true) or now-s.lastHit<c.showAfterHit
    if show~=s.shown then
        s.shown=show; s.fadeFrom=s.alpha; s.fadeStart=now
    end
    local target=show and 1 or 0
    local duration=show and c.fadeIn or c.fadeOut
    local p=smooth((now-(s.fadeStart or now))/duration)
    s.alpha=(s.fadeFrom or 0)+(target-(s.fadeFrom or 0))*p
    s.previous=hp
    return {hp=hp, tail=s.tail, alpha=s.alpha, locked=locked==true}
end

return M
