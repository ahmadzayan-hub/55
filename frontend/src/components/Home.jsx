import React from "react";

function greeting() {
  const h = new Date().getHours();
  return (h < 12 ? "Good morning" : h < 18 ? "Good afternoon" : "Good evening") + ", Engineer 👋";
}

export default function Home({ status, kbs, models, onNavigate, onOpenWebUI, onRefresh }) {
  const freeRam = status.ram.total != null ? status.ram.free.toFixed(1) : "—";

  return (
    <section className="view active" aria-label="Home">
      <h1>{greeting()}</h1>
      <p className="sub">Your private AI workspace — live from the local stack.</p>

      <div className="cards">
        <div className="card">
          <div className="k">Knowledge bases</div>
          <div className="stat">{kbs ? kbs.length : "—"}</div>
        </div>
        <div className="card">
          <div className="k">Models installed</div>
          <div className="stat">{models ? models.length : "—"}</div>
        </div>
        <div className="card">
          <div className="k">Loaded in RAM</div>
          <div className="stat">{status.loadedModels.length}</div>
        </div>
        <div className="card">
          <div className="k">Free RAM</div>
          <div className="stat">
            {freeRam} <small>GB</small>
          </div>
        </div>
      </div>

      <h2>Top knowledge bases</h2>
      <div className="kbgrid">
        {kbs && kbs.length ? (
          kbs.slice(0, 4).map((k) => (
            <div className="card kb" key={k.id}>
              <div className="glyph">📚</div>
              <b>{k.name}</b>
              <div className="meta">{(k.files || []).length} documents</div>
            </div>
          ))
        ) : (
          <div className="empty">Connect in Settings to load…</div>
        )}
      </div>

      <h2>Quick actions</h2>
      <div>
        <button className="chip" onClick={() => onNavigate("chat")}>
          💬 New chat
        </button>
        <button className="chip" onClick={() => onNavigate("kb")}>
          📚 Knowledge bases
        </button>
        <button className="chip" onClick={onOpenWebUI}>
          ↗ Open WebUI (uploads &amp; admin)
        </button>
        <button className="chip" onClick={onRefresh}>
          ⟳ Refresh
        </button>
      </div>
    </section>
  );
}
