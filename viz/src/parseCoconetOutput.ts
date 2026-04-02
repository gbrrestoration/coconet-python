import Papa from "papaparse";

const TABLE_HEADER_PREFIX = "Ensemble,";

/** Max preamble lines to scan before giving up (avoids scanning gigabytes of “preamble”). */
const MAX_LINES_SCAN_FOR_HEADER = 250_000;

/** First N lines (non-empty trimmed) recorded as previews for debugging. */
const FIRST_LINE_PREVIEWS = 12;

const LINE_PREVIEW_MAX_CHARS = 240;

const PREAMBLE_SNIPPET_ON_FAILURE = 16_384;

const LARGE_FILE_CHAR_THRESHOLD = 50_000_000;

export type ParsedCoconetOutput = {
  preamble: string;
  headers: string[];
  rows: Record<string, string>[];
  diagnostics: ParseDiagnostics;
};

export type ParseLineHint = {
  lineIndex: number;
  preview: string;
  startsWithEnsembleComma: boolean;
  hasReefId: boolean;
  hasYear: boolean;
};

export type ParseCoconetOptions = {
  /** From `File.size` when loading in the browser — explains “0 chars” vs non-empty file. */
  sourceFileSizeBytes?: number;
  /** Bytes actually passed to `Blob.text()` (full file or prefix). */
  loadedByteLength?: number;
  /** True when `loadedByteLength` is less than `sourceFileSizeBytes`. */
  fileContentTruncated?: boolean;
};

export type ParseDiagnostics = {
  /** Decoded CSV text length; null when the table was parsed via chunked file streaming. */
  textLengthChars: number | null;
  /** True when the table body was parsed with Papa Parse `step` + Blob/File chunks (no whole-file string). */
  parseViaStream: boolean;
  /** Browser-reported file size when provided (may differ from decoded character length). */
  sourceFileSizeBytes: number | null;
  /** Bytes decoded via `Blob.text()` for this parse (prefix or whole file). */
  loadedByteLength: number | null;
  /** Subset of the file was loaded (browser string / memory limits). */
  fileContentTruncated: boolean;
  truncationNote: string | null;
  /** True when input string was empty before any scan (distinct from “no header”). */
  decodedTextEmpty: boolean;
  /** Total newlines in file; omitted for very large inputs to avoid an extra full scan. */
  newlineCount: number | null;
  newlineCountNote: string | null;
  leadingUtf8Bom: boolean;
  scannedLines: number;
  stoppedEarlyMaxLines: boolean;
  tableHeaderFound: boolean;
  tableHeaderLineIndex: number | null;
  tableHeaderCharOffset: number | null;
  firstLinePreviews: { lineIndex: number; content: string }[];
  lineHints: ParseLineHint[];
  rejectionSummary: string | null;
  papaErrors: { type: string; code?: string; message: string; row?: number }[];
  papaRowCount: number | null;
  largeFileNote: string | null;
};

function normalizeLineForHeaderCheck(raw: string): string {
  return raw.replace(/^\uFEFF+/, "").trim();
}

function truncate(s: string, max: number): string {
  if (s.length <= max) return s;
  return `${s.slice(0, max)}…`;
}

/**
 * Single-pass scan: preamble previews, candidate hints, and table header offset
 * without splitting the whole file into an array (critical for multi-GB CSV).
 */
