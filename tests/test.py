from pathlib import Path
import sys

from lupa import LuaRuntime
root=Path(__file__).resolve().parents[1]/"Scripts"
lua=LuaRuntime(unpack_returned_tuples=True)
lua.execute('assert(load(...))',(root/'main.lua').read_text(encoding='utf-8'))
policy=lua.execute((root/'policy.lua').read_text())
cfg=lua.table_from(dict(trailHold=.45,trailFade=.5,showAfterHit=3.,fadeIn=.12,fadeOut=.3,width=90,minWidth=68,maxWidth=134,referenceHP=252,widthExponent=.25,comboWindow=1.2,damageHold=1.2,damageFade=.3))
s=policy.new()
def step(t,hp,lock=False): return policy.step(s,t,hp,lock,cfg)
assert step(0,1).alpha==0
assert step(1,1,True).alpha==0
assert step(1.12,1,True).alpha==1
assert step(2,.8,True).tail==1
r=step(2.7,.8,True); assert abs(r.tail-.9)<1e-7
assert step(2.95,.8,True).tail==.8
assert step(3,.5,True).tail==.8 # Consecutive hit holds the previous health.
assert step(4,.5,False).alpha==1 # Recent damage keeps a non-target visible.
assert step(6,.5).alpha==1
assert step(6.3,.5).alpha==0
assert step(6.4,.9).tail==.9 # Healing is immediate, never shown as damage.
assert step(0,.9).alpha==0 # Map travel/time reset.
assert step(1,float('nan')) is None
assert policy.width(252,cfg)==90
assert policy.width(84,cfg)==68
assert policy.width(588,cfg)==112
assert policy.width(10**12,cfg)==134
assert policy.width(None,cfg)==90
d=policy.new()
assert policy.damage(d,0,252,252,cfg).sum==0
assert policy.damage(d,1,181,252,cfg).sum==71
assert policy.damage(d,1.5,110,252,cfg).sum==142
assert policy.damage(d,2,130,252,cfg).sum==142 # Healing adds no damage.
assert policy.damage(d,3,59,252,cfg).sum==71 # New series after a pause.
assert policy.damage(d,4.6,59,252,cfg).alpha==0
assert policy.damage(d,5,100,504,cfg).sum==0 # Max-HP buff resets the baseline.
assert policy.damage(d,0,100,504,cfg).sum==0
print('PASS compact: bounded widths, real integer damage, series accumulation/reset, healing and max-HP changes.')
print('PASS policy: hidden idle, lock, hit trail, consecutive hits, timeout/fade, healing, travel, invalid HP.')

# Exercise the actual adapter with strict engine-object mocks, including the
# projected-dot position and recovery if a required function fails.
from support.adapter_fixture import fixture
lua, _ = fixture()
lua.execute('''
poll(); assert(floatingRoot.alpha==0); floatingRoot.RenderOpacity=1; floatingHook({get=function() return floating end}); assert(floatingRoot.alpha==0); wrongOwner=true; frame(0,false,1); assert(#objects==0)
wrongOwner=false; frame(1,false,1); assert(#objects==4); assert(hp.alpha==0); assert(objects[3].Font.FontObject.class=='Font' and objects[3].Font.TypefaceFontName=='Default' and objects[3].Font.Size==12 and objects[3].Font.OutlineSettings.OutlineSize==1 and objects[3].shadowColor.A==0)
frame(2,true,1); frame(2.2,true,1); assert(hp.alpha==1 and widget.LockIcon.alpha==0)
assert(objects[4].alpha==1 and objects[4].Slot.p.X==116 and objects[4].Slot.p.Y==225)
frame(3,true,.7); assert(objects[2].Percent==1); assert(objects[3].text=='120' and objects[3].alpha==1); assert(widget.DamageTextCanvas.alpha==0); assert(hp.Slot.size.X==102 and hp.Slot.size.Y==7)
assert(hp.FillColorAndOpacity.R==.34 and hp.FillColorAndOpacity.G==.0385); assert(widget.DamageText.alpha==0)
assert(objects[1].Slot.p.X+1==hp.Slot.p.X)
assert(objects[1].Slot.size.X-objects[2].Slot.size.X==2)
frame(4,false,.7); assert(objects[4].alpha==0 and hp.alpha==1)
frame(6,false,.7); frame(6.4,false,.7); assert(hp.alpha==0)
bossMode=true; frame(6.5,true,.7)
assert(hp.alpha==0 and objects[1].alpha==0 and objects[2].alpha==0 and objects[3].alpha==0)
assert(objects[4].alpha==1 and widget.DamageTextCanvas.alpha==0)
bossMode=false; failProjection=true; frame(7,true,.7)
assert(hp.alpha==1 and hp.Slot.size.X==200 and widget.LockIcon.alpha==1)
for _,o in ipairs(objects) do assert(o.removed) end
''')
print('PASS adapter: player excluded; per-enemy HP; centre projection; independent dot; native restoration on failure.')
