// SPDX-License-Identifier: MPL-2.0
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const source = fs.readFileSync(process.argv[2], 'utf8');
let clock = 0, next = 0, callbacks = {}, timers = new Map();
const bar = {appendChild(node) { this.child = node; }};
const context = {
    window: null, Date: {now: () => clock * 1000}, console,
    document: {getElementById: id => id === 'BossHP' ? bar : id === 'BossName' ? {} : null,
        createElement: () => ({style: {}, textContent: ''})},
    getComputedStyle: () => ({fontSize: '24px'}), addEventListener() {},
    setTimeout(fn) { timers.set(++next, fn); return next; }, clearTimeout(id) {timers.delete(id);},
    GetUOVal(key) {return this[key];},
    CoherentHelper: {Bind(name, fn) { (callbacks[name] ||= []).push(fn); }}
};
context.window = context;
vm.createContext(context);
// A native listener stays in place; adding ours must not replace it.
let nativeCalls = 0;
context.CoherentHelper.Bind('UpdateBossStat', () => nativeCalls++);
vm.runInContext(source, context);
function sample(time, hp, max = 100, id = 'SEH1:1:2:3') {
    clock = time;
    callbacks.UpdateBossStat.forEach(fn => fn(0, 'Boss', {HP: hp, MaxHP: max}, id));
}
function advance(time) {clock = time; const pending = [...timers.values()]; timers.clear(); pending.forEach(fn => fn());}
sample(0, 100); sample(1, 80); assert.equal(bar.child.textContent, '20');
sample(1.5, 50); assert.equal(bar.child.textContent, '50');
sample(1.6, 70); assert.equal(bar.child.textContent, '50'); // healing
sample(3, 60); assert.equal(bar.child.textContent, '10'); // expired combo
advance(4.35); assert.ok(Math.abs(Number(bar.child.style.opacity) - .5) < 1e-8);
advance(4.5); assert.equal(bar.child.style.opacity, '0');
assert.equal(bar.child.style.fontSize, '24px');
sample(5, 120, 200); assert.equal(bar.child.textContent, ''); // MaxHP change
sample(6, 100, 200); assert.equal(bar.child.textContent, '20');
sample(6.1, 90, 200, 'SEH1:1:4:5'); assert.equal(bar.child.textContent, ''); // real source changes
sample(6.2, 80, 200, 'SEH1:1:4:5'); assert.equal(bar.child.textContent, '10');
callbacks.ToggleDisplayBossStat.forEach(fn => fn(false)); assert.equal(bar.child.style.opacity, '0');
sample(7, 80, 200, undefined); // default parameter supplies valid bridge for this helper
callbacks.UpdateBossStat.forEach(fn => fn(0, 'Boss', {HP: 50, MaxHP: 200}));
assert.equal(bar.child.style.opacity, '0'); // missing bridge identity fails closed
sample(8, 80); sample(8.1, 79.4); sample(8.2, 78.8); assert.equal(bar.child.textContent, '1');
sample(8.3, NaN); assert.equal(bar.child.style.opacity, '0');
assert.ok(nativeCalls > 10);
const before = callbacks.UpdateBossStat.length;
vm.runInContext(source, context); assert.equal(callbacks.UpdateBossStat.length, before);
console.log('PASS boss UI: real positive losses, float accumulation/rounding, healing, combo/MaxHP/source reset, timed fade, native listener preservation, font size and invalid-bridge fallback.');