export function scanForTableHeader(text: string): {
  header: { charOffset: number; lineIndex: number; rawLine: string } | null;
  firstLinePreviews: { lineIndex: number; content: string }[];
  lineHints: ParseLineHint[];
  scannedLines: number;
  stoppedEarlyMaxLines: boolean;
  newlinesInScan: number;
} {
  const firstLinePreviews: { lineIndex: number; content: string }[] = [];
  const lineHints: ParseLineHint[] = [];
  let lineStart = 0;
  let lineIndex = 0;
  let previewsCollected = 0;
  let newlinesInScan = 0;
  const n = text.length;
  let stoppedEarlyMaxLines = false;

  for (let i = 0; i <= n; i++) {
    const atEnd = i === n;
    const isNewline = !atEnd && text[i] === "\n";
    if (!atEnd && !isNewline) continue;
    if (isNewline) newlinesInScan++;

    if (lineIndex >= MAX_LINES_SCAN_FOR_HEADER) {
      stoppedEarlyMaxLines = true;
      break;
    }

    let end = i;
    if (end > lineStart && text[end - 1] === "\r") end--;

    const rawLine = text.slice(lineStart, end);
    const line = normalizeLineForHeaderCheck(rawLine);

    if (line.length > 0 && previewsCollected < FIRST_LINE_PREVIEWS) {
      firstLinePreviews.push({
        lineIndex,
        content: truncate(line, LINE_PREVIEW_MAX_CHARS),
      });
      previewsCollected++;
    }

    const lower = line.toLowerCase();
    if (
      line.length > 0 &&
      (lower.includes("ensemble") ||
        lower.includes("reef_id") ||
        lower.includes("reef id"))
    ) {
      const startsWithEnsembleComma = line.startsWith(TABLE_HEADER_PREFIX);
      const hasReefId = line.includes("Reef_ID");
      const hasYear = line.includes("Year");

      if (lineHints.length < 40) {
        lineHints.push({
          lineIndex,
          preview: truncate(line, LINE_PREVIEW_MAX_CHARS),
          startsWithEnsembleComma,
          hasReefId,
          hasYear,
        });
      }
    }

    if (
      line.startsWith(TABLE_HEADER_PREFIX) &&
      line.includes("Reef_ID") &&
      line.includes("Year")
    ) {
      return {
        header: { charOffset: lineStart, lineIndex, rawLine },
        firstLinePreviews,
        lineHints,
        scannedLines: lineIndex + 1,
        stoppedEarlyMaxLines: false,
        newlinesInScan,
      };
    }

    lineStart = i + 1;
    lineIndex++;
  }

  return {
    header: null,
    firstLinePreviews,
    lineHints,
    scannedLines: lineIndex,
    stoppedEarlyMaxLines,
    newlinesInScan,
  };
}

function countNewlinesFull(text: string): number {
  let c = 0;
  for (let i = 0; i < text.length; i++) {
    if (text[i] === "\n") c++;
  }
  return c;
}

export function buildRejectionSummary(
  scan: ReturnType<typeof scanForTableHeader>,
): string | null {
  if (scan.header) return null;
  const parts: string[] = [];
  if (scan.stoppedEarlyMaxLines) {
    parts.push(
      `No header line in the first ${MAX_LINES_SCAN_FOR_HEADER.toLocaleString()} lines.`,
    );
  } else {
    parts.push(
      `Scanned all ${scan.scannedLines.toLocaleString()} lines; no line matched the expected header pattern.`,
    );
  }
  const almost = scan.lineHints.filter(
    (h) =>
      h.startsWithEnsembleComma ||
      (h.hasReefId && h.hasYear) ||
      (h.startsWithEnsembleComma && h.hasReefId),
  );
  if (almost.length > 0) {
    parts.push(
      `Found ${almost.length} line(s) mentioning Ensemble/Reef/Year; see hints below — check column names, spacing, or BOM.`,
    );
  } else if (scan.lineHints.length === 0) {
    parts.push(
      "No line in the scanned region contains “Ensemble”, “Reef_ID”, or “Reef ID” (case-insensitive). File may be wrong format or truncated.",
    );
  }
  return parts.join(" ");
}

function normalizeFileSizeBytes(n: number | undefined): number | null {
  if (n == null || !Number.isFinite(n)) return null;
  const x = Math.floor(n);
  return x >= 0 ? x : null;
}

function buildTruncationNote(
  truncated: boolean,
  loaded: number | null,
  total: number | null,
): string | null {
  if (!truncated || loaded == null || total == null || loaded >= total) {
    return null;
  }
  const loadedMb = (loaded / (1024 * 1024)).toFixed(0);
  const totalMb = (total / (1024 * 1024)).toFixed(0);
  return `Only the first ~${loadedMb} MiB of this ~${totalMb} MiB file was loaded. JavaScript engines cannot hold multi–gigabyte CSVs in one string, so charts and counts use this prefix only. For a full run, export fewer reefs/years or split the table outside the browser.`;
}

