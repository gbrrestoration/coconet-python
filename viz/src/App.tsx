import {
  Fragment,
  useCallback,
  useMemo,
  useState,
  type ReactNode,
} from "react";
import {
  Area,
  Bar,
  BarChart,
  CartesianGrid,
  ComposedChart,
  Legend,
  Line,
  LineChart,
  ResponsiveContainer,
  Scatter,
  ScatterChart,
  Tooltip,
  Customized,
  XAxis,
  YAxis,
  ZAxis,
} from "recharts";
import {
  aggregateByYear,
  buildRegionYearHeatmap,
  meanCsaByRegionForYear,
  meanCsaSeriesForRegionWithSpread,
  multiLineRegionCoralSeries,
  reefScatterLatestYear,
  sortedYears,
  uniqueRegionsSorted,
  type YearPoint,
} from "./aggregates";
import {
  InterventionVerticalMarkers,
  interventionChartGeometry,
} from "./InterventionVerticalMarkers";
import {
  formatDiagnosticsForConsole,
  parseCoconetOutput,
  type ParseDiagnostics,
  type ParsedCoconetOutput,
} from "./parseCoconetOutput";
import {
  extractInterventionMarkers,
  groupInterventionsByYear,
  parsePreambleKeyValueLines,
} from "./parseParameterPreamble";
import {
  readModelOutputFile,
  SAFE_FULL_READ_BYTES,
} from "./readModelOutputFile";
import { streamCoCoNetFromFile } from "./streamCoCoNetFile";

const REGION_LINE_COLORS = [
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
];

function heatmapCellColor(
  v: number | null,
  min: number,
  max: number,
): string {
  if (v === null) return "rgb(30 41 59)";
  if (max <= min) return "hsl(187 80% 45%)";
  const t = (v - min) / (max - min);
  const light = 22 + t * 48;
  return `hsl(187 78% ${light}%)`;
}

function parseDebugEnabled(): boolean {
  if (typeof window === "undefined") return false;
  try {
    const q = new URLSearchParams(window.location.search).get("debug");
    if (q === "1" || q === "parse") return true;
    return window.localStorage.getItem("coconetVizParseDebug") === "1";
  } catch {
    return false;
  }
}

