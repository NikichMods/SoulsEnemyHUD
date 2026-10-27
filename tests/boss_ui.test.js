// SPDX-License-Identifier: MPL-2.0
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const source = fs.readFileSync(process.argv[2], 'utf8');
let clock = 0, next = 0, callbacks = {}, timers = new Map();
const nodes = {};
function node() { return {style: {}, textContent: '', appendChild(child) {
    this.child = child; if (child.id) nodes[child.id] = child;
}, getBoundingClientRect() { return {width: this.textContent.length * parseFloat(this.style.fontSize || '24') * .8}; }}; }
const bar = node();
bar.getBoundingClientRect = () => ({width: 925.56, right: 1422.78});
const nativeName = {textContent: 'Native localized name'};
const context = {
    window: null, Date: {now: () => clock * 1000}, console,
    document: {getElementById: id => id === 'BossHP' ? bar : id === 'BossName' ? nativeName : nodes[id],
        createElement: node}, innerWidth: 1920, innerHeight: 1080,
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
    callbacks.UpdateBossStat.forEach(fn => fn(0, 'Пожиратель Ненасытный', {HP: hp, MaxHP: max}, id));
}
function advance(time) {clock = time; const pending = [...timers.values()]; timers.clear(); pending.forEach(fn => fn());}
sample(0, 100);
const damage = nodes.SoulsEnemyHUDBossDamage;
const title = nodes.SoulsEnemyHUDBossName;
assert.equal(title.child.textContent, 'POZHIRATEL NENASYTNYY');
assert.equal(nativeName.textContent, 'Native localized name');
sample(1, 80); assert.equal(damage.textContent, '20');
sample(1.5, 50); assert.equal(damage.textContent, '50');
sample(1.6, 70); assert.equal(damage.textContent, '50'); // healing
sample(3, 60); assert.equal(damage.textContent, '10'); // expired combo
advance(4.35); assert.ok(Math.abs(Number(damage.style.opacity) - .5) < 1e-8);
advance(4.5); assert.equal(damage.style.opacity, '0');
assert.equal(damage.style.fontSize, '24px');
sample(5, 120, 200); assert.equal(damage.textContent, ''); // MaxHP change
sample(6, 100, 200); assert.equal(damage.textContent, '20');
sample(6.1, 90, 200, 'SEH1:1:4:5'); assert.equal(damage.textContent, ''); // real source changes
sample(6.2, 80, 200, 'SEH1:1:4:5'); assert.equal(damage.textContent, '10');
callbacks.ToggleDisplayBossStat.forEach(fn => fn(false)); assert.equal(damage.style.opacity, '0');
assert.equal(title.child.textContent, ''); assert.equal(title.style.visibility, 'hidden');
sample(7, 80, 200, undefined); // default parameter supplies valid bridge for this helper
callbacks.UpdateBossStat.forEach(fn => fn(0, 'Boss', {HP: 50, MaxHP: 200}));
assert.equal(damage.style.opacity, '0'); // missing bridge identity fails closed
assert.equal(title.child.textContent, '');
sample(8, 80); sample(8.1, 79.4); sample(8.2, 78.8); assert.equal(damage.textContent, '1');
sample(8.3, NaN); assert.equal(damage.style.opacity, '0');
callbacks.UpdateBossStat.forEach(fn => fn(0, 'Baraad', {HP: 100, MaxHP: 100}, 'SEH1:1:2:3'));
assert.equal(title.child.textContent, 'BARAAD');
callbacks.UpdateBossStat.forEach(fn => fn(0, '王', {HP: 100, MaxHP: 100}, 'SEH1:1:2:3'));
assert.equal(title.style.visibility, 'hidden'); // never fabricate an untranslated name
assert.ok(nativeCalls > 10);
const before = callbacks.UpdateBossStat.length;
vm.runInContext(source, context); assert.equal(callbacks.UpdateBossStat.length, before);
console.log('PASS boss UI: real positive losses, float accumulation/rounding, healing, combo/MaxHP/source reset, timed fade, native listener preservation, font size and invalid-bridge fallback.');