export function parseCoconetOutput(
  text: string,
  options?: ParseCoconetOptions,
): ParsedCoconetOutput {
  const sourceFileSizeBytes = normalizeFileSizeBytes(options?.sourceFileSizeBytes);
  const loadedByteLength = normalizeFileSizeBytes(options?.loadedByteLength);
  const fileContentTruncated = Boolean(options?.fileContentTruncated);

  if (text.length === 0) {
    let rejectionSummary: string;
    if (
      sourceFileSizeBytes != null &&
      sourceFileSizeBytes > 0 &&
      loadedByteLength != null &&
      loadedByteLength > 0
    ) {
      rejectionSummary =
        `The first ${loadedByteLength.toLocaleString()} bytes were read, but decoded text is still empty (0 characters). The file may not be UTF-8 text, or the read failed. Expected a UTF-8 CSV. File size on disk: ${sourceFileSizeBytes.toLocaleString()} bytes.`;
    } else if (sourceFileSizeBytes != null && sourceFileSizeBytes > 0) {
      rejectionSummary =
        `Decoded text is empty (0 characters) but the file’s reported size is ${sourceFileSizeBytes.toLocaleString()} bytes. Very large files often exceed a single JavaScript string limit when using File.text() on the whole file; this app retries with a prefix automatically—if you still see this, the prefix read also failed or the file is not UTF-8. Confirm UTF-8 encoding and that the run finished writing.`;
    } else {
      rejectionSummary =
        "No UTF-8 text was loaded (0 characters). The file is likely empty on disk (0 bytes), or output has not been flushed yet. The snippet you see in an editor may be from an unsaved buffer or another file.";
    }
    return {
      preamble: "",
      headers: [],
      rows: [],
      diagnostics: {
        textLengthChars: 0,
        parseViaStream: false,
        sourceFileSizeBytes,
        loadedByteLength,
        fileContentTruncated,
        truncationNote: null,
        decodedTextEmpty: true,
        newlineCount: 0,
        newlineCountNote: null,
        leadingUtf8Bom: false,
        scannedLines: 0,
        stoppedEarlyMaxLines: false,
        tableHeaderFound: false,
        tableHeaderLineIndex: null,
        tableHeaderCharOffset: null,
        firstLinePreviews: [],
        lineHints: [],
        rejectionSummary,
        papaErrors: [],
        papaRowCount: null,
        largeFileNote: null,
      },
    };
  }

  const truncationNote = buildTruncationNote(
    fileContentTruncated,
    loadedByteLength,
    sourceFileSizeBytes,
  );

  const leadingUtf8Bom = text.length > 0 && text.charCodeAt(0) === 0xfeff;

  const scan = scanForTableHeader(text);

  const MAX_CHARS_FOR_FULL_NEWLINE_COUNT = 40_000_000;
  let newlineCount: number | null = null;
  let newlineCountNote: string | null = null;
  if (text.length <= MAX_CHARS_FOR_FULL_NEWLINE_COUNT) {
    newlineCount = countNewlinesFull(text);
  } else {
    newlineCountNote = `Newline count not computed (file > ${(MAX_CHARS_FOR_FULL_NEWLINE_COUNT / 1e6).toFixed(0)}M chars). Scan saw ${scan.newlinesInScan.toLocaleString()} newlines in the scanned region.`;
  }

  const largeFileNote =
    text.length >= LARGE_FILE_CHAR_THRESHOLD
      ? `Input is ~${(text.length / 1e6).toFixed(1)}M characters; the browser may run out of memory when parsing all rows. Consider a smaller extract or a server-side sample.`
      : null;

  const baseDiagnostics: ParseDiagnostics = {
    textLengthChars: text.length,
    parseViaStream: false,
    sourceFileSizeBytes,
    loadedByteLength,
    fileContentTruncated,
    truncationNote,
    decodedTextEmpty: false,
    newlineCount,
    newlineCountNote,
    leadingUtf8Bom,
    scannedLines: scan.scannedLines,
    stoppedEarlyMaxLines: scan.stoppedEarlyMaxLines,
    tableHeaderFound: scan.header != null,
    tableHeaderLineIndex: scan.header?.lineIndex ?? null,
    tableHeaderCharOffset: scan.header?.charOffset ?? null,
    firstLinePreviews: scan.firstLinePreviews,
    lineHints: scan.lineHints,
    rejectionSummary: null,
    papaErrors: [],
    papaRowCount: null,
    largeFileNote,
  };

  if (!scan.header) {
    const rejectionSummary = buildRejectionSummary(scan);
    return {
      preamble: text.slice(0, PREAMBLE_SNIPPET_ON_FAILURE),
      headers: [],
      rows: [],
      diagnostics: {
        ...baseDiagnostics,
        rejectionSummary,
        papaErrors: [],
        papaRowCount: null,
      },
    };
  }

  const preamble = text.slice(0, scan.header.charOffset).trimEnd();
  const csvBody = text.slice(scan.header.charOffset);

  const parsed = Papa.parse<Record<string, string>>(csvBody, {
    header: true,
    skipEmptyLines: true,
    dynamicTyping: false,
    transformHeader: (h) => h.trim(),
  });

  const papaErrors = (parsed.errors ?? []).map((e) => ({
    type: e.type,
    code: e.code,
    message: e.message,
    row: e.row,
  }));

  const headers = parsed.meta.fields?.filter(Boolean) ?? [];
  const rows = (parsed.data ?? []).filter((row) =>
    Object.values(row).some((v) => v !== undefined && String(v).trim() !== ""),
  );

  return {
    preamble,
    headers,
    rows,
    diagnostics: {
      ...baseDiagnostics,
      tableHeaderFound: true,
      rejectionSummary: null,
      papaErrors,
      papaRowCount: rows.length,
    },
  };
}