export default function App() {
  const [fileName, setFileName] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [parseDiagnostics, setParseDiagnostics] =
    useState<ParseDiagnostics | null>(null);
  const [preamble, setPreamble] = useState<string>("");
  const [rowCount, setRowCount] = useState(0);
  const [rawRows, setRawRows] = useState<Record<string, string>[]>([]);
  const [yearSeries, setYearSeries] = useState<
    ReturnType<typeof aggregateByYear>
  >([]);
  const [regionBarYear, setRegionBarYear] = useState<number>(0);
  const [heatmapFocusYear, setHeatmapFocusYear] = useState<number>(0);
  const [selectedRegion, setSelectedRegion] = useState<string>("");

  const yearsList = useMemo(() => sortedYears(rawRows), [rawRows]);
  const interventionGrouped = useMemo(() => {
    if (!preamble.trim() || yearsList.length === 0) return [];
    const yMin = yearsList[0]!;
    const yMax = yearsList[yearsList.length - 1]!;
    const rows = parsePreambleKeyValueLines(preamble);
    const raw = extractInterventionMarkers(rows, yMin, yMax);
    return groupInterventionsByYear(raw);
  }, [preamble, yearsList]);
  const interventionTooltipByYear = useMemo(
    () => new Map(interventionGrouped.map((g) => [g.year, g.tooltip])),
    [interventionGrouped],
  );
  const regionsList = useMemo(() => uniqueRegionsSorted(rawRows), [rawRows]);
  const heatmap = useMemo(
    () => buildRegionYearHeatmap(rawRows),
    [rawRows],
  );
  const multiLine = useMemo(
    () => multiLineRegionCoralSeries(rawRows),
    [rawRows],
  );
  const regionBarsForYear = useMemo(
    () =>
      rawRows.length > 0
        ? meanCsaByRegionForYear(rawRows, regionBarYear)
        : [],
    [rawRows, regionBarYear],
  );
  const singleRegionSeries = useMemo(
    () =>
      selectedRegion
        ? meanCsaSeriesForRegionWithSpread(rawRows, selectedRegion)
        : [],
    [rawRows, selectedRegion],
  );

  const yearChartData = useMemo(
    () =>
      yearSeries.map((p) => ({
        ...p,
        iqrSpan:
          p.q1C_sa != null && p.q3C_sa != null
            ? Math.max(0, p.q3C_sa - p.q1C_sa)
            : null,
      })),
    [yearSeries],
  );

  const regionCoralChartData = useMemo(
    () =>
      singleRegionSeries.map((p) => ({
        ...p,
        iqrSpan: Math.max(0, p.q3C_sa - p.q1C_sa),
      })),
    [singleRegionSeries],
  );
  const reefPoints = useMemo(
    () => reefScatterLatestYear(rawRows),
    [rawRows],
  );

  type LoadTextMeta = {
    sourceFileSizeBytes?: number;
    loadedByteLength?: number;
    fileContentTruncated?: boolean;
  };

  const applyParsedOutput = useCallback((name: string, parsed: ParsedCoconetOutput) => {
    const d = parsed.diagnostics;
    setFileName(name);
    setParseDiagnostics(d);

    const debug = parseDebugEnabled();
    const shouldLog =
      debug ||
      parsed.headers.length === 0 ||
      (parsed.headers.length > 0 && parsed.rows.length === 0);
    if (shouldLog) {
      console.warn(formatDiagnosticsForConsole(d));
      if (debug) {
        console.info("[coconet-viz] parse diagnostics (object)", d);
      }
    }

    setPreamble(parsed.preamble);

    if (parsed.headers.length === 0) {
      const extra =
        d.rejectionSummary != null && d.rejectionSummary.length > 0
          ? ` ${d.rejectionSummary}`
          : "";
      setError(
        `No data table found. Expected a CSV header line starting with Ensemble, Year, Reef_ID, …${extra}`,
      );
      setRowCount(0);
      setRawRows([]);
      setYearSeries([]);
      return;
    }
    setRowCount(parsed.rows.length);
    if (parsed.rows.length === 0) {
      const errTail =
        d.papaErrors.length > 0
          ? ` Papa Parse reported ${d.papaErrors.length} issue(s); open “Parse diagnostics” below.`
          : "";
      setError(`Table header found but no data rows.${errTail}`);
      setRawRows([]);
      setYearSeries([]);
      return;
    }
    setError(null);
    const ys = sortedYears(parsed.rows);
    const lastY = ys.length ? ys[ys.length - 1] : 0;
    setRegionBarYear(lastY);
    setHeatmapFocusYear(lastY);
    const regs = uniqueRegionsSorted(parsed.rows);
    setSelectedRegion(regs[0] ?? "");
    setRawRows(parsed.rows);
    setYearSeries(aggregateByYear(parsed.rows));
  }, []);

  const loadText = useCallback(
    (name: string, text: string, meta?: LoadTextMeta) => {
      setError(null);
      setParseDiagnostics(null);
      setFileName(name);
      try {
        const parsed = parseCoconetOutput(text, {
          sourceFileSizeBytes: meta?.sourceFileSizeBytes,
          loadedByteLength: meta?.loadedByteLength,
          fileContentTruncated: meta?.fileContentTruncated,
        });
        const d = parsed.diagnostics;

        if (text.length === 0) {
          setParseDiagnostics(parsed.diagnostics);
          setError(
            d.rejectionSummary ??
              "No text was read from the file (0 characters).",
          );
          setRowCount(0);
          setRawRows([]);
          setYearSeries([]);
          return;
        }

        applyParsedOutput(name, parsed);
      } catch (e) {
        setParseDiagnostics(null);
        console.error("[coconet-viz] parse threw", e);
        setError(e instanceof Error ? e.message : "Failed to parse file");
        setRowCount(0);
        setRawRows([]);
        setYearSeries([]);
      }
    },
    [applyParsedOutput],
  );

  const handleReadFailure = useCallback((f: File, err: unknown) => {
    console.error("[coconet-viz] file read/parse failed", err);
    setFileName(f.name);
    setParseDiagnostics(null);
    setError(
      `Reading the file failed: ${err instanceof Error ? err.message : String(err)}. Very large files can still exhaust memory after streaming; try a smaller CSV or fewer columns.`,
    );
    setRowCount(0);
    setRawRows([]);
    setYearSeries([]);
  }, []);

  const loadFile = useCallback(
    (f: File) => {
      setError(null);
      setParseDiagnostics(null);
      if (f.size > SAFE_FULL_READ_BYTES) {
        void streamCoCoNetFromFile(f)
          .then((parsed) => applyParsedOutput(f.name, parsed))
          .catch((err) => handleReadFailure(f, err));
        return;
      }
      void readModelOutputFile(f)
        .then((r) =>
          loadText(f.name, r.text, {
            sourceFileSizeBytes: r.fileSize,
            loadedByteLength: r.loadedBytes,
            fileContentTruncated: r.truncated,
          }),
        )
        .catch((err) => handleReadFailure(f, err));
    },
    [applyParsedOutput, handleReadFailure, loadText],
  );

  const onDrop = useCallback(
    (e: React.DragEvent) => {
      e.preventDefault();
      const f = e.dataTransfer.files[0];
      if (!f) return;
      loadFile(f);
    },
    [loadFile],
  );

  const onFileInput = useCallback(
    (e: React.ChangeEvent<HTMLInputElement>) => {
      const f = e.target.files?.[0];
      if (!f) return;
      loadFile(f);
    },
    [loadFile],
  );

  const heatmapYearIndex = useMemo(() => {
    const i = heatmap.years.indexOf(heatmapFocusYear);
    return i >= 0 ? i : heatmap.years.length - 1;
  }, [heatmap.years, heatmapFocusYear]);

  return (
    <div className="mx-auto max-w-6xl px-4 py-10">
      <header className="mb-8">
        <h1 className="text-2xl font-semibold tracking-tight text-slate-50">
          CoCoNet output
        </h1>
        <p className="mt-1 text-sm text-slate-400">
          Drop a model <code className="text-cyan-400/90">output.csv</code>{" "}
          (preamble + reef table) to explore means by year and region. Files larger
          than ~180&nbsp;MiB are parsed in chunks (no whole-file string); all rows are
          still held in memory for the charts, so very large runs can hit RAM limits.
          Add <code className="text-cyan-400/90">?debug=1</code> to the URL or set{" "}
          <code className="text-cyan-400/90">localStorage.coconetVizParseDebug=1</code>{" "}
          for verbose parse logging.
        </p>
      </header>

      <label
        onDragOver={(e) => e.preventDefault()}
        onDrop={onDrop}
        className="flex cursor-pointer flex-col items-center justify-center rounded-xl border border-dashed border-slate-600 bg-slate-900/50 px-6 py-14 transition hover:border-cyan-600/60 hover:bg-slate-900"
      >
        <span className="text-slate-300">
          Drag and drop CSV here, or click to choose a file
        </span>
        <input
          type="file"
          accept=".csv,text/csv,text/plain"
          className="sr-only"
          onChange={onFileInput}
        />
        {fileName ? (
          <span className="mt-3 text-xs text-slate-500">{fileName}</span>
        ) : null}
      </label>

      {error ? (
        <p className="mt-4 rounded-lg border border-amber-900/60 bg-amber-950/40 px-3 py-2 text-sm text-amber-200">
          {error}
        </p>
      ) : null}

      {!error &&
      parseDiagnostics?.fileContentTruncated &&
      parseDiagnostics.truncationNote ? (
        <p className="mt-4 rounded-lg border border-cyan-900/50 bg-cyan-950/35 px-3 py-2 text-sm text-cyan-100">
          {parseDiagnostics.truncationNote}
        </p>
      ) : null}

      {parseDiagnostics ? (
        <details
          className={`mt-4 rounded-lg border border-slate-800 bg-slate-900/30 ${
            error ||
            parseDebugEnabled() ||
            parseDiagnostics.fileContentTruncated ||
            parseDiagnostics.parseViaStream
              ? ""
              : "hidden"
          }`}
          open={Boolean(
            error ||
              parseDiagnostics.fileContentTruncated ||
              parseDiagnostics.parseViaStream,
          )}
        >
          <summary className="cursor-pointer px-3 py-2 text-sm text-slate-400">
            Parse diagnostics
            {parseDiagnostics.largeFileNote ? (
              <span className="ml-2 text-amber-400/90">(large file)</span>
            ) : null}
            {parseDiagnostics.fileContentTruncated ? (
              <span className="ml-2 text-cyan-400/90">(prefix load)</span>
            ) : null}
            {parseDiagnostics.parseViaStream && !parseDiagnostics.fileContentTruncated ? (
              <span className="ml-2 text-cyan-400/90">(streamed table)</span>
            ) : null}
          </summary>
          <div className="space-y-3 border-t border-slate-800 p-3 text-xs text-slate-400">
            {parseDiagnostics.largeFileNote ? (
              <p className="text-amber-200/90">{parseDiagnostics.largeFileNote}</p>
            ) : null}
            {parseDiagnostics.newlineCountNote ? (
              <p className="text-slate-500">{parseDiagnostics.newlineCountNote}</p>
            ) : null}
            {parseDiagnostics.truncationNote ? (
              <p className="text-cyan-200/90">{parseDiagnostics.truncationNote}</p>
            ) : null}
            <dl className="grid grid-cols-[auto_1fr] gap-x-3 gap-y-1">
              <dt className="text-slate-500">Reported file size</dt>
              <dd className="font-mono text-slate-300">
                {parseDiagnostics.sourceFileSizeBytes != null
                  ? `${parseDiagnostics.sourceFileSizeBytes.toLocaleString()} bytes (File.size)`
                  : "—"}
              </dd>
              <dt className="text-slate-500">Bytes read (Blob slice)</dt>
              <dd className="font-mono text-slate-300">
                {parseDiagnostics.loadedByteLength != null
                  ? `${parseDiagnostics.loadedByteLength.toLocaleString()}`
                  : "—"}
              </dd>
              <dt className="text-slate-500">Prefix only</dt>
              <dd className="font-mono text-slate-300">
                {parseDiagnostics.fileContentTruncated ? "yes" : "no"}
              </dd>
              <dt className="text-slate-500">Table parse</dt>
              <dd className="font-mono text-slate-300">
                {parseDiagnostics.parseViaStream
                  ? "chunked (Blob → row array)"
                  : "single decoded string"}
              </dd>
              <dt className="text-slate-500">Decoded characters</dt>
              <dd className="font-mono text-slate-300">
                {parseDiagnostics.textLengthChars != null
                  ? parseDiagnostics.textLengthChars.toLocaleString()
                  : "—"}
                {parseDiagnostics.parseViaStream &&
                parseDiagnostics.textLengthChars == null ? (
                  <span className="ml-2 text-slate-500">(streamed)</span>
                ) : null}
                {parseDiagnostics.decodedTextEmpty ? (
                  <span className="ml-2 text-amber-400/90">(empty)</span>
                ) : null}
              </dd>
              <dt className="text-slate-500">Newlines</dt>
              <dd className="font-mono text-slate-300">
                {parseDiagnostics.newlineCount != null
                  ? parseDiagnostics.newlineCount.toLocaleString()
                  : "—"}
              </dd>
              <dt className="text-slate-500">UTF-8 BOM</dt>
              <dd className="font-mono text-slate-300">
                {parseDiagnostics.leadingUtf8Bom ? "yes" : "no"}
              </dd>
              <dt className="text-slate-500">Header line</dt>
              <dd className="font-mono text-slate-300">
                {parseDiagnostics.tableHeaderFound
                  ? `index ${parseDiagnostics.tableHeaderLineIndex} (char ${parseDiagnostics.tableHeaderCharOffset?.toLocaleString()})`
                  : "not found"}
              </dd>
              <dt className="text-slate-500">Lines scanned</dt>
              <dd className="font-mono text-slate-300">
                {parseDiagnostics.scannedLines.toLocaleString()}
                {parseDiagnostics.stoppedEarlyMaxLines
                  ? " (stopped at limit)"
                  : ""}
              </dd>
              <dt className="text-slate-500">Data rows</dt>
              <dd className="font-mono text-slate-300">
                {parseDiagnostics.papaRowCount != null
                  ? parseDiagnostics.papaRowCount.toLocaleString()
                  : "—"}
              </dd>
            </dl>
            {parseDiagnostics.firstLinePreviews.length > 0 ? (
              <div>
                <div className="mb-1 font-medium text-slate-500">
                  First non-empty lines (preview)
                </div>
                <ul className="max-h-40 overflow-auto font-mono text-[11px] text-slate-400">
                  {parseDiagnostics.firstLinePreviews.map((p) => (
                    <li key={p.lineIndex} className="border-b border-slate-800/80 py-1">
                      <span className="text-slate-600">[{p.lineIndex}]</span>{" "}
                      {p.content}
                    </li>
                  ))}
                </ul>
              </div>
            ) : null}
            {parseDiagnostics.lineHints.length > 0 ? (
              <div>
                <div className="mb-1 font-medium text-slate-500">
                  Lines mentioning Ensemble / Reef_ID (hints)
                </div>
                <ul className="max-h-48 overflow-auto font-mono text-[11px] text-slate-400">
                  {parseDiagnostics.lineHints.map((h) => (
                    <li key={h.lineIndex} className="border-b border-slate-800/80 py-1">
                      <span className="text-slate-600">[{h.lineIndex}]</span>{" "}
                      <span className="text-slate-500">
                        Ensemble,…={String(h.startsWithEnsembleComma)} Reef_ID=
                        {String(h.hasReefId)} Year={String(h.hasYear)}
                      </span>
                      <div className="mt-0.5 whitespace-pre-wrap break-all text-slate-400">
                        {h.preview}
                      </div>
                    </li>
                  ))}
                </ul>
              </div>
            ) : null}
            {parseDiagnostics.papaErrors.length > 0 ? (
              <div>
                <div className="mb-1 font-medium text-slate-500">
                  Papa Parse messages
                </div>
                <ul className="max-h-32 overflow-auto font-mono text-[11px] text-rose-300/90">
                  {parseDiagnostics.papaErrors.slice(0, 20).map((e, i) => (
                    <li key={i}>
                      {e.type}
                      {e.code ? ` (${e.code})` : ""}: {e.message}
                      {e.row != null ? ` @ row ${e.row}` : ""}
                    </li>
                  ))}
                </ul>
              </div>
            ) : null}
          </div>
        </details>
      ) : null}

      {preamble ? (
        <details className="mt-6 rounded-lg border border-slate-800 bg-slate-900/30">
          <summary className="cursor-pointer px-3 py-2 text-sm text-slate-400">
            {error
              ? "File preview (start; truncated on parse failure)"
              : "Run parameters (preamble)"}
          </summary>
          <pre className="max-h-40 overflow-auto whitespace-pre-wrap border-t border-slate-800 p-3 text-xs text-slate-500">
            {preamble}
          </pre>
        </details>
      ) : null}

      {rowCount > 0 ? (
        <p className="mt-4 text-sm text-slate-400">
          {rowCount.toLocaleString()} reef-year rows loaded
        </p>
      ) : null}

      {yearSeries.length > 0 ? (
        <section className="mt-8 space-y-10">
          <ChartCard title="Mean coral cover (C_sa) and DHW by year">
            <p className="mb-2 text-xs text-slate-500">
              Shaded band: 25th–75th percentile of C_sa across all reef–ensemble
              rows in each year (mean as the line).
              {interventionGrouped.length > 0 ? (
                <>
                  {" "}
                  Faint dashed vertical lines mark intervention start years from
                  the run preamble (hover for parameters).
                </>
              ) : null}
            </p>
            <div className="h-72 w-full">
              <ResponsiveContainer width="100%" height="100%">
                <ComposedChart data={yearChartData}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#334155" />
                  <XAxis
                    dataKey="year"
                    stroke="#94a3b8"
                    tick={{ fill: "#94a3b8", fontSize: 12 }}
                  />
                  <YAxis
                    yAxisId="left"
                    stroke="#94a3b8"
                    tick={{ fill: "#94a3b8", fontSize: 12 }}
                    label={{
                      value: "Mean C_sa",
                      angle: -90,
                      position: "insideLeft",
                      fill: "#94a3b8",
                      fontSize: 11,
                    }}
                  />
                  <YAxis
                    yAxisId="right"
                    orientation="right"
                    stroke="#94a3b8"
                    tick={{ fill: "#94a3b8", fontSize: 12 }}
                    label={{
                      value: "Mean DHW",
                      angle: 90,
                      position: "insideRight",
                      fill: "#94a3b8",
                      fontSize: 11,
                    }}
                  />
                  <Tooltip
                    content={
                      <GlobalCoralYearTooltip
                        interventionByYear={interventionTooltipByYear}
                      />
                    }
                  />
                  <Legend />
                  <Customized
                    component={(p) => (
                      <InterventionVerticalMarkers
                        grouped={interventionGrouped}
                        {...interventionChartGeometry(p)}
                      />
                    )}
                  />
                  <Area
                    yAxisId="left"
                    type="monotone"
                    dataKey="q1C_sa"
                    stackId="coralIqr"
                    stroke="none"
                    fill="transparent"
                    fillOpacity={0}
                    legendType="none"
                    isAnimationActive={false}
                  />
                  <Area
                    yAxisId="left"
                    type="monotone"
                    dataKey="iqrSpan"
                    stackId="coralIqr"
                    stroke="none"
                    fill="#22d3ee"
                    fillOpacity={0.22}
                    name="C_sa IQR (25–75%)"
                    connectNulls
                    isAnimationActive={false}
                  />
                  <Line
                    yAxisId="left"
                    type="monotone"
                    dataKey="meanC_sa"
                    name="Mean C_sa"
                    stroke="#22d3ee"
                    dot={false}
                    strokeWidth={2}
                    connectNulls
                  />
                  <Line
                    yAxisId="right"
                    type="monotone"
                    dataKey="meanDHW"
                    name="Mean DHW"
                    stroke="#f472b6"
                    dot={false}
                    strokeWidth={2}
                    connectNulls
                  />
                </ComposedChart>
              </ResponsiveContainer>
            </div>
          </ChartCard>

          {multiLine.data.length > 0 && multiLine.regions.length > 0 ? (
            <ChartCard title="Mean C_sa by region through time (one line per region)">
              <p className="mb-2 text-xs text-slate-500">
                Click legend entries to show or hide regions. Values are
                mean C_sa across reefs in each region per year.
                {interventionGrouped.length > 0 ? (
                  <>
                    {" "}
                    Dashed vertical lines: intervention starts from preamble
                    (hover for details).
                  </>
                ) : null}
              </p>
              <div className="h-80 w-full">
                <ResponsiveContainer width="100%" height="100%">
                  <LineChart data={multiLine.data}>
                    <CartesianGrid strokeDasharray="3 3" stroke="#334155" />
                    <XAxis
                      dataKey="year"
                      stroke="#94a3b8"
                      tick={{ fill: "#94a3b8", fontSize: 12 }}
                    />
                    <YAxis
                      stroke="#94a3b8"
                      tick={{ fill: "#94a3b8", fontSize: 12 }}
                      label={{
                        value: "Mean C_sa",
                        angle: -90,
                        position: "insideLeft",
                        fill: "#94a3b8",
                        fontSize: 11,
                      }}
                    />
                    <Tooltip
                      content={
                        <MultiRegionYearTooltip
                          interventionByYear={interventionTooltipByYear}
                        />
                      }
                    />
                    <Legend wrapperStyle={{ fontSize: 11 }} />
                    <Customized
                      component={(p) => (
                        <InterventionVerticalMarkers
                          grouped={interventionGrouped}
                          {...interventionChartGeometry(p)}
                        />
                      )}
                    />
                    {multiLine.regions.map((reg, i) => (
                      <Line
                        key={reg}
                        type="monotone"
                        dataKey={reg}
                        name={reg}
                        stroke={REGION_LINE_COLORS[i % REGION_LINE_COLORS.length]}
                        dot={false}
                        strokeWidth={2}
                        connectNulls
                      />
                    ))}
                  </LineChart>
                </ResponsiveContainer>
              </div>
            </ChartCard>
          ) : null}

          {heatmap.regions.length > 0 && heatmap.years.length > 0 ? (
            <ChartCard title="Heatmap: mean C_sa by region × year">
              <div className="mb-3 flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
                <label className="flex flex-wrap items-center gap-2 text-xs text-slate-400">
                  <span className="whitespace-nowrap">Focus year</span>
                  <input
                    type="range"
                    className="w-48 accent-cyan-500"
                    min={0}
                    max={Math.max(0, heatmap.years.length - 1)}
                    value={heatmapYearIndex}
                    onChange={(e) => {
                      const idx = Number(e.target.value);
                      const y = heatmap.years[idx];
                      if (y !== undefined) setHeatmapFocusYear(y);
                    }}
                  />
                  <span className="font-mono text-cyan-300/90">
                    {heatmap.years[heatmapYearIndex] ?? "—"}
                  </span>
                </label>
                <div className="flex items-center gap-2 text-[10px] text-slate-500">
                  <span>low</span>
                  <span
                    className="h-3 w-28 rounded border border-slate-700"
                    style={{
                      background:
                        "linear-gradient(to right, hsl(187 78% 22%), hsl(187 78% 70%))",
                    }}
                  />
                  <span>high C_sa</span>
                </div>
              </div>
              <p className="mb-2 text-xs text-slate-500">
                Columns align with years; the slider highlights the focused
                year. Hover cells for values.
              </p>
              <div className="max-h-[min(28rem,55vh)] overflow-auto rounded-lg border border-slate-800">
                <div
                  className="inline-grid gap-px bg-slate-800 p-px"
                  style={{
                    gridTemplateColumns: `minmax(7rem,auto) repeat(${heatmap.years.length}, minmax(1.5rem, 1fr))`,
                  }}
                >
                  <div className="sticky left-0 z-10 bg-slate-900 px-2 py-1 text-[10px] font-medium text-slate-500">
                    Region / Year
                  </div>
                  {heatmap.years.map((y, yi) => (
                    <div
                      key={y}
                      className={`bg-slate-900 px-0.5 py-1 text-center text-[9px] text-slate-500 ${
                        yi === heatmapYearIndex
                          ? "ring-1 ring-cyan-500/80 ring-inset"
                          : ""
                      }`}
                      title={`Year ${y}`}
                    >
                      {y}
                    </div>
                  ))}
                  {heatmap.regions.map((region, ri) => (
                    <Fragment key={region}>
                      <div
                        className="sticky left-0 z-10 bg-slate-900 px-2 py-1 text-[10px] text-slate-400"
                        title={region}
                      >
                        <span className="line-clamp-2">{region}</span>
                      </div>
                      {heatmap.years.map((y, yi) => {
                        const v = heatmap.matrix[ri]?.[yi] ?? null;
                        const focused = yi === heatmapYearIndex;
                        return (
                          <div
                            key={`${region}-${y}`}
                            className={`relative min-h-[1.75rem] min-w-[1.5rem] ${
                              focused ? "ring-1 ring-cyan-500/70 ring-inset" : ""
                            }`}
                            style={{
                              backgroundColor: heatmapCellColor(
                                v,
                                heatmap.min,
                                heatmap.max,
                              ),
                            }}
                            title={`${region}, ${y}: ${
                              v === null ? "no data" : v.toFixed(4)
                            }`}
                          />
                        );
                      })}
                    </Fragment>
                  ))}
                </div>
              </div>
            </ChartCard>
          ) : null}

          {regionsList.length > 0 && yearsList.length > 0 ? (
            <ChartCard title="Mean C_sa by region (choose year)">
              <div className="mb-3">
                <label className="flex flex-wrap items-center gap-2 text-xs text-slate-400">
                  <span>Year</span>
                  <select
                    className="rounded-md border border-slate-700 bg-slate-900 px-2 py-1 text-sm text-slate-200"
                    value={regionBarYear}
                    onChange={(e) =>
                      setRegionBarYear(Number(e.target.value))
                    }
                  >
                    {yearsList.map((y) => (
                      <option key={y} value={y}>
                        {y}
                      </option>
                    ))}
                  </select>
                </label>
              </div>
              {regionBarsForYear.length > 0 ? (
                <div className="h-72 w-full">
                  <ResponsiveContainer width="100%" height="100%">
                    <BarChart
                      data={regionBarsForYear}
                      layout="vertical"
                      margin={{ left: 8 }}
                    >
                      <CartesianGrid strokeDasharray="3 3" stroke="#334155" />
                      <XAxis
                        type="number"
                        stroke="#94a3b8"
                        tick={{ fill: "#94a3b8", fontSize: 12 }}
                      />
                      <YAxis
                        type="category"
                        dataKey="region"
                        width={120}
                        stroke="#94a3b8"
                        tick={{ fill: "#94a3b8", fontSize: 11 }}
                      />
                      <Tooltip
                        contentStyle={{
                          backgroundColor: "#0f172a",
                          border: "1px solid #334155",
                          borderRadius: "8px",
                        }}
                      />
                      <Bar
                        dataKey="meanC_sa"
                        name="Mean C_sa"
                        fill="#34d399"
                        radius={[0, 4, 4, 0]}
                      />
                    </BarChart>
                  </ResponsiveContainer>
                </div>
              ) : (
                <p className="text-sm text-slate-500">
                  No C_sa values for this year.
                </p>
              )}
            </ChartCard>
          ) : null}

          {regionsList.length > 0 ? (
            <ChartCard title="Coral cover through time (selected region)">
              <p className="mb-2 text-xs text-slate-500">
                Shaded band: interquartile range of C_sa in that region each year
                (across reefs and ensembles).
                {interventionGrouped.length > 0 ? (
                  <>
                    {" "}
                    Dashed vertical lines: intervention starts from preamble
                    (hover for details).
                  </>
                ) : null}
              </p>
              <div className="mb-3">
                <label className="flex flex-wrap items-center gap-2 text-xs text-slate-400">
                  <span>Region</span>
                  <select
                    className="max-w-full rounded-md border border-slate-700 bg-slate-900 px-2 py-1 text-sm text-slate-200"
                    value={selectedRegion}
                    onChange={(e) => setSelectedRegion(e.target.value)}
                  >
                    {regionsList.map((r) => (
                      <option key={r} value={r}>
                        {r}
                      </option>
                    ))}
                  </select>
                </label>
              </div>
              {singleRegionSeries.length > 0 ? (
                <div className="h-64 w-full">
                  <ResponsiveContainer width="100%" height="100%">
                    <ComposedChart data={regionCoralChartData}>
                      <CartesianGrid strokeDasharray="3 3" stroke="#334155" />
                      <XAxis
                        dataKey="year"
                        stroke="#94a3b8"
                        tick={{ fill: "#94a3b8", fontSize: 12 }}
                      />
                      <YAxis
                        stroke="#94a3b8"
                        tick={{ fill: "#94a3b8", fontSize: 12 }}
                        label={{
                          value: "Mean C_sa",
                          angle: -90,
                          position: "insideLeft",
                          fill: "#94a3b8",
                          fontSize: 11,
                        }}
                      />
                      <Tooltip
                        content={
                          <RegionCoralTooltip
                            interventionByYear={interventionTooltipByYear}
                          />
                        }
                      />
                      <Legend />
                      <Customized
                        component={(p) => (
                          <InterventionVerticalMarkers
                            grouped={interventionGrouped}
                            {...interventionChartGeometry(p)}
                          />
                        )}
                      />
                      <Area
                        type="monotone"
                        dataKey="q1C_sa"
                        stackId="regionIqr"
                        stroke="none"
                        fill="transparent"
                        fillOpacity={0}
                        legendType="none"
                        isAnimationActive={false}
                      />
                      <Area
                        type="monotone"
                        dataKey="iqrSpan"
                        stackId="regionIqr"
                        stroke="none"
                        fill="#22d3ee"
                        fillOpacity={0.22}
                        name="C_sa IQR (25–75%)"
                        isAnimationActive={false}
                      />
                      <Line
                        type="monotone"
                        dataKey="meanC_sa"
                        name="Mean C_sa"
                        stroke="#22d3ee"
                        dot={{ r: 2, fill: "#22d3ee" }}
                        strokeWidth={2}
                        connectNulls
                      />
                    </ComposedChart>
                  </ResponsiveContainer>
                </div>
              ) : (
                <p className="text-sm text-slate-500">
                  No series for this region.
                </p>
              )}
            </ChartCard>
          ) : null}

          {reefPoints.length > 0 ? (
            <ChartCard title="Reefs in latest year: location vs C_sa">
              <div className="h-80 w-full">
                <ResponsiveContainer width="100%" height="100%">
                  <ScatterChart margin={{ top: 8, right: 8, bottom: 8, left: 8 }}>
                    <CartesianGrid strokeDasharray="3 3" stroke="#334155" />
                    <XAxis
                      type="number"
                      dataKey="lon"
                      name="Longitude"
                      stroke="#94a3b8"
                      tick={{ fill: "#94a3b8", fontSize: 12 }}
                    />
                    <YAxis
                      type="number"
                      dataKey="lat"
                      name="Latitude"
                      stroke="#94a3b8"
                      tick={{ fill: "#94a3b8", fontSize: 12 }}
                    />
                    <ZAxis type="number" dataKey="c_sa" range={[20, 400]} name="C_sa" />
                    <Tooltip
                      cursor={{ strokeDasharray: "3 3" }}
                      contentStyle={{
                        backgroundColor: "#0f172a",
                        border: "1px solid #334155",
                        borderRadius: "8px",
                      }}
                      formatter={(value: number, name: string) => [
                        typeof value === "number" ? value.toFixed(3) : value,
                        name,
                      ]}
                    />
                    <Scatter name="Reefs" data={reefPoints} fill="#a78bfa" />
                  </ScatterChart>
                </ResponsiveContainer>
              </div>
            </ChartCard>
          ) : null}
        </section>
      ) : null}
    </div>
  );
}

