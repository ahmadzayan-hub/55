import React, { useEffect, useState } from "react";
import { runAgent } from "../api.js";

const TOOL_LABEL = {
  search_knowledge_base: "🔎 Searched knowledge base",
  read_document: "📄 Read document",
  get_current_datetime: "🕒 Checked date/time",
  calculate: "🧮 Calculated",
  web_search: "🌐 Searched the web",
};

function StepCard({ step }) {
  if (step.type === "answer") {
    return (
      <div className="bubble-a" dir="auto">
        {step.content}
        {step.truncated && (
          <div style={{ marginTop: 8, fontSize: 11.5, color: "var(--warn)" }}>
            Stopped after the step limit — this answer may be incomplete.
          </div>
        )}
      </div>
    );
  }
  const label = TOOL_LABEL[step.tool] || step.tool;
  return (
    <div className={"toolstep" + (step.network ? " network" : "")}>
      <div className="toolstep-head">
        <span>{label}</span>
        {step.network && <span className="badge">leaves this machine</span>}
      </div>
      <div className="toolstep-args">{JSON.stringify(step.args)}</div>
      <div className="toolstep-result">{step.result}</div>
    </div>
  );
}

export default function Agent({ models, kbs, hasKey, onNeedKey }) {
  const [model, setModel] = useState("");
  const [kbIds, setKbIds] = useState([]);
  const [allowWeb, setAllowWeb] = useState(false);
  const [input, setInput] = useState("");
  const [running, setRunning] = useState(false);
  const [turns, setTurns] = useState([]); // [{role:'user',content} | {role:'agent', steps:[...]}]
  const [error, setError] = useState("");

  useEffect(() => {
    if (!model && models && models.length) setModel(models[0].id);
  }, [models, model]);

  function toggleKb(id) {
    setKbIds((cur) => (cur.includes(id) ? cur.filter((x) => x !== id) : [...cur, id]));
  }

  function historyForApi() {
    // Flatten prior turns into plain chat messages (system prompt is added server-side).
    const msgs = [];
    for (const t of turns) {
      if (t.role === "user") msgs.push({ role: "user", content: t.content });
      else {
        const answer = t.steps.find((s) => s.type === "answer");
        if (answer) msgs.push({ role: "assistant", content: answer.content });
      }
    }
    return msgs;
  }

  async function send() {
    const text = input.trim();
    if (!text) return;
    if (!hasKey) {
      onNeedKey();
      return;
    }
    setError("");
    setInput("");
    setRunning(true);
    const nextTurns = [...turns, { role: "user", content: text }];
    setTurns(nextTurns);

    try {
      const result = await runAgent({
        model,
        kbIds,
        allowWeb,
        history: [...historyForApi(), { role: "user", content: text }],
      });
      setTurns((t) => [...t, { role: "agent", steps: result.steps || [] }]);
    } catch (e) {
      setError(e.message);
    }
    setRunning(false);
  }

  function onKeyDown(e) {
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault();
      send();
    }
  }

  return (
    <section className="view active" aria-label="Agent">
      <h1>Agent</h1>
      <p className="sub">
        A tool-using agent: it decides when to search your knowledge bases, read a specific
        document, check the date, or do math — and shows every step it takes.
      </p>

      <div className="chatwrap">
        <div className="card">
          <div className="k">Session</div>
          <div style={{ marginTop: 10 }} className="setrow">
            <span>Model</span>
          </div>
          <select style={{ width: "100%" }} value={model} onChange={(e) => setModel(e.target.value)}>
            {(models || []).map((m) => (
              <option key={m.id} value={m.id}>
                {m.name || m.id}
              </option>
            ))}
          </select>
          <p style={{ fontSize: 11, color: "var(--muted)", marginTop: 4 }}>
            Tool calling needs a tool-capable model (e.g. qwen3).
          </p>

          <div style={{ marginTop: 12 }} className="setrow">
            <span>Knowledge bases</span>
          </div>
          <div style={{ display: "flex", flexDirection: "column", gap: 4 }}>
            {(kbs || []).map((k) => (
              <label key={k.id} style={{ display: "flex", alignItems: "center", gap: 8, fontSize: 12.5 }}>
                <input type="checkbox" checked={kbIds.includes(k.id)} onChange={() => toggleKb(k.id)} />
                {k.name}
              </label>
            ))}
            {!kbs?.length && <span className="empty" style={{ padding: 8 }}>None available</span>}
          </div>

          <div className="notice" style={{ marginTop: 14 }}>
            <label style={{ display: "flex", alignItems: "center", gap: 8, cursor: "pointer" }}>
              <input type="checkbox" checked={allowWeb} onChange={(e) => setAllowWeb(e.target.checked)} />
              <span>
                <b>Allow web search</b> — sends queries outside this machine. Off by default; must be
                enabled every session.
              </span>
            </label>
          </div>
        </div>

        <div className="chatpane">
          <div className="chathead">
            <b>Agent trace</b>
          </div>
          <div className="msgs">
            {!turns.length && (
              <div className="bubble-a" dir="auto">
                Ask something — I'll show each tool I use before the final answer.
              </div>
            )}
            {turns.map((t, i) =>
              t.role === "user" ? (
                <div className="bubble-u" dir="auto" key={i}>
                  {t.content}
                </div>
              ) : (
                <div key={i} style={{ display: "flex", flexDirection: "column", gap: 8 }}>
                  {t.steps.map((s, j) => (
                    <StepCard step={s} key={j} />
                  ))}
                </div>
              )
            )}
            {running && <div className="bubble-a">Working…</div>}
            {error && <div className="bubble-a" style={{ color: "var(--bad)" }}>Error: {error}</div>}
          </div>
          <div className="composer">
            <textarea
              placeholder="Ask the agent… (Enter to send, Shift+Enter for newline)"
              value={input}
              onChange={(e) => setInput(e.target.value)}
              onKeyDown={onKeyDown}
            />
            <button className="send" onClick={send} disabled={running} title="Send">
              ➤
            </button>
          </div>
        </div>
      </div>
    </section>
  );
}
