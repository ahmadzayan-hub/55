import React, { useState } from "react";
import { getKey, setKey } from "../api.js";

export default function Settings({ status, onSaveKey }) {
  const [value, setValue] = useState(getKey());
  const [result, setResult] = useState("");
  const [saving, setSaving] = useState(false);

  async function save() {
    setKey(value.trim());
    setSaving(true);
    setResult("Testing…");
    try {
      await onSaveKey();
      setResult("Connected ✓");
    } catch (e) {
      setResult("Failed: " + e.message);
    }
    setSaving(false);
  }

  return (
    <section className="view active" aria-label="Settings">
      <h1>Settings</h1>
      <p className="sub">Connection and live system information. Everything stays on 127.0.0.1.</p>
      <div className="setgrid">
        <div className="card">
          <div className="k">Connection</div>
          <div className="setrow" style={{ marginTop: 8 }}>
            <span>Open WebUI API key</span>
          </div>
          <input
            type="password"
            style={{ width: "100%" }}
            placeholder="paste API key (stored in this browser only)"
            value={value}
            onChange={(e) => setValue(e.target.value)}
          />
          <div style={{ marginTop: 10, display: "flex", gap: 8 }}>
            <button className="primary" onClick={save} disabled={saving}>
              Save &amp; test
            </button>
            <span style={{ alignSelf: "center", fontSize: 12.5, color: "var(--muted)" }}>{result}</span>
          </div>
          <div className="setrow" style={{ marginTop: 14 }}>
            <span>Frontend</span>
            <b>127.0.0.1:8090</b>
          </div>
          <div className="setrow">
            <span>Open WebUI</span>
            <b>127.0.0.1:8080 (proxied)</b>
          </div>
          <div className="setrow">
            <span>Ollama</span>
            <b>127.0.0.1:11434 (proxied)</b>
          </div>
        </div>
        <div className="card">
          <div className="k">System information</div>
          <div className="setrow" style={{ marginTop: 8 }}>
            <span>Ollama version</span>
            <b>{status.ollamaUp ? status.ollamaVersion : "—"}</b>
          </div>
          <div className="setrow">
            <span>RAM total</span>
            <b>{status.ram.total != null ? status.ram.total + " GB" : "—"}</b>
          </div>
          <div className="setrow">
            <span>RAM free</span>
            <b>{status.ram.free != null ? status.ram.free + " GB" : "—"}</b>
          </div>
          <div className="setrow">
            <span>CPU load</span>
            <b>{status.cpu != null ? status.cpu + "%" : "—"}</b>
          </div>
          <div className="setrow">
            <span>Loaded models</span>
            <b>{status.loadedModels.map((m) => m.name).join(", ") || "none"}</b>
          </div>
        </div>
      </div>
    </section>
  );
}
