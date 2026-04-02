#!/usr/bin/env node
import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { parseCoconetOutputFile } from "./src/parseCoconetOutput.js";
import {
  configureLogging,
  log,
  logErrorStackIfDebug,
} from "./src/logger.js";
import {
  aggregateByYear,
  buildRegionYearHeatmap,
  meanCsaByRegionForYear,
  meanCsaSeriesForRegionWithSpread,
  multiLineRegionCoralSeries,
  reefScatterLatestYear,
  sortedYears,
  uniqueRegionsSorted,
} from "./src/aggregates.js";
import {
  buildGlobalCoralDhwSpec,
  buildHeatmapSpec,
  buildRegionCoralSpreadSpec,
  buildReefScatterSpec,
  buildRegionBarSpec,
  buildRegionMultiLineSpec,
} from "./src/charts.js";
import { renderSpecToPng } from "./src/render.js";

const CHART_WIDTH = 1200;
const CHART_HEIGHT = 700;

const SCRIPT_PATH = fileURLToPath(import.meta.url);

function printHelp() {
  console.log(`gen-charts

Generate static PNG charts from CoCoNet output.csv files.

Usage:
  gen-charts --input <path/to/output.csv> [--output-dir outputs/charts]

Options:
  --input, -i         Input CSV file path (required)
  --output-dir, -o    Output directory for PNG files (default: ./outputs/charts)
  --verbose, -v       Verbose logging (same as --log-level debug)
  --log-level <lvl>   error | warn | info | debug (default: info). Overrides GEN_CHARTS_LOG.
  --help, -h          Show this help text

Environment:
  GEN_CHARTS_LOG      Default log level if --log-level is not set (error|warn|info|debug)
`);
}

function parseArgs(argv) {
  const args = {
    input: null,
    outputDir: path.resolve(process.cwd(), "outputs/charts"),
    help: false,
    verbose: false,
    logLevel: null,
  };

  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === "--help" || a === "-h") {
      args.help = true;
      continue;
    }
    if (a === "--verbose" || a === "-v") {
      args.verbose = true;
      continue;
    }
    if (a === "--log-level") {
      args.logLevel = argv[i + 1] ?? null;
      i += 1;
      continue;
    }
    if (a === "--input" || a === "-i") {
      args.input = argv[i + 1] ?? null;
      i += 1;
      continue;
    }
    if (a === "--output-dir" || a === "-o") {
      args.outputDir = path.resolve(process.cwd(), argv[i + 1] ?? "");
      i += 1;
      continue;
    }
    throw new Error(`Unknown argument: ${a}`);
  }

  return args;
}

async function ensureDir(dirPath) {
  await fs.mkdir(dirPath, { recursive: true });
}

