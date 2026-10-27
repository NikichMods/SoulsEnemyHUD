/* SPDX-License-Identifier: MPL-2.0 */
(function () {
    "use strict";
    if (window.SoulsEnemyHUDBoss) return;
    var state = null, text = null, timer = null, title = null, letters = null;
    var titleValue = "", lastDamage = null;
    // Aphes maps Latin characters to decorative glyphs; never translate or replace
    // the native localized name. Unsupported scripts simply omit this decoration.
    var cyrillic = "АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ";
    var latin = ["A", "B", "V", "G", "D", "E", "YO", "ZH", "Z", "I", "Y", "K", "L", "M",
        "N", "O", "P", "R", "S", "T", "U", "F", "KH", "TS", "CH", "SH", "SHCH", "", "Y", "", "E", "YU", "YA"];
    function inscription(value) {
        if (typeof value !== "string") return "";
        return value.toUpperCase().replace(/[А-ЯЁ]/g, function (c) {
            return latin[cyrillic.indexOf(c)];
        }).replace(/[^A-Z0-9 '\-]/g, " ").replace(/\s+/g, " ").replace(/^ | $/g, "");
    }
    function now() { return Date.now() / 1000; }
    function reset() {
        state = null;
        if (timer !== null) { clearTimeout(timer); timer = null; }
        if (text) { text.textContent = ""; text.style.opacity = "0"; }
        titleValue = "";
        if (letters) letters.textContent = "";
        if (title) title.style.visibility = "hidden";
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
        if (!title) {
            title = document.createElement("div");
            title.id = "SoulsEnemyHUDBossName";
            letters = document.createElement("span");
            letters.className = "AphesText";
            title.appendChild(letters);
            bar.appendChild(title);
        }
        return text;
    }
    function layoutName() {
        if (!title || !letters) return;
        var bar = document.getElementById("BossHP");
        if (!bar) return;
        // offsetWidth ignores our transform. The base font/tracking never changes,
        // so repeated fitting cannot feed its own previous result back into itself.
        var available = bar.getBoundingClientRect().width * 0.90 - 1;
        var natural = letters.offsetWidth;
        if (available <= 0 || natural <= 0) { title.style.visibility = "hidden"; return; }
        var scale = Math.min(1, available / natural);
        letters.style.transform = "translate(-50%, -50%) scale(" + scale + ")";
        title.style.visibility = titleValue ? "inherit" : "hidden";
    }
    function layoutDamage() {
        if (!text) return;
        var bar = document.getElementById("BossHP"), name = document.getElementById("BossName");
        if (!bar || !name) return;
        text.style.fontSize = window.getComputedStyle(name).fontSize;
        var room = window.innerWidth - bar.getBoundingClientRect().right - window.innerHeight * 0.0255;
        var damageWidth = text.getBoundingClientRect().width;
        if (room > 0 && damageWidth > room) {
            text.style.fontSize = (parseFloat(text.style.fontSize) * room / damageWidth) + "px";
        }
    }
    function layout() { layoutName(); layoutDamage(); }
    function setName(value) {
        var next = inscription(value);
        if (!element() || next === titleValue) return;
        titleValue = next;
        letters.textContent = next;
        layoutName();
    }
    function render() {
        timer = null;
        if (!state || !element()) return;
        var elapsed = state.hit === null ? Infinity : now() - state.hit;
        var t = Math.max(0, Math.min(1, (elapsed - 1.2) / 0.3));
        var alpha = 1 - t * t * (3 - 2 * t);
        text.textContent = state.sum > 0 ? String(Math.floor(state.sum + 0.5)) : "";
        if (lastDamage !== text.textContent) { lastDamage = text.textContent; layoutDamage(); }
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
        setName(name);
        if (timer !== null) { clearTimeout(timer); timer = null; }
        render();
    }
    CoherentHelper.Bind("UpdateBossStat", update);
    CoherentHelper.Bind("ToggleDisplayBossStat", reset);
    window.addEventListener("resize", layout);
    if (document.fonts && document.fonts.ready) document.fonts.ready.then(layout);
    if (document.fonts && document.fonts.addEventListener) document.fonts.addEventListener("loadingdone", layout);
    window.SoulsEnemyHUDBoss = { reset: reset }; // Page lifetime owns all state.
}());
