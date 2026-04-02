const BASE_CONFIG = {
  background: "#0b1220",
  axis: {
    labelColor: "#94a3b8",
    titleColor: "#cbd5e1",
    gridColor: "#334155",
    domainColor: "#64748b",
    tickColor: "#64748b",
  },
  legend: {
    labelColor: "#cbd5e1",
    titleColor: "#e2e8f0",
  },
  title: {
    color: "#e2e8f0",
    subtitleColor: "#94a3b8",
    anchor: "start",
    fontSize: 14,
  },
  view: {
    stroke: "#334155",
  },
};

function hexToRgb(h) {
  const n = h.replace("#", "");
  const r = Number.parseInt(n.slice(0, 2), 16);
  const g = Number.parseInt(n.slice(2, 4), 16);
  const b = Number.parseInt(n.slice(4, 6), 16);
  return { r, g, b };
}

function rgbToHex(r, g, b) {
  const hr = Math.round(r).toString(16).padStart(2, "0");
  const hg = Math.round(g).toString(16).padStart(2, "0");
  const hb = Math.round(b).toString(16).padStart(2, "0");
  return `#${hr}${hg}${hb}`;
}

function blendHex(a, b, t) {
  const c1 = hexToRgb(a);
  const c2 = hexToRgb(b);
  return rgbToHex(
    c1.r + (c2.r - c1.r) * t,
    c1.g + (c2.g - c1.g) * t,
    c1.b + (c2.b - c1.b) * t,
  );
}

function heatmapCellColor(value, min, max) {
  if (value === null || value === undefined || !Number.isFinite(value)) {
    return "#1e293b";
  }
  if (!(max > min)) return "#22d3ee";
  const t = Math.max(0, Math.min(1, (value - min) / (max - min)));
  return blendHex("#134e4a", "#67e8f9", t);
}

export function buildGlobalYearSpec(yearSeries, options = {}) {
  const width = options.width ?? 1100;
  const height = options.height ?? 420;
  const points = yearSeries.map((d) => ({
    year: d.year,
    meanC_sa: d.meanC_sa,
    meanDHW: d.meanDHW,
    q1C_sa: d.q1C_sa,
    q3C_sa: d.q3C_sa,
  }));

  return {
    $schema: "https://vega.github.io/schema/vega-lite/v5.json",
    config: BASE_CONFIG,
    width,
    height,
    title: {
      text: "Mean coral cover (C_sa) and DHW by year",
      subtitle:
        "C_sa band is 25th–75th percentile across reef-year rows; lines show means.",
    },
    layer: [
      {
        data: { values: points },
        mark: { type: "area", opacity: 0.22, color: "#22d3ee" },
        encoding: {
          x: { field: "year", type: "quantitative", title: "Year" },
          y: { field: "q1C_sa", type: "quantitative", title: "Mean C_sa" },
          y2: { field: "q3C_sa" },
        },
      },
      {
        data: { values: points },
        mark: { type: "line", color: "#22d3ee", strokeWidth: 2.5 },
        encoding: {
          x: { field: "year", type: "quantitative", title: "Year" },
          y: { field: "meanC_sa", type: "quantitative", title: "Mean C_sa" },
        },
      },
      {
        data: { values: points },
        mark: { type: "line", color: "#f472b6", strokeWidth: 2.5 },
        encoding: {
          x: { field: "year", type: "quantitative", title: "Year" },
          y: {
            field: "meanDHW",
            type: "quantitative",
            title: "Mean DHW",
            axis: { orient: "right", titleColor: "#f9a8d4", labelColor: "#f9a8d4" },
          },
        },
      },
    ],
    resolve: { scale: { y: "independent" } },
  };
}

export function buildRegionBarsSpec(regionBars, year, options = {}) {
  const width = options.width ?? 1100;
  const height = options.height ?? Math.max(260, regionBars.length * 40);
  return {
    $schema: "https://vega.github.io/schema/vega-lite/v5.json",
    config: BASE_CONFIG,
    width,
    height,
    title: {
      text: `Mean C_sa by region (${year})`,
      subtitle: "Bars sorted by mean C_sa.",
    },
    data: { values: regionBars },
    mark: { type: "bar", color: "#34d399" },
    encoding: {
      y: {
        field: "region",
        type: "nominal",
        sort: "-x",
        title: "Region",
      },
      x: { field: "meanC_sa", type: "quantitative", title: "Mean C_sa" },
      tooltip: [
        { field: "region", type: "nominal" },
        { field: "meanC_sa", type: "quantitative", format: ".4f" },
        { field: "n", type: "quantitative" },
      ],
    },
  };
}

