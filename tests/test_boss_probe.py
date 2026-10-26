# SPDX-License-Identifier: MPL-2.0
"""Exercise the real research observer with read-only host proxies, not engine rendering."""
from pathlib import Path
from lupa import LuaRuntime

source = (Path(__file__).resolve().parents[1] /
          'research/boss-hud/diagnostic-01/Scripts/main.lua').read_text(encoding='utf-8')


def fixture(missing=(), source_text=source):
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute('''
wall=100; serial=0; logs={}; registered={}; queue={}; available={}
os.time=function() return wall end
print=function(s) table.insert(logs,s) end
local parent={CharAttrComponent='ActorComponent',CoherentUIGTHUD='ActorComponent'}
local function cls(name)
 if not name then return nil end
 return {IsValid=function() return true end,
 GetFName=function() return {ToString=function() return name end} end,
 GetSuperStruct=function() return cls(parent[name]) end}
end
function obj(name,props)
 serial=serial+1
 props=props or {}; props.address=serial; props.alive=true
 props.IsValid=function() return props.alive end
 props.GetAddress=function() return props.address end
 props.GetFullName=function() return name..'_'..props.address end
 props.GetClass=function() return cls(name) end
 return setmetatable({}, {__index=props,__newindex=function() error('UObject mutation forbidden') end}),props
end
function str(s) return {ToString=function() return s end} end
function wrap(o) return {get=function() return o end, set=function() error('param mutation forbidden') end} end
function array(values)
 return {ForEach=function(self,fn) for i,v in ipairs(values) do fn(i,wrap(v)) end end}
end
function StaticFindObject(path)
 if available[path]==false then return nil end
 return obj('Function')
end
function RegisterHook(path,pre,post)
 assert(not registered[path], 'duplicate hook')
 registered[path]={pre=pre,post=post}
 return 100,101
end
function LoopAsync(ms,fn) assert(ms==1000); poll=fn end
function ExecuteInGameThread(fn) table.insert(queue,fn) end
function tick()
 local stop=poll()
 while #queue>0 do table.remove(queue,1)() end
 return stop
end
function findHook(fragment)
 for p,h in pairs(registered) do if p:find(fragment,1,true) then return h end end
end
function invoke(fragment,...)
 local h=assert(findHook(fragment), 'missing hook '..fragment)
 local r=h.pre(...); assert(r==nil, 'native return overridden')
 if h.post then local r2=h.post(...); assert(r2==nil, 'native post result overridden') end
end
function contains(fragment)
 for _,s in ipairs(logs) do if s:find(fragment,1,true) then return true end end
 return false
end
function count(fragment)
 local n=0
 for _,s in ipairs(logs) do if s:find(fragment,1,true) then n=n+1 end end
 return n
end
actor,ap=obj('GenesisCharacter',{DisplayName=str('Boss Name')})
attr,atp=obj('CharAttrComponent',{HP=100,MaxHP=100,GetOwner=function() return actor end})
ap.CharAttrComponent=attr
bar,bp=obj('ProgressBar',{Percent=1})
widget,wp=obj('MeterOnHead2_C',{Avatar=actor,HPBar=bar,IsLockShowing=true})
event,ep=obj('CoherentUIGTJSEvent')
hud,hp=obj('NormalHUDBP_C',{IsShowBossStat=true,IsPageReady=true,JsEventObject=event})
component,cp=obj('CoherentUIGTHUD',{GetOwner=function() return hud end})
hp.CoherentUIGTHUD=component
function nativeQuery(values,tag,flag)
 invoke('GetSceneGameCharacterWithTag',wrap(nil),wrap(str(tag or 'Boss')),wrap(array(values)),wrap(flag or false))
end
function add(o) invoke('JSEvent:AddObject',wrap(event),wrap(o)) end
function dispatch(name) invoke('BaseComponent:TriggerJSEvent',wrap(component),wrap(str(name or 'UpdateBossStat')),wrap(event)) end
function overhead(w) invoke('MeterOnHead2_C:Tick',wrap(w or widget)) end
function batch() invoke('NormalHUDBP_C:UpdateBossStat',wrap(hud),wrap(1.0)) end
''')
    for path in missing:
        lua.globals().available[path] = False
    lua.execute(source_text)
    lua.execute('tick()')
    return lua