type YearChartRow = YearPoint & { iqrSpan: number | null };

function MultiRegionYearTooltip({
  active,
  payload,
  label,
  interventionByYear,
}: {
  active?: boolean;
  payload?: {
    name?: string;
    value?: number | string;
    color?: string;
    dataKey?: string | number;
  }[];
  label?: string | number;
  interventionByYear?: Map<number, string>;
}) {
  if (!active || !payload?.length) return null;
  const y = typeof label === "number" ? label : Number(label);
  const interventionText =
    Number.isFinite(y) && interventionByYear?.get(y);
  return (
    <div
      className="rounded-lg border border-slate-700 px-3 py-2 text-xs shadow-lg"
      style={{
        backgroundColor: "#0f172a",
        color: "#e2e8f0",
      }}
    >
      <div className="mb-1 font-medium text-slate-200">Year {label}</div>
      {payload.map((e, i) => {
        const v = e.value;
        const shown =
          typeof v === "number" && Number.isFinite(v) ? v.toFixed(4) : v;
        return (
          <div key={i} className="flex items-center gap-2">
            <span
              className="inline-block h-2 w-2 shrink-0 rounded-full"
              style={{ backgroundColor: e.color ?? "#94a3b8" }}
            />
            <span className="text-slate-300">{e.name}</span>
            <span className="font-mono text-slate-100">{shown}</span>
          </div>
        );
      })}
      {interventionText ? (
        <div className="mt-2 max-w-xs border-t border-slate-700 pt-2 whitespace-pre-wrap text-slate-300">
          <div className="mb-1 font-medium text-slate-400">
            Intervention (preamble)
          </div>
          {interventionText}
        </div>
      ) : null}
    </div>
  );
}

