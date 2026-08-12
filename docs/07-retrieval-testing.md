# Retrieval Testing — Test Set, Metrics, Evaluation (Gates 6–8)

## Test set design

For **each** knowledge library, before trusting it, write 20 questions against
documents you know well:

| Category | Count | Purpose |
|---|---|---|
| Simple factual (answer in one place) | 5 | Baseline retrieval precision |
| Multi-section (answer spans sections/chapters) | 5 | Chunking + top-k adequacy |
| Comparison (two documents or two sections) | 5 | Cross-document retrieval |
| **Not answerable from the documents** | 5 | **Refusal test — the critical one** |

Record them in a copy of the template below (keep per-library test files in your
backup folder, e.g. `tests/RE-Signalling-testset.md`):

```
Q##: <question>  [<language: EN|AR|mixed>]
Expected source: <document, section, page> | NOT IN CORPUS
Result: <answer summary>
Retrieved correctly: Y/N   Faithful: Y/N   Citation correct: Y/N
Refused correctly (for NOT-IN-CORPUS): Y/N
Latency: <s>   Notes:
```

For **Gate 8**, ensure across the set: ≥5 questions in Arabic, ≥5 in English,
≥2 mixed (Arabic question about an English document and vice versa).

## Pass criteria

- **Gate 6:** ≥ 80% of answerable questions answered faithfully with correct
  source attribution; no fabricated citations at all.
- **Gate 7:** ≥ 4 of 5 unanswerable questions per library produce the refusal
  ("The available knowledge base does not provide sufficient evidence…") —
  a confident hallucinated answer here is an automatic gate failure: fix
  (prompt, retrieval settings, or document QC) and re-test.
- **Gate 8:** no systematic quality gap between Arabic and English retrieval;
  Arabic citations point at genuinely Arabic source passages.

## Metrics and scoring

Per library, compute from the test log:

| Metric | Definition | Target |
|---|---|---|
| Retrieval precision | Correct source retrieved / answerable Qs | ≥ 0.8 |
| Answer faithfulness | Answers fully supported by retrieved text / answerable Qs | ≥ 0.8 |
| Citation accuracy | Citations pointing to real, correct locations / cited answers | 1.0 (no fakes) |
| Missing-info detection | Correct refusals / unanswerable Qs | ≥ 0.8 |
| Latency | Median seconds to complete answer | ≤ 60 s STANDARD mode |
| RAM headroom | Free RAM during RAG answer | > 1.5 GB |

Simple evaluation score = mean of the first four ratios.
**Faithfulness > fluency**: a plain answer supported by evidence always outranks
an impressive hallucination.

## Tuning loop when a metric fails

1. Bad retrieval (wrong/no chunks) → check document QC first (bad extraction is
   the usual culprit), then raise top-k, then adjust chunk size, then enable
   hybrid search if off.
2. Good retrieval, unfaithful answer → tighten the system prompt; reduce
   temperature (0.3–0.5 for RAG assistants); consider the other 4B model.
3. Wrong citations → smaller chunks (tighter attribution); re-check page metadata
   survived extraction.
4. Failed refusals → verify the refusal instruction is in the model's system
   prompt (not just chat); test again with temperature lowered.

Change one variable per iteration; re-run the same test set; log the result in
`docs/12-final-report.md` §F.
