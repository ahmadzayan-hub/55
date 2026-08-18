import React from "react";

export default function Assistants({ models }) {
  return (
    <section className="view active" aria-label="Assistants">
      <h1>Assistants</h1>
      <p className="sub">Models and custom assistants published by Open WebUI (Workspace → Models).</p>
      <div className="kbgrid">
        {models && models.length ? (
          models.map((m) => (
            <div className="card kb" key={m.id}>
              <div className="glyph">🤖</div>
              <b>{m.name || m.id}</b>
              <div className="meta">{m.id}</div>
            </div>
          ))
        ) : (
          <div className="empty">Connect in Settings to load…</div>
        )}
      </div>
    </section>
  );
}
