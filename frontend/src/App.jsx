import React, { useCallback, useEffect, useState } from "react";
import Sidebar from "./components/Sidebar.jsx";
import Home from "./components/Home.jsx";
import Chat from "./components/Chat.jsx";
import KnowledgeBases from "./components/KnowledgeBases.jsx";
import Assistants from "./components/Assistants.jsx";
import Settings from "./components/Settings.jsx";
import { useStatus } from "./useStatus.js";
import { getKey, owuiModels, owuiKnowledge } from "./api.js";

export default function App() {
  const [view, setView] = useState("home");
  const [chatResetSignal, setChatResetSignal] = useState(0);
  const [models, setModels] = useState(null);
  const [kbs, setKbs] = useState(null);
  const [needKeyNotice, setNeedKeyNotice] = useState(!getKey());

  const status = useStatus(7000);

  const loadData = useCallback(async () => {
    if (!getKey()) {
      setNeedKeyNotice(true);
      throw new Error("API key required");
    }
    const [m, k] = await Promise.all([owuiModels(), owuiKnowledge()]);
    setModels(m);
    setKbs(k);
    setNeedKeyNotice(false);
  }, []);

  useEffect(() => {
    loadData().catch(() => {});
  }, [loadData]);

  function openWebUI() {
    window.open("http://localhost:8080", "_blank");
  }
  function newChat() {
    setChatResetSignal((s) => s + 1);
    setView("chat");
  }

  return (
    <div className="app">
      <Sidebar view={view} onNavigate={setView} onNewChat={newChat} status={status} />
      <main className="main">
        {needKeyNotice && (
          <div className="notice">
            <b>Setup needed</b> — paste your Open WebUI API key in{" "}
            <a
              href="#"
              onClick={(e) => {
                e.preventDefault();
                setView("set");
              }}
            >
              Settings
            </a>{" "}
            (Open WebUI → Settings → Account → API keys) to load knowledge bases and chat.
          </div>
        )}

        {view === "home" && (
          <Home status={status} kbs={kbs} models={models} onNavigate={setView} onOpenWebUI={openWebUI} onRefresh={loadData} />
        )}
        {view === "chat" && (
          <Chat models={models} kbs={kbs} hasKey={!!getKey()} onNeedKey={() => setView("set")} resetSignal={chatResetSignal} />
        )}
        {view === "kb" && <KnowledgeBases kbs={kbs} />}
        {view === "as" && <Assistants models={models} />}
        {view === "set" && <Settings status={status} onSaveKey={loadData} />}
      </main>
    </div>
  );
}
