/**
 * Decode a modest-sized file as one UTF-8 string. Files larger than
 * {@link SAFE_FULL_READ_BYTES} use chunked streaming in `streamCoCoNetFile.ts` instead,
 * because a single JS string cannot span multi–gigabyte CSVs.
 */
export const SAFE_FULL_READ_BYTES = 180 * 1024 * 1024;

/** Fallback prefix when a full read returns empty on a non-empty file (rare). */
const PREFIX_READ_BYTES = 64 * 1024 * 1024;

export type ReadModelOutputFileResult = {
  text: string;
  fileSize: number;
  loadedBytes: number;
  truncated: boolean;
};

export async function readModelOutputFile(
  file: File,
): Promise<ReadModelOutputFileResult> {
  const fileSize = file.size;

  if (fileSize === 0) {
    const text = await file.text();
    return { text, fileSize, loadedBytes: 0, truncated: false };
  }

  let text = await file.text();
  if (text.length === 0) {
    const loadedBytes = Math.min(PREFIX_READ_BYTES, fileSize);
    text = await file.slice(0, loadedBytes).text();
    return {
      text,
      fileSize,
      loadedBytes,
      truncated: loadedBytes < fileSize,
    };
  }

  return {
    text,
    fileSize,
    loadedBytes: fileSize,
    truncated: false,
  };
}
