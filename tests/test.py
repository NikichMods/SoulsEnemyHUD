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
lua=LuaRuntime(unpack_returned_tuples=True)
lua.globals().source=(root/'policy.lua').read_text()
lua.execute('''
package.preload.policy=function() return assert(load(source))() end
objects={}; now=0; wrongOwner=false; failProjection=false; serial=0
function obj(class)
 serial=serial+1
 local o={class=class,addr=serial,alpha=1,visibility=0}
 o.IsValid=function() return true end
 o.GetAddress=function(self) return self.addr end
 o.GetFullName=function(self) return self.class..self.addr end
 o.GetClass=function(self)
   return {IsValid=function() return true end,GetFName=function() return {ToString=function() return self.class end} end,
    GetSuperStruct=function() return nil end,ForEachProperty=function() end}
 end
 o.SetRenderOpacity=function(self,a) self.alpha=a; self.RenderOpacity=a end
 o.SetVisibility=function(self,v) self.visibility=v end
 o.GetVisibility=function(self) return self.visibility end
 o.RemoveFromParent=function(self) self.removed=true end
 return o
end
function slot()
 local o=obj('CanvasPanelSlot'); o.p={X=-100,Y=90}; o.size={X=200,Y=7}; o.z=0
 o.GetPosition=function(self) return self.p end; o.SetPosition=function(self,p) self.p=p end
 o.GetSize=function(self) return self.size end; o.SetSize=function(self,p) self.size=p end
 o.GetZOrder=function(self) return self.z end; o.SetZOrder=function(self,z) self.z=z end
 o.SetAnchors=function(self,a) self.anchors=a end
 return o
end
canvas=obj('CanvasPanel')
canvas.AddChildToCanvas=function(self,child) child.Slot=slot(); return child.Slot end
avatar=obj('GenesisCharacter'); avatar.IsPlayerControlled=function() return wrongOwner end
avatar.K2_GetActorLocation=function() return {X=10,Y=20,Z=30} end
hp=obj('ProgressBar'); hp.Percent=1; hp.FillColorAndOpacity={R=.6,G=.04,B=.04,A=1}; hp.Slot=slot()
hp.GetParent=function() return canvas end
hp.SetFillColorAndOpacity=function(self,c) self.FillColorAndOpacity=c end
pc=obj('PlayerController')
pc.ProjectWorldLocationToScreen=function(self,world,screen,relative)
 if failProjection then error('Mock projection failure') end
 assert(world.Z==30 and relative==false); screen.X=400; screen.Y=500; return true
end
widget=obj('MeterOnHead2_C'); widget.Avatar=avatar; widget.HPBar=hp; widget.LockIcon=obj('Image')
function array(values)
 return {ForEach=function(self,fn) for i,v in ipairs(values) do fn(i,{get=function() return v end}) end end}
end
widget.CurVals=array({400,100}); widget.MaxVals=array({400,100}); widget.CurColorClasses=array({'red','yellow'})
widget.DamageTextCanvas=obj('CanvasPanel'); widget.DamageTextCanvas.RenderOpacity=.8
widget.DamageText=obj('TextBlock'); widget.DamageText.Font={Size=24,OutlineSettings={OutlineSize=2}}
widget.WidgetTree=obj('WidgetTree'); widget.GetOwningPlayer=function() return pc end
slate=obj('SlateBlueprintLibrary')
slate.ScreenToWidgetLocal=function(self,context,geometry,screen,localpos,window)
 assert(context==widget and geometry=='current geometry' and screen.X==400)
 localpos.X=123; localpos.Y=234
end
function StaticFindObject(path) if path:find('ExtendedCoherent') then return nil end; if path:find('Default__Slate') then return slate end return obj(path) end
function FName(name) return name end
function LoadAsset(path) if path:find('EBGaramond') then return obj('Font') end; assert(path:find('WhiteSquareTexture')); return obj('Texture2D') end
function StaticConstructObject(cls,outer)
 assert(outer==widget.WidgetTree)
 local o=obj(cls.class); table.insert(objects,o)
 o.WidgetStyle={BackgroundImage={TintColor={}}}; o.Font={Size=24,OutlineSettings={OutlineSize=0}}
 o.SetBrushFromTexture=function(self,texture,match) assert(texture.class=='Texture2D') end
 o.SetColorAndOpacity=function(self,c) self.tint=c end; o.SetFillColorAndOpacity=function() end
 o.SetPercent=function(self,p) self.Percent=p end
 o.SetText=function(self,text) self.text=text end; o.SetFont=function() end
 o.SetJustification=function() end; o.SetShadowOffset=function(self,v) self.shadowOffset=v end; o.SetShadowColorAndOpacity=function(self,v) self.shadowColor=v end
 return o
end
package.preload.UEHelpers=function() return {
 GetKismetTextLibrary=function() return {Conv_StringToText=function(self,text) return text end} end,
 GetGameplayStatics=function() return {GetTimeSeconds=function(self,context) assert(context==widget); return now end} end
} end
function LoopAsync(ms,fn) poll=fn end
function ExecuteInGameThread(fn) fn() end
function RegisterHook(path,fn) if path:find('MeterOnHead2') then hook=fn else floatingHook=fn end end
floatingRoot=obj('CanvasPanel'); floatingRoot.RenderOpacity=1
floating=obj('HudUmg_C'); floating.WidgetTree={RootWidget=floatingRoot}; floating.DamageDigits0=obj('TextBlock')
floating.DamageDigits0.GetParent=function() return floatingRoot end
function FindAllOf(class) assert(class=='HudUmg_C'); return {floating} end

function frame(t,lock,h) now=t; widget.IsLockShowing=lock; hp.Percent=h; widget.CurVals=array({400*h,100}); hook({get=function() return widget end},{get=function() return 'current geometry' end}) end
''')
lua.execute('package.preload.boss=function() return {isBoss=function() return bossMode==true end,poll=function() end} end')
lua.execute((root/'main.lua').read_text(encoding='utf-8'))
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
