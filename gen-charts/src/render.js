import { compile } from "vega-lite";
import * as vega from "vega";
import { Resvg } from "@resvg/resvg-js";
import { log } from "./logger.js";

export async function renderSpecToPng(spec, contextLabel = "chart") {
  const t0 = performance.now();

  const tCompile = performance.now();
  const compiled = compile(spec).spec;
  log.debug(
    `[${contextLabel}] Vega-Lite compile: ${(performance.now() - tCompile).toFixed(1)}ms`,
  );

  const tView = performance.now();
  const view = new vega.View(vega.parse(compiled), {
    renderer: "none",
  });
  const svg = await view.toSVG();
  log.debug(
    `[${contextLabel}] Vega SVG: ${(performance.now() - tView).toFixed(1)}ms`,
  );

  const tPng = performance.now();
  const resvg = new Resvg(svg, {
    fitTo: { mode: "original" },
  });
  const rendered = resvg.render();
  const png = rendered.asPng();
  log.debug(
    `[${contextLabel}] resvg PNG: ${(performance.now() - tPng).toFixed(1)}ms (total ${(performance.now() - t0).toFixed(1)}ms, ${png.length} bytes)`,
  );

  return png;
}