function GlobalCoralYearTooltip({
  active,
  payload,
  label,
  interventionByYear,
}: {
  active?: boolean;
  payload?: { payload: YearChartRow }[];
  label?: string | number;
  interventionByYear?: Map<number, string>;
}) {
  if (!active || !payload?.length) return null;
  const d = payload[0]!.payload;
  const y = typeof label === "number" ? label : Number(label);
  const interventionText =
    Number.isFinite(y) && interventionByYear?.get(y);
  return (
    <div
      className="rounded-lg border border-slate-700 px-3 py-2 text-xs shadow-lg"
      style={{
        backgroundColor: "#0f172a",
        color: "#e2e8f0",
      }}
    >
      <div className="mb-1 font-medium text-slate-200">Year {label}</div>
      {d.meanC_sa != null ? (
        <div>Mean C_sa: {d.meanC_sa.toFixed(4)}</div>
      ) : null}
      {d.q1C_sa != null && d.q3C_sa != null ? (
        <div className="text-slate-400">
          IQR: {d.q1C_sa.toFixed(4)} – {d.q3C_sa.toFixed(4)}
        </div>
      ) : null}
      {d.meanDHW != null ? (
        <div>Mean DHW: {d.meanDHW.toFixed(4)}</div>
      ) : null}
      {interventionText ? (
        <div className="mt-2 max-w-xs border-t border-slate-700 pt-2 whitespace-pre-wrap text-slate-300">
          <div className="mb-1 font-medium text-slate-400">
            Intervention (preamble)
          </div>
          {interventionText}
        </div>
      ) : null}
    </div>
  );
}

