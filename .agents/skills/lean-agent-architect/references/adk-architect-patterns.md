# Architect/SRE → Google ADK Pattern Mapping & Gotchas

Use this reference to translate Java / Enterprise Architecture / SRE mental models into minimal, idiomatic Google ADK (Python) constructs without over-engineering.

## 1. Topology Selection Matrix (Always Pick the Simplest Match)

| Architect / Java / SRE Concept | Google ADK Pattern | When to Choose | Key ADK Primitives |
| :--- | :--- | :--- | :--- |
| **Single Microservice + DAO/Adapter** | **Single `Agent` + `FunctionTool`s** | **Default (80% of cases).** Up to 5 tools with clear docstrings and one domain responsibility. | `Agent(name=..., tools=[fn1, fn2])` |
| **Servlet Filter Chain / Unix Pipe** | **`SequentialAgent` Pipeline** | Fixed deterministic order (e.g., `Collect → Analyze → Format DTO`). | `SequentialAgent(sub_agents=[a, b])`, pass data via `output_key="x"` → `{x}` |
| **Scatter-Gather / ForkJoinPool** | **`ParallelAgent` + Merger** | Independent read-only queries (e.g., fetch Logs, Metrics, Recent Deploys simultaneously) to cut latency. | `ParallelAgent` inside `SequentialAgent`; **each child MUST use a distinct `output_key`** |
| **Kubernetes Reconciler / Retry Loop** | **`LoopAgent` + Escalation Gate** | Generate-Critique-Refine until deterministic criteria pass. | `LoopAgent(sub_agents=[...], max_iterations=3)` + `BaseAgent` yielding `EventActions(escalate=True)` |
| **L7 API Gateway (Ownership Handoff)** | **Coordinator `sub_agents`** | Multi-turn conversation transfers ownership to a domain specialist. | `Agent(sub_agents=[billing_agent, sre_agent])` with crisp `description`s |
| **Synchronous RPC / Subroutine Call** | **`AgentTool` or `mode="task"`** | Root orchestrator stays in control and invokes a specialist for a bounded subtask. | `tools=[AgentTool(specialist)]` or ADK 2.0 `Agent(mode="task", output_schema=DTO)` |
| **Spring AOP / Envoy Filter / Policy Gate** | **Callbacks & `BasePlugin`** | Deterministic guardrails: block destructive args, enforce dry-run, redact PII, audit log. | `before_tool_callback`, `before_model_callback`, `ReflectAndRetryToolPlugin` |
| **Cron / PubSub Worker** | **Ambient Agent (`trigger_sources`)** | Event-driven alerts (Cloud Monitoring → Pub/Sub → Agent) or Cloud Scheduler cron. | `get_fast_api_app(..., trigger_sources=["pubsub", "eventarc"])` |

## 2. Stub-First Interface Pattern (Java Interface/Impl Equivalent)

Never wire live GCP/external APIs in Slice 1. Define pure Python functions with strict type hints, docstrings, and deterministic return dicts, toggled by an environment variable (`USE_MOCK_TOOLS=true` default in Slice 1):

```python
import os

def fetch_error_logs(service_name: str, window_minutes: int = 30) -> dict:
    """Fetches error log summary for a GCP service within the time window.

    Args:
        service_name: Target Cloud Run or GKE service name.
        window_minutes: Lookback window in minutes (1 to 1440).
    """
    if window_minutes < 1 or window_minutes > 1440:
        return {"status": "error", "error_code": "INVALID_WINDOW", "entries": []}

    if os.getenv("USE_MOCK_TOOLS", "true").lower() == "true":
        return {
            "status": "success",
            "service": service_name,
            "entries": [{"severity": "ERROR", "message": "Connection pool exhausted", "count": 42}],
        }
    # Slice 2 replaces/extends this branch with real google-cloud-logging client
    raise NotImplementedError("Live GCP Logging wired in Slice 2")
```

## 3. Top 5 ADK Slop & Token-Burn Gotchas (Check Before Writing Code)

1. **`output_schema` Disables Tools & Sub-Agents**:
   - Setting `output_schema=MyPydanticModel` on a standard `Agent` **disables `tools` and `sub_agents`**!
   - *Fix*: Either place a tool-less Formatter `Agent(output_schema=MyDTO)` as the **final step** of a `SequentialAgent`, OR use `mode="task"` on a delegated sub-agent.
2. **`App(name=...)` Directory Mismatch Breaks Eval**:
   - `App(name="app", root_agent=root_agent)` **MUST match the Python package directory name** (default `app`). Naming it `App(name="sre_agent")` inside `app/` causes `Session not found` in `agents-cli eval`.
3. **Callback Parameter Names Are Invoked by Keyword**:
   - Signatures must use exact ADK keyword names:
     - `before_tool_callback(tool: BaseTool, args: dict, tool_context: ToolContext) -> dict | None` (return `None` to allow, or return a `dict` to block/short-circuit the tool call!).
4. **Never Assert LLM Prose in `pytest`**:
   - `uv run pytest` is strictly for deterministic Python code: tool input validation, mock stub schemas, and `before_tool_callback` blocking rules. Use `agents-cli run` for smoke checks and `agents-cli eval` for LLM behavior.
5. **Preserve Scaffolded Model Strings**:
   - Never downgrade a scaffolded Gemini model string to legacy `gemini-1.5-*` or guessed names from training data. Keep the scaffolded model or list live models via `google-genai`.
