import { num } from "./parseCoconetOutput";

export type YearPoint = {
  year: number;
  meanC_sa: number | null;
  /** 25th percentile of C_sa across reef-year rows for this year (ensemble + spatial spread). */
  q1C_sa: number | null;
  /** 75th percentile of C_sa for this year. */
  q3C_sa: number | null;
  meanDHW: number | null;
};

export type RegionPoint = {
  region: string;
  meanC_sa: number;
  n: number;
};

export type ReefPoint = {
  id: string;
  lon: number;
  lat: number;
  c_sa: number;
};

export type RegionYearHeatmap = {
  regions: string[];
  years: number[];
  /** matrix[regionIndex][yearIndex] */
  matrix: (number | null)[][];
  min: number;
  max: number;
};

export type MultiLineRegionRow = { year: number } & Record<string, number | null>;

function maxYear(rows: Record<string, string>[]): number | null {
  let m = -Infinity;
  for (const r of rows) {
    const y = num(r, "Year");
    if (y !== null && y > m) m = y;
  }
  return Number.isFinite(m) ? m : null;
}

export function sortedYears(rows: Record<string, string>[]): number[] {
  const ys = new Set<number>();
  for (const r of rows) {
    const y = num(r, "Year");
    if (y !== null) ys.add(y);
  }
  return [...ys].sort((a, b) => a - b);
}

function regionLabel(r: Record<string, string>): string {
  return (r.Region ?? "").trim() || "—";
}

function quantileLinear(values: number[], q: number): number | null {
  if (values.length === 0) return null;
  const sorted = [...values].sort((a, b) => a - b);
  const pos = (sorted.length - 1) * q;
  const lo = Math.floor(pos);
  const hi = Math.ceil(pos);
  const a = sorted[lo]!;
  const b = sorted[hi]!;
  if (lo === hi) return a;
  return a + (b - a) * (pos - lo);
}

export function aggregateByYear(rows: Record<string, string>[]): YearPoint[] {
  const map = new Map<
    number,
    { cValues: number[]; sumD: number; nD: number }
  >();
  for (const r of rows) {
    const year = num(r, "Year");
    if (year === null) continue;
    let agg = map.get(year);
    if (!agg) {
      agg = { cValues: [], sumD: 0, nD: 0 };
      map.set(year, agg);
    }
    const c = num(r, "C_sa");
    if (c !== null) {
      agg.cValues.push(c);
    }
    const d = num(r, "DHW");
    if (d !== null) {
      agg.sumD += d;
      agg.nD++;
    }
  }
  return [...map.entries()]
    .sort((a, b) => a[0] - b[0])
    .map(([year, a]) => {
      const nC = a.cValues.length;
      return {
        year,
        meanC_sa: nC ? a.cValues.reduce((s, x) => s + x, 0) / nC : null,
        q1C_sa: quantileLinear(a.cValues, 0.25),
        q3C_sa: quantileLinear(a.cValues, 0.75),
        meanDHW: a.nD ? a.sumD / a.nD : null,
      };
    });
}

export function meanCsaByRegionForYear(
  rows: Record<string, string>[],
  year: number,
): RegionPoint[] {
  const subset = rows.filter((r) => num(r, "Year") === year);
  const map = new Map<string, { sum: number; n: number }>();
  for (const r of subset) {
    const region = regionLabel(r);
    const c = num(r, "C_sa");
    if (c === null) continue;
    const agg = map.get(region) ?? { sum: 0, n: 0 };
    agg.sum += c;
    agg.n++;
    map.set(region, agg);
  }
  return [...map.entries()]
    .map(([region, a]) => ({
      region,
      meanC_sa: a.sum / a.n,
      n: a.n,
    }))
    .sort((a, b) => b.meanC_sa - a.meanC_sa);
}

export function aggregateByRegionLatestYear(
  rows: Record<string, string>[],
): RegionPoint[] {
  const yLast = maxYear(rows);
  if (yLast === null) return [];
  return meanCsaByRegionForYear(rows, yLast);
}

export function uniqueRegionsSorted(rows: Record<string, string>[]): string[] {
  const set = new Set<string>();
  for (const r of rows) {
    const c = num(r, "C_sa");
    if (c === null) continue;
    set.add(regionLabel(r));
  }
  return [...set].sort((a, b) => a.localeCompare(b));
}

export type RegionYearCoralPoint = {
  year: number;
  meanC_sa: number;
  q1C_sa: number;
  q3C_sa: number;
  n: number;
};

/** Mean C_sa by year for one region (reef-year rows aggregated). */
export function meanCsaSeriesForRegion(
  rows: Record<string, string>[],
  region: string,
): { year: number; meanC_sa: number; n: number }[] {
  return meanCsaSeriesForRegionWithSpread(rows, region).map(
    ({ year, meanC_sa, n }) => ({ year, meanC_sa, n }),
  );
}

