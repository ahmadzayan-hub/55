import React, { useState } from "react";
import { fmtSize } from "../api.js";

export default function KnowledgeBases({ kbs }) {
  const [selected, setSelected] = useState(null);
  const kb = kbs?.find((k) => k.id === selected);

  return (
    <section className="view active" aria-label="Knowledge bases">
      <h1>Knowledge Bases</h1>
      <p className="sub">Collections indexed by the local RAG pipeline. Upload documents via Open WebUI.</p>

      <div className="kbgrid">
        {kbs && kbs.length ? (
          kbs.map((k) => (
            <div className="card kb" key={k.id}>
              <div className="glyph">📚</div>
              <b>{k.name}</b>
              <div className="meta">{(k.files || []).length} documents</div>
              <div style={{ marginTop: 8 }}>
                <button className="chip" onClick={() => setSelected(k.id)}>
                  View files
                </button>
              </div>
            </div>
          ))
        ) : (
          <div className="empty">
            No knowledge bases yet — create one in Open WebUI → Workspace → Knowledge
          </div>
        )}
      </div>

      <h2>Files in selected knowledge base</h2>
      <div className="tablewrap">
        <table>
          <thead>
            <tr>
              <th>Name</th>
              <th>Uploaded</th>
              <th>Size</th>
            </tr>
          </thead>
          <tbody>
            {kb && kb.files && kb.files.length ? (
              kb.files.map((f) => {
                const m = f.meta || {};
                return (
                  <tr key={f.id}>
                    <td>{m.name || f.id}</td>
                    <td>{f.created_at ? new Date(f.created_at * 1000).toLocaleDateString() : "—"}</td>
                    <td>{fmtSize(m.size)}</td>
                  </tr>
                );
              })
            ) : (
              <tr>
                <td colSpan={3} className="empty">
                  {kb ? "No files in this knowledge base" : "Select a knowledge base above"}
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </section>
  );
}