export function formatDiagnosticsForConsole(d: ParseDiagnostics): string {
  const nl =
    d.newlineCount != null
      ? d.newlineCount.toLocaleString()
      : `(not computed; ${d.newlineCountNote ?? "large file"})`;
  const chars =
    d.textLengthChars != null
      ? d.textLengthChars.toLocaleString()
      : "(streamed; no single decoded string)";
  const lines = [
    `[coconet-viz] parse diagnostics`,
    `  chars: ${chars}  newlines: ${nl}  BOM: ${d.leadingUtf8Bom}`,
    ...(d.parseViaStream ? [`  parse: STREAM (chunked file → row array)`] : []),
    d.sourceFileSizeBytes != null
      ? `  File.size (bytes): ${d.sourceFileSizeBytes.toLocaleString()}`
      : `  File.size: (not provided)`,
    ...(d.decodedTextEmpty ? [`  decoded text: EMPTY`] : []),
    ...(d.fileContentTruncated
      ? [
          `  load: PREFIX ${d.loadedByteLength != null ? d.loadedByteLength.toLocaleString() : "?"} bytes of ${d.sourceFileSizeBytes != null ? d.sourceFileSizeBytes.toLocaleString() : "?"} total`,
        ]
      : []),
    `  header: ${d.tableHeaderFound ? `line ${d.tableHeaderLineIndex} @ char ${d.tableHeaderCharOffset}` : "not found"}`,
    `  scanned lines: ${d.scannedLines.toLocaleString()}${d.stoppedEarlyMaxLines ? " (hit max scan limit)" : ""}`,
  ];
  if (d.rejectionSummary) lines.push(`  reason: ${d.rejectionSummary}`);
  if (d.truncationNote) lines.push(`  truncation: ${d.truncationNote}`);
  if (d.largeFileNote) lines.push(`  note: ${d.largeFileNote}`);
  if (d.papaErrors.length)
    lines.push(`  Papa Parse errors: ${d.papaErrors.length}`);
  if (d.papaRowCount != null) {
    lines.push(`  data rows: ${d.papaRowCount.toLocaleString()}`);
  }
  if (d.firstLinePreviews.length) {
    lines.push("  first non-empty lines:");
    for (const p of d.firstLinePreviews.slice(0, 6)) {
      lines.push(`    [${p.lineIndex}] ${p.content}`);
    }
  }
  if (d.lineHints.length) {
    lines.push("  Ensemble/Reef-related line hints:");
    for (const h of d.lineHints.slice(0, 8)) {
      lines.push(
        `    [${h.lineIndex}] ensemblePrefix=${h.startsWithEnsembleComma} reefId=${h.hasReefId} yearCol=${h.hasYear} | ${h.preview}`,
      );
    }
  }
  return lines.join("\n");
}

export function num(row: Record<string, string>, key: string): number | null {
  const v = row[key];
  if (v === undefined || v === "") return null;
  const n = Number(v);
  return Number.isFinite(n) ? n : null;
}
