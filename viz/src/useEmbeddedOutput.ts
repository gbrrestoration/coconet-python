import { useEffect, useMemo, useState } from "react";

export type EmbeddedLoadMeta = {
  sourceFileSizeBytes?: number;
  loadedByteLength?: number;
  fileContentTruncated?: boolean;
};

export function useEmbeddedMode(): boolean {
  return useMemo(() => {
    if (typeof window === "undefined") return false;
    try {
      return new URLSearchParams(window.location.search).get("embedded") === "1";
    } catch {
      return false;
    }
  }, []);
}

export function useEmbeddedOutput(
  embedded: boolean,
  loadText: (name: string, text: string, meta?: EmbeddedLoadMeta) => void,
  setError: (message: string | null) => void,
): boolean {
  const [loading, setLoading] = useState(embedded);

  useEffect(() => {
    if (!embedded) return;
    let cancelled = false;
    void (async () => {
      try {
        const res = await fetch("/api/model-output");
        if (!res.ok) {
          throw new Error(`Could not load model output (HTTP ${res.status}).`);
        }
        const text = await res.text();
        if (cancelled) return;
        const name =
          res.headers.get("X-Coconet-Filename")?.trim() || "output.csv";
        const sizeHeader = res.headers.get("X-Coconet-File-Size");
        const fileSize = sizeHeader ? Number(sizeHeader) : text.length;
        loadText(name, text, {
          sourceFileSizeBytes: Number.isFinite(fileSize) ? fileSize : text.length,
          loadedByteLength: text.length,
          fileContentTruncated: false,
        });
      } catch (err) {
        if (!cancelled) {
          setError(
            err instanceof Error
              ? err.message
              : "Failed to load output from the desktop app.",
          );
        }
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [embedded, loadText, setError]);

  return loading;
}