/** Mean and interquartile range of C_sa by year within one region. */
export function meanCsaSeriesForRegionWithSpread(
  rows: Record<string, string>[],
  region: string,
): RegionYearCoralPoint[] {
  const map = new Map<number, number[]>();
  for (const r of rows) {
    if (regionLabel(r) !== region) continue;
    const year = num(r, "Year");
    const c = num(r, "C_sa");
    if (year === null || c === null) continue;
    const arr = map.get(year) ?? [];
    arr.push(c);
    map.set(year, arr);
  }
  return [...map.entries()]
    .sort((a, b) => a[0] - b[0])
    .map(([year, cValues]) => {
      const n = cValues.length;
      const meanC_sa = cValues.reduce((s, x) => s + x, 0) / n;
      const q1 = quantileLinear(cValues, 0.25)!;
      const q3 = quantileLinear(cValues, 0.75)!;
      return { year, meanC_sa, q1C_sa: q1, q3C_sa: q3, n };
    });
}

/**
 * One row per year; each region key is mean C_sa for that year (null if no data).
 */
export function multiLineRegionCoralSeries(
  rows: Record<string, string>[],
): { data: MultiLineRegionRow[]; regions: string[] } {
  const years = sortedYears(rows);
  const regions = uniqueRegionsSorted(rows);
  if (years.length === 0 || regions.length === 0) {
    return { data: [], regions: [] };
  }

  const cell = new Map<string, { sum: number; n: number }>();
  for (const r of rows) {
    const year = num(r, "Year");
    const c = num(r, "C_sa");
    if (year === null || c === null) continue;
    const reg = regionLabel(r);
    const key = `${year}\t${reg}`;
    const agg = cell.get(key) ?? { sum: 0, n: 0 };
    agg.sum += c;
    agg.n++;
    cell.set(key, agg);
  }

  const data: MultiLineRegionRow[] = years.map((year) => {
    const row: MultiLineRegionRow = { year };
    for (const reg of regions) {
      const k = `${year}\t${reg}`;
      const a = cell.get(k);
      row[reg] = a && a.n ? a.sum / a.n : null;
    }
    return row;
  });

  return { data, regions };
}

/** Mean coral cover by region (rows) × year (columns) for heatmaps. */
export function buildRegionYearHeatmap(
  rows: Record<string, string>[],
): RegionYearHeatmap {
  const years = sortedYears(rows);
  const regions = uniqueRegionsSorted(rows);
  if (years.length === 0 || regions.length === 0) {
    return { regions: [], years: [], matrix: [], min: 0, max: 0 };
  }

  const yi = new Map<number, number>();
  years.forEach((y, i) => yi.set(y, i));
  const ri = new Map<string, number>();
  regions.forEach((r, i) => ri.set(r, i));

  const cell = new Map<string, { sum: number; n: number }>();
  for (const row of rows) {
    const year = num(row, "Year");
    const c = num(row, "C_sa");
    if (year === null || c === null) continue;
    const reg = regionLabel(row);
    if (!ri.has(reg)) continue;
    const key = `${reg}\t${year}`;
    const agg = cell.get(key) ?? { sum: 0, n: 0 };
    agg.sum += c;
    agg.n++;
    cell.set(key, agg);
  }

  const matrix: (number | null)[][] = regions.map(() =>
    years.map(() => null),
  );
  let min = Infinity;
  let max = -Infinity;
  for (const reg of regions) {
    const i = ri.get(reg)!;
    for (const year of years) {
      const a = cell.get(`${reg}\t${year}`);
      const v = a && a.n ? a.sum / a.n : null;
      matrix[i][yi.get(year)!] = v;
      if (v !== null) {
        if (v < min) min = v;
        if (v > max) max = v;
      }
    }
  }
  if (!Number.isFinite(min) || !Number.isFinite(max)) {
    return { regions, years, matrix, min: 0, max: 0 };
  }
  if (min === max) {
    max = min + 1e-6;
  }
  return { regions, years, matrix, min, max };
}

export function reefScatterLatestYear(
  rows: Record<string, string>[],
  maxPoints = 2000,
): ReefPoint[] {
  const yLast = maxYear(rows);
  if (yLast === null) return [];
  const subset = rows.filter((r) => num(r, "Year") === yLast);
  const out: ReefPoint[] = [];
  for (const r of subset) {
    const lon = num(r, "Longitude");
    const lat = num(r, "Latitude");
    const c = num(r, "C_sa");
    const id = (r.Reef_ID ?? "").trim() || `${lon},${lat}`;
    if (lon === null || lat === null || c === null) continue;
    out.push({ id, lon, lat, c_sa: c });
  }
  if (out.length <= maxPoints) return out;
  const step = Math.ceil(out.length / maxPoints);
  return out.filter((_, i) => i % step === 0);
}