function RegionCoralTooltip({
  active,
  payload,
  label,
  interventionByYear,
}: {
  active?: boolean;
  payload?: {
    payload: {
      year: number;
      meanC_sa: number;
      q1C_sa: number;
      q3C_sa: number;
      n: number;
    };
  }[];
  label?: string | number;
  interventionByYear?: Map<number, string>;
}) {
  if (!active || !payload?.length) return null;
  const d = payload[0]!.payload;
  const y = typeof label === "number" ? label : Number(label);
  const interventionText =
    Number.isFinite(y) && interventionByYear?.get(y);
  return (
    <div
      className="rounded-lg border border-slate-700 px-3 py-2 text-xs shadow-lg"
      style={{
        backgroundColor: "#0f172a",
        color: "#e2e8f0",
      }}
    >
      <div className="mb-1 font-medium text-slate-200">Year {label}</div>
      <div>Mean C_sa: {d.meanC_sa.toFixed(4)}</div>
      <div className="text-slate-400">
        IQR: {d.q1C_sa.toFixed(4)} – {d.q3C_sa.toFixed(4)}
      </div>
      <div className="text-slate-500">n = {d.n} rows</div>
      {interventionText ? (
        <div className="mt-2 max-w-xs border-t border-slate-700 pt-2 whitespace-pre-wrap text-slate-300">
          <div className="mb-1 font-medium text-slate-400">
            Intervention (preamble)
          </div>
          {interventionText}
        </div>
      ) : null}
    </div>
  );
}

function ChartCard({
  title,
  children,
}: {
  title: string;
  children: ReactNode;
}) {
  return (
    <div className="rounded-xl border border-slate-800 bg-slate-900/40 p-4">
      <h2 className="mb-3 text-sm font-medium text-slate-300">{title}</h2>
      {children}
    </div>
  );
}
