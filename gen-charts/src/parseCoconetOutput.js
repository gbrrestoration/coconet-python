import { createReadStream } from "node:fs";
import { stat } from "node:fs/promises";
import readline from "node:readline";
import Papa from "papaparse";
import { log } from "./logger.js";

const ROW_PROGRESS_DEBUG_INTERVAL = 250_000;

const TABLE_HEADER_PREFIX = "Ensemble,";

function findTableStart(lines) {
  for (let i = 0; i < lines.length; i += 1) {
    const line = lines[i].trim();
    if (
      line.startsWith(TABLE_HEADER_PREFIX) &&
      line.includes("Reef_ID") &&
      line.includes("Year")
    ) {
      return i;
    }
  }
  return -1;
}

export function parseCoconetOutput(text) {
  const normalized = text.replace(/\r\n/g, "\n").replace(/\r/g, "\n");
  const lines = normalized.split("\n");
  const start = findTableStart(lines);

  if (start < 0) {
    return { preamble: normalized.trim(), headers: [], rows: [] };
  }

  const preamble = lines.slice(0, start).join("\n").trim();
  const csvBody = lines.slice(start).join("\n");
  const parsed = Papa.parse(csvBody, {
    header: true,
    skipEmptyLines: true,
    dynamicTyping: false,
    transformHeader: (h) => h.trim(),
  });

  if (parsed.errors?.length) {
    const first = parsed.errors[0];
    throw new Error(`CSV parse error at row ${first.row}: ${first.message}`);
  }

  const headers = (parsed.meta.fields ?? []).filter(Boolean);
  const rows = (parsed.data ?? []).filter((row) =>
    Object.values(row).some((v) => v !== undefined && String(v).trim() !== ""),
  );

  return { preamble, headers, rows };
}

/**
 * Parse a CoCoNet output file without reading it into a single string (avoids V8 max string length on multi‑GB files).
 * Data rows are written one line per reef with unquoted fields, so line-based parsing matches the writer.
 */
export async function parseCoconetOutputFile(inputPath) {
  const t0 = performance.now();
  log.info(`Streaming parse: ${inputPath}`);

  try {
    const st = await stat(inputPath);
    log.info(
      `Input file size ${st.size.toLocaleString()} bytes (${(st.size / 1024 ** 3).toFixed(3)} GiB)`,
    );
  } catch (e) {
    log.warn("Could not stat input file (will still attempt read)", e);
  }

  const stream = createReadStream(inputPath, { encoding: "utf8" });
  stream.on("error", (err) => {
    log.error("Read stream error", err);
  });

  const rl = readline.createInterface({ input: stream, crlfDelay: Infinity });

  const preambleLines = [];
  let headers = null;
  const rows = [];
  let dataLineIndex = 0;
  let physicalLineIndex = 0;

  for await (const line of rl) {
    physicalLineIndex += 1;
    const trimmed = line.trim();
    if (headers === null) {
      if (
        trimmed.startsWith(TABLE_HEADER_PREFIX) &&
        trimmed.includes("Reef_ID") &&
        trimmed.includes("Year")
      ) {
        const hr = Papa.parse(line, {
          header: false,
          skipEmptyLines: false,
        });
        if (hr.errors?.length) {
          const e = hr.errors[0];
          throw new Error(`CSV parse error in header: ${e.message}`);
        }
        const raw = hr.data[0] ?? [];
        headers = raw.map((h) => String(h ?? "").trim()).filter(Boolean);
        log.info(
          `Found output table at line ${physicalLineIndex}: ${headers.length} columns`,
        );
        log.debug(
          "Column names:",
          headers.length > 12
            ? `${headers.slice(0, 12).join(", ")} … (+${headers.length - 12} more)`
            : headers.join(", "),
        );
        continue;
      }
      preambleLines.push(line);
      continue;
    }

    if (!trimmed) continue;

    const pr = Papa.parse(line, {
      header: false,
      skipEmptyLines: true,
    });
    if (pr.errors?.length) {
      const e = pr.errors[0];
      throw new Error(
        `CSV parse error at data row ${dataLineIndex}: ${e.message}`,
      );
    }
    dataLineIndex += 1;
    const values = pr.data[0];
    if (!values) continue;

    const row = {};
    for (let i = 0; i < headers.length; i += 1) {
      const h = headers[i];
      row[h] = values[i] !== undefined ? String(values[i]) : "";
    }
    if (
      Object.values(row).some(
        (v) => v !== undefined && String(v).trim() !== "",
      )
    ) {
      rows.push(row);
      if (
        rows.length > 0 &&
        rows.length % ROW_PROGRESS_DEBUG_INTERVAL === 0
      ) {
        log.debug(
          `Parsed ${rows.length.toLocaleString()} data rows (${physicalLineIndex.toLocaleString()} lines read)`,
        );
      }
    }
  }

  const elapsedMs = Math.round((performance.now() - t0) * 100) / 100;

  if (headers === null) {
    log.warn(
      `No Ensemble/Year/Reef_ID header found after ${physicalLineIndex} lines (${elapsedMs}ms)`,
    );
    return {
      preamble: preambleLines.join("\n").trim(),
      headers: [],
      rows: [],
    };
  }

  log.info(
    `Parse finished: ${preambleLines.length} preamble lines, ${rows.length.toLocaleString()} data rows, ${physicalLineIndex.toLocaleString()} total lines, ${elapsedMs}ms`,
  );

  return {
    preamble: preambleLines.join("\n").trim(),
    headers,
    rows,
  };
}

export function num(row, key) {
  const v = row[key];
  if (v === undefined || v === "") return null;
  const n = Number(v);
  return Number.isFinite(n) ? n : null;
}
