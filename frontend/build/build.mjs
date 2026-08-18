// build.mjs — compiles frontend/src (React + JSX) into frontend/dist/bundle.js
// and frontend/dist/bundle.css. Run with: node build/build.mjs
//
// The output is what ships to the Windows laptop — plain JS/CSS, no Node
// required there, no runtime JSX transform, no CDN fetch. Re-run this after
// editing anything under src/ (see frontend/README.md).
import { build } from "esbuild";
import { mkdirSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const here = dirname(fileURLToPath(import.meta.url));
const distDir = join(here, "..", "dist");
mkdirSync(distDir, { recursive: true });

await build({
  entryPoints: [join(here, "..", "src", "main.jsx")],
  bundle: true,
  minify: true,
  sourcemap: false,
  target: ["chrome100", "edge100", "firefox100", "safari15"],
  outfile: join(distDir, "bundle.js"),
  jsx: "automatic",
  loader: { ".css": "css" },
  logLevel: "info",
});

console.log("Built frontend/dist/bundle.js (+ bundle.css)");
