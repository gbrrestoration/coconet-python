import { num } from "./parseCoconetOutput.js";

function maxYear(rows) {
  let m = -Infinity;
  for (const r of rows) {
    const y = num(r, "Year");
    if (y !== null && y > m) m = y;
  }
  return Number.isFinite(m) ? m : null;
}

export function sortedYears(rows) {
  const ys = new Set();
  for (const r of rows) {
    const y = num(r, "Year");
    if (y !== null) ys.add(y);
  }
  return [...ys].sort((a, b) => a - b);
}

function regionLabel(r) {
  return (r.Region ?? "").trim() || "—";
}

function quantileLinear(values, q) {
  if (values.length === 0) return null;
  const sorted = [...values].sort((a, b) => a - b);
  const pos = (sorted.length - 1) * q;
  const lo = Math.floor(pos);
  const hi = Math.ceil(pos);
  const a = sorted[lo];
  const b = sorted[hi];
  if (lo === hi) return a;
  return a + (b - a) * (pos - lo);
}

export function aggregateByYear(rows) {
  const map = new Map();
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

export function meanCsaByRegionForYear(rows, year) {
  const subset = rows.filter((r) => num(r, "Year") === year);
  const map = new Map();
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

export function uniqueRegionsSorted(rows) {
  const set = new Set();
  for (const r of rows) {
    const c = num(r, "C_sa");
    if (c === null) continue;
    set.add(regionLabel(r));
  }
  return [...set].sort((a, b) => a.localeCompare(b));
}

export function meanCsaSeriesForRegionWithSpread(rows, region) {
  const map = new Map();
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
      const q1 = quantileLinear(cValues, 0.25);
      const q3 = quantileLinear(cValues, 0.75);
      return { year, meanC_sa, q1C_sa: q1, q3C_sa: q3, n };
    });
}

export function multiLineRegionCoralSeries(rows) {
  const years = sortedYears(rows);
  const regions = uniqueRegionsSorted(rows);
  if (years.length === 0 || regions.length === 0) {
    return { data: [], regions: [] };
  }

  const cell = new Map();
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

  const data = years.map((year) => {
    const row = { year };
    for (const reg of regions) {
      const k = `${year}\t${reg}`;
      const a = cell.get(k);
      row[reg] = a && a.n ? a.sum / a.n : null;
    }
    return row;
  });

  return { data, regions };
}

export function buildRegionYearHeatmap(rows) {
  const years = sortedYears(rows);
  const regions = uniqueRegionsSorted(rows);
  if (years.length === 0 || regions.length === 0) {
    return { regions: [], years: [], matrix: [], min: 0, max: 0 };
  }

  const yi = new Map();
  years.forEach((y, i) => yi.set(y, i));
  const ri = new Map();
  regions.forEach((r, i) => ri.set(r, i));

  const cell = new Map();
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

  const matrix = regions.map(() => years.map(() => null));
  let min = Infinity;
  let max = -Infinity;
  for (const reg of regions) {
    const i = ri.get(reg);
    for (const year of years) {
      const a = cell.get(`${reg}\t${year}`);
      const v = a && a.n ? a.sum / a.n : null;
      matrix[i][yi.get(year)] = v;
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

export function reefScatterLatestYear(rows, maxPoints = 2000) {
  const yLast = maxYear(rows);
  if (yLast === null) return [];
  const subset = rows.filter((r) => num(r, "Year") === yLast);
  const out = [];
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

