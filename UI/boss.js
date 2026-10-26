/* SPDX-License-Identifier: MPL-2.0 */
(function () {
    "use strict";
    if (window.SoulsEnemyHUDBoss) return;
    var state = null, text = null, timer = null;
    function now() { return Date.now() / 1000; }
    function reset() {
        state = null;
        if (timer !== null) { clearTimeout(timer); timer = null; }
        if (text) { text.textContent = ""; text.style.opacity = "0"; }
    }
    function element() {
        var bar = document.getElementById("BossHP");
        var name = document.getElementById("BossName");
        if (!bar || !name) return null;
        if (!text) {
            text = document.createElement("div");
            text.id = "SoulsEnemyHUDBossDamage";
            bar.appendChild(text);
        }
        text.style.fontSize = window.getComputedStyle(name).fontSize;
        return text;
    }
    function render() {
        timer = null;
        if (!state || !element()) return;
        var elapsed = state.hit === null ? Infinity : now() - state.hit;
        var t = Math.max(0, Math.min(1, (elapsed - 1.2) / 0.3));
        var alpha = 1 - t * t * (3 - 2 * t);
        text.textContent = state.sum > 0 ? String(Math.floor(state.sum + 0.5)) : "";
        text.style.opacity = String(state.sum > 0 ? alpha : 0);
        if (state.sum > 0 && alpha > 0) timer = setTimeout(render, 16);
    }
    function update(index, name, attributes, identity) {
        if (typeof identity !== "string" || !/^SEH1:\d+:\d+:\d+$/.test(identity) || !attributes) {
            reset(); return;
        }
        var hp = GetUOVal.call(attributes, "HP");
        var maximum = GetUOVal.call(attributes, "MaxHP");
        if (typeof hp !== "number" || typeof maximum !== "number" || !isFinite(hp) ||
            !isFinite(maximum) || maximum <= 0) { reset(); return; }
        hp = Math.max(0, Math.min(maximum, hp));
        var time = now();
        if (!state || state.id !== identity || state.maximum !== maximum || time < state.time) {
            reset();
            state = { id: identity, hp: hp, maximum: maximum, time: time, sum: 0, hit: null };
        } else if (hp < state.hp) {
            if (state.hit === null || time - state.hit > 1.2) state.sum = 0;
            state.sum += state.hp - hp;
            state.hit = time;
        }
        state.hp = hp; state.time = time;
        if (timer !== null) { clearTimeout(timer); timer = null; }
        render();
    }
    CoherentHelper.Bind("UpdateBossStat", update);
    CoherentHelper.Bind("ToggleDisplayBossStat", reset);
    window.addEventListener("resize", function () { if (text) element(); });
    window.SoulsEnemyHUDBoss = { reset: reset }; // Page lifetime owns all state.
}());
