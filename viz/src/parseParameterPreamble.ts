/** Keys like "CoTS control start year" in legacy parameter CSV preambles. */
const START_YEAR_KEY = /^(.+?)\s+start year$/i;

export type InterventionMarkerRaw = {
  year: number;
  interventionLabel: string;
  parameters: { key: string; value: string }[];
};

export type GroupedIntervention = {
  year: number;
  /** Shown as native SVG tooltip on hover over the vertical marker. */
  tooltip: string;
};

export function parsePreambleKeyValueLines(
  preamble: string,
): { key: string; value: string }[] {
  const rows: { key: string; value: string }[] = [];
  const lines = preamble.replace(/\r\n/g, "\n").replace(/\r/g, "\n").split("\n");
  for (const rawLine of lines) {
    const line = rawLine.trim();
    if (!line || line.startsWith("#")) continue;
    const idx = line.indexOf(",");
    if (idx < 0) continue;
    const key = line.slice(0, idx).trim();
    const value = line.slice(idx + 1).trim();
    if (!key) continue;
    rows.push({ key, value });
  }
  return rows;
}

function parseStartYearValue(raw: string): number | null {
  const n = Number(String(raw).trim().replace(/,/g, ""));
  if (!Number.isFinite(n)) return null;
  const yi = Math.trunc(n);
  if (Math.abs(n - yi) > 1e-6) return null;
  return yi;
}

/**
 * Collects each legacy "… start year" parameter whose year is not the usual
 * off sentinel (9999) and lies in [yearMin, yearMax]. Following key/value
 * lines until the next "… start year" row are attached as parameter details.
 */
export function extractInterventionMarkers(
  orderedRows: { key: string; value: string }[],
  yearMin: number,
  yearMax: number,
): InterventionMarkerRaw[] {
  const markers: InterventionMarkerRaw[] = [];

  for (let i = 0; i < orderedRows.length; i++) {
    const row = orderedRows[i]!;
    const m = row.key.match(START_YEAR_KEY);
    if (!m) continue;

    const year = parseStartYearValue(row.value);
    if (year === null || year === 9999) continue;
    if (year < yearMin || year > yearMax) continue;

    const interventionLabel = m[1]!.trim();
    const parameters: { key: string; value: string }[] = [
      { key: row.key, value: row.value },
    ];

    for (let j = i + 1; j < orderedRows.length; j++) {
      const next = orderedRows[j]!;
      if (START_YEAR_KEY.test(next.key)) break;
      parameters.push({ key: next.key, value: next.value });
    }

    markers.push({ year, interventionLabel, parameters });
  }

  return markers;
}

function formatSingle(m: InterventionMarkerRaw): string {
  const head = `${m.interventionLabel} — starts ${m.year}`;
  const body = m.parameters.map((p) => `${p.key}: ${p.value}`).join("\n");
  return `${head}\n${body}`;
}

function formatGrouped(year: number, list: InterventionMarkerRaw[]): string {
  if (list.length === 1) return formatSingle(list[0]!);
  const intro = `${list.length} interventions starting ${year}`;
  const blocks = list.map((m) => {
    const lines = m.parameters.map((p) => `  ${p.key}: ${p.value}`).join("\n");
    return `— ${m.interventionLabel}\n${lines}`;
  });
  return `${intro}\n\n${blocks.join("\n\n")}`;
}

/** One entry per calendar year so overlapping starts share one vertical line. */
export function groupInterventionsByYear(
  markers: InterventionMarkerRaw[],
): GroupedIntervention[] {
  const byYear = new Map<number, InterventionMarkerRaw[]>();
  for (const m of markers) {
    const list = byYear.get(m.year) ?? [];
    list.push(m);
    byYear.set(m.year, list);
  }

  return [...byYear.entries()]
    .sort((a, b) => a[0] - b[0])
    .map(([year, list]) => ({
      year,
      tooltip: formatGrouped(year, list),
    }));
}