async function writeChart(filePath, spec) {
  const label = path.basename(filePath);
  const pngBytes = await renderSpecToPng(spec, label);
  await fs.writeFile(filePath, pngBytes);
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  if (args.help) {
    printHelp();
    return;
  }

  configureLogging({ verbose: args.verbose, logLevel: args.logLevel });

  log.info("gen-charts starting", {
    node: process.version,
    cwd: process.cwd(),
    script: SCRIPT_PATH,
  });

  if (!args.input) {
    throw new Error("Missing required --input <path/to/output.csv>.");
  }

  const inputPath = path.resolve(process.cwd(), args.input);
  log.info("Resolved paths", { input: inputPath, outputDir: args.outputDir });

  const parsed = await parseCoconetOutputFile(inputPath);

  if (parsed.headers.length === 0) {
    throw new Error(
      "No output table found. Expected a line starting with Ensemble, Year, Reef_ID, ...",
    );
  }
  if (parsed.rows.length === 0) {
    throw new Error("Input table has headers but no data rows.");
  }

  const years = sortedYears(parsed.rows);
  if (years.length === 0) {
    throw new Error("No valid years found in parsed rows.");
  }
  const latestYear = years[years.length - 1];

  log.info("Building aggregates from parsed rows");
  const aggT0 = performance.now();
  const byYear = aggregateByYear(parsed.rows);
  log.debug(`aggregateByYear: ${(performance.now() - aggT0).toFixed(1)}ms`);

  const tMulti = performance.now();
  const regionMulti = multiLineRegionCoralSeries(parsed.rows);
  log.debug(
    `multiLineRegionCoralSeries: ${(performance.now() - tMulti).toFixed(1)}ms (${regionMulti.regions?.length ?? 0} regions)`,
  );

  const tHeat = performance.now();
  const heatmap = buildRegionYearHeatmap(parsed.rows);
  log.debug(`buildRegionYearHeatmap: ${(performance.now() - tHeat).toFixed(1)}ms`);

  const tBars = performance.now();
  const regionBars = meanCsaByRegionForYear(parsed.rows, latestYear);
  log.debug(
    `meanCsaByRegionForYear(${latestYear}): ${(performance.now() - tBars).toFixed(1)}ms (${regionBars.length} regions)`,
  );

  const tScatter = performance.now();
  const reefPoints = reefScatterLatestYear(parsed.rows, 2000);
  log.debug(
    `reefScatterLatestYear: ${(performance.now() - tScatter).toFixed(1)}ms (${reefPoints.length} points)`,
  );

  const tRegions = performance.now();
  const regions = uniqueRegionsSorted(parsed.rows);
  log.debug(
    `uniqueRegionsSorted: ${(performance.now() - tRegions).toFixed(1)}ms (${regions.length} regions)`,
  );

  const selectedRegion = regions[0] ?? null;
  const singleRegionSeries = selectedRegion
    ? meanCsaSeriesForRegionWithSpread(parsed.rows, selectedRegion)
    : [];
  if (selectedRegion) {
    log.debug(
      `meanCsaSeriesForRegionWithSpread("${selectedRegion}"): ${singleRegionSeries.length} year buckets`,
    );
  }

  log.info(
    `Aggregates done in ${(performance.now() - aggT0).toFixed(1)}ms (latest year ${latestYear}, ${years.length} distinct years)`,
  );

  await ensureDir(args.outputDir);
  log.info(`Output directory ready: ${args.outputDir}`);

  const jobs = [
    {
      filename: "global-coral-dhw-by-year.png",
      spec: buildGlobalCoralDhwSpec(byYear, {
        width: CHART_WIDTH,
        height: CHART_HEIGHT,
      }),
    },
    {
      filename: "mean-csa-by-region-over-time.png",
      spec: buildRegionMultiLineSpec(regionMulti, {
        width: CHART_WIDTH,
        height: CHART_HEIGHT,
      }),
    },
    {
      filename: "mean-csa-heatmap-region-year.png",
      spec: buildHeatmapSpec(heatmap, {
        width: CHART_WIDTH,
        height: CHART_HEIGHT,
      }),
    },
    {
      filename: `mean-csa-by-region-${latestYear}.png`,
      spec: buildRegionBarSpec(regionBars, latestYear, {
        width: CHART_WIDTH,
        height: CHART_HEIGHT,
      }),
    },
    {
      filename: `reef-scatter-latest-year-${latestYear}.png`,
      spec: buildReefScatterSpec(reefPoints, latestYear, {
        width: CHART_WIDTH,
        height: CHART_HEIGHT,
      }),
    },
  ];

  if (selectedRegion && singleRegionSeries.length > 0) {
    jobs.push({
      filename: `mean-csa-region-${selectedRegion.replaceAll(/\s+/g, "_")}.png`,
      spec: buildRegionCoralSpreadSpec(singleRegionSeries, selectedRegion, {
        width: CHART_WIDTH,
        height: CHART_HEIGHT,
      }),
    });
  }

  log.info(`Rendering ${jobs.length} chart(s) at ${CHART_WIDTH}×${CHART_HEIGHT}`);

  const renderT0 = performance.now();
  for (let i = 0; i < jobs.length; i += 1) {
    const job = jobs[i];
    const outPath = path.join(args.outputDir, job.filename);
    log.info(`[${i + 1}/${jobs.length}] Rendering ${job.filename}`);
    const tOne = performance.now();
    await writeChart(outPath, job.spec);
    log.info(
      `Wrote ${outPath} (${(performance.now() - tOne).toFixed(0)}ms)`,
    );
  }
  log.info(
    `All charts rendered in ${(performance.now() - renderT0).toFixed(1)}ms`,
  );

  const summaryPath = path.join(args.outputDir, "summary.json");
  await fs.writeFile(
    summaryPath,
    JSON.stringify(
      {
        source: inputPath,
        rows: parsed.rows.length,
        years: {
          min: years[0],
          max: latestYear,
          count: years.length,
        },
        charts: jobs.map((j) => j.filename),
      },
      null,
      2,
    ),
  );
  log.info(`Wrote ${summaryPath}`);
  log.debug("process.memoryUsage()", process.memoryUsage());
  log.info("gen-charts finished successfully");
}

main().catch((err) => {
  log.error(err instanceof Error ? err.message : String(err));
  logErrorStackIfDebug(err);
  process.exit(1);
});
