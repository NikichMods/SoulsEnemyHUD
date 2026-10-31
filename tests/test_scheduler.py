# SPDX-License-Identifier: MPL-2.0
from pathlib import Path
from support.adapter_fixture import fixture

source=(Path(__file__).resolve().parents[1]/'Scripts/main.lua').read_text()
assert 'LoopAsync' not in source and 'ExecuteInGameThread(' not in source and 'pending' not in source
lua,logs=fixture()
lua.execute("""
assert(registrations==1 and cancelCalls==0 and setupCalls==0)
advance(999); assert(setupCalls==0)
advance(1000); assert(setupCalls==1)
assert(table.concat(order,",")=="boss,floating,scan,overhead")
advance(9000); assert(setupCalls==2) -- no catch-up batch
advance(9001); assert(setupCalls==2)
advance(10000); assert(setupCalls==3)
local count=0; for _,n in pairs(hookCounts) do assert(n==1); count=count+1 end; assert(count==2)
-- A nested engine operation cannot deliver setup again while its timer is executing.
local find=FindAllOf
FindAllOf=function(class) local before=setupCalls; poll(); assert(setupCalls==before); frame(1,true,1); assert(gameThread and #objects==4); return find(class) end
poll(); assert(setupCalls==4 and registrations==1)
""")

# Missing game objects are a wait state, not a reason to create more timers/hooks.
lua,_=fixture({'missingObjects':True})
lua.execute("poll(); poll(); assert(setupCalls==2 and next(hookCounts)==nil and cancelCalls==0); opts.missingObjects=false; poll(); local n=0; for _,v in pairs(hookCounts) do assert(v==1); n=n+1 end; assert(n==2 and registrations==1)")

for options in [{}, {'cancelError':True}, {'cancelFalse':True}, {'restoreFailure':True}]:
    lua,logs=fixture(options)
    lua.execute("""
    floatingRoot.RenderOpacity=.6
    poll(); frame(1,true,1); assert(#objects==4 and floatingRoot.alpha==0)
    if opts.restoreFailure then hp.Slot.SetPosition=function() error('injected cleanup failure') end end
    opts.pollFailure=true
    poll(); assert(bossStopped and cancelCalls==1 and floatingRoot.alpha==.6)
    for _,o in ipairs(objects) do assert(o.removed) end
    local before=setupCalls
    poll(); poll(); assert(setupCalls==before and cancelCalls==1)
    local bad={get=function() error('disabled callback must not unwrap parameters') end}
    hook(bad,bad); floatingHook(bad)
    """)
    assert sum('Setup stopped' in x for x in logs)==1
    assert sum('Scheduler cancellation failed' in x for x in logs)==bool(options.get('cancelError') or options.get('cancelFalse'))

for options in [{'missingApi':True},{'missingCancel':True},{'registrationError':True},{'invalidHandle':True},{'invalidHook':True},{'scanFailure':True}]:
    lua,logs=fixture(options)
    lua.execute('poll(); poll(); assert(bossStopped); local before=setupCalls; poll(); assert(setupCalls==before and cancelCalls<=1 and registrations<=1)')
    assert any('Scheduler' in x or 'Setup stopped' in x for x in logs)
print('PASS scheduler: one nominal 1000ms timer, source contract sequential/no catch-up/reentry; hooks register once; missing objects wait; errors disable owned callbacks and restore before single cancellation, including failed cancel.')
print('LIMIT: contract models do not prove native thread identity, actual cadence, GC/registry/restart safety or absence of crashes.')
