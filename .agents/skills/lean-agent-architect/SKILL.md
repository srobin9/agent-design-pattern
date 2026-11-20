---
name: lean-agent-architect
description: >-
  Token-saving, anti-slop Spec-Driven & SRE Gate workflow for designing and building
  Google ADK, Python, and GCP AI agents or backend systems. Activate this skill whenever
  the user wants to design, start, scaffold, or implement an agent or backend system
  (including Korean prompts like "에이전트 만들어줘", "새 에이전트 시작", "스펙 작성", "슬라이스 구현"),
  or when `.agents-cli-spec.md` or `STATE.md` exists in the workspace. Governs and
  constrains `google-agents-cli-*` skills to prevent context bloat, over-engineering,
  and debugging loops.
---

# Lean Agent Architect (Anti-Slop & SRE Gate Workflow)

This skill enforces an Architect/SRE-oriented **Contract-First, Thin-Slice, Black-Box Verified** workflow for building Python / Google ADK / GCP agents with minimal token burn.

## 0. Token Hygiene Overrides (CRITICAL — Apply Before `google-agents-cli-*`)

When working alongside `google-agents-cli-workflow` or `google-agents-cli-adk-code`, **these overrides take precedence**:

1. **Subagent Context Isolation (No Main-Thread Recipe Cloning)**:
   - NEVER clone or read multiple ADK sample repositories or large docs directly in the main conversation.
   - If Phase 1 recipe study or doc lookup is needed, delegate to the `research` subagent (max 1–2 recipes) and ask it to return a **≤25-line Architecture Digest** (pattern, key imports, gotchas).
2. **State Externalization (`STATE.md`)**:
   - If `STATE.md` and `.agents-cli-spec.md` exist in the workspace root, read them FIRST and resume from the current active slice without re-interviewing or re-exploring the codebase.
3. **2-Strike Circuit Breaker**:
   - If the **same error or test failure occurs 2 times in a row**, STOP modifying code immediately.
   - Output a 5-line **SRE Incident Summary** (`증상` / `근본 원인 가설` / `시도한 조치` / `선택지 A·B`) and wait for user direction. Never shotgun-edit multiple files at once.

---

## Phase 1: Bootstrap & 1-Page Architecture Contract (Gate 1)

**Do NOT run `agents-cli scaffold` or write `.py` files until Gate 1 is approved.**

1. **Initialize Workspace Files** (if `GEMINI.md` or `.agents-cli-spec.md` is missing):
   Run the `init_lean_agent.sh` script located in this skill's `scripts/` directory (e.g., [scripts/init_lean_agent.sh](./scripts/init_lean_agent.sh) `<workspace_root>`).
2. **Translate Intent to ADK Pattern**:
   - Read [references/adk-architect-patterns.md](./references/adk-architect-patterns.md) to map the user's requirements (Java/MSA/SRE concepts: DTO, Pipeline, Scatter-Gather, Reconciler, Interceptor) into the simplest viable ADK topology.
   - Ask **at most 2–3 high-impact clarifying questions** (one at a time via `ask_question` if ambiguous) covering:
     1. Input/Output boundary & core tools
     2. Read-only vs mutating side effects (SRE safety boundary)
     3. Runtime target (Local prototype first vs Cloud Run / Agent Runtime)
3. **Draft `.agents-cli-spec.md` & `STATE.md`**:
   - Fill in `.agents-cli-spec.md` (1-Page Architecture Contract) including **3 Thin Vertical Slices**:
     - **Slice 1 (Skeleton + Deterministic Stubs)**: Scaffold + ADK topology + hardcoded/mock tool stubs + contract `pytest` + local smoke run (`agents-cli run`). *Zero external GCP/API auth dependencies.*
     - **Slice 2 (Real Tool Integration + Callbacks)**: Replace stubs one by one with real GCP/API calls + `before_tool_callback` safety guardrails.
     - **Slice 3 (Behavior Eval + Deploy Prep)**: 2 core eval cases (`agents-cli eval run`) + deployment config if requested.
   - Present a concise Korean summary of the Contract and **STOP for Gate 1 approval**.

---

## Phase 2: Thin-Slice Implementation & SRE Black-Box Gate (Gate 2)

Implement **ONLY ONE slice per turn/approval cycle**. Never implement Slice 2 while building Slice 1.

1. **Execute Active Slice**:
   - For Slice 1, run `agents-cli info` first; if uninitialized, scaffold via `/google-agents-cli-scaffold` (`agents-cli scaffold create`).
   - Keep code surgical and minimal. Preserve scaffolded model names unless asked.
   - Check the Top ADK Gotchas in [references/adk-architect-patterns.md](./references/adk-architect-patterns.md) before writing `Agent` or `App` code.
2. **Run Black-Box Verification**:
   - **Deterministic Contract Check**: `uv run pytest` ONLY on tool I/O schemas, mock stubs, and guardrail callbacks (NEVER assert LLM free-text in `pytest`).
   - **Agent Smoke Check**: `agents-cli run "<test prompt>"` to verify end-to-end agent wiring.
   - **Behavior Eval (Slice 3)**: Load `/google-agents-cli-eval` and run `agents-cli eval run` starting with 1–2 core cases.
3. **Update `STATE.md` & Report SRE Gate Summary**:
   Instead of dumping code, report a compact Korean **Black-Box Gate Report**:
   - **구현 범위**: (변경된 파일 및 ADK 컴포넌트 2~3줄 요약)
   - **계약 검증 결과**: (`pytest` 스키마/가드레일 통과 여부, `agents-cli run` 입출력 요약)
   - **컨텍스트·모델 가이드**:
     - Update `STATE.md` with completed slice, next slice task, and key decisions.
     - Recommend `/compact` (or starting a fresh chat pointing to `@STATE.md`) at slice boundaries.
     - Recommend model tier for next step (**Flash** for straightforward tool wiring/boilerplate; **Pro** for multi-agent architecture, complex IAM/GCP debugging, or RCA).
   - **STOP and ask for approval** to proceed to the next slice.
