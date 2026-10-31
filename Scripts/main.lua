local UEHelpers=require("UEHelpers")
local Policy=require("policy")
local Boss=require("boss")
local config={trailHold=0.45,trailFade=0.5,showAfterHit=3.0,fadeIn=0.12,fadeOut=0.3,
    width=90,height=7,minWidth=68,maxWidth=134,referenceHP=252,widthExponent=0.25,
    comboWindow=1.2,damageHold=1.2,damageFade=0.3,damageFontSize=12,
    dotSize=14,dotFontSize=12}
local entries={}
local hooked=false
local disabled=false
local timerHandle
local floatingHooked=false
local hiddenFloating={}
local floatingOpacity={}
local damageFont
local reported={}
local BP="/Game/MainContent/Template/UMG/MeterOnHead2.MeterOnHead2_C:Tick"
local function valid(o) return o~=nil and o:IsValid() end
local function log(s) print("[SoulsEnemyHUD] "..s.."\n") end
local function report(s) if not reported[s] then reported[s]=true; log(s) end end
local function vec(x,y) return {X=x,Y=y} end
local function color(r,g,b,a) return {R=r,G=g,B=b,A=a or 1} end
local function derived(o,name)
    if not valid(o) then return false end
    local cls=o:GetClass()
    for _=1,32 do
        if not valid(cls) then return false end
        if cls:GetFName():ToString()==name then return true end
        cls=cls:GetSuperStruct()
    end
    return false
end
local function add(canvas,child,x,y,w,h,z)
    local slot=canvas:AddChildToCanvas(child)
    assert(valid(slot),"Canvas slot not created")
    slot:SetAnchors({Minimum=vec(0.5,0),Maximum=vec(0.5,0)})
    slot:SetPosition(vec(x,y)); slot:SetSize(vec(w,h)); slot:SetZOrder(z)
    child:SetVisibility(4) -- HitTestInvisible; no input capture.
    return slot
end
local function construct(className,outer)
    local cls=StaticFindObject("/Script/UMG."..className)
    assert(valid(cls),"Missing class "..className)
    local object=StaticConstructObject(cls,outer)
    assert(valid(object),"Unable to construct "..className)
    return object
end
local function arrayValues(array)
    local result={}
    array:ForEach(function(index,value) result[index]=value:get() end)
    return result
