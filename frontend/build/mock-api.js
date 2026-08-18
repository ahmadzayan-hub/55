// mock-api.js — demo-only data layer. Swapped in for src/api.js by
// build-demo.mjs so the DEMO deployment (Vercel) never calls a real
// backend. Same export surface as src/api.js — components are unmodified.

const DEMO_ANSWER = `ATC (Automatic Train Control) systems are designed to ensure train safety and optimize operations. The architecture has three subsystems:

1. Wayside subsystem — trackside balises, beacons, transponders, and wayside controllers.
2. Onboard subsystem — the onboard computer, Driver Machine Interface (DMI), and speed/odometry sensors.
3. Control center subsystem — centralized monitoring, traffic management, and data logging.

Sources: ATC_System_Architecture.pdf (p. 12), Railway_Signalling_Standards.pdf (p. 45).`;

export function getKey() {
  return "demo-key";
}
export function setKey() {
  /* no-op in demo mode */
}

export async function ollamaVersion() {
  return { version: "0.3.12" };
}
export async function ollamaPs() {
  return { models: [{ name: "qwen3:4b", size: 2.6e9 }] };
}
export async function owuiHealthy() {
  return true;
}
export async function sysStats() {
  return { total: 16, free: 7.4, cpu: 23 };
}
export async function owuiModels() {
  return [
    { id: "qwen3:4b", name: "Qwen3 4B" },
    { id: "gemma3:4b", name: "Gemma3 4B" },
  ];
}
export async function owuiKnowledge() {
  return [
    {
      id: "kb-railway",
      name: "Railway Engineering",
      files: [
        { id: "f1", meta: { name: "ATC_System_Architecture.pdf", size: 2.4e6 }, created_at: 1737331200 },
        { id: "f2", meta: { name: "Railway_Signalling_Standards.pdf", size: 5.7e6 }, created_at: 1737244800 },
      ],
    },
    {
      id: "kb-mba",
      name: "MBA Learning",
      files: [{ id: "f3", meta: { name: "MBA_Strategy_Framework.pptx", size: 3.1e6 }, created_at: 1737158400 }],
    },
    {
      id: "kb-biz",
      name: "Business Strategy",
      files: [{ id: "f4", meta: { name: "Market_Analysis_2026.xlsx", size: 2.8e6 }, created_at: 1737072000 }],
    },
  ];
}

function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

// Matches src/api.js's real signature: streamChat({model,kbId,history}, onDelta)
export async function streamChat(_opts, onDelta) {
  const words = DEMO_ANSWER.split(" ");
  let full = "";
  for (const w of words) {
    full += (full ? " " : "") + w;
    if (onDelta) onDelta(full);
    await sleep(18);
  }
  return full;
}

export async function runAgent({ allowWeb } = {}) {
  await sleep(500);
  const steps = [
    {
      type: "tool",
      tool: "search_knowledge_base",
      args: { query: "ATC architecture" },
      result: "[1] (ATC_System_Architecture.pdf) ATC systems use balises and transponders for train detection and onboard DMI for driver interaction.",
      network: false,
    },
    { type: "tool", tool: "calculate", args: { expression: "6*7" }, result: "42", network: false },
  ];
  if (allowWeb) {
    steps.push({
      type: "tool",
      tool: "web_search",
      args: { query: "CBTC vs ATC industry comparison 2026" },
      result: "- CBTC moving-block systems vs fixed-block ATC — industry overview\n  (demo result — no real network call was made)",
      network: true,
    });
  }
  const answer =
    "Based on the wayside/onboard/control-center architecture (ATC_System_Architecture.pdf), and 6×7 = 42 as requested.";
  steps.push({ type: "answer", content: answer });
  return { steps, answer };
}

export function fmtSize(b) {
  if (b == null) return "—";
  if (b > 1e9) return (b / 1e9).toFixed(1) + " GB";
  if (b > 1e6) return (b / 1e6).toFixed(1) + " MB";
  return Math.round(b / 1e3) + " KB";
}
