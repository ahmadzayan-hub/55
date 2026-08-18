import React, { useEffect, useRef, useState } from "react";
import { streamChat } from "../api.js";

const GREETING = "مرحباً — Ready. Ask in English or Arabic. اسألني بالعربية أو الإنجليزية.";

export default function Chat({ models, kbs, hasKey, onNeedKey, resetSignal }) {
  const [model, setModel] = useState("");
  const [kbId, setKbId] = useState("");
  const [title, setTitle] = useState("New conversation");
  const [messages, setMessages] = useState([{ role: "assistant", content: GREETING }]);
  const [input, setInput] = useState("");
  const [sending, setSending] = useState(false);
  const msgsRef = useRef(null);
  const historyRef = useRef([]); // role/content pairs sent to the API (excludes the greeting)

  useEffect(() => {
    if (!model && models && models.length) setModel(models[0].id);
  }, [models, model]);

  useEffect(() => {
    if (msgsRef.current) msgsRef.current.scrollTop = msgsRef.current.scrollHeight;
  }, [messages]);

  // The sidebar's "New Chat" button bumps resetSignal in App; react to it here.
  useEffect(() => {
    if (resetSignal === undefined) return;
    historyRef.current = [];
    setMessages([{ role: "assistant", content: GREETING }]);
    setTitle("New conversation");
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [resetSignal]);

  async function send() {
    const text = input.trim();
    if (!text) return;
    if (!hasKey) {
      onNeedKey();
      return;
    }
    setInput("");
    setSending(true);
    if (title === "New conversation") setTitle(text.slice(0, 60));

    setMessages((m) => [...m, { role: "user", content: text }, { role: "assistant", content: "…" }]);
    historyRef.current = [...historyRef.current, { role: "user", content: text }];

    try {
      const full = await streamChat(
        { model, kbId, history: historyRef.current },
        (partial) => {
          setMessages((m) => {
            const copy = m.slice();
            copy[copy.length - 1] = { role: "assistant", content: partial };
            return copy;
          });
        }
      );
      if (full) historyRef.current = [...historyRef.current, { role: "assistant", content: full }];
      else
        setMessages((m) => {
          const copy = m.slice();
          copy[copy.length - 1] = {
            role: "assistant",
            content: "(empty response — is the model loaded? Check Ollama.)",
          };
          return copy;
        });
    } catch (e) {
      setMessages((m) => {
        const copy = m.slice();
        copy[copy.length - 1] = { role: "assistant", content: "Error: " + e.message };
        return copy;
      });
    }
    setSending(false);
  }

  function onKeyDown(e) {
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault();
      send();
    }
  }

  return (
    <section className="view active" aria-label="Chat">
      <h1>Chat</h1>
      <p className="sub">Answers stream from your local model; pick a knowledge base for source-grounded RAG.</p>
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
          <div style={{ marginTop: 10 }} className="setrow">
            <span>Knowledge base</span>
          </div>
          <select style={{ width: "100%" }} value={kbId} onChange={(e) => setKbId(e.target.value)}>
            <option value="">None (model only)</option>
            {(kbs || []).map((k) => (
              <option key={k.id} value={k.id}>
                {k.name}
              </option>
            ))}
          </select>
          <p style={{ fontSize: 11.5, color: "var(--muted)", marginTop: 12 }}>
            With a knowledge base selected, retrieved passages ground the answer and the
            assistant is instructed to cite documents and refuse when evidence is missing.
          </p>
        </div>

        <div className="chatpane">
          <div className="chathead">
            <b>{title}</b>
          </div>
          <div className="msgs" ref={msgsRef}>
            {messages.map((m, i) => (
              <div key={i} className={m.role === "user" ? "bubble-u" : "bubble-a"} dir="auto">
                {m.content}
              </div>
            ))}
          </div>
          <div className="composer">
            <textarea
              placeholder="Message… (Enter to send, Shift+Enter for newline)"
              value={input}
              onChange={(e) => setInput(e.target.value)}
              onKeyDown={onKeyDown}
            />
            <button className="send" onClick={send} disabled={sending} title="Send">
              ➤
            </button>
          </div>
        </div>
      </div>
    </section>
  );
}
