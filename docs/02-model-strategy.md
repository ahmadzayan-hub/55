# Model Strategy — Selection, Benchmarking, Context Sizing, GPU/NPU Validation

## Model classes for this machine

| Class | Policy | Examples |
|---|---|---|
| 3–4B | **Default starting point** | qwen3:4b, gemma3:4b |
| 7–8B | Advanced configuration, after Gate 6, DEEP ANALYSIS mode only | qwen3:8b |
| 12–14B | Experimental only after benchmarking proves headroom (unlikely on 16 GB) | qwen3:14b |
| 20B+ | **Do not use** | — |

Quantization: use the default Q4_K_M tags. Do not pull fp16 variants.

Storage: Ollama stores models under `%USERPROFILE%\.ollama\models` (override with
`OLLAMA_MODELS`). Budget ≈ 2.6 GB (qwen3:4b) + 3.3 GB (gemma3:4b) + 1.2 GB (bge-m3)
+ 5.2 GB (qwen3:8b, later) ≈ **12 GB** for the full register. Do not hoard models:
`ollama rm <model>` removes losers after the bake-off.

## Baseline procedure (Gate 3)

1. `ollama pull qwen3:4b` — one model only.
2. Interactive smoke test (`ollama run qwen3:4b`): general reasoning, a technical
   explanation, summarize a pasted paragraph, Arabic prompt, English prompt, mixed
   Arabic/English prompt, a Markdown table request, a short business analysis, and
   railway engineering terminology. Verify Arabic answers read correctly RTL.
3. `.\scripts\03-benchmark.ps1 -Model qwen3:4b` — runs the standard prompt set in
   `benchmarks/prompts.json`, records CSV to `reports\`.
4. Only now `ollama pull gemma3:4b` and repeat step 3 with the identical prompts.

## Benchmark metrics (captured by scripts/03-benchmark.ps1)

Per model, per prompt, from Ollama's API response fields:

- **Load time** — `load_duration` (cold-load run recorded separately)
- **Time to first token** — approximated as `load_duration + prompt_eval_duration`
- **Generation speed** — `eval_count / eval_duration` (tok/s)
- **RAM** — `ollama ps` model size + process working set, before/during
- **CPU / GPU utilization** — observe Task Manager → Performance during the run
- **Quality** — human-scored 1–5 per prompt: correctness, Arabic quality, English
  quality, technical reasoning, hallucination tendency (5 = none observed)

## Scorecard (weighted)

| Dimension | Weight | Source |
|---|---|---|
| Quality | 35% | Mean human score across prompt set |
| Speed | 20% | tok/s + TTFT, normalized to best candidate |
| Memory efficiency | 20% | Resident RAM, normalized (lower = better) |
| Technical reasoning | 15% | Human score on engineering/business prompts |
| Arabic/English capability | 10% | Human score on AR/EN/mixed prompts |

Score = Σ(normalized dimension × weight). **The measured winner becomes the
default model** — reputation does not vote. Record the scorecard in
`docs/12-final-report.md` §C/§E.

## Context window management

Do not maximize context. KV-cache RAM grows with context length and is the easiest
way to push a 16 GB machine into paging.

| Setting | Use |
|---|---|
| 4K | LIGHT mode, quick Q&A |
| **8K** | **STANDARD mode default** — right for RAG (system prompt + top-k chunks + answer) |
| 16K | DEEP ANALYSIS only, when a task demonstrably needs it; benchmark RAM first |

Set per-model in Open WebUI (Admin → Models → num_ctx) or in a Modelfile.
For RAG, better retrieval beats a bigger window: never feed a whole 100-page
document when 5 good chunks answer the question.

## GPU and NPU validation — evidence rules

Claim nothing without evidence.

1. **Baseline is CPU.** Stock Ollama on Windows uses CUDA/ROCm GPUs only; an Intel
   Arc iGPU is not used by default builds → expect `100% CPU` in `ollama ps` and
   near-zero GPU compute in Task Manager during generation. Document this.
2. **Evidence to check:** `ollama ps` (CPU/GPU split column), Ollama logs at
   `%LOCALAPPDATA%\Ollama\server.log` (look for detected accelerators at startup),
   Task Manager → Performance → GPU (compute engines, not video decode) during a
   generation, and tok/s deltas in the benchmark CSV.
3. **Optional experiment (only with explicit approval, after all gates):**
   Intel's **IPEX-LLM portable Ollama** build runs models on Arc iGPUs via SYCL.
   Test it side-by-side using the same benchmark script and keep it **only** if
   tok/s improves materially with equal stability — remember iGPU memory is carved
   from the same 16 GB, so "GPU offload" does not reduce total RAM pressure.
4. **NPU (Intel AI Boost):** no Ollama support. Unless separately verified with a
   supported runtime, record in the final report: *NPU contributes no acceleration
   to this stack.* Do not install experimental drivers or unsupported runtimes
   chasing it.

## Cloud comparison (Section 37 — after the stack is stable)

Using **non-confidential** material only, compare the local winner vs a frontier
cloud model on reasoning, document analysis, Arabic, English, and speed. Expected
result: the cloud model wins general reasoning; the local system wins on privacy,
ownership, your documents, zero marginal cost, and offline capability. That is the
point of the local system — record the comparison honestly in the final report.