lua = fixture()
lua.execute('''
local n=0; for _ in pairs(registered) do n=n+1 end; assert(n==5)
assert(findHook('GetSceneGameCharacterWithTag').post, 'query must read outputs after native execution')
assert(not findHook('JSEvent:AddObject').post, 'event input observed before native call')
overhead(); batch(); nativeQuery({actor}); add(attr); dispatch(); tick()
assert(contains('event=DISPATCH') and contains('query_member=true') and contains('overhead_count=1'))
assert(contains('name="Boss Name"') and contains('hp=100 max=100'))
assert(contains('event=HUD') and contains('shown=true ready=true'))
local old=count('event=DISPATCH'); add(attr); dispatch(); assert(count('event=DISPATCH')==old)
event,ep=obj('CoherentUIGTJSEvent'); hp.JsEventObject=event
add(attr); dispatch(); assert(count('event=DISPATCH')==old, 'new event allocation must not spam unchanged state')
atp.HP=75; bp.Percent=.75; wp.IsLockShowing=false
add(attr); dispatch(); assert(contains('hp=75 max=100') and contains('locked=false'))
-- Multiple real source packets: preserve native dispatch order instead of choosing first.
other,op=obj('GenesisCharacter',{DisplayName=str('Second Boss')})
otherAttr,oat=obj('CharAttrComponent',{HP=250,MaxHP=300,GetOwner=function() return other end})
op.CharAttrComponent=otherAttr
nativeQuery({actor,other}); add(otherAttr); dispatch(); add(attr); dispatch()
assert(contains('name="Second Boss"') and contains('count=2'))
-- An unrelated event consumes the prior packet: it cannot establish a later boss link.
add(attr); dispatch('UpdateCharStat'); dispatch(); assert(contains('event=INCOMPLETE'))
-- Unrelated character-attribute events do not read their possibly uninitialised HP.
local spare,sp=obj('GenesisCharacter',{})
local spareAttr=obj('CharAttrComponent',{GetOwner=function() return spare end})
sp.CharAttrComponent=spareAttr
add(spareAttr); dispatch('UpdateCharStat'); assert(not contains('event=ERROR'))
-- A source outside the latest native query is explicitly a negative, not a boss guess.
nativeQuery({}); add(attr); dispatch(); assert(contains('query_member=false'))
hp.IsShowBossStat=false; wall=101; tick(); assert(contains('shown=false ready=true'))
wp.alive=false; hp.alive=false; wall=102; tick()
assert(contains('event=HUD_REMOVED') and contains('event=OVERHEAD_REMOVED'))
-- Expired packets and query snapshots are never promoted into current proof.
hp.alive=true; add(attr); wall=110; dispatch(); assert(contains('reason=no-current-attribute-packet'))
assert(not contains('event=ERROR'))
''')
print('PASS boss probe: exact native output/dispatch, identity, multiple bosses, unlocked HP, negatives, stale packets, teardown; no UObject/parameter writes or return overrides.')

lua = fixture()
lua.execute('''
nativeQuery({actor}); overhead(); add(attr)
hp.CoherentUIGTHUD=obj('CoherentUIGTHUD') -- Fault injection in the MOCK only.
dispatch(); assert(contains('action=observer-disabled') and not contains('event=DISPATCH'))
local before=count('event=ERROR'); dispatch(); assert(count('event=ERROR')==before)
tick(); assert(contains('event=OVERHEAD'), 'failure must stay scoped to dispatch')
''')
print('PASS boss probe: sender mismatch disables only affected observation; no false link or repeated error.')

