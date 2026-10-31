# SPDX-License-Identifier: MPL-2.0
from pathlib import Path
from lupa import LuaRuntime
root=Path(__file__).resolve().parents[2]/'Scripts'

def fixture(options=None):
    lua=LuaRuntime(unpack_returned_tuples=True)
    lua.globals().opts=lua.table_from(options or {})
    logs=[]
    lua.globals().print=lambda message: logs.append(str(message))
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
    function StaticFindObject(path) assert(gameThread and not cancelMarked); if opts.missingObjects then return nil end; if path:find('ExtendedCoherent') then return nil end; if path:find('Default__Slate') then return slate end return obj(path) end
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
    function LoopAsync() error('async API forbidden') end
    function ExecuteInGameThread() error('secondary dispatch forbidden') end
    local timerFn, active, executing, due = nil, false, false, 1000
    registrations, cancelCalls, setupCalls = 0, 0, 0
    hookCounts = {}; order = {}; gameThread = false; cancelMarked = false
    function LoopInGameThreadWithDelay(ms,fn)
     assert(ms==1000); registrations=registrations+1
     if opts.registrationError then error('injected timer registration error') end
     timerFn=fn; active=true
     if opts.invalidHandle then return -1 end
     return 17
    end
    function CancelDelayedAction(handle)
     assert(gameThread and handle==17); cancelCalls=cancelCalls+1; cancelMarked=true
     if opts.cancelError then error('injected cancel error') end
     if opts.cancelFalse then return false end
     active=false; return true
    end
    function poll()
     if not active or executing then return end
     executing=true; gameThread=true
     local ok,err=pcall(timerFn)
     gameThread=false; executing=false
     assert(ok,err)
    end
    function advance(ms)
     if active and ms>=due then poll(); due=ms+1000 end
    end
    function RegisterHook(path,fn)
     assert(gameThread and not cancelMarked)
     table.insert(order,path:find('MeterOnHead2') and 'overhead' or 'floating')
     hookCounts[path]=(hookCounts[path] or 0)+1
     if path:find('MeterOnHead2') then hook=fn else floatingHook=fn end
     if opts.invalidHook then return nil end
     return 1,2
    end
    floatingRoot=obj('CanvasPanel'); floatingRoot.RenderOpacity=1
    floating=obj('HudUmg_C'); floating.WidgetTree={RootWidget=floatingRoot}; floating.DamageDigits0=obj('TextBlock')
    floating.DamageDigits0.GetParent=function() return floatingRoot end
    function FindAllOf(class) assert(gameThread and not cancelMarked); table.insert(order,'scan'); assert(class=='HudUmg_C'); if opts.scanFailure then error('injected scan error') end; if opts.missingObjects then return nil end; return {floating} end
    
    function frame(t,lock,h) local previousThread=gameThread; gameThread=true; now=t; widget.IsLockShowing=lock; hp.Percent=h; widget.CurVals=array({400*h,100}); hook({get=function() return widget end},{get=function() return 'current geometry' end}); gameThread=previousThread end
    ''')
    lua.execute('package.preload.boss=function() return {isBoss=function() return bossMode==true end,poll=function() table.insert(order,"boss"); setupCalls=setupCalls+1; if opts.pollFailure then error("injected poll failure") end end,stop=function() bossStopped=true end} end')
    lua.execute('if opts.missingApi then LoopInGameThreadWithDelay=nil end; if opts.missingCancel then CancelDelayedAction=nil end')
    lua.execute((root/'main.lua').read_text(encoding='utf-8'))
    return lua, logs