export function buildRegionHeatmapSpec(heatmap, options = {}) {
  const width = options.width ?? 1100;
  const height = options.height ?? Math.max(260, heatmap.regions.length * 24);
  const values = [];
  for (let ri = 0; ri < heatmap.regions.length; ri++) {
    for (let yi = 0; yi < heatmap.years.length; yi++) {
      values.push({
        region: heatmap.regions[ri],
        year: heatmap.years[yi],
        meanC_sa: heatmap.matrix[ri][yi],
        color: heatmapCellColor(heatmap.matrix[ri][yi], heatmap.min, heatmap.max),
      });
    }
  }

  return {
    $schema: "https://vega.github.io/schema/vega-lite/v5.json",
    config: BASE_CONFIG,
    width,
    height,
    title: {
      text: "Heatmap: mean C_sa by region × year",
      subtitle: "Color scale follows viz package palette trend from dark to cyan.",
    },
    data: { values },
    mark: { type: "rect" },
    encoding: {
      x: {
        field: "year",
        type: "ordinal",
        title: "Year",
        sort: heatmap.years,
      },
      y: {
        field: "region",
        type: "nominal",
        title: "Region",
        sort: heatmap.regions,
      },
      color: {
        field: "color",
        type: "nominal",
        scale: null,
        legend: null,
      },
      tooltip: [
        { field: "region", type: "nominal" },
        { field: "year", type: "quantitative" },
        { field: "meanC_sa", type: "quantitative", format: ".4f" },
      ],
    },
  };
}

export function buildReefScatterSpec(reefPoints, latestYear, options = {}) {
  const width = options.width ?? 1100;
  const height = options.height ?? 480;
  return {
    $schema: "https://vega.github.io/schema/vega-lite/v5.json",
    config: BASE_CONFIG,
    width,
    height,
    title: {
      text: `Reefs in latest year (${latestYear}): location vs C_sa`,
      subtitle: "Point size encodes coral cover C_sa.",
    },
    data: { values: reefPoints },
    mark: { type: "circle", color: "#a78bfa", opacity: 0.72 },
    encoding: {
      x: { field: "lon", type: "quantitative", title: "Longitude" },
      y: { field: "lat", type: "quantitative", title: "Latitude" },
      size: {
        field: "c_sa",
        type: "quantitative",
        title: "C_sa",
        scale: { range: [12, 900] },
      },
      tooltip: [
        { field: "id", type: "nominal", title: "Reef_ID" },
        { field: "lon", type: "quantitative", format: ".4f" },
        { field: "lat", type: "quantitative", format: ".4f" },
        { field: "c_sa", type: "quantitative", format: ".4f" },
      ],
    },
  };
}

export function buildMultiRegionLineSpec(multiLine, options = {}) {
  const width = options.width ?? 1100;
  const height = options.height ?? 420;
  const values = [];
  for (const row of multiLine.data) {
    for (const region of multiLine.regions) {
      const value = row[region];
      if (value === null || value === undefined) continue;
      values.push({ year: row.year, region, meanC_sa: value });
    }
  }

  return {
    $schema: "https://vega.github.io/schema/vega-lite/v5.json",
    config: BASE_CONFIG,
    width,
    height,
    title: {
      text: "Mean C_sa by region through time",
      subtitle: "One line per region.",
    },
    data: { values },
    mark: { type: "line", strokeWidth: 2 },
    encoding: {
      x: { field: "year", type: "quantitative", title: "Year" },
      y: { field: "meanC_sa", type: "quantitative", title: "Mean C_sa" },
      color: {
        field: "region",
        type: "nominal",
        scale: {
          range: [
            "#22d3ee",
            "#f472b6",
            "#a78bfa",
            "#34d399",
            "#fbbf24",
            "#fb923c",
            "#38bdf8",
            "#e879f9",
            "#2dd4bf",
            "#f87171",
          ],
        },
      },
      tooltip: [
        { field: "region", type: "nominal" },
        { field: "year", type: "quantitative" },
        { field: "meanC_sa", type: "quantitative", format: ".4f" },
      ],
    },
  };
}

// Aliases used by the CLI entrypoint.
export const buildGlobalCoralDhwSpec = buildGlobalYearSpec;
export const buildRegionBarSpec = buildRegionBarsSpec;
export const buildHeatmapSpec = buildRegionHeatmapSpec;
export const buildRegionMultiLineSpec = buildMultiRegionLineSpec;
export const buildRegionCoralSpreadSpec = buildSingleRegionSpreadSpec;

export function buildSingleRegionSpreadSpec(regionSeries, region, options = {}) {
  const width = options.width ?? 1100;
  const height = options.height ?? 420;
  return {
    $schema: "https://vega.github.io/schema/vega-lite/v5.json",
    config: BASE_CONFIG,
    width,
    height,
    title: {
      text: `Coral cover through time (${region})`,
      subtitle: "Band is interquartile range (25th–75th percentile); line is mean C_sa.",
    },
    layer: [
      {
        data: { values: regionSeries },
        mark: { type: "area", opacity: 0.22, color: "#22d3ee" },
        encoding: {
          x: { field: "year", type: "quantitative", title: "Year" },
          y: { field: "q1C_sa", type: "quantitative", title: "C_sa" },
          y2: { field: "q3C_sa" },
        },
      },
      {
        data: { values: regionSeries },
        mark: { type: "line", color: "#22d3ee", strokeWidth: 2.5 },
        encoding: {
          x: { field: "year", type: "quantitative", title: "Year" },
          y: { field: "meanC_sa", type: "quantitative", title: "Mean C_sa" },
          tooltip: [
            { field: "year", type: "quantitative" },
            { field: "meanC_sa", type: "quantitative", format: ".4f" },
            { field: "q1C_sa", type: "quantitative", format: ".4f" },
            { field: "q3C_sa", type: "quantitative", format: ".4f" },
            { field: "n", type: "quantitative" },
          ],
        },
      },
    ],
  };
}
