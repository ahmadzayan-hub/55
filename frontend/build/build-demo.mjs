// build-demo.mjs — builds a SAMPLE-DATA demo bundle for public hosting
// (Vercel etc). Copies src/ verbatim into a throwaway tree and swaps only
// api.js for mock-api.js, so every component runs unmodified against
// canned data instead of the real local-only backend. Also injects a
// visible "demo" banner via an esbuild `define` flag — the real app build
// (build.mjs) never sets this flag, so nothing here touches the shipped
// product build.
//
// Run with: node build/build-demo.mjs
// Output:   frontend/demo-dist/{index.html, bundle.js, bundle.css}
import { build } from "esbuild";
import { cpSync, copyFileSync, mkdirSync, rmSync, readFileSync, writeFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const here = dirname(fileURLToPath(import.meta.url));
const root = join(here, "..");
const tmpSrc = join(here, ".demo-src");
const outDir = join(root, "demo-dist");

rmSync(tmpSrc, { recursive: true, force: true });
mkdirSync(tmpSrc, { recursive: true });
cpSync(join(root, "src"), tmpSrc, { recursive: true });
copyFileSync(join(here, "mock-api.js"), join(tmpSrc, "api.js"));

rmSync(outDir, { recursive: true, force: true });
mkdirSync(outDir, { recursive: true });

await build({
  entryPoints: [join(tmpSrc, "main.jsx")],
  bundle: true,
  minify: true,
  sourcemap: false,
  target: ["chrome100", "edge100", "firefox100", "safari15"],
  outfile: join(outDir, "bundle.js"),
  jsx: "automatic",
  loader: { ".css": "css" },
  define: { "process.env.DEMO": '"true"' },
  logLevel: "info",
});

// demo-dist/ is deployed as the site root (no /dist subfolder there, unlike
// the real app where server.py serves dist/ alongside index.html) — rewrite
// the asset paths accordingly.
const html = readFileSync(join(root, "index.html"), "utf8")
  .replace('href="/dist/bundle.css"', 'href="/bundle.css"')
  .replace('src="/dist/bundle.js"', 'src="/bundle.js"');
writeFileSync(join(outDir, "index.html"), html);

rmSync(tmpSrc, { recursive: true, force: true });
console.log("Built frontend/demo-dist/ (sample-data demo, safe for public hosting)");
