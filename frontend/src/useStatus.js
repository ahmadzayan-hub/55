import { useEffect, useState } from "react";
import { ollamaVersion, ollamaPs, owuiHealthy, sysStats } from "./api.js";

const INITIAL = {
  ollamaUp: false,
  ollamaVersion: "",
  owuiUp: false,
  loadedModels: [],
  ram: { total: null, free: null },
  cpu: null,
};

/** Polls Ollama / Open WebUI / system stats every `intervalMs`. No API key required. */
export function useStatus(intervalMs = 7000) {
  const [status, setStatus] = useState(INITIAL);

  useEffect(() => {
    let cancelled = false;

    async function tick() {
      const next = { ...INITIAL, ram: { ...INITIAL.ram } };
      try {
        const v = await ollamaVersion();
        next.ollamaUp = true;
        next.ollamaVersion = v.version;
        const ps = await ollamaPs();
        next.loadedModels = (ps.models || []).map((m) => ({ name: m.name, size: m.size }));
      } catch {
        /* Ollama down — defaults stand */
      }
      next.owuiUp = await owuiHealthy();
      try {
        const s = await sysStats();
        next.ram = { total: s.total, free: s.free };
        next.cpu = s.cpu;
      } catch {
        /* stats endpoint unavailable (e.g. non-Windows) */
      }
      if (!cancelled) setStatus(next);
    }

    tick();
    const id = setInterval(tick, intervalMs);
    return () => {
      cancelled = true;
      clearInterval(id);
    };
  }, [intervalMs]);

  return status;
}
