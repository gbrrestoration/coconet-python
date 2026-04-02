import Papa from "papaparse";
import {
  buildRejectionSummary,
  scanForTableHeader,
  type ParsedCoconetOutput,
  type ParseDiagnostics,
} from "./parseCoconetOutput";

const PREAMBLE_SCAN_MAX_BYTES = 64 * 1024 * 1024;
const INITIAL_PREFIX_BYTES = 2 * 1024 * 1024;

const LARGE_FILE_CHAR_THRESHOLD = 50_000_000;

function utf8ByteLengthOfStringPrefix(text: string, endCharExclusive: number): number {
  return new TextEncoder().encode(text.slice(0, endCharExclusive)).length;
}

/**
 * Read successively larger prefixes until the CoCoNet table header is found or limits hit.
 */
async function loadHeadUntilHeader(file: File): Promise<{
  head: string;
  scan: ReturnType<typeof scanForTableHeader>;
}> {
  let scanBytes = Math.min(INITIAL_PREFIX_BYTES, file.size);

  while (true) {
    const head = await file.slice(0, scanBytes).text();
    const scan = scanForTableHeader(head);

    if (scan.header) return { head, scan };
    if (scan.stoppedEarlyMaxLines) return { head, scan };
    if (scanBytes >= file.size) return { head, scan };

    const next = Math.min(scanBytes * 2, file.size, PREAMBLE_SCAN_MAX_BYTES);
    if (next === scanBytes) return { head, scan };
    scanBytes = next;
  }
}

function pushPapaErrors(
  acc: ParseDiagnostics["papaErrors"],
  errors: unknown,
) {
  if (!Array.isArray(errors)) return;
  for (const e of errors) {
    if (!e || typeof e !== "object") continue;
    const o = e as {
      type?: string;
      code?: string;
      message?: string;
      row?: number;
    };
    acc.push({
      type: String(o.type ?? "unknown"),
      code: o.code,
      message: String(o.message ?? ""),
      row: o.row,
    });
  }
}

/**
 * Parse preamble + table without ever materializing the full CSV as one string.
 * Papa Parse reads the table portion via chunked `Blob` I/O and invokes `step` per row.
 */
export async function streamCoCoNetFromFile(file: File): Promise<ParsedCoconetOutput> {
  const sourceFileSizeBytes = file.size;

  if (file.size === 0) {
    const head = await file.text();
    const scan = scanForTableHeader(head);
    return {
      preamble: "",
      headers: [],
      rows: [],
      diagnostics: {
        textLengthChars: 0,
        parseViaStream: true,
        sourceFileSizeBytes: 0,
        loadedByteLength: 0,
        fileContentTruncated: false,
        truncationNote: null,
        decodedTextEmpty: true,
        newlineCount: 0,
        newlineCountNote: null,
        leadingUtf8Bom: false,
        scannedLines: scan.scannedLines,
        stoppedEarlyMaxLines: scan.stoppedEarlyMaxLines,
        tableHeaderFound: false,
        tableHeaderLineIndex: null,
        tableHeaderCharOffset: null,
        firstLinePreviews: scan.firstLinePreviews,
        lineHints: scan.lineHints,
        rejectionSummary:
          "No UTF-8 text was loaded (0 characters). The file is empty on disk or has not been written yet.",
        papaErrors: [],
        papaRowCount: null,
        largeFileNote: null,
      },
    };
  }

  const { head, scan } = await loadHeadUntilHeader(file);

  const leadingUtf8Bom = head.length > 0 && head.charCodeAt(0) === 0xfeff;

  const sharedMeta = {
    textLengthChars: null as null,
    parseViaStream: true as const,
    sourceFileSizeBytes,
    loadedByteLength: sourceFileSizeBytes,
    fileContentTruncated: false,
    truncationNote: null as null,
    decodedTextEmpty: false as const,
    newlineCount: null as null,
    newlineCountNote: "Not computed for streamed parse (table read in chunks).",
    leadingUtf8Bom,
    scannedLines: scan.scannedLines,
    stoppedEarlyMaxLines: scan.stoppedEarlyMaxLines,
    firstLinePreviews: scan.firstLinePreviews,
    lineHints: scan.lineHints,
    largeFileNote:
      sourceFileSizeBytes >= LARGE_FILE_CHAR_THRESHOLD
        ? "Very large file: all rows are accumulated in memory as objects; the browser may still run out of RAM."
        : null,
  };

  if (!scan.header) {
    const rejectionSummary = buildRejectionSummary(scan);
    return {
      preamble: head.slice(0, 16_384),
      headers: [],
      rows: [],
      diagnostics: {
        ...sharedMeta,
        tableHeaderFound: false,
        tableHeaderLineIndex: null,
        tableHeaderCharOffset: null,
        rejectionSummary,
        papaErrors: [],
        papaRowCount: null,
      },
    };
  }

  const preamble = head.slice(0, scan.header.charOffset).trimEnd();
  const headerByteOffset = utf8ByteLengthOfStringPrefix(head, scan.header.charOffset);
  const tableBlob = file.slice(headerByteOffset);

  const rows: Record<string, string>[] = [];
  const papaErrors: ParseDiagnostics["papaErrors"] = [];
  let headers: string[] = [];

  await new Promise<void>((resolve, reject) => {
    // Papa’s types only list `File`; in browsers `Blob` uses the same slice + FileReader path.
    Papa.parse(tableBlob as unknown as File, {
      header: true,
      skipEmptyLines: true,
      dynamicTyping: false,
      transformHeader: (h) => h.trim(),
      worker: false,
      step: (results) => {
        pushPapaErrors(papaErrors, results.errors);
        const fields = results.meta.fields?.filter(Boolean) as string[] | undefined;
        if (fields?.length) headers = fields;

        const row = results.data as Record<string, string>;
        if (!row || typeof row !== "object" || Array.isArray(row)) return;
        if (
          !Object.values(row).some((v) => v !== undefined && String(v).trim() !== "")
        ) {
          return;
        }
        rows.push(row);
      },
      complete: (results) => {
        pushPapaErrors(papaErrors, results?.errors);
        const fields = results?.meta?.fields?.filter(Boolean) as string[] | undefined;
        if (fields?.length) headers = fields;
        resolve();
      },
      error: (err) => {
        reject(err instanceof Error ? err : new Error(String(err)));
      },
    });
  });

  if (!headers.length && rows.length > 0) {
    headers = Object.keys(rows[0]!);
  }

  return {
    preamble,
    headers,
    rows,
    diagnostics: {
      ...sharedMeta,
      tableHeaderFound: true,
      tableHeaderLineIndex: scan.header.lineIndex,
      tableHeaderCharOffset: scan.header.charOffset,
      rejectionSummary: null,
      papaErrors,
      papaRowCount: rows.length,
    },
  };
}