end
local function readHealth(widget,e)
    local current=arrayValues(widget.CurVals)
    local maximum=arrayValues(widget.MaxVals)
    local colors=arrayValues(widget.CurColorClasses)
    local matches={}
    for index,cur in pairs(current) do
        local max=maximum[index]
        if type(cur)=="number" and type(max)=="number" and max>0 and
            math.abs(math.max(0,math.min(1,cur/max))-e.hp.Percent)<0.0001 then
            local tag=colors[index]
            if type(tag)~="string" and tag~=nil then tag=tag:ToString() end
            if type(tag)=="string" and tag:lower()=="red" then
                e.healthIndex=index
                return cur,max
            end
            matches[#matches+1]={index=index,cur=cur,max=max}
        end
    end
    for _,match in ipairs(matches) do
        if match.index==e.healthIndex or #matches==1 then
            e.healthIndex=match.index
            return match.cur,match.max
        end
    end
    -- Ambiguous full HP/stamina arrays are not guessed. Keep native numbers and
    -- fixed compact width until the HP entry can be positively identified.
    return nil,nil
end
local function layout(e,width)
    if e.width==width then return end
    local y=e.old.position.Y
    e.hp.Slot:SetPosition(vec(-width/2,y)); e.hp.Slot:SetSize(vec(width,config.height))
    e.frame.Slot:SetPosition(vec(-width/2-1,y-1)); e.frame.Slot:SetSize(vec(width+2,config.height+2))
    e.trail.Slot:SetPosition(vec(-width/2,y)); e.trail.Slot:SetSize(vec(width,config.height))
    e.damage.Slot:SetPosition(vec(width/2-70,y-23))
    e.width=width
end
local function restore(e)
    if not e then return end
    for _,child in ipairs(e.created or {}) do
        if valid(child) then pcall(function() child:RemoveFromParent() end) end
    end
    if valid(e.hp) and e.old then
        pcall(function()
            e.hp.Slot:SetPosition(e.old.position)
            e.hp.Slot:SetSize(e.old.size)
            e.hp.Slot:SetZOrder(e.old.z)
            e.hp:SetFillColorAndOpacity(e.old.fill)
            e.hp:SetRenderOpacity(1)
            e.hp:SetVisibility(e.old.visibility)
        end)
    end
    if valid(e.icon) then pcall(function() e.icon:SetRenderOpacity(1) end) end
    if valid(e.nativeDamageText) and e.nativeTextOpacity~=nil then
        pcall(function() e.nativeDamageText:SetRenderOpacity(e.nativeTextOpacity) end)
    end
    if valid(e.nativeDamage) and e.nativeDamageOpacity~=nil then
        pcall(function() e.nativeDamage:SetRenderOpacity(e.nativeDamageOpacity) end)
    end
end
local function prepare(widget,e)
    local hp=widget.HPBar
    local avatar=widget.Avatar
    if not derived(hp,"ProgressBar") or not derived(avatar,"GenesisCharacter") then return false end
    -- Never modify the player's own HUD or a widget with an unrelated owner.
    if avatar:IsPlayerControlled() then return false end
    local canvas=hp:GetParent()
    if not derived(canvas,"CanvasPanel") or not derived(hp.Slot,"CanvasPanelSlot") then return false end
    e.hp=hp; e.icon=widget.LockIcon; e.avatar=avatar; e.canvas=canvas
    e.created={}
    local p=hp.Slot:GetPosition(); local size=hp.Slot:GetSize(); local fill=hp.FillColorAndOpacity
    e.old={position=vec(p.X,p.Y),size=vec(size.X,size.Y),z=hp.Slot:GetZOrder(),
        fill=color(fill.R,fill.G,fill.B,fill.A),visibility=hp:GetVisibility()}
    local y=p.Y
    local tree=widget.WidgetTree
    assert(valid(tree),"WidgetTree not available")
    local white=LoadAsset("/Engine/EngineResources/WhiteSquareTexture.WhiteSquareTexture")
    assert(derived(white,"Texture2D"),"WhiteSquareTexture not available")
    e.frame=construct("Image",tree); table.insert(e.created,e.frame)
    e.frame:SetBrushFromTexture(white,false)
    e.frame:SetColorAndOpacity(color(0.09,0.075,0.055,0.95))
    add(canvas,e.frame,-config.width/2-1,y-1,config.width+2,config.height+2,0)
    e.trail=construct("ProgressBar",tree); table.insert(e.created,e.trail)
    -- Set appearance before the new Slate widget is built by AddChildToCanvas.
    e.trail.WidgetStyle.BackgroundImage.TintColor.SpecifiedColor=color(0.015,0.012,0.012,0.95)
    e.trail:SetFillColorAndOpacity(color(0.65,0.42,0.12,1))
    e.trail:SetPercent(hp.Percent)
    add(canvas,e.trail,-config.width/2,y,config.width,config.height,1)
    hp.Slot:SetPosition(vec(-config.width/2,y))
    hp.Slot:SetSize(vec(config.width,config.height))
    hp.Slot:SetZOrder(2)
    hp:SetFillColorAndOpacity(color(0.34,0.0385,0.038,1))
    e.damage=construct("TextBlock",tree); table.insert(e.created,e.damage)
    if derived(widget.DamageText,"TextBlock") then e.damage:SetFont(widget.DamageText.Font) end
    if not valid(damageFont) then
        damageFont=LoadAsset("/Game/Fonts/EBGaramond-SemiBold_Font.EBGaramond-SemiBold_Font")
        assert(derived(damageFont,"Font"),"EB Garamond Font asset not available")
    end
    e.damage.Font.FontObject=damageFont
    e.damage.Font.TypefaceFontName=FName("Default")
    e.damage.Font.Size=config.damageFontSize
    e.damage.Font.OutlineSettings.OutlineSize=1
    e.damage.Font.OutlineSettings.OutlineColor=color(0,0,0,1)
    e.damage.Font.OutlineSettings.bApplyOutlineToDropShadows=false
    e.damage:SetFont(e.damage.Font)
    e.damage:SetJustification(2)
    e.damage:SetColorAndOpacity({SpecifiedColor=color(0.9,0.86,0.75,1),ColorUseRule=0})
    e.damage:SetShadowOffset(vec(0,0))
    e.damage:SetShadowColorAndOpacity(color(0,0,0,0))
    add(canvas,e.damage,config.width/2-70,y-23,70,22,3)
    e.damage:SetRenderOpacity(0)
    e.nativeDamageText=widget.DamageText
    if valid(e.nativeDamageText) then
        e.nativeTextOpacity=e.nativeDamageText.RenderOpacity
        e.nativeDamageText:SetRenderOpacity(0)
    end
    e.nativeDamage=widget.DamageTextCanvas
    if valid(e.nativeDamage) then e.nativeDamageOpacity=e.nativeDamage.RenderOpacity end
    e.dot=construct("TextBlock",tree); table.insert(e.created,e.dot)
    local text=UEHelpers.GetKismetTextLibrary():Conv_StringToText("●")
    e.dot:SetText(text)
    e.dot.Font.Size=config.dotFontSize
    e.dot:SetFont(e.dot.Font)
    e.dot:SetJustification(1)
    e.dot:SetColorAndOpacity({SpecifiedColor=color(0.92,0.97,1,1),ColorUseRule=0})
    e.dot:SetShadowOffset(vec(0,0))
    e.dot:SetShadowColorAndOpacity(color(0.2,0.45,0.8,0.7))
    e.dotSlot=add(canvas,e.dot,-config.dotSize/2,0,config.dotSize,config.dotSize+4,20)
    e.dot:SetRenderOpacity(0)
    e.policy=Policy.new(); e.ready=true
    if valid(e.icon) then e.icon:SetRenderOpacity(0) end
    log("Styled "..widget:GetFullName().." owner="..avatar:GetFullName())
    return true
end
local function updateDot(widget,e,geometry,locked)
    if not locked then
        if e.dotVisible then e.dot:SetRenderOpacity(0); e.dotVisible=false end
        return
    end
    local pc=widget:GetOwningPlayer()
    if not derived(pc,"PlayerController") then return end
    local screen={X=0,Y=0}
    -- Actor location is the capsule/root centre, not the nameplate above the head.
    if not pc:ProjectWorldLocationToScreen(e.avatar:K2_GetActorLocation(),screen,false) then
        e.dot:SetRenderOpacity(0); e.dotVisible=false; return
    end
    local slate=StaticFindObject("/Script/UMG.Default__SlateBlueprintLibrary")
    assert(valid(slate),"SlateBlueprintLibrary not available")
    local coordinate={X=0,Y=0}
    slate:ScreenToWidgetLocal(widget,geometry,screen,coordinate,false)
    -- The root canvas fills the user widget. Our slot is anchored to its left top.
    e.dotSlot:SetAnchors({Minimum=vec(0,0),Maximum=vec(0,0)})
    e.dotSlot:SetPosition(vec(coordinate.X-config.dotSize/2,coordinate.Y-(config.dotSize+4)/2))
    if not e.dotVisible then e.dot:SetRenderOpacity(1); e.dotVisible=true end
end
local function tick(widget,geometry)
    if not valid(widget) then return end
    local key=widget:GetAddress()
    local e=entries[key]
    if not e then
        if not derived(widget,"MeterOnHead2_C") then return end
        e={widget=widget}; entries[key]=e
    end
    if e.failed then return end
    local ok,err=pcall(function()
        if not e.ready and not prepare(widget,e) then return end
        if not valid(e.avatar) or not valid(e.hp) then return end
        local boss=Boss.isBoss(widget.Avatar)
        if boss~=e.isBoss then
            e.policy=Policy.new(); e.lastAlpha=nil; e.lastTail=nil; e.lastDamage=nil; e.damageAlpha=nil
            e.isBoss=boss
        end
        if boss and widget.Avatar:GetAddress()==e.avatar:GetAddress() then
            -- Post native Tick: only HP/digits, never the root, stamina or lock dot.
            e.hp:SetRenderOpacity(0); e.frame:SetRenderOpacity(0); e.trail:SetRenderOpacity(0)
            e.damage:SetRenderOpacity(0)
            if valid(e.nativeDamageText) then e.nativeDamageText:SetRenderOpacity(0) end
            if valid(e.nativeDamage) then e.nativeDamage:SetRenderOpacity(0) end
            updateDot(widget,e,geometry,widget.IsLockShowing==true)
            return
        end
        local now=UEHelpers.GetGameplayStatics():GetTimeSeconds(widget)
        local locked=widget.IsLockShowing==true
        local result=Policy.step(e.policy,now,e.hp.Percent,locked,config)
        if not result then return end
        -- Do not change the parent widget's native visibility, distance culling,
        -- positioning or enemy stamina.
        if result.alpha>0 and e.hp:GetVisibility()~=4 then e.hp:SetVisibility(4) end
        if result.alpha~=e.lastAlpha then
            e.hp:SetRenderOpacity(result.alpha)
            e.frame:SetRenderOpacity(result.alpha)
            e.trail:SetRenderOpacity(result.alpha)
            e.lastAlpha=result.alpha
        end
        if result.tail~=e.lastTail then e.trail:SetPercent(result.tail); e.lastTail=result.tail end
        if valid(e.nativeDamageText) and e.nativeDamageText.RenderOpacity~=0 then e.nativeDamageText:SetRenderOpacity(0) end
        local tint=e.hp.FillColorAndOpacity
        if math.abs(tint.R-.34)>0.0001 or math.abs(tint.G-.0385)>0.0001 then
            e.hp:SetFillColorAndOpacity(color(.34,.0385,.038,1))
        end
        local sourceOK,cur,max=pcall(readHealth,widget,e)
        if not sourceOK then
            report("HP source unavailable; retaining native damage numbers: "..tostring(cur))
            cur,max=nil,nil
        end
        if cur~=nil then
            layout(e,Policy.width(max,config))
            local damage=Policy.damage(e.policy,now,cur,max,config)
            if damage.sum~=e.lastDamage then
                e.damage:SetText(UEHelpers.GetKismetTextLibrary():Conv_StringToText(tostring(damage.sum)))
                e.lastDamage=damage.sum
            end
            local alpha=damage.sum>0 and damage.alpha or 0
            if alpha~=e.damageAlpha then e.damage:SetRenderOpacity(alpha); e.damageAlpha=alpha end
            if valid(e.nativeDamage) and e.nativeDamage.RenderOpacity~=0 then e.nativeDamage:SetRenderOpacity(0) end
            if max~=e.loggedMax then
                log(string.format("HP verified owner=%s current=%s max=%s width=%s index=%s",e.avatar:GetFullName(),cur,max,e.width,e.healthIndex))
                e.loggedMax=max
            end
        else
            -- A missing/ambiguous source must never fabricate damage numbers.
            if e.damageAlpha~=0 then e.damage:SetRenderOpacity(0); e.damageAlpha=0 end
            if e.loggedMax==nil then report("Waiting for unambiguous HP array: "..widget:GetFullName()) end
        end
        updateDot(widget,e,geometry,result.locked)
    end)
    if not ok then
        restore(e); e.failed=true
        report("Restored native widget after error: "..tostring(err))
    end
end

local FLOAT_BP="/Game/MainContent/Template/UMG/HudUmg.HudUmg_C:Tick"
local function hideFloating(hud)
    if not derived(hud,"HudUmg_C") then return end
    local root=hud.WidgetTree.RootWidget
    local first=hud.DamageDigits0
    if not derived(root,"CanvasPanel") or not derived(first,"TextBlock") then return end
    if first:GetParent():GetAddress()~=root:GetAddress() then return end
    local key=root:GetAddress()
    if not hiddenFloating[key] then floatingOpacity[key]=root.RenderOpacity end
    if root.RenderOpacity~=0 then root:SetRenderOpacity(0) end
    if not hiddenFloating[key] then
        hiddenFloating[key]=root
        log("Suppressed verified DamageDigits pool: "..hud:GetFullName())
    end
end

local function setup()
    Boss.poll(report)
    for key,e in pairs(entries) do
        if not valid(e.widget) then entries[key]=nil end
    end
    for key,root in pairs(hiddenFloating) do
        if not valid(root) then hiddenFloating[key]=nil; floatingOpacity[key]=nil end
    end
    if not floatingHooked and valid(StaticFindObject(FLOAT_BP)) then
        local pre,post=RegisterHook(FLOAT_BP,function(context)
            if disabled then return end
            local ok,err=pcall(hideFloating,context:get())
            if not ok then report("Floating HUD suppression error: "..tostring(err)) end
        end)
        assert(type(pre)=="number" and type(post)=="number","Floating Tick hook registration failed")
        floatingHooked=true; log("Verified HudUmg damage-pool Tick hook ready")
    end
    for _,floating in ipairs(FindAllOf("HudUmg_C") or {}) do hideFloating(floating) end
    if not hooked and valid(StaticFindObject(BP)) then
        local pre,post=RegisterHook(BP,function(context,geometry)
            if disabled then return end
            tick(context:get(),geometry:get())
        end)
        assert(type(pre)=="number" and type(post)=="number","Overhead Tick hook registration failed")
        hooked=true; log("MeterOnHead2 Tick hook ready")
    end
end

local function disable(reason)
    disabled=true -- guards precede fallible cleanup; no callback can restart setup
    pcall(log,reason)
    local stopped,stopErr=pcall(Boss.stop)
    if not stopped then pcall(log,"Boss cleanup failed: "..tostring(stopErr)) end
    -- Existing per-widget restoration is best-effort. Complete all UObject calls
    -- before CancelDelayedAction to avoid the pinned nested-removal index hazard.
    for _,entry in pairs(entries) do
        local ok,err=pcall(restore,entry)
        if not ok then pcall(log,"Widget cleanup failed: "..tostring(err)) end
    end
    for key,root in pairs(hiddenFloating) do
        local ok,err=pcall(function()
            if valid(root) then root:SetRenderOpacity(floatingOpacity[key]) end
        end)
        if not ok then pcall(log,"Floating cleanup failed: "..tostring(err)) end
    end
    entries={}; hiddenFloating={}; floatingOpacity={}
    local handle=timerHandle
    timerHandle=nil -- only one cancellation attempt, including when it fails
    if handle~=nil then
        local ok,cancelled=pcall(CancelDelayedAction,handle)
        if not ok or cancelled~=true then
            pcall(log,"Scheduler cancellation failed; callbacks remain inert: "..tostring(cancelled))
        end
    end
end

log("Loaded 0.3.3; compact enemies and boss bridge; GameThread setup candidate; nominal 1000ms polling")
if type(LoopInGameThreadWithDelay)~="function" or type(CancelDelayedAction)~="function" then
    disable("Scheduler unavailable; GameThread delayed-action API required; native HUD retained")
else
    local ok,handle=pcall(LoopInGameThreadWithDelay,1000,function()
        if disabled then return end
        local updated,err=pcall(setup)
        if not updated then disable("Setup stopped; native HUD restoration attempted: "..tostring(err)) end
        -- This API ignores return values; stopping requires the saved handle.
    end)
    if ok and math.type(handle)=="integer" and handle>=0 then
        timerHandle=handle
    else
        disable("Scheduler registration failed; native HUD retained: "..tostring(handle))
    end
end
