# Switchboard Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a machine-level CLI (`sb`) that lets any harness - Claude Code, Codex, Cowork - dispatch a sub-agent to a different model family and get the result back.

**Architecture:** A thin Python CLI over three lane adapters (Anthropic-dialect via `claude --print`, OpenAI-dialect via `codex exec`, local via Ollama HTTP). Lane definitions live in a machine-level YAML file so adding a model is a config edit, never a code change. Every dispatch writes a self-contained run directory of plain files and appends one ledger line. Routing judgment lives in a text rubric read by the calling agent - the CLI dials, it never decides.

**Tech Stack:** Python 3.11+, PyYAML, argparse, stdlib `subprocess` / `urllib`. No web framework, no database, no async runtime. pytest for tests.

**Spec:** `docs/superpowers/specs/2026-08-29-switchboard-design.md` (merged to main, PR #7). Read it before starting.

## Global Constraints

- **Python `>=3.11`**; dependencies pinned to exact versions (`PyYAML==6.0.2`), matching the eval kit.
- **Supply chain** (`~/.claude/GUARDRAILS-security.md`): exact versions only, lockfile committed, `pip install --only-binary :all:`, no install scripts, 7-day age gate on any new dependency.
- **Repo rules:** `remixpartners/remix-switchboard`, cloned to `~/remix-switchboard`. Never push to `main` - branch, push, PR, self-review, self-merge, verify. A `pre-push` agent-guard enforces this; never bypass with `--no-verify` or `STAFFORD_ALLOW_MAIN_PUSH=1`.
- **The bright line:** no automatic lane selection anywhere in the code. No `--auto` flag, no heuristic that picks a lane. If a task tempts you toward one, stop and re-read the spec section "The bright line".
- **Secrets never enter a brief**, and never appear in `meta.json`, the ledger, or any log. Only `api_key_path` is stored, never the key value.
- **Test hygiene** (`chief-of-staff/CLAUDE.md`): every test pytest-collectable, clocks injected not read from the system, no real filesystem paths, no real credentials, no network calls. Lane binaries are faked with shell stubs on `PATH` (the eval kit's `_fake_claude` pattern, reproduced in Task 3).
- **Port, do not reinvent:** `~/remix-eval-kit/evalkit/runner.py` and `evalkit/config.py` are the proven originals. Read both before Task 1.

---

## File Structure

```
~/remix-switchboard/
  pyproject.toml              # packaging; console entry point `sb`
  README.md                   # runbook
  config/
    lanes.example.yaml        # shipped example, installed to ~/.config/switchboard/lanes.yaml
    rubric.md                 # routing rubric, installed to ~/.config/switchboard/rubric.md
  switchboard/
    __init__.py
    config.py                 # Lane dataclass + YAML loader + validation
    profile.py                # env + isolation + leash construction (the consequential module)
    runs.py                   # run directory, meta.json, ledger append, run lookup
    lanes/
      __init__.py             # kind -> adapter dispatch
      anthropic.py            # `claude --print` adapter (kinds: anthropic, gateway)
      codex.py                # `codex exec` adapter (kind: codex)
      ollama.py               # Ollama HTTP adapter (kind: ollama), brain mode only
    dispatch.py               # orchestration: validate -> build env -> run -> persist
    health.py                 # per-lane reachability probe for `sb lanes --check`
    cli.py                    # argparse: dispatch / list / log / kill / lanes
  tests/
    __init__.py
    test_config.py
    test_profile.py
    test_lane_anthropic.py
    test_lane_codex.py
    test_lane_ollama.py
    test_runs.py
    test_dispatch.py
    test_health.py
    test_cli.py
```

Responsibilities are split so that each lane adapter can be reviewed and rejected independently, and so `profile.py` - the module whose bugs are silent and dangerous - is isolated and separately testable.

---

### Task 1: Repo scaffold and lane config loader

**Files:**
- Create: `~/remix-switchboard/pyproject.toml`
- Create: `~/remix-switchboard/switchboard/__init__.py` (empty)
- Create: `~/remix-switchboard/switchboard/config.py`
- Create: `~/remix-switchboard/config/lanes.example.yaml`
- Test: `~/remix-switchboard/tests/__init__.py` (empty), `~/remix-switchboard/tests/test_config.py`

**Interfaces:**
- Consumes: nothing.
- Produces: `Lane` dataclass with fields `name: str`, `kind: str`, `model: str`, `modes: list[str]`, `context_tokens: int`, `max_concurrency: int`, `timeout_default: int`, `base_url: str | None`, `api_key_path: Path | None`, `extra_env: dict[str, str]`, `profile_dir: Path`, `enabled: bool`. Function `load_lanes(path: Path) -> dict[str, Lane]`. Function `config_path() -> Path` returning `$SWITCHBOARD_CONFIG` if set, else `~/.config/switchboard/lanes.yaml`.

- [ ] **Step 1: Create the repo and its git remote**

```bash
mkdir -p ~/remix-switchboard && cd ~/remix-switchboard && git init -q
gh repo create remixpartners/remix-switchboard --private --source=. --remote=origin
git switch -c task-1-config
```

- [ ] **Step 2: Write `pyproject.toml`**

```toml
[build-system]
requires = ["setuptools>=68"]
build-backend = "setuptools.build_meta"

[project]
name = "remix-switchboard"
version = "0.1.0"
requires-python = ">=3.11"
dependencies = ["PyYAML==6.0.2"]

[project.scripts]
sb = "switchboard.cli:main"

[tool.setuptools.packages.find]
include = ["switchboard*"]

[tool.pytest.ini_options]
testpaths = ["tests"]
```

- [ ] **Step 3: Write the failing test**

Create `tests/test_config.py`:

```python
import pytest
from pathlib import Path
from switchboard.config import load_lanes, config_path

LANES_YAML = """
lanes:
  glm:
    kind: gateway
    model: glm-5.2-vision
    modes: [hands, brain]
    base_url: https://gw.lunaroute.com
    api_key_path: ~/.config/lunaroute/api_key
    context_tokens: 524288
    max_concurrency: 4
    timeout_default: 1800
    extra_env: {CLAUDE_CODE_MAX_CONTEXT_TOKENS: "524288"}
  gemma:
    kind: ollama
    model: gemma4-remix:latest
    modes: [brain]
    base_url: http://100.120.116.15:11434
    context_tokens: 128000
    max_concurrency: 1
    timeout_default: 600
  retired:
    kind: ollama
    model: old
    modes: [brain]
    base_url: http://example.invalid
    context_tokens: 1000
    max_concurrency: 1
    timeout_default: 60
    enabled: false
"""

def test_loads_lanes_and_expands_key_path(tmp_path):
    f = tmp_path / "lanes.yaml"; f.write_text(LANES_YAML)
    lanes = load_lanes(f)
    assert set(lanes) == {"glm", "gemma"}          # disabled lane excluded
    glm = lanes["glm"]
    assert glm.kind == "gateway"
    assert glm.modes == ["hands", "brain"]
    assert glm.api_key_path == Path.home() / ".config/lunaroute/api_key"
    assert glm.extra_env == {"CLAUDE_CODE_MAX_CONTEXT_TOKENS": "524288"}
    assert glm.timeout_default == 1800

def test_brain_only_lane_has_no_hands_mode(tmp_path):
    f = tmp_path / "lanes.yaml"; f.write_text(LANES_YAML)
    assert load_lanes(f)["gemma"].modes == ["brain"]

def test_unknown_kind_is_rejected(tmp_path):
    f = tmp_path / "lanes.yaml"
    f.write_text("lanes:\n  x:\n    kind: telepathy\n    model: m\n    modes: [brain]\n"
                 "    context_tokens: 1\n    max_concurrency: 1\n    timeout_default: 1\n")
    with pytest.raises(ValueError, match="unknown kind"):
        load_lanes(f)

def test_unknown_mode_is_rejected(tmp_path):
    f = tmp_path / "lanes.yaml"
    f.write_text("lanes:\n  x:\n    kind: ollama\n    model: m\n    modes: [telepathy]\n"
                 "    context_tokens: 1\n    max_concurrency: 1\n    timeout_default: 1\n")
    with pytest.raises(ValueError, match="unknown mode"):
        load_lanes(f)

def test_config_path_honours_env_override(tmp_path, monkeypatch):
    monkeypatch.setenv("SWITCHBOARD_CONFIG", str(tmp_path / "custom.yaml"))
    assert config_path() == tmp_path / "custom.yaml"

def test_config_path_defaults_to_user_config_dir(monkeypatch):
    monkeypatch.delenv("SWITCHBOARD_CONFIG", raising=False)
    assert config_path() == Path.home() / ".config" / "switchboard" / "lanes.yaml"
```

- [ ] **Step 4: Run the test to verify it fails**

Run: `cd ~/remix-switchboard && python -m venv .venv && .venv/bin/pip install --only-binary :all: -e . pytest && .venv/bin/pytest tests/test_config.py -v`
Expected: FAIL with `ModuleNotFoundError: No module named 'switchboard.config'`

- [ ] **Step 5: Write `switchboard/config.py`**

```python
import os
from dataclasses import dataclass, field
from pathlib import Path
import yaml

KINDS = ("anthropic", "gateway", "codex", "ollama")
MODES = ("hands", "brain")

@dataclass
class Lane:
    name: str
    kind: str
    model: str
    modes: list[str]
    context_tokens: int
    max_concurrency: int
    timeout_default: int
    base_url: str | None = None
    api_key_path: Path | None = None
    extra_env: dict = field(default_factory=dict)
    profile_dir: Path = field(default_factory=Path)
    enabled: bool = True

def config_path() -> Path:
    override = os.environ.get("SWITCHBOARD_CONFIG")
    if override:
        return Path(override).expanduser()
    return Path.home() / ".config" / "switchboard" / "lanes.yaml"

def load_lanes(path: Path) -> dict[str, Lane]:
    raw = yaml.safe_load(path.read_text())
    if not raw or "lanes" not in raw:
        raise ValueError(f"{path}: no 'lanes:' block")
    lanes: dict[str, Lane] = {}
    for name, spec in raw["lanes"].items():
        if not spec.get("enabled", True):
            continue
        kind = spec["kind"]
        if kind not in KINDS:
            raise ValueError(f"lane {name}: unknown kind {kind!r}")
        modes = list(spec["modes"])
        for m in modes:
            if m not in MODES:
                raise ValueError(f"lane {name}: unknown mode {m!r}")
        key = spec.get("api_key_path")
        profile = spec.get("profile_dir") or f"~/.switchboard/profiles/{name}"
        lanes[name] = Lane(
            name=name, kind=kind, model=spec["model"], modes=modes,
            context_tokens=int(spec["context_tokens"]),
            max_concurrency=int(spec["max_concurrency"]),
            timeout_default=int(spec["timeout_default"]),
            base_url=spec.get("base_url"),
            api_key_path=Path(key).expanduser() if key else None,
            extra_env={k: str(v) for k, v in (spec.get("extra_env") or {}).items()},
            profile_dir=Path(profile).expanduser(),
        )
    return lanes
```

- [ ] **Step 6: Run the test to verify it passes**

Run: `.venv/bin/pytest tests/test_config.py -v`
Expected: 6 passed

- [ ] **Step 7: Write `config/lanes.example.yaml` with the four measured lanes**

```yaml
# Installed to ~/.config/switchboard/lanes.yaml. Adding a model is an edit here,
# never a code change. Measured latencies recorded 2026-08-29.
lanes:
  codex:                        # GPT family, with hands. Measured 7s round trip.
    kind: codex
    model: gpt-5-codex
    modes: [hands, brain]
    context_tokens: 400000
    max_concurrency: 2
    timeout_default: 1800

  glm:                          # GLM 5.2 via Lunaroute. Measured 5.5s round trip.
    kind: gateway
    model: glm-5.2-vision
    modes: [hands, brain]
    base_url: https://gw.lunaroute.com
    api_key_path: ~/.config/lunaroute/api_key
    context_tokens: 524288
    max_concurrency: 4          # Apex tier, minus headroom
    timeout_default: 1800
    extra_env:
      CLAUDE_CODE_MAX_CONTEXT_TOKENS: "524288"

  gemma:                        # Local 26B on the Mini. Brain only: tool use gate-failed 2026-08-29.
    kind: ollama
    model: gemma4-remix:latest
    modes: [brain]
    base_url: http://100.120.116.15:11434
    context_tokens: 128000
    max_concurrency: 1
    timeout_default: 900        # measured: cold load exceeds 90s

  gemma-small:                  # Local 8B. Measured 9.5s warm.
    kind: ollama
    model: gemma4:e4b
    modes: [brain]
    base_url: http://100.120.116.15:11434
    context_tokens: 128000
    max_concurrency: 1
    timeout_default: 300
```

- [ ] **Step 8: Commit and open the PR**

```bash
cd ~/remix-switchboard
printf '.venv/\n__pycache__/\n*.egg-info/\n.pytest_cache/\n' > .gitignore
git add -A && git commit -m "feat: repo scaffold and lane config loader"
git push -u origin task-1-config && gh pr create --fill
```

---

### Task 2: Profile and environment construction

This is the consequential module and gets full test-first treatment per the spec. A leaked gateway variable makes a run labelled `glm` silently execute on Claude, corrupting every comparison drawn from it - a silent, plausible, hard-to-detect wrong answer.

**Files:**
- Create: `~/remix-switchboard/switchboard/profile.py`
- Test: `~/remix-switchboard/tests/test_profile.py`

**Interfaces:**
- Consumes: `Lane` from `switchboard.config`.
- Produces: `GATEWAY_VARS: tuple[str, ...]`; `build_env(lane: Lane, *, mcp: bool, base_env: dict | None = None) -> dict[str, str]`; `Leash` dataclass with fields `clean: bool`, `mcp: bool`, `write: bool`; `resolve_cwd(leash: Leash, requested: Path, scratch_root: Path) -> Path`.

- [ ] **Step 1: Write the failing test**

Create `tests/test_profile.py`:

```python
from pathlib import Path
from switchboard.config import Lane
from switchboard.profile import build_env, resolve_cwd, Leash, GATEWAY_VARS

def _lane(**kw):
    base = dict(name="glm", kind="gateway", model="glm-5.2-vision", modes=["hands", "brain"],
                context_tokens=1000, max_concurrency=1, timeout_default=60,
                profile_dir=Path("/tmp/profiles/glm"))
    base.update(kw)
    return Lane(**base)

def test_gateway_lane_sets_base_url_and_all_three_model_slots(tmp_path):
    key = tmp_path / "key"; key.write_text("sekrit\n")
    env = build_env(_lane(base_url="https://gw.example", api_key_path=key), mcp=False, base_env={})
    assert env["ANTHROPIC_BASE_URL"] == "https://gw.example"
    assert env["ANTHROPIC_API_KEY"] == "sekrit"          # stripped of trailing newline
    for slot in ("OPUS", "SONNET", "HAIKU"):
        assert env[f"ANTHROPIC_DEFAULT_{slot}_MODEL"] == "glm-5.2-vision"

def test_ambient_gateway_env_is_scrubbed_for_a_native_anthropic_lane():
    # THE bug this module exists to prevent: a machine-wide Lunaroute toggle
    # must never leak into a lane that did not ask for it, or a run labelled
    # "claude" silently executes on GLM.
    dirty = {v: "leaked" for v in GATEWAY_VARS}
    env = build_env(_lane(name="claude", kind="anthropic", model="claude-opus-5", base_url=None),
                    mcp=False, base_env=dirty)
    for var in GATEWAY_VARS:
        assert var not in env, f"{var} leaked into a native anthropic lane"

def test_scrub_happens_before_lane_vars_are_applied(tmp_path):
    key = tmp_path / "key"; key.write_text("real")
    dirty = {"ANTHROPIC_API_KEY": "stale", "ANTHROPIC_BASE_URL": "https://stale.example"}
    env = build_env(_lane(base_url="https://gw.example", api_key_path=key), mcp=False, base_env=dirty)
    assert env["ANTHROPIC_API_KEY"] == "real"
    assert env["ANTHROPIC_BASE_URL"] == "https://gw.example"

def test_config_dir_is_the_lane_profile_never_the_users_real_one():
    env = build_env(_lane(), mcp=False, base_env={"CLAUDE_CONFIG_DIR": "/Users/justinmassa/.claude"})
    assert env["CLAUDE_CONFIG_DIR"] == "/tmp/profiles/glm"

def test_codex_lane_isolates_codex_home_instead():
    env = build_env(_lane(name="codex", kind="codex", model="gpt-5-codex",
                          profile_dir=Path("/tmp/profiles/codex")), mcp=False, base_env={})
    assert env["CODEX_HOME"] == "/tmp/profiles/codex"
    assert "CLAUDE_CONFIG_DIR" not in env

def test_extra_env_is_applied():
    env = build_env(_lane(extra_env={"CLAUDE_CODE_MAX_CONTEXT_TOKENS": "524288"}),
                    mcp=False, base_env={})
    assert env["CLAUDE_CODE_MAX_CONTEXT_TOKENS"] == "524288"

def test_secret_value_never_appears_when_no_key_path_is_set():
    env = build_env(_lane(api_key_path=None, base_url="https://gw.example"), mcp=False, base_env={})
    assert "ANTHROPIC_API_KEY" not in env

def test_default_leash_runs_in_the_callers_cwd_so_conventions_load(tmp_path):
    repo, scratch = tmp_path / "repo", tmp_path / "scratch"
    repo.mkdir()
    assert resolve_cwd(Leash(clean=False, mcp=False, write=False), repo, scratch) == repo

def test_clean_leash_runs_in_a_scratch_dir_with_no_project_conventions(tmp_path):
    repo, scratch = tmp_path / "repo", tmp_path / "scratch"
    repo.mkdir(); (repo / "CLAUDE.md").write_text("our house rules")
    got = resolve_cwd(Leash(clean=True, mcp=False, write=False), repo, scratch)
    assert got != repo
    assert got.is_dir()
    assert not (got / "CLAUDE.md").exists()
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `.venv/bin/pytest tests/test_profile.py -v`
Expected: FAIL with `ModuleNotFoundError: No module named 'switchboard.profile'`

- [ ] **Step 3: Write `switchboard/profile.py`**

```python
from dataclasses import dataclass
from pathlib import Path
import os

# Anthropic-dialect variables that redirect a session to another provider.
# Any of these surviving from the ambient environment can silently point a
# lane at the wrong model, so they are removed before lane values are applied.
GATEWAY_VARS = (
    "ANTHROPIC_BASE_URL",
    "ANTHROPIC_API_KEY",
    "ANTHROPIC_DEFAULT_OPUS_MODEL",
    "ANTHROPIC_DEFAULT_SONNET_MODEL",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL",
)

@dataclass(frozen=True)
class Leash:
    clean: bool = False   # withhold project conventions (adversarial review only)
    mcp: bool = False     # grant account access via MCP servers
    write: bool = False   # allow writes (into an isolated worktree)

def build_env(lane, *, mcp: bool, base_env: dict | None = None) -> dict[str, str]:
    env = dict(os.environ if base_env is None else base_env)

    # Always-on isolation, step 1: scrub. Must happen before lane values are
    # applied so a stale ambient key cannot outlive its replacement.
    for var in GATEWAY_VARS:
        env.pop(var, None)

    # Always-on isolation, step 2: the lane gets its own config/home dir so it
    # cannot disturb Justin's real sessions, history, or auth.
    if lane.kind == "codex":
        env.pop("CLAUDE_CONFIG_DIR", None)
        env["CODEX_HOME"] = str(lane.profile_dir)
    else:
        env["CLAUDE_CONFIG_DIR"] = str(lane.profile_dir)

    if lane.kind == "gateway":
        env["ANTHROPIC_BASE_URL"] = lane.base_url
        if lane.api_key_path:
            env["ANTHROPIC_API_KEY"] = lane.api_key_path.read_text().strip()
        for slot in ("OPUS", "SONNET", "HAIKU"):
            env[f"ANTHROPIC_DEFAULT_{slot}_MODEL"] = lane.model

    env.update(lane.extra_env)
    return env

def resolve_cwd(leash: Leash, requested: Path, scratch_root: Path) -> Path:
    """Full leash runs in the caller's directory so project conventions load
    naturally. `--clean` runs in an empty scratch directory instead, which is
    how we withhold CLAUDE.md / AGENTS.md from an adversarial reviewer without
    depending on any harness flag semantics."""
    if not leash.clean:
        return requested
    scratch_root.mkdir(parents=True, exist_ok=True)
    return scratch_root
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `.venv/bin/pytest tests/test_profile.py -v`
Expected: 9 passed

- [ ] **Step 5: Commit and open the PR**

```bash
git switch -c task-2-profile && git add -A
git commit -m "feat: lane profile and env construction with gateway scrubbing"
git push -u origin task-2-profile && gh pr create --fill
```

---

### Task 3: Anthropic-dialect lane adapter

**Files:**
- Create: `~/remix-switchboard/switchboard/lanes/__init__.py`
- Create: `~/remix-switchboard/switchboard/lanes/anthropic.py`
- Test: `~/remix-switchboard/tests/test_lane_anthropic.py`

**Interfaces:**
- Consumes: `Lane` from `switchboard.config`; `build_env`, `Leash`, `resolve_cwd` from `switchboard.profile`.
- Produces: `LaneResult` dataclass with fields `ok: bool`, `output: str`, `seconds: float`, `error: str | None`, `pid: int | None`. Function `run(lane, brief: str, *, mode: str, leash: Leash, cwd: Path, timeout: int, transcript_path: Path) -> LaneResult`. `DENY_TOOLS: tuple[str, ...]`. This `run` signature is shared by all three adapters, so Tasks 4 and 5 implement the identical shape.

- [ ] **Step 1: Write the failing test**

Create `tests/test_lane_anthropic.py`:

```python
import os, stat
from pathlib import Path
from switchboard.config import Lane
from switchboard.profile import Leash
from switchboard.lanes import anthropic

def _fake_claude(tmp_path, script):
    exe = tmp_path / "bin" / "claude"
    exe.parent.mkdir(exist_ok=True)
    exe.write_text("#!/bin/bash\n" + script)
    exe.chmod(exe.stat().st_mode | stat.S_IEXEC)
    return exe.parent

def _lane(tmp_path, **kw):
    base = dict(name="glm", kind="gateway", model="glm-5.2-vision", modes=["hands", "brain"],
                context_tokens=1000, max_concurrency=1, timeout_default=60,
                base_url="https://gw.example", profile_dir=tmp_path / "prof")
    base.update(kw)
    return Lane(**base)

def _run(tmp_path, monkeypatch, script, **kw):
    monkeypatch.setenv("PATH", f"{_fake_claude(tmp_path, script)}:{os.environ['PATH']}")
    kw.setdefault("mode", "hands")
    kw.setdefault("leash", Leash())
    kw.setdefault("cwd", tmp_path)
    kw.setdefault("timeout", 30)
    kw.setdefault("transcript_path", tmp_path / "t.log")
    return anthropic.run(_lane(tmp_path), "do the thing", **kw)

def test_captures_output_and_reports_success(tmp_path, monkeypatch):
    res = _run(tmp_path, monkeypatch, 'echo "the answer"')
    assert res.ok and "the answer" in res.output and res.seconds >= 0

def test_brief_is_passed_on_stdin(tmp_path, monkeypatch):
    res = _run(tmp_path, monkeypatch, 'cat')
    assert "do the thing" in res.output

def test_full_leash_grants_skill_and_agent_tools(tmp_path, monkeypatch):
    # Verified 2026-08-29: skills survive the isolation flags. Withholding them
    # would forbid the hybrid lane (GLM drafts, Claude judges), the flagship use.
    res = _run(tmp_path, monkeypatch, 'echo "ARGS=$*"')
    allowed = res.output.split("--allowedTools ")[1].split(" --")[0]
    assert "Skill" in allowed and "Agent" in allowed

def test_read_only_by_default_no_write_tool(tmp_path, monkeypatch):
    res = _run(tmp_path, monkeypatch, 'echo "ARGS=$*"')
    allowed = res.output.split("--allowedTools ")[1].split(" --")[0]
    assert "Write" not in allowed and "Edit" not in allowed

def test_write_leash_grants_write_tools(tmp_path, monkeypatch):
    res = _run(tmp_path, monkeypatch, 'echo "ARGS=$*"', leash=Leash(write=True))
    allowed = res.output.split("--allowedTools ")[1].split(" --")[0]
    assert "Write" in allowed and "Edit" in allowed

def test_mcp_off_by_default(tmp_path, monkeypatch):
    res = _run(tmp_path, monkeypatch, 'echo "ARGS=$*"')
    assert "--strict-mcp-config" in res.output

def test_mcp_leash_drops_the_strict_flag(tmp_path, monkeypatch):
    res = _run(tmp_path, monkeypatch, 'echo "ARGS=$*"', leash=Leash(mcp=True))
    assert "--strict-mcp-config" not in res.output

def test_messaging_tools_are_always_denied(tmp_path, monkeypatch):
    res = _run(tmp_path, monkeypatch, 'echo "ARGS=$*"')
    denied = res.output.split("--disallowedTools ")[1].split(" --")[0]
    assert "gws gmail +send" in denied and "gchat_sender" in denied

def test_user_settings_and_hooks_are_always_suppressed(tmp_path, monkeypatch):
    res = _run(tmp_path, monkeypatch, 'echo "ARGS=$*"')
    assert "--setting-sources" in res.output

def test_nonzero_exit_is_reported_as_failure_with_stderr(tmp_path, monkeypatch):
    res = _run(tmp_path, monkeypatch, 'echo "boom" >&2; exit 3')
    assert not res.ok and "boom" in res.error

def test_empty_output_counts_as_failure_not_silent_success(tmp_path, monkeypatch):
    res = _run(tmp_path, monkeypatch, 'exit 0')
    assert not res.ok and res.error == "empty output"

def test_timeout_is_reported_explicitly(tmp_path, monkeypatch):
    res = _run(tmp_path, monkeypatch, 'sleep 5', timeout=1)
    assert not res.ok and res.error == "timeout"

def test_transcript_is_written_to_disk(tmp_path, monkeypatch):
    t = tmp_path / "transcript.log"
    _run(tmp_path, monkeypatch, 'echo "chatter"', transcript_path=t)
    assert "chatter" in t.read_text()
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `.venv/bin/pytest tests/test_lane_anthropic.py -v`
Expected: FAIL with `ModuleNotFoundError: No module named 'switchboard.lanes'`

- [ ] **Step 3: Write `switchboard/lanes/__init__.py`**

```python
from dataclasses import dataclass

@dataclass
class LaneResult:
    ok: bool
    output: str
    seconds: float
    error: str | None = None
    pid: int | None = None

def adapter_for(kind: str):
    from . import anthropic, codex, ollama
    return {"anthropic": anthropic, "gateway": anthropic,
            "codex": codex, "ollama": ollama}[kind]
```

- [ ] **Step 4: Write `switchboard/lanes/anthropic.py`**

```python
import subprocess, time
from pathlib import Path
from ..profile import build_env
from . import LaneResult

# A dispatched sub-agent must never be able to message a human as Justin.
DENY_TOOLS = ("Bash(gws gmail +send*)", "Bash(gws gmail +reply*)",
              "Bash(gws gmail +forward*)", "Bash(*gchat_sender*)", "Bash(*notify_cos*)")

READ_TOOLS = ("Read", "Glob", "Grep", "Bash", "Skill", "Agent", "WebFetch", "WebSearch")
WRITE_TOOLS = ("Write", "Edit", "NotebookEdit")

def _allowed(mode: str, write: bool) -> str:
    if mode == "brain":
        return ""
    tools = list(READ_TOOLS) + (list(WRITE_TOOLS) if write else [])
    return ",".join(tools)

def run(lane, brief: str, *, mode: str, leash, cwd: Path, timeout: int,
        transcript_path: Path) -> LaneResult:
    env = build_env(lane, mcp=leash.mcp)
    lane.profile_dir.mkdir(parents=True, exist_ok=True)
    cmd = ["claude", "--print", "--model", lane.model,
           "--setting-sources", "",                       # no hooks, no user settings
           "--allowedTools", _allowed(mode, leash.write),
           "--disallowedTools", ",".join(DENY_TOOLS),
           "--dangerously-skip-permissions"]
    if not leash.mcp:
        cmd.append("--strict-mcp-config")
    t0 = time.monotonic()
    try:
        p = subprocess.run(cmd, input=brief, text=True, capture_output=True,
                           timeout=timeout, cwd=cwd, env=env)
    except subprocess.TimeoutExpired:
        return LaneResult(ok=False, output="", seconds=time.monotonic() - t0, error="timeout")
    elapsed = time.monotonic() - t0
    transcript_path.parent.mkdir(parents=True, exist_ok=True)
    transcript_path.write_text(p.stdout + ("\n--- stderr ---\n" + p.stderr if p.stderr else ""))
    ok = p.returncode == 0 and bool(p.stdout.strip())
    error = None if ok else ((p.stderr[-2000:].strip() or "empty output") if p.returncode == 0
                             else (p.stderr[-2000:].strip() or f"exit {p.returncode}"))
    if p.returncode == 0 and not p.stdout.strip():
        error = "empty output"
    return LaneResult(ok=ok, output=p.stdout, seconds=elapsed, error=error)
```

- [ ] **Step 5: Run the test to verify it passes**

Run: `.venv/bin/pytest tests/test_lane_anthropic.py -v`
Expected: 13 passed

- [ ] **Step 6: Commit and open the PR**

```bash
git switch -c task-3-lane-anthropic && git add -A
git commit -m "feat: anthropic-dialect lane adapter with leash-driven tool sets"
git push -u origin task-3-lane-anthropic && gh pr create --fill
```

---

### Task 4: Codex lane adapter

**Files:**
- Create: `~/remix-switchboard/switchboard/lanes/codex.py`
- Test: `~/remix-switchboard/tests/test_lane_codex.py`

**Interfaces:**
- Consumes: `build_env` from `switchboard.profile`; `LaneResult` from `switchboard.lanes`.
- Produces: `run(lane, brief, *, mode, leash, cwd, timeout, transcript_path) -> LaneResult` - identical signature to `anthropic.run`.

- [ ] **Step 1: Write the failing test**

Create `tests/test_lane_codex.py`:

```python
import os, stat
from pathlib import Path
from switchboard.config import Lane
from switchboard.profile import Leash
from switchboard.lanes import codex

def _fake_codex(tmp_path, script):
    exe = tmp_path / "bin" / "codex"
    exe.parent.mkdir(exist_ok=True)
    exe.write_text("#!/bin/bash\n" + script)
    exe.chmod(exe.stat().st_mode | stat.S_IEXEC)
    return exe.parent

def _lane(tmp_path):
    return Lane(name="codex", kind="codex", model="gpt-5-codex", modes=["hands", "brain"],
                context_tokens=400000, max_concurrency=2, timeout_default=60,
                profile_dir=tmp_path / "codexhome")

def _run(tmp_path, monkeypatch, script, **kw):
    monkeypatch.setenv("PATH", f"{_fake_codex(tmp_path, script)}:{os.environ['PATH']}")
    kw.setdefault("mode", "hands"); kw.setdefault("leash", Leash())
    kw.setdefault("cwd", tmp_path); kw.setdefault("timeout", 30)
    kw.setdefault("transcript_path", tmp_path / "t.log")
    return codex.run(_lane(tmp_path), "do the thing", **kw)

def test_invokes_exec_subcommand(tmp_path, monkeypatch):
    res = _run(tmp_path, monkeypatch, 'echo "ARGS=$*"')
    assert res.ok and "exec" in res.output

def test_read_only_sandbox_by_default(tmp_path, monkeypatch):
    res = _run(tmp_path, monkeypatch, 'echo "ARGS=$*"')
    assert "--sandbox read-only" in res.output

def test_write_leash_uses_workspace_write_sandbox(tmp_path, monkeypatch):
    res = _run(tmp_path, monkeypatch, 'echo "ARGS=$*"', leash=Leash(write=True))
    assert "--sandbox workspace-write" in res.output

def test_codex_home_is_isolated_to_the_lane_profile(tmp_path, monkeypatch):
    res = _run(tmp_path, monkeypatch, 'echo "HOME=$CODEX_HOME"')
    assert str(tmp_path / "codexhome") in res.output

def test_model_flag_is_passed(tmp_path, monkeypatch):
    res = _run(tmp_path, monkeypatch, 'echo "ARGS=$*"')
    assert "gpt-5-codex" in res.output

def test_brief_is_passed_on_stdin(tmp_path, monkeypatch):
    res = _run(tmp_path, monkeypatch, 'cat')
    assert "do the thing" in res.output

def test_timeout_is_reported_explicitly(tmp_path, monkeypatch):
    res = _run(tmp_path, monkeypatch, 'sleep 5', timeout=1)
    assert not res.ok and res.error == "timeout"

def test_nonzero_exit_is_reported_as_failure(tmp_path, monkeypatch):
    res = _run(tmp_path, monkeypatch, 'echo "kaboom" >&2; exit 4')
    assert not res.ok and "kaboom" in res.error

def test_transcript_is_written_to_disk(tmp_path, monkeypatch):
    t = tmp_path / "transcript.log"
    _run(tmp_path, monkeypatch, 'echo "chatter"', transcript_path=t)
    assert "chatter" in t.read_text()
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `.venv/bin/pytest tests/test_lane_codex.py -v`
Expected: FAIL with `ImportError: cannot import name 'codex'`

- [ ] **Step 3: Write `switchboard/lanes/codex.py`**

```python
import subprocess, time
from pathlib import Path
from ..profile import build_env
from . import LaneResult

def run(lane, brief: str, *, mode: str, leash, cwd: Path, timeout: int,
        transcript_path: Path) -> LaneResult:
    env = build_env(lane, mcp=leash.mcp)
    lane.profile_dir.mkdir(parents=True, exist_ok=True)
    sandbox = "workspace-write" if leash.write else "read-only"
    cmd = ["codex", "exec", "--model", lane.model, "--sandbox", sandbox,
           "--skip-git-repo-check"]
    t0 = time.monotonic()
    try:
        p = subprocess.run(cmd, input=brief, text=True, capture_output=True,
                           timeout=timeout, cwd=cwd, env=env)
    except subprocess.TimeoutExpired:
        return LaneResult(ok=False, output="", seconds=time.monotonic() - t0, error="timeout")
    elapsed = time.monotonic() - t0
    transcript_path.parent.mkdir(parents=True, exist_ok=True)
    transcript_path.write_text(p.stdout + ("\n--- stderr ---\n" + p.stderr if p.stderr else ""))
    ok = p.returncode == 0 and bool(p.stdout.strip())
    error = None
    if not ok:
        error = (p.stderr[-2000:].strip() or
                 ("empty output" if p.returncode == 0 else f"exit {p.returncode}"))
    return LaneResult(ok=ok, output=p.stdout, seconds=elapsed, error=error)
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `.venv/bin/pytest tests/test_lane_codex.py -v`
Expected: 9 passed

- [ ] **Step 5: Create the lean codex profile**

The measured dispatch pulled in two MCP servers that threw auth errors. A dedicated `CODEX_HOME` fixes this by giving the lane an empty config it can populate on first auth.

```bash
mkdir -p ~/.switchboard/profiles/codex
printf '# Lean profile for switchboard dispatches. Deliberately minimal: the\n# ambient ~/.codex config pulled in two MCP servers that threw auth errors\n# mid-dispatch (measured 2026-08-29).\n' > ~/.switchboard/profiles/codex/config.toml
```

- [ ] **Step 6: Commit and open the PR**

```bash
git switch -c task-4-lane-codex && git add -A
git commit -m "feat: codex lane adapter with isolated CODEX_HOME"
git push -u origin task-4-lane-codex && gh pr create --fill
```

---

### Task 5: Ollama brain lane adapter

**Files:**
- Create: `~/remix-switchboard/switchboard/lanes/ollama.py`
- Test: `~/remix-switchboard/tests/test_lane_ollama.py`

**Interfaces:**
- Consumes: `LaneResult` from `switchboard.lanes`.
- Produces: `run(lane, brief, *, mode, leash, cwd, timeout, transcript_path) -> LaneResult` - identical signature to the other two adapters. Rejects `mode="hands"` because Gemma gate-failed tool use on 2026-08-29.

- [ ] **Step 1: Write the failing test**

Create `tests/test_lane_ollama.py`:

```python
import json
from pathlib import Path
from switchboard.config import Lane
from switchboard.profile import Leash
from switchboard.lanes import ollama

def _lane(tmp_path):
    return Lane(name="gemma", kind="ollama", model="gemma4-remix:latest", modes=["brain"],
                context_tokens=128000, max_concurrency=1, timeout_default=60,
                base_url="http://mini.example:11434", profile_dir=tmp_path / "prof")

def _run(tmp_path, **kw):
    kw.setdefault("mode", "brain"); kw.setdefault("leash", Leash())
    kw.setdefault("cwd", tmp_path); kw.setdefault("timeout", 30)
    kw.setdefault("transcript_path", tmp_path / "t.log")
    return ollama.run(_lane(tmp_path), "why is the sky blue", **kw)

def test_posts_to_chat_endpoint_and_returns_content(tmp_path, monkeypatch):
    seen = {}
    def fake_post(url, payload, timeout):
        seen["url"], seen["payload"] = url, payload
        return {"message": {"content": "rayleigh scattering"}}
    monkeypatch.setattr(ollama, "_post_json", fake_post)
    res = _run(tmp_path)
    assert res.ok and res.output == "rayleigh scattering"
    assert seen["url"] == "http://mini.example:11434/api/chat"
    assert seen["payload"]["model"] == "gemma4-remix:latest"
    assert seen["payload"]["stream"] is False
    assert seen["payload"]["messages"] == [{"role": "user", "content": "why is the sky blue"}]

def test_hands_mode_is_refused_with_a_clear_message(tmp_path, monkeypatch):
    res = _run(tmp_path, mode="hands")
    assert not res.ok
    assert "brain" in res.error and "gemma" in res.error

def test_connection_failure_is_explicit_never_silent(tmp_path, monkeypatch):
    def boom(url, payload, timeout):
        raise OSError("connection refused")
    monkeypatch.setattr(ollama, "_post_json", boom)
    res = _run(tmp_path)
    assert not res.ok and "connection refused" in res.error

def test_empty_content_counts_as_failure(tmp_path, monkeypatch):
    monkeypatch.setattr(ollama, "_post_json", lambda u, p, t: {"message": {"content": "   "}})
    res = _run(tmp_path)
    assert not res.ok and res.error == "empty output"

def test_transcript_is_written_to_disk(tmp_path, monkeypatch):
    monkeypatch.setattr(ollama, "_post_json", lambda u, p, t: {"message": {"content": "hi"}})
    t = tmp_path / "transcript.log"
    _run(tmp_path, transcript_path=t)
    assert "hi" in t.read_text()
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `.venv/bin/pytest tests/test_lane_ollama.py -v`
Expected: FAIL with `ImportError: cannot import name 'ollama'`

- [ ] **Step 3: Write `switchboard/lanes/ollama.py`**

```python
import json, time, urllib.request
from pathlib import Path
from . import LaneResult

def _post_json(url: str, payload: dict, timeout: int) -> dict:
    req = urllib.request.Request(url, data=json.dumps(payload).encode(),
                                 headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read())

def run(lane, brief: str, *, mode: str, leash, cwd: Path, timeout: int,
        transcript_path: Path) -> LaneResult:
    if mode != "brain":
        return LaneResult(ok=False, output="", seconds=0.0,
                          error=f"lane {lane.name!r} supports brain mode only "
                                f"(gemma tool use gate-failed 2026-08-29); got mode={mode!r}")
    payload = {"model": lane.model, "stream": False,
               "messages": [{"role": "user", "content": brief}]}
    t0 = time.monotonic()
    try:
        data = _post_json(f"{lane.base_url}/api/chat", payload, timeout)
    except Exception as e:                       # explicit failure, never silence
        return LaneResult(ok=False, output="", seconds=time.monotonic() - t0, error=str(e))
    elapsed = time.monotonic() - t0
    content = (data.get("message") or {}).get("content", "")
    transcript_path.parent.mkdir(parents=True, exist_ok=True)
    transcript_path.write_text(content)
    if not content.strip():
        return LaneResult(ok=False, output="", seconds=elapsed, error="empty output")
    return LaneResult(ok=True, output=content, seconds=elapsed)
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `.venv/bin/pytest tests/test_lane_ollama.py -v`
Expected: 5 passed

- [ ] **Step 5: Commit and open the PR**

```bash
git switch -c task-5-lane-ollama && git add -A
git commit -m "feat: ollama brain-mode lane adapter"
git push -u origin task-5-lane-ollama && gh pr create --fill
```

---

### Task 6: Run storage and ledger

**Files:**
- Create: `~/remix-switchboard/switchboard/runs.py`
- Test: `~/remix-switchboard/tests/test_runs.py`

**Interfaces:**
- Consumes: nothing from earlier tasks.
- Produces: `runs_root() -> Path` (`$SWITCHBOARD_HOME` or `~/.switchboard`); `new_run_id(lane: str, now: datetime) -> str`; `create_run(run_id, brief, meta, root) -> Path`; `finish_run(run_dir, result_text, meta_updates) -> None`; `load_meta(run_dir) -> dict`; `list_runs(root, limit=20) -> list[dict]`; `find_run(root, run_id) -> Path` (accepts an unambiguous id prefix); `append_ledger(root, record) -> None`.

- [ ] **Step 1: Write the failing test**

Create `tests/test_runs.py`:

```python
import json
from datetime import datetime
from pathlib import Path
import pytest
from switchboard import runs

FIXED = datetime(2026, 8, 29, 14, 30, 5)     # clock injected, never read from the system

def test_run_id_is_sortable_and_names_the_lane():
    rid = runs.new_run_id("glm", FIXED)
    assert rid.startswith("20260829-143005-glm-") and len(rid.split("-")[-1]) == 6

def test_create_run_writes_brief_and_meta(tmp_path):
    d = runs.create_run(runs.new_run_id("glm", FIXED), "do the thing",
                        {"lane": "glm", "mode": "hands"}, root=tmp_path)
    assert (d / "brief.md").read_text() == "do the thing"
    assert json.loads((d / "meta.json").read_text())["lane"] == "glm"
    assert json.loads((d / "meta.json").read_text())["status"] == "running"

def test_finish_run_writes_result_and_updates_status(tmp_path):
    d = runs.create_run(runs.new_run_id("glm", FIXED), "b", {"lane": "glm"}, root=tmp_path)
    runs.finish_run(d, "the answer", {"status": "ok", "seconds": 4.2})
    assert (d / "result.md").read_text() == "the answer"
    meta = runs.load_meta(d)
    assert meta["status"] == "ok" and meta["seconds"] == 4.2

def test_ledger_appends_one_json_line_per_run(tmp_path):
    runs.append_ledger(tmp_path, {"run_id": "a", "lane": "glm"})
    runs.append_ledger(tmp_path, {"run_id": "b", "lane": "codex"})
    lines = (tmp_path / "ledger.jsonl").read_text().strip().split("\n")
    assert len(lines) == 2 and json.loads(lines[1])["lane"] == "codex"

def test_list_runs_returns_newest_first(tmp_path):
    for i, lane in enumerate(["glm", "codex", "gemma"]):
        runs.create_run(runs.new_run_id(lane, datetime(2026, 8, 29, 10, i, 0)),
                        "b", {"lane": lane}, root=tmp_path)
    assert [r["lane"] for r in runs.list_runs(tmp_path)] == ["gemma", "codex", "glm"]

def test_list_runs_on_empty_root_is_explicit_not_an_error(tmp_path):
    assert runs.list_runs(tmp_path) == []

def test_find_run_accepts_an_unambiguous_prefix(tmp_path):
    rid = runs.new_run_id("glm", FIXED)
    runs.create_run(rid, "b", {"lane": "glm"}, root=tmp_path)
    assert runs.find_run(tmp_path, rid[:17]).name == rid

def test_find_run_rejects_an_ambiguous_prefix(tmp_path):
    runs.create_run(runs.new_run_id("glm", FIXED), "b", {"lane": "glm"}, root=tmp_path)
    runs.create_run(runs.new_run_id("glm", FIXED), "b", {"lane": "glm"}, root=tmp_path)
    with pytest.raises(ValueError, match="ambiguous"):
        runs.find_run(tmp_path, "20260829")

def test_find_run_unknown_id_raises_clearly(tmp_path):
    with pytest.raises(ValueError, match="no run"):
        runs.find_run(tmp_path, "nope")

def test_secrets_are_never_written_into_meta(tmp_path):
    d = runs.create_run(runs.new_run_id("glm", FIXED), "b",
                        {"lane": "glm", "api_key": "sekrit", "ANTHROPIC_API_KEY": "sekrit"},
                        root=tmp_path)
    assert "sekrit" not in (d / "meta.json").read_text()
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `.venv/bin/pytest tests/test_runs.py -v`
Expected: FAIL with `ModuleNotFoundError: No module named 'switchboard.runs'`

- [ ] **Step 3: Write `switchboard/runs.py`**

```python
import json, os, uuid
from datetime import datetime
from pathlib import Path

# Anything whose key looks secret is dropped before meta.json is written.
_SECRET_HINTS = ("key", "token", "secret", "password")

def runs_root() -> Path:
    return Path(os.environ.get("SWITCHBOARD_HOME", Path.home() / ".switchboard")).expanduser()

def new_run_id(lane: str, now: datetime) -> str:
    return f"{now:%Y%m%d-%H%M%S}-{lane}-{uuid.uuid4().hex[:6]}"

def _scrub(meta: dict) -> dict:
    return {k: v for k, v in meta.items()
            if not any(h in k.lower() for h in _SECRET_HINTS)}

def create_run(run_id: str, brief: str, meta: dict, root: Path) -> Path:
    d = root / "runs" / run_id
    d.mkdir(parents=True, exist_ok=True)
    (d / "brief.md").write_text(brief)
    payload = {"run_id": run_id, "status": "running", **_scrub(meta)}
    (d / "meta.json").write_text(json.dumps(payload, indent=2))
    return d

def load_meta(run_dir: Path) -> dict:
    return json.loads((run_dir / "meta.json").read_text())

def finish_run(run_dir: Path, result_text: str, meta_updates: dict) -> None:
    (run_dir / "result.md").write_text(result_text)
    meta = load_meta(run_dir)
    meta.update(_scrub(meta_updates))
    (run_dir / "meta.json").write_text(json.dumps(meta, indent=2))

def list_runs(root: Path, limit: int = 20) -> list[dict]:
    d = root / "runs"
    if not d.is_dir():
        return []
    out = []
    for run_dir in sorted(d.iterdir(), reverse=True):
        if (run_dir / "meta.json").exists():
            out.append(load_meta(run_dir))
        if len(out) >= limit:
            break
    return out

def find_run(root: Path, run_id: str) -> Path:
    d = root / "runs"
    matches = [p for p in d.iterdir() if p.name.startswith(run_id)] if d.is_dir() else []
    if not matches:
        raise ValueError(f"no run matching {run_id!r}")
    if len(matches) > 1:
        raise ValueError(f"ambiguous run id {run_id!r}: {len(matches)} matches")
    return matches[0]

def append_ledger(root: Path, record: dict) -> None:
    root.mkdir(parents=True, exist_ok=True)
    with (root / "ledger.jsonl").open("a") as f:
        f.write(json.dumps(_scrub(record)) + "\n")
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `.venv/bin/pytest tests/test_runs.py -v`
Expected: 10 passed

- [ ] **Step 5: Commit and open the PR**

```bash
git switch -c task-6-runs && git add -A
git commit -m "feat: run directories, meta, and ledger"
git push -u origin task-6-runs && gh pr create --fill
```

---

### Task 7: Dispatch orchestration

**Files:**
- Create: `~/remix-switchboard/switchboard/dispatch.py`
- Test: `~/remix-switchboard/tests/test_dispatch.py`

**Interfaces:**
- Consumes: `Lane`, `load_lanes` from `switchboard.config`; `Leash`, `resolve_cwd` from `switchboard.profile`; `adapter_for` from `switchboard.lanes`; everything from `switchboard.runs`.
- Produces: `dispatch(lane_name, brief, *, lanes, mode="hands", leash=Leash(), cwd=None, timeout=None, root=None, now=None) -> dict` returning `{"run_id", "lane", "mode", "status", "seconds", "result", "result_path", "error"}`. Function `make_worktree(repo: Path, run_id: str) -> Path`.

- [ ] **Step 1: Write the failing test**

Create `tests/test_dispatch.py`:

```python
from datetime import datetime
from pathlib import Path
import pytest
from switchboard.config import Lane
from switchboard.profile import Leash
from switchboard.lanes import LaneResult
from switchboard import dispatch as D

FIXED = datetime(2026, 8, 29, 14, 30, 5)

def _lanes(tmp_path):
    return {"glm": Lane(name="glm", kind="gateway", model="glm-5.2-vision",
                        modes=["hands", "brain"], context_tokens=1000, max_concurrency=1,
                        timeout_default=42, base_url="https://gw.example",
                        profile_dir=tmp_path / "prof"),
            "gemma": Lane(name="gemma", kind="ollama", model="g", modes=["brain"],
                          context_tokens=1000, max_concurrency=1, timeout_default=10,
                          base_url="http://mini.example:11434", profile_dir=tmp_path / "p2")}

def _stub(monkeypatch, result, capture=None):
    class FakeAdapter:
        @staticmethod
        def run(lane, brief, **kw):
            if capture is not None:
                capture.update(lane=lane, brief=brief, **kw)
            return result
    monkeypatch.setattr(D, "adapter_for", lambda kind: FakeAdapter)

def test_successful_dispatch_persists_run_and_returns_compact_summary(tmp_path, monkeypatch):
    _stub(monkeypatch, LaneResult(ok=True, output="the answer", seconds=4.2))
    out = D.dispatch("glm", "do it", lanes=_lanes(tmp_path), root=tmp_path, now=FIXED)
    assert out["status"] == "ok" and out["result"] == "the answer" and out["lane"] == "glm"
    assert Path(out["result_path"]).read_text() == "the answer"
    assert (tmp_path / "ledger.jsonl").exists()

def test_unknown_lane_fails_explicitly_and_lists_what_exists(tmp_path):
    with pytest.raises(ValueError, match="unknown lane 'telepathy'.*glm.*gemma"):
        D.dispatch("telepathy", "do it", lanes=_lanes(tmp_path), root=tmp_path, now=FIXED)

def test_mode_not_supported_by_lane_is_refused_before_dispatch(tmp_path):
    with pytest.raises(ValueError, match="does not support mode 'hands'"):
        D.dispatch("gemma", "do it", lanes=_lanes(tmp_path), mode="hands",
                   root=tmp_path, now=FIXED)

def test_lane_timeout_default_is_used_when_none_given(tmp_path, monkeypatch):
    cap = {}
    _stub(monkeypatch, LaneResult(ok=True, output="x", seconds=1.0), cap)
    D.dispatch("glm", "do it", lanes=_lanes(tmp_path), root=tmp_path, now=FIXED)
    assert cap["timeout"] == 42

def test_explicit_timeout_overrides_the_lane_default(tmp_path, monkeypatch):
    cap = {}
    _stub(monkeypatch, LaneResult(ok=True, output="x", seconds=1.0), cap)
    D.dispatch("glm", "do it", lanes=_lanes(tmp_path), timeout=7, root=tmp_path, now=FIXED)
    assert cap["timeout"] == 7

def test_clean_leash_sends_the_agent_to_a_scratch_dir(tmp_path, monkeypatch):
    cap = {}
    _stub(monkeypatch, LaneResult(ok=True, output="x", seconds=1.0), cap)
    repo = tmp_path / "repo"; repo.mkdir(); (repo / "CLAUDE.md").write_text("rules")
    D.dispatch("glm", "review this", lanes=_lanes(tmp_path), leash=Leash(clean=True),
               cwd=repo, root=tmp_path, now=FIXED)
    assert cap["cwd"] != repo and not (cap["cwd"] / "CLAUDE.md").exists()

def test_default_leash_keeps_the_agent_in_the_callers_dir(tmp_path, monkeypatch):
    cap = {}
    _stub(monkeypatch, LaneResult(ok=True, output="x", seconds=1.0), cap)
    repo = tmp_path / "repo"; repo.mkdir()
    D.dispatch("glm", "work", lanes=_lanes(tmp_path), cwd=repo, root=tmp_path, now=FIXED)
    assert cap["cwd"] == repo

def test_lane_failure_is_recorded_not_raised(tmp_path, monkeypatch):
    _stub(monkeypatch, LaneResult(ok=False, output="", seconds=0.5, error="timeout"))
    out = D.dispatch("glm", "do it", lanes=_lanes(tmp_path), root=tmp_path, now=FIXED)
    assert out["status"] == "failed" and out["error"] == "timeout"

def test_ledger_records_the_lane_and_model_for_the_october_question(tmp_path, monkeypatch):
    import json
    _stub(monkeypatch, LaneResult(ok=True, output="x", seconds=2.5))
    D.dispatch("glm", "do it", lanes=_lanes(tmp_path), root=tmp_path, now=FIXED)
    rec = json.loads((tmp_path / "ledger.jsonl").read_text().strip())
    assert rec["lane"] == "glm" and rec["model"] == "glm-5.2-vision" and rec["seconds"] == 2.5
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `.venv/bin/pytest tests/test_dispatch.py -v`
Expected: FAIL with `ModuleNotFoundError: No module named 'switchboard.dispatch'`

- [ ] **Step 3: Write `switchboard/dispatch.py`**

```python
import subprocess
from datetime import datetime
from pathlib import Path
from .lanes import adapter_for
from .profile import Leash, resolve_cwd
from . import runs as R

def make_worktree(repo: Path, run_id: str) -> Path:
    """Writes land in an isolated git worktree, never the live checkout."""
    wt = R.runs_root() / "worktrees" / run_id
    wt.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(["git", "-C", str(repo), "worktree", "add", "-d", str(wt)],
                   check=True, capture_output=True)
    return wt

def dispatch(lane_name: str, brief: str, *, lanes: dict, mode: str = "hands",
             leash: Leash | None = None, cwd: Path | None = None,
             timeout: int | None = None, root: Path | None = None,
             now: datetime | None = None) -> dict:
    leash = leash or Leash()
    root = root or R.runs_root()
    now = now or datetime.now()
    cwd = Path(cwd) if cwd else Path.cwd()

    if lane_name not in lanes:
        raise ValueError(f"unknown lane {lane_name!r}; available: {', '.join(sorted(lanes))}")
    lane = lanes[lane_name]
    if mode not in lane.modes:
        raise ValueError(f"lane {lane_name!r} does not support mode {mode!r}; "
                         f"supports: {', '.join(lane.modes)}")

    run_id = R.new_run_id(lane_name, now)
    run_dir = R.create_run(run_id, brief,
                           {"lane": lane_name, "model": lane.model, "mode": mode,
                            "clean": leash.clean, "mcp": leash.mcp, "write": leash.write,
                            "started_at": now.isoformat()},
                           root=root)

    work_cwd = resolve_cwd(leash, cwd, root / "scratch" / run_id)
    if leash.write and not leash.clean:
        work_cwd = make_worktree(cwd, run_id)

    result = adapter_for(lane.kind).run(
        lane, brief, mode=mode, leash=leash, cwd=work_cwd,
        timeout=timeout if timeout is not None else lane.timeout_default,
        transcript_path=run_dir / "transcript.log")

    status = "ok" if result.ok else "failed"
    R.finish_run(run_dir, result.output,
                 {"status": status, "seconds": round(result.seconds, 2),
                  "error": result.error, "cwd": str(work_cwd)})
    R.append_ledger(root, {"run_id": run_id, "lane": lane_name, "model": lane.model,
                           "mode": mode, "status": status,
                           "seconds": round(result.seconds, 2),
                           "recorded_at": now.isoformat()})
    return {"run_id": run_id, "lane": lane_name, "mode": mode, "status": status,
            "seconds": round(result.seconds, 2), "result": result.output,
            "result_path": str(run_dir / "result.md"), "error": result.error}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `.venv/bin/pytest tests/test_dispatch.py -v`
Expected: 9 passed

- [ ] **Step 5: Commit and open the PR**

```bash
git switch -c task-7-dispatch && git add -A
git commit -m "feat: dispatch orchestration with worktree writes and ledger"
git push -u origin task-7-dispatch && gh pr create --fill
```

---

### Task 8: Lane health probe

**Files:**
- Create: `~/remix-switchboard/switchboard/health.py`
- Test: `~/remix-switchboard/tests/test_health.py`

**Interfaces:**
- Consumes: `Lane` from `switchboard.config`.
- Produces: `check_lane(lane, *, timeout=10) -> dict` returning `{"lane", "ok", "detail"}`; `check_all(lanes, *, timeout=10) -> list[dict]`.

- [ ] **Step 1: Write the failing test**

Create `tests/test_health.py`:

```python
from pathlib import Path
from switchboard.config import Lane
from switchboard import health

def _ollama(tmp_path):
    return Lane(name="gemma", kind="ollama", model="gemma4-remix:latest", modes=["brain"],
                context_tokens=1, max_concurrency=1, timeout_default=1,
                base_url="http://mini.example:11434", profile_dir=tmp_path)

def _gateway(tmp_path, key=None):
    return Lane(name="glm", kind="gateway", model="glm-5.2-vision", modes=["hands"],
                context_tokens=1, max_concurrency=1, timeout_default=1,
                base_url="https://gw.example", api_key_path=key, profile_dir=tmp_path)

def test_ollama_lane_is_healthy_when_the_model_is_present(tmp_path, monkeypatch):
    monkeypatch.setattr(health, "_get_json",
                        lambda u, t: {"models": [{"name": "gemma4-remix:latest"}]})
    assert health.check_lane(_ollama(tmp_path))["ok"] is True

def test_ollama_lane_is_unhealthy_when_the_model_is_missing(tmp_path, monkeypatch):
    monkeypatch.setattr(health, "_get_json", lambda u, t: {"models": [{"name": "other"}]})
    r = health.check_lane(_ollama(tmp_path))
    assert r["ok"] is False and "not installed" in r["detail"]

def test_unreachable_host_is_explicit_never_silent(tmp_path, monkeypatch):
    def boom(u, t): raise OSError("no route to host")
    monkeypatch.setattr(health, "_get_json", boom)
    r = health.check_lane(_ollama(tmp_path))
    assert r["ok"] is False and "no route to host" in r["detail"]

def test_gateway_lane_reports_missing_key_file(tmp_path):
    r = health.check_lane(_gateway(tmp_path, key=tmp_path / "absent"))
    assert r["ok"] is False and "key file missing" in r["detail"]

def test_gateway_lane_is_healthy_when_the_model_is_listed(tmp_path, monkeypatch):
    key = tmp_path / "k"; key.write_text("sekrit")
    monkeypatch.setattr(health, "_get_json", lambda u, t: {"data": [{"id": "glm-5.2-vision"}]})
    assert health.check_lane(_gateway(tmp_path, key=key))["ok"] is True

def test_gateway_lane_flags_a_renamed_model(tmp_path, monkeypatch):
    # GLM has already churned once (nvfp4 -> vision); this is the canary for it.
    key = tmp_path / "k"; key.write_text("sekrit")
    monkeypatch.setattr(health, "_get_json", lambda u, t: {"data": [{"id": "glm-6.0"}]})
    r = health.check_lane(_gateway(tmp_path, key=key))
    assert r["ok"] is False and "not offered" in r["detail"]

def test_check_all_returns_one_row_per_lane(tmp_path, monkeypatch):
    monkeypatch.setattr(health, "_get_json", lambda u, t: {"models": [{"name": "gemma4-remix:latest"}]})
    rows = health.check_all({"gemma": _ollama(tmp_path)})
    assert len(rows) == 1 and rows[0]["lane"] == "gemma"
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `.venv/bin/pytest tests/test_health.py -v`
Expected: FAIL with `ModuleNotFoundError: No module named 'switchboard.health'`

- [ ] **Step 3: Write `switchboard/health.py`**

```python
import json, shutil, urllib.request

def _get_json(url: str, timeout: int) -> dict:
    with urllib.request.urlopen(url, timeout=timeout) as r:
        return json.loads(r.read())

def check_lane(lane, *, timeout: int = 10) -> dict:
    def result(ok, detail):
        return {"lane": lane.name, "ok": ok, "detail": detail}
    try:
        if lane.kind == "ollama":
            names = [m["name"] for m in _get_json(f"{lane.base_url}/api/tags", timeout)["models"]]
            if lane.model not in names:
                return result(False, f"model {lane.model!r} not installed on {lane.base_url}")
            return result(True, f"{lane.model} ready")
        if lane.kind == "gateway":
            if lane.api_key_path and not lane.api_key_path.exists():
                return result(False, f"key file missing: {lane.api_key_path}")
            ids = [m["id"] for m in _get_json(f"{lane.base_url}/v1/models", timeout).get("data", [])]
            if ids and lane.model not in ids:
                return result(False, f"model {lane.model!r} not offered by {lane.base_url}; "
                                     f"gateway lists: {', '.join(ids[:5])}")
            return result(True, f"{lane.model} ready")
        if lane.kind == "codex":
            if not shutil.which("codex"):
                return result(False, "codex binary not on PATH")
            return result(True, "codex on PATH")
        if lane.kind == "anthropic":
            if not shutil.which("claude"):
                return result(False, "claude binary not on PATH")
            return result(True, "claude on PATH")
        return result(False, f"unknown kind {lane.kind!r}")
    except Exception as e:
        return result(False, str(e))

def check_all(lanes: dict, *, timeout: int = 10) -> list[dict]:
    return [check_lane(l, timeout=timeout) for l in lanes.values()]
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `.venv/bin/pytest tests/test_health.py -v`
Expected: 7 passed

- [ ] **Step 5: Commit and open the PR**

```bash
git switch -c task-8-health && git add -A
git commit -m "feat: per-lane health probe"
git push -u origin task-8-health && gh pr create --fill
```

---

### Task 9: CLI

**Files:**
- Create: `~/remix-switchboard/switchboard/cli.py`
- Test: `~/remix-switchboard/tests/test_cli.py`

**Interfaces:**
- Consumes: everything from Tasks 1, 6, 7, 8.
- Produces: `main(argv: list[str] | None = None) -> int`. Verbs: `dispatch`, `list`, `log`, `kill`, `lanes`.

- [ ] **Step 1: Write the failing test**

Create `tests/test_cli.py`:

```python
import json
from pathlib import Path
import pytest
from switchboard import cli

LANES = """
lanes:
  glm:
    kind: gateway
    model: glm-5.2-vision
    modes: [hands, brain]
    base_url: https://gw.example
    context_tokens: 1000
    max_concurrency: 1
    timeout_default: 60
"""

@pytest.fixture
def env(tmp_path, monkeypatch):
    cfg = tmp_path / "lanes.yaml"; cfg.write_text(LANES)
    monkeypatch.setenv("SWITCHBOARD_CONFIG", str(cfg))
    monkeypatch.setenv("SWITCHBOARD_HOME", str(tmp_path / "home"))
    return tmp_path

def test_dispatch_prints_compact_summary_not_the_transcript(env, monkeypatch, capsys):
    monkeypatch.setattr(cli, "dispatch", lambda *a, **k: {
        "run_id": "20260829-143005-glm-abc123", "lane": "glm", "mode": "hands",
        "status": "ok", "seconds": 4.2, "result": "the answer",
        "result_path": "/x/result.md", "error": None})
    assert cli.main(["dispatch", "--lane", "glm", "do the thing"]) == 0
    out = capsys.readouterr().out
    assert "ok" in out and "glm" in out and "the answer" in out
    assert "sb log 20260829-143005-glm-abc123" in out      # next-step hint

def test_dispatch_failure_returns_nonzero_and_names_the_error(env, monkeypatch, capsys):
    monkeypatch.setattr(cli, "dispatch", lambda *a, **k: {
        "run_id": "r1", "lane": "glm", "mode": "hands", "status": "failed",
        "seconds": 1.0, "result": "", "result_path": "/x", "error": "timeout"})
    assert cli.main(["dispatch", "--lane", "glm", "do it"]) == 1
    assert "timeout" in capsys.readouterr().out

def test_dispatch_reads_brief_from_stdin_when_given_a_dash(env, monkeypatch, capsys):
    seen = {}
    def fake(lane, brief, **kw):
        seen["brief"] = brief
        return {"run_id": "r", "lane": lane, "mode": "hands", "status": "ok",
                "seconds": 1.0, "result": "x", "result_path": "/x", "error": None}
    monkeypatch.setattr(cli, "dispatch", fake)
    monkeypatch.setattr("sys.stdin", __import__("io").StringIO("piped brief"))
    cli.main(["dispatch", "--lane", "glm", "-"])
    assert seen["brief"] == "piped brief"

def test_unknown_lane_prints_the_available_lanes(env, capsys):
    assert cli.main(["dispatch", "--lane", "telepathy", "do it"]) == 2
    assert "glm" in capsys.readouterr().err

def test_list_on_empty_home_says_so_explicitly(env, capsys):
    assert cli.main(["list"]) == 0
    assert "no runs" in capsys.readouterr().out.lower()

def test_lanes_lists_configured_lanes(env, capsys):
    assert cli.main(["lanes"]) == 0
    out = capsys.readouterr().out
    assert "glm" in out and "hands" in out

def test_lanes_check_reports_health_per_lane(env, monkeypatch, capsys):
    monkeypatch.setattr(cli, "check_all",
                        lambda lanes, **k: [{"lane": "glm", "ok": False, "detail": "key file missing"}])
    assert cli.main(["lanes", "--check"]) == 1
    assert "key file missing" in capsys.readouterr().out

def test_log_prints_the_result_by_default(env, capsys):
    from switchboard import runs as R
    from datetime import datetime
    root = Path(env / "home")
    d = R.create_run(R.new_run_id("glm", datetime(2026, 8, 29, 1, 2, 3)), "b",
                     {"lane": "glm"}, root=root)
    R.finish_run(d, "the answer", {"status": "ok"})
    (d / "transcript.log").write_text("noisy chatter")
    assert cli.main(["log", d.name]) == 0
    out = capsys.readouterr().out
    assert "the answer" in out and "noisy chatter" not in out

def test_log_full_prints_the_transcript(env, capsys):
    from switchboard import runs as R
    from datetime import datetime
    root = Path(env / "home")
    d = R.create_run(R.new_run_id("glm", datetime(2026, 8, 29, 1, 2, 3)), "b",
                     {"lane": "glm"}, root=root)
    R.finish_run(d, "the answer", {"status": "ok"})
    (d / "transcript.log").write_text("noisy chatter")
    cli.main(["log", d.name, "--full"])
    assert "noisy chatter" in capsys.readouterr().out

def test_there_is_no_auto_lane_selection_flag(env):
    # The bright line: the switchboard dials, it never decides.
    with pytest.raises(SystemExit):
        cli.main(["dispatch", "--auto", "do it"])
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `.venv/bin/pytest tests/test_cli.py -v`
Expected: FAIL with `ModuleNotFoundError: No module named 'switchboard.cli'`

- [ ] **Step 3: Write `switchboard/cli.py`**

```python
import argparse, os, signal, sys
from pathlib import Path
from .config import config_path, load_lanes
from .dispatch import dispatch
from .health import check_all
from .profile import Leash
from . import runs as R

def _build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(prog="sb", description="Dispatch a sub-agent to another model family.")
    sub = p.add_subparsers(dest="verb", required=True)

    d = sub.add_parser("dispatch", help="fire a sub-agent on a lane")
    d.add_argument("--lane", required=True)           # never optional: no auto-selection
    d.add_argument("--mode", default="hands", choices=["hands", "brain"])
    d.add_argument("--clean", action="store_true", help="withhold project conventions (review only)")
    d.add_argument("--mcp", action="store_true", help="grant account access via MCP servers")
    d.add_argument("--write", action="store_true", help="allow writes (into an isolated worktree)")
    d.add_argument("--timeout", type=int, default=None)
    d.add_argument("--cwd", default=None)
    d.add_argument("brief", help="the brief, a file path, or - for stdin")

    l = sub.add_parser("list", help="recent runs, newest first")
    l.add_argument("--limit", type=int, default=20)

    g = sub.add_parser("log", help="show a run's result")
    g.add_argument("run_id"); g.add_argument("--full", action="store_true")

    k = sub.add_parser("kill", help="stop a running sub-agent")
    k.add_argument("run_id")

    n = sub.add_parser("lanes", help="available lanes")
    n.add_argument("--check", action="store_true", help="probe each lane and report health")
    return p

def _read_brief(arg: str) -> str:
    if arg == "-":
        return sys.stdin.read()
    p = Path(arg)
    return p.read_text() if p.is_file() else arg

def main(argv: list[str] | None = None) -> int:
    args = _build_parser().parse_args(argv)
    root = R.runs_root()
    lanes = load_lanes(config_path())

    if args.verb == "dispatch":
        try:
            out = dispatch(args.lane, _read_brief(args.brief), lanes=lanes, mode=args.mode,
                           leash=Leash(clean=args.clean, mcp=args.mcp, write=args.write),
                           cwd=Path(args.cwd) if args.cwd else None,
                           timeout=args.timeout, root=root)
        except ValueError as e:
            print(str(e), file=sys.stderr)
            return 2
        # Compact by default: the orchestrator's context stays clean.
        print(f"[{out['status']}] {out['lane']}/{out['mode']}  {out['seconds']}s  {out['run_id']}")
        if out["error"]:
            print(f"error: {out['error']}")
        if out["result"]:
            print()
            print(out["result"].strip())
        print(f"\nNext: sb log {out['run_id']} --full   (transcript at {out['result_path']})")
        return 0 if out["status"] == "ok" else 1

    if args.verb == "list":
        rows = R.list_runs(root, limit=args.limit)
        if not rows:
            print("no runs yet. Next: sb dispatch --lane <lane> \"<brief>\"")
            return 0
        for r in rows:
            print(f"{r['run_id']}  {r.get('status','?'):8} {r.get('lane','?'):10} "
                  f"{r.get('seconds','?')}s")
        print(f"\n{len(rows)} run(s). Next: sb log <run-id>")
        return 0

    if args.verb == "log":
        try:
            d = R.find_run(root, args.run_id)
        except ValueError as e:
            print(str(e), file=sys.stderr)
            return 2
        f = d / ("transcript.log" if args.full else "result.md")
        print(f.read_text() if f.exists() else f"(no {f.name} for this run)")
        return 0

    if args.verb == "kill":
        try:
            d = R.find_run(root, args.run_id)
        except ValueError as e:
            print(str(e), file=sys.stderr)
            return 2
        meta = R.load_meta(d)
        pid = meta.get("pid")
        if not pid or meta.get("status") != "running":
            print(f"run {d.name} is not running (status: {meta.get('status')})")
            return 0
        os.kill(pid, signal.SIGTERM)
        R.finish_run(d, "", {"status": "killed"})
        print(f"killed {d.name}")
        return 0

    if args.verb == "lanes":
        if args.check:
            rows = check_all(lanes)
            for r in rows:
                print(f"{'OK  ' if r['ok'] else 'DOWN'}  {r['lane']:12} {r['detail']}")
            return 0 if all(r["ok"] for r in rows) else 1
        for name, lane in sorted(lanes.items()):
            print(f"{name:12} {lane.kind:9} {lane.model:22} modes={','.join(lane.modes)}")
        print(f"\n{len(lanes)} lane(s). Next: sb lanes --check")
        return 0
    return 2
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `.venv/bin/pytest tests/test_cli.py -v`
Expected: 10 passed

- [ ] **Step 5: Run the full suite**

Run: `.venv/bin/pytest -v`
Expected: 78 passed

- [ ] **Step 6: Commit and open the PR**

```bash
git switch -c task-9-cli && git add -A
git commit -m "feat: sb CLI with dispatch, list, log, kill, lanes"
git push -u origin task-9-cli && gh pr create --fill
```

---

### Task 10: Install, live verification, rubric, and the Claude Code skill

The first nine tasks are proven against fake binaries. This task proves the real thing works against real lanes, then gives the harnesses a door to it.

**Files:**
- Create: `~/remix-switchboard/config/rubric.md`
- Create: `~/remix-switchboard/README.md`
- Create: `~/.claude/skills/skills/switchboard/SKILL.md`
- Install: `~/.config/switchboard/lanes.yaml`, `~/.config/switchboard/rubric.md`

**Interfaces:**
- Consumes: the installed `sb` entry point from Task 1's `pyproject.toml`.
- Produces: nothing further in code.

- [ ] **Step 1: Install the config and the CLI**

```bash
mkdir -p ~/.config/switchboard
cp ~/remix-switchboard/config/lanes.example.yaml ~/.config/switchboard/lanes.yaml
cd ~/remix-switchboard && .venv/bin/pip install --only-binary :all: -e .
```

- [ ] **Step 2: Verify every lane is reachable for real**

Run: `~/remix-switchboard/.venv/bin/sb lanes --check`
Expected: `OK` for `codex`, `glm`, `gemma`, `gemma-small`. If `gemma` reports DOWN, the Mini is asleep - wake it and re-run. Do not proceed until every lane reports OK.

- [ ] **Step 3: Verify a real round trip on each lane**

```bash
SB=~/remix-switchboard/.venv/bin/sb
$SB dispatch --lane glm   --mode brain "Reply with exactly: LANE OK"
$SB dispatch --lane codex --mode hands "Reply with exactly: LANE OK"
$SB dispatch --lane gemma-small --mode brain "Reply with exactly: LANE OK"
```
Expected: each prints `[ok]`, the reply, and a `Next: sb log ...` hint. Expected latencies from the 2026-08-29 measurements: glm ~5s, codex ~7s, gemma-small ~10s.

- [ ] **Step 4: Verify the refusals actually refuse**

A control never observed refusing is a hypothesis, not a control.

```bash
$SB dispatch --lane gemma --mode hands "anything"     # expect: brain-mode-only refusal, exit 2
$SB dispatch --lane nope  --mode brain "anything"     # expect: unknown lane + list, exit 2
$SB dispatch --auto "anything"                        # expect: argparse rejects; no such flag
$SB list                                              # expect: the 3 runs from Step 3
```
Expected: the first two print a specific message and exit non-zero; the third fails as an unrecognized argument; `list` shows three runs newest-first.

- [ ] **Step 5: Write `config/rubric.md` and install it**

```markdown
# Switchboard routing rubric

Read this before choosing a lane. It is data, not code - edit it freely as evidence
arrives. The switchboard dials; you decide.

## Provisional, pending eval-kit evidence (v0, 2026-08-29)

- **Cross-family adversarial review** -> the family OPPOSITE whoever wrote the work.
  Use `--clean`. This is the killer app: a reviewer briefed on our rulebook just
  agrees with our rulebook.
- **Structure and scaffolding drafts** -> `glm`. First graded head-to-head (Tullman
  proposal, 2026-08-29): completeness 5/5, accuracy 1/5. It inverted a fact, cited an
  untraceable source, and invented a word cap. Gets the shape right, confidently wrong
  on specifics. NEVER route fact-critical work here.
- **Bulk mechanical brain work** -> `gemma` (free, private, always on). Sits below
  Haiku on the judgment ladder until eval evidence promotes it. Brain mode only.
- **Anything client-stakes or fact-critical** -> stays on frontier Claude. Do not
  dispatch it at all.

## Always

- Write the brief for a stranger: a dispatched sub-agent has no CLAUDE.md, no memory,
  and no idea who Stafford is. State the goal, the inputs, the constraints, and the
  exact shape of the output you expect.
- Secrets, API keys, and credentials never go into a brief. Any lane, always.
- Same-family work does NOT belong here. Inside Claude Code, use the native Agent tool.
```

```bash
cp ~/remix-switchboard/config/rubric.md ~/.config/switchboard/rubric.md
```

- [ ] **Step 6: Write the Claude Code skill**

Create `~/.claude/skills/skills/switchboard/SKILL.md`:

```markdown
---
name: switchboard
description: Dispatch a sub-agent to a different model family (GPT via Codex, GLM via Lunaroute, local Gemma) and get the result back. Use when a task wants a second opinion from outside the Claude family, an adversarial review of work Claude just produced, bulk mechanical work that should run locally and free, or when Justin says "ask Codex", "ask GLM", "have another model look at this", "second opinion", or /switchboard.
---

# Switchboard

Cross-family sub-agent dispatch. `sb` is installed at `~/remix-switchboard/.venv/bin/sb`.

**This is ONLY for crossing model families.** Claude-family sub-agents keep using the
native Agent tool - it is better integrated (background runs, notifications, isolation).

## Before dispatching

Read `~/.config/switchboard/rubric.md`. It says which lane earns which work and is
updated as eval evidence arrives. You choose the lane; the CLI never chooses for you.

## Commands

    sb lanes                    # what's available
    sb lanes --check            # probe each lane, report health
    sb dispatch --lane <lane> --mode <hands|brain> "<brief>"
    sb list                     # recent runs
    sb log <run-id> [--full]    # result, or the whole transcript
    sb kill <run-id>

Briefs can be a quoted string, a file path, or `-` to read stdin.

## Flags that matter

- `--clean` - withholds our repo conventions and CLAUDE.md. Use ONLY for adversarial
  review. A reviewer that has read our rulebook will just agree with our rulebook.
- `--mcp` - grants account access (Gmail, Drive, Slack, RemixOS). Off by default. Only
  add it when the task genuinely needs it.
- `--write` - allows writes, into an isolated git worktree, never the live checkout.
  Default is read-only.

## Writing the brief

The sub-agent is a stranger: no CLAUDE.md, no memory, no idea who Stafford is. Make
every brief self-contained - goal, inputs (paths or inline), constraints, and the exact
shape of the output. Never put secrets, API keys, or credentials in a brief.

## Reporting back

`sb dispatch` returns a compact summary on purpose - status, timing, and the answer, not
the transcript. Keep it that way; pulling a full transcript into your context defeats the
point of delegating. Fetch it with `sb log <id> --full` only when actually debugging.
```

- [ ] **Step 7: Verify the skill's door works end to end**

Run: `~/remix-switchboard/.venv/bin/sb dispatch --lane codex --mode hands --clean "Read nothing. Reply with exactly: CLEAN ROOM OK"`
Expected: `[ok]` with the reply, and the run's `meta.json` records `"clean": true`. Confirm with `sb log <run-id>`.

- [ ] **Step 8: Write `README.md`**

```markdown
# remix-switchboard

Cross-family sub-agent dispatch. One CLI (`sb`) that lets any harness - Claude Code,
Codex, Cowork - fire a sub-agent on a different model family and get the result back.

Design spec: `ClaudeProjects/docs/superpowers/specs/2026-08-29-switchboard-design.md`.

## Install

    python -m venv .venv && .venv/bin/pip install --only-binary :all: -e .
    mkdir -p ~/.config/switchboard
    cp config/lanes.example.yaml ~/.config/switchboard/lanes.yaml
    cp config/rubric.md ~/.config/switchboard/rubric.md
    .venv/bin/sb lanes --check

## Lanes

Configured in `~/.config/switchboard/lanes.yaml`. Adding a model is an edit there, never
a code change. Kinds: `anthropic`, `gateway` (any Anthropic-dialect endpoint), `codex`,
`ollama`.

## The bright line

The switchboard dials; it never decides. There is deliberately no flag that picks a lane
for you - routing judgment belongs to the calling agent, guided by
`~/.config/switchboard/rubric.md`. Do not add one.

## Rules

- Branch, PR, self-review, self-merge. Never push to `main`.
- Runs and the ledger live in `~/.switchboard/` and are not committed.
- Secrets never enter a brief, a run's `meta.json`, or the ledger.
```

- [ ] **Step 9: Commit, PR, merge, and verify it is live**

```bash
cd ~/remix-switchboard
git switch -c task-10-install && git add -A
git commit -m "feat: rubric, README, Claude Code skill, live lane verification"
git push -u origin task-10-install && gh pr create --fill
gh pr merge --squash --delete-branch
git switch main && git pull && ~/remix-switchboard/.venv/bin/sb lanes --check
```

Then commit the skill separately in the skills repo:

```bash
cd ~/.claude/skills && git switch -c switchboard-skill
git add skills/switchboard/SKILL.md
git commit -m "feat: switchboard skill - cross-family sub-agent dispatch"
git push -u origin switchboard-skill && gh pr create --fill && gh pr merge --squash --delete-branch
```

---

## Self-Review

**Spec coverage.** Purpose -> Tasks 7, 9. Two modes -> Tasks 3-5 (`mode` parameter; Task 5 refuses `hands`). Lane registry -> Task 1. Isolation vs. leash -> Task 2 (always-on) and Task 3 (leash-driven tool sets, `--clean`, `--mcp`). Briefs for strangers -> Task 10 rubric and skill. CLI surface, all five verbs -> Task 9. Run storage -> Task 6. Output contract: compact default, explicit failures, explicit completion, next-step hints, shortcut-not-gate -> Tasks 3-6, 9 and the README. Safety model -> Task 3 (deny-list, read-only default), Task 7 (`make_worktree`), Task 9 (`--mcp` opt-in). Data policy -> Task 6 (`_scrub`) and the rubric. Routing rubric -> Task 10. The bright line -> asserted by test in Task 9, restated in the README. Agent-native checklist -> the five verbs give CRUD parity; lanes and rubric are config; no gaps found.

**Concurrency caps.** `max_concurrency` is loaded and validated in Task 1 but nothing enforces it in v1, because v1 dispatches one run at a time. This is deliberate and stated here rather than left implicit: the field exists for the fan-out work that comes after v1.

**Placeholder scan.** No TBD/TODO. Every code step carries real code. Every test step carries real assertions. No "similar to Task N" references.

**Type consistency.** `Lane` fields are identical across Tasks 1-8. `LaneResult` is defined once in Task 3's `lanes/__init__.py` and imported by Tasks 4 and 5. All three adapters implement the same `run(lane, brief, *, mode, leash, cwd, timeout, transcript_path)` signature. `Leash(clean, mcp, write)` is used consistently in Tasks 2, 3, 4, 7, 9. `runs.py` function names match their call sites in `dispatch.py` and `cli.py`. `check_all(lanes)` takes the lane dict in both Task 8 and Task 9.
