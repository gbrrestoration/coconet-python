/** @typedef {'error' | 'warn' | 'info' | 'debug'} LogLevelName */

const LEVELS = /** @type {const} */ ({
  error: 0,
  warn: 1,
  info: 2,
  debug: 3,
});

/** @type {number} */
let minLevel = LEVELS.info;

/**
 * @param {string} s
 */
function parseLevelName(s) {
  const k = String(s).toLowerCase();
  if (k in LEVELS) return LEVELS[/** @type {keyof typeof LEVELS} */ (k)];
  return LEVELS.info;
}

/**
 * @param {{ verbose?: boolean, logLevel?: string | null }} [opts]
 */
export function configureLogging(opts = {}) {
  if (opts.verbose) {
    minLevel = LEVELS.debug;
    return;
  }
  if (opts.logLevel) {
    minLevel = parseLevelName(opts.logLevel);
    return;
  }
  if (process.env.GEN_CHARTS_LOG) {
    minLevel = parseLevelName(process.env.GEN_CHARTS_LOG);
    return;
  }
  minLevel = LEVELS.info;
}

function timestamp() {
  return new Date().toISOString();
}

/**
 * @param {keyof typeof LEVELS} levelName
 * @param {string} msg
 * @param {unknown[]} rest
 */
function emit(levelName, msg, ...rest) {
  const levelVal = LEVELS[levelName];
  if (levelVal > minLevel) return;
  const prefix = `[${timestamp()}] [${levelName.toUpperCase()}]`;
  if (rest.length) {
    console.error(prefix, msg, ...rest);
  } else {
    console.error(prefix, msg);
  }
}

export const log = {
  /** @param {string} msg @param {...unknown} rest */
  error: (msg, ...rest) => emit("error", msg, ...rest),
  /** @param {string} msg @param {...unknown} rest */
  warn: (msg, ...rest) => emit("warn", msg, ...rest),
  /** @param {string} msg @param {...unknown} rest */
  info: (msg, ...rest) => emit("info", msg, ...rest),
  /** @param {string} msg @param {...unknown} rest */
  debug: (msg, ...rest) => emit("debug", msg, ...rest),
};

/** @param {unknown} err */
export function logErrorStackIfDebug(err) {
  if (minLevel < LEVELS.debug) return;
  if (err instanceof Error && err.stack) {
    console.error(err.stack);
  }
}
