// Tea Rush web spike — HTML-shell side (ADR-0001 / ADR-0005 shell duties + measurement).
// Loaded from <head> via the export preset's html/head_include, before the engine loader.
(function () {
  "use strict";
  var spike = (window.spike = {
    lastDown: 0,          // performance.now() of the last pointerdown/touchstart
    downs: 0,             // physical presses seen by the browser
    onVis: null,          // set by GDScript (JavaScriptBridge.create_callback)
    visLog: [],           // [{visible, type, t}] even before the engine is up
    mem: null,            // WebAssembly.Memory of the engine, captured below
    gl: null,             // WebGL2 probe result
  });

  // --- WebGL2 probe on a throwaway canvas (ADR-0001 Implementation Guidelines) ---
  try {
    var c = document.createElement("canvas");
    var gl = c.getContext("webgl2");
    if (gl) {
      var dbg = gl.getExtension("WEBGL_debug_renderer_info");
      spike.gl = {
        webgl2: true,
        vendor: dbg ? gl.getParameter(dbg.UNMASKED_VENDOR_WEBGL) : gl.getParameter(gl.VENDOR),
        renderer: dbg ? gl.getParameter(dbg.UNMASKED_RENDERER_WEBGL) : gl.getParameter(gl.RENDERER),
        max_texture: gl.getParameter(gl.MAX_TEXTURE_SIZE),
      };
      var lose = gl.getExtension("WEBGL_lose_context");
      if (lose) lose.loseContext();
    } else {
      spike.gl = { webgl2: false };
    }
  } catch (e) {
    spike.gl = { webgl2: false, error: String(e) };
  }

  // --- Input timing: browser-side timestamp of each physical press ---
  function down(e) { spike.lastDown = performance.now(); spike.downs += 1; }
  document.addEventListener("pointerdown", down, { capture: true, passive: true });

  // --- Visibility (ADR-0001): visibilitychange + pagehide forwarded to GDScript ---
  function vis(type) {
    var visible = type === "pagehide" ? false : document.visibilityState === "visible";
    var entry = { visible: visible, type: type, t: performance.now() };
    spike.visLog.push(entry);
    if (spike.onVis) {
      try { spike.onVis(visible, type, entry.t); } catch (e) { entry.error = String(e); }
    }
  }
  document.addEventListener("visibilitychange", function () { vis("visibilitychange"); });
  window.addEventListener("pagehide", function () { vis("pagehide"); });
  spike.isVisible = function () { return document.visibilityState === "visible"; };

  // --- ADR-0005 save helper (verbatim contract) ---
  window.teaRushSave = {
    available: (function () { try { localStorage.setItem("__t", "1"); localStorage.removeItem("__t"); return true; } catch (e) { return false; } })(),
    read: function () { try { return localStorage.getItem("tea_rush.save"); } catch (e) { return null; } },
    write: function (s) { try { localStorage.setItem("tea_rush.save", s); return true; } catch (e) { return false; } },
  };

  // --- Capture the engine's wasm memory to read the real heap size (ADR-0007 §6) ---
  function capture(result, imports) {
    try {
      var inst = result && (result.instance || result);
      var found = null;
      if (inst && inst.exports) {
        for (var k in inst.exports) if (inst.exports[k] instanceof WebAssembly.Memory) { found = inst.exports[k]; break; }
      }
      if (!found && imports) {
        for (var ns in imports) for (var n in imports[ns]) if (imports[ns][n] instanceof WebAssembly.Memory) { found = imports[ns][n]; break; }
      }
      if (found) spike.mem = found;
    } catch (e) {}
    return result;
  }
  var oi = WebAssembly.instantiate, ois = WebAssembly.instantiateStreaming;
  WebAssembly.instantiate = function (src, imports) {
    return oi.apply(this, arguments).then(function (r) { return capture(r, imports); });
  };
  if (ois) {
    WebAssembly.instantiateStreaming = function (src, imports) {
      return ois.apply(this, arguments).then(function (r) { return capture(r, imports); });
    };
  }
  spike.heapBytes = function () { return spike.mem ? spike.mem.buffer.byteLength : -1; };

  // --- Download sizes and timings of the engine files (ADR-0007 §4–5) ---
  spike.resources = function () {
    var out = [];
    performance.getEntriesByType("resource").forEach(function (r) {
      if (/\.(wasm|pck|js)(\?|$)/.test(r.name)) {
        out.push({ name: r.name.split("/").pop(), transfer: r.transferSize, encoded: r.encodedBodySize,
                   decoded: r.decodedBodySize, start: Math.round(r.startTime), end: Math.round(r.responseEnd) });
      }
    });
    var nav = performance.getEntriesByType("navigation")[0];
    return JSON.stringify({ files: out, nav_type: nav ? nav.type : "", dom_loaded: nav ? Math.round(nav.domContentLoadedEventEnd) : -1 });
  };

  spike.device = function () {
    return JSON.stringify({
      ua: navigator.userAgent, dpr: window.devicePixelRatio, inner: [window.innerWidth, window.innerHeight],
      screen: [screen.width, screen.height], mem_gb: navigator.deviceMemory || -1,
      cores: navigator.hardwareConcurrency || -1, gl: spike.gl,
      reduced_motion: window.matchMedia && window.matchMedia("(prefers-reduced-motion: reduce)").matches,
      save_available: window.teaRushSave.available,
      audio_ctx: typeof AudioContext !== "undefined",
    });
  };

  // --- Results go back to the dev machine (prototypes/web-spike/server.py) ---
  spike.report = function (json) {
    try {
      fetch("/report", { method: "POST", body: json, keepalive: true, headers: { "Content-Type": "application/json" } });
      return true;
    } catch (e) { return false; }
  };
})();
