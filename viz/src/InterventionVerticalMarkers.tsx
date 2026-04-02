import type { GroupedIntervention } from "./parseParameterPreamble";

type AxisScale = (v: unknown) => number;

type XAxisEntry = {
  scale: AxisScale & { bandwidth?: () => number };
};

export type InterventionChartProps = {
  xAxisMap?: Record<string, XAxisEntry>;
  offset?: { top: number; bottom: number; left: number; right: number };
  width?: number;
  height?: number;
};

/** Narrow Recharts `Customized` render props for TypeScript. */
export function interventionChartGeometry(
  props: unknown,
): InterventionChartProps {
  const o =
    typeof props === "object" && props !== null
      ? (props as Record<string, unknown>)
      : {};
  return {
    xAxisMap: o.xAxisMap as InterventionChartProps["xAxisMap"],
    offset: o.offset as InterventionChartProps["offset"],
    width: typeof o.width === "number" ? o.width : undefined,
    height: typeof o.height === "number" ? o.height : undefined,
  };
}

function xToPixel(scale: AxisScale, year: number): number | null {
  const s = scale as AxisScale & { bandwidth?: () => number };
  const bw =
    typeof s.bandwidth === "function" ? s.bandwidth() : 0;
  const pad = Number.isFinite(bw) && bw > 0 ? bw / 2 : 0;
  for (const v of [year, String(year)]) {
    const x = scale(v);
    if (typeof x === "number" && Number.isFinite(x)) return x + pad;
  }
  return null;
}

/** Dashed vertical guides; SVG `<title>` elements provide native hover tooltips. */
export function InterventionVerticalMarkers({
  grouped,
  xAxisMap,
  offset,
  width,
  height,
}: { grouped: GroupedIntervention[] } & InterventionChartProps) {
  const xAxis = xAxisMap?.[0];
  if (!xAxis || grouped.length === 0 || width == null || height == null) {
    return null;
  }

  const scale = xAxis.scale;
  const top = offset?.top ?? 0;
  const bottom = offset?.bottom ?? 0;
  const y0 = top;
  const y1 = height - bottom;

  return (
    <g className="recharts-intervention-markers" aria-hidden>
      {grouped.map((g) => {
        const x = xToPixel(scale, g.year);
        if (x == null) return null;
        return (
          <g key={g.year}>
            <line
              x1={x}
              x2={x}
              y1={y0}
              y2={y1}
              stroke="transparent"
              strokeWidth={16}
              pointerEvents="stroke"
            >
              <title>{g.tooltip}</title>
            </line>
            <line
              x1={x}
              x2={x}
              y1={y0}
              y2={y1}
              stroke="#94a3b8"
              strokeDasharray="4 6"
              strokeOpacity={0.4}
              strokeWidth={1}
              pointerEvents="none"
            />
          </g>
        );
      })}
    </g>
  );
}