missing = '/Script/CoherentUIGTPlugin.CoherentUIGTJSEvent:AddObject'
lua = fixture((missing,))
lua.execute('wall=116; tick(); assert(contains("object=waiting")); assert(not contains("event=DISPATCH"))')
lua.execute('wall=1900; tick(); assert(contains("reason=30-minute-limit")); assert(tick()==true)')
print('PASS boss probe: absent hooks remain waiting, bounded lifetime ends observation; offline mocks do not prove UE4SS binding or live JS delivery.')

# Diagnostic 02 deliberately uses the proven outgoing-event path, not the failed
# query adapter or the broad overhead registry. Keep 01's frozen payload intact.
source02 = (Path(__file__).resolve().parents[1] /
            'research/boss-hud/diagnostic-02/Scripts/main.lua').read_text(encoding='utf-8')
lua = fixture(source_text=source02)
lua.execute('''
assert(not findHook('GetSceneGameCharacterWithTag') and not findHook('MeterOnHead2_C:Tick'))
function visibility(value,direct)
 hp.IsShowBossStat=value
 local localEvent=obj('CoherentUIGTJSEvent')
 -- Native visibility uses a LOCAL event; it must not require hud.JsEventObject.
 local parameter=wrap(value); if direct then parameter=value end
 invoke('JSEvent:AddBool',wrap(localEvent),parameter)
 invoke('BaseComponent:TriggerJSEvent',wrap(component),wrap(str('ToggleDisplayBossStat')),wrap(localEvent))
end
hp.IsShowBossStat=false; batch(); tick()
assert(contains('event=HUD_STATE') and contains('shown=false ready=true'))
visibility(true,true); add(attr); dispatch(); tick()
assert(contains('event=SOURCE') and contains('name="Boss Name"'))
-- A bad independent HUD must not stop the healthy HUD or scheduler.
local bad,badProps=obj('NormalHUDBP_C',{IsShowBossStat='invalid',IsPageReady=true})
invoke('NormalHUDBP_C:UpdateBossStat',wrap(bad),wrap(1.0))
wall=101; tick(); assert(contains('event=REJECT'))
-- Player death itself is a user action; simulate only its observed native UI output here.
wall=102; visibility(false,true); tick()
assert(contains('payload_shown=false shown=false ready=true'))
assert(contains('actor_valid=true attr_valid=true owner_matches=true'))
wall=115; tick(); assert(count('event=HEARTBEAT')>=2, 'one bad HUD must not stop heartbeat')
assert(count('event=REJECT')==1, 'same bad HUD must not flood log')
-- Partial teardown: a stale attribute owner reports false instead of killing the poll.
atp.GetOwner=function() return nil end; wall=116; tick()
assert(contains('owner_matches=false'))
hp.alive=false; wall=117; tick(); assert(contains('event=HUD_REMOVED'))
hud,hp=obj('NormalHUDBP_C',{IsShowBossStat=false,IsPageReady=true,JsEventObject=event})
component,cp=obj('CoherentUIGTHUD',{GetOwner=function() return hud end}); hp.CoherentUIGTHUD=component
batch(); wall=118; tick()
assert(contains('shown=false ready=true last_actor=none'))
-- A rejected source sample must not prevent later visibility events.
add(attr); wall=130; dispatch(); local before=count('event=VISIBILITY')
visibility(false); assert(count('event=VISIBILITY')==before+1)
-- Temporary queue failure is reported, then observation can resume.
local enqueue=ExecuteInGameThread
ExecuteInGameThread=function() error('mock unavailable game thread') end
wall=131; tick(); assert(contains('game-thread-queue'))
ExecuteInGameThread=enqueue; wall=145; tick(); assert(count('event=HEARTBEAT')>=3)
wall=1900; tick(); assert(contains('reason=30-minute-limit')); assert(tick()==true)
''')
print('PASS boss probe 02: native show/hide including false/local events, live boss after hide, bad-HUD isolation, stale owner, HUD destruction/new HUD, recovery after rejected samples/queue errors; all callbacks preserve native returns.')
