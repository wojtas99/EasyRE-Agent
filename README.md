<div align="center">

# 🧩 EasyRE-Agent

**Give it a binary and a task. Pick any model. Get the answer, or learn how to find it yourself.**

![Docker](https://img.shields.io/badge/runs%20in-Docker-2496ED?logo=docker&logoColor=white)
![Python](https://img.shields.io/badge/driver-Python%203-3776AB?logo=python&logoColor=white)
![Backends](https://img.shields.io/badge/backends-Claude%20%7C%20Codex%20%7C%20OpenAI--compatible-8A2BE2)
![License](https://img.shields.io/badge/license-MIT-green)

</div>

---

## ✨ What it does

EasyRE-Agent runs an AI agent inside a Docker container. The container holds your reverse engineering toolchain, and the agent uses it to solve a task you give it.

```
📁 tasks/crackme ─► 🔎 triage ─► 🤖 agent (your model) ─► ✅ verifier ─► 📄 report.md / 💡 hints.md
```

| | Feature | |
|---|---|---|
| 🤖 | **Any model** | Claude Code, OpenAI Codex, or any OpenAI-compatible API: OpenRouter, Ollama, LM Studio, vLLM |
| ✅ | **Verified answers** | Checks against a regex, a success message, or your own command. The agent keeps working until a candidate passes. |
| 🎓 | **Hint mode** | The agent solves privately and gives you graded hints, one at a time. The answer stays hidden, including in the console output. |
| 🧑‍🏫 | **Tutor mode** | An interactive tutor: you tell it what you did, and it guides you step by step without spoiling the answer |
| 💰 | **Stats** | Totals of time, tokens and cost per model over all jobs |
| ⏱️ | **Budgets** | Time and token limits per job |
| 🔁 | **Resumable** | Continue a job later with more time or a different model |
| 🔎 | **Triage** | File types, runtimes and packers detected up front |
| 📄 | **Reports** | Answer, solution path, scripts, dead ends, time and tokens |
| 🧰 | **Your toolchain** | Plug-in install script plus Markdown skills (playbooks) the agent reads on demand |

---

## 🚀 Quick start

Pick your system: [🪟 Windows](#-windows) · [🐧 Linux](#-linux) · [🍎 macOS](#-macos)

You need about 5 GB of free disk space (see [💾 Disk space](#-disk-space)).

### 🪟 Windows

1. **Install Docker.** Get [Docker Desktop](https://www.docker.com/products/docker-desktop/), install it with the default settings (WSL 2), and start it.
2. **Run the setup.** Double-click **`setup.cmd`** in the project folder. It builds the image, asks which model to use, logs you in and checks everything (see [⚙️ What the setup does](#️-what-the-setup-does)).
3. **Add a task.** Put the files into a folder under `tasks`:
   ```
   tasks\crackme\crackme.exe
   tasks\crackme\task.md      (description, optional)
   ```
4. **Solve it.** Open PowerShell or Command Prompt in the project folder:
   ```powershell
   .\easyre.cmd run crackme --success "Correct"
   .\easyre.cmd open
   ```
   The first command solves the task. The second opens the report.

### 🐧 Linux

1. **Install Docker.** Install [Docker Engine](https://docs.docker.com/engine/install/) with the Compose plugin. Then let your user run Docker without `sudo`, and log out and back in:
   ```bash
   sudo usermod -aG docker $USER
   ```
2. **Run the setup** in the project folder:
   ```bash
   sh setup.sh
   ```
3. **Add a task:** put its files into `tasks/crackme/` (plus an optional `task.md` with the description).
4. **Solve it:**
   ```bash
   sh easyre.sh run crackme --success "Correct"
   sh easyre.sh open
   ```

> The image is x86-64 (Wine needs 32-bit x86 libraries). On ARM Linux it runs only with x86 emulation (qemu/binfmt) and is slow.

### 🍎 macOS

1. **Install Docker.** Get [Docker Desktop for Mac](https://www.docker.com/products/docker-desktop/) and start it. On Apple Silicon (M1–M4), enable **Settings → General → Use Rosetta for x86_64/amd64 emulation**. The image is x86-64, so it runs emulated there: it works, but builds and runs more slowly.
2. **Run the setup** in Terminal, in the project folder:
   ```bash
   sh setup.sh
   ```
3. **Add a task:** put its files into `tasks/crackme/` (plus an optional `task.md` with the description).
4. **Solve it:**
   ```bash
   sh easyre.sh run crackme --success "Correct"
   sh easyre.sh open
   ```

> 📝 The examples below use the Windows form `.\easyre.cmd`. On Linux and macOS, write `sh easyre.sh` instead; everything else is the same.

### ⚙️ What the setup does

1. Checks that Docker runs.
2. Builds the image (the first build takes several minutes).
3. Asks which model you want to use and logs you in:

   | | Choice | You need |
   |---|---|---|
   | 🟠 | Claude subscription (recommended) | Claude Pro or Max account |
   | 🟠 | Claude API key | Anthropic API key |
   | 🟢 | ChatGPT account via Codex | ChatGPT account |
   | 🟢 | OpenAI API key | OpenAI API key |
   | 🔵 | OpenRouter | OpenRouter API key |
   | 💎 | Google Gemini | Gemini API key from aistudio.google.com |
   | 🦙 | Ollama (local, free) | Ollama running with a model that supports tool calling |
   | 🖥️ | LM Studio (local, free) | LM Studio server running |

4. Runs `easyre doctor` to check that everything works.

`--success` is the text the program prints when the answer is right. Leave it out if the program prints nothing like that.

### 🩺 Something wrong?

```powershell
.\easyre.cmd doctor
```

`doctor` checks your model profile, credentials, API connection, Wine and skills. It shows each problem together with how to fix it. To switch models later, run the setup again, or see [🎛️ Profiles](#️-profiles).

**Colors:** the output is colored. If you see codes like `←[32m` instead of colors, use Windows Terminal, or add `NO_COLOR=1` to `.env`.

---

## 🕹️ Usage

```
easyre run TARGET [options]     solve a task (folder or file under ./tasks)
easyre resume JOB [options]     continue a job
easyre hint JOB [--answer]      next hint (or reveal the answer)
easyre tutor JOB                continue a tutor conversation
easyre jobs                     list jobs
easyre open [JOB] [folder]      open a job's report (or tutor chat, or folder)
easyre profiles                 list model profiles
easyre doctor                   check that the setup works
easyre stats                    time, tokens and cost per model
easyre close JOB                mark a job as closed (resume reopens it)
easyre rm JOB... | --FILTER     delete job folders; filters: --open --closed --unsolved --solved --all
easyre login claude|codex       authenticate a backend
```

| Option | Description |
|---|---|
| `--desc` / `--desc-file` | Task description. Default: `task.md`, `opis.txt` or `README.md` from the task folder. |
| `--success REGEX` | Output that means the answer was accepted |
| `--verify CMD` | Checker command. `{}` is replaced by the candidate; otherwise the candidate goes to stdin. |
| `--flag-format REGEX` | Required answer shape, e.g. `"flag\{.+\}"` |
| `--profile` | Model profile from `config/backends.toml` |
| `--backend` | `claude` (default), `codex` or `openai` |
| `--model` | Model name for the backend |
| `--mode` | `solve` (default), `hint` or `tutor` |
| `--budget-min` / `--budget-tokens` | Time budget in minutes (default 120) and output-token budget |
| `-i` | Interactive session (Claude Code / Codex UI) |

### 📌 Examples

```powershell
.\easyre.cmd run crackme --success "(?i)correct"
.\easyre.cmd run keygenme --verify "wine /work/src/app.exe {}" --success "Valid"
.\easyre.cmd run ctf-rev --flag-format "CTF\{.+\}"
.\easyre.cmd run crackme --mode hint
.\easyre.cmd hint crackme
.\easyre.cmd run crackme --mode tutor --success "Correct"
.\easyre.cmd tutor crackme
.\easyre.cmd run crackme --backend openai --model qwen3-coder --budget-min 30
.\easyre.cmd resume crackme --budget-min 60
```

### 📂 Opening results

```powershell
.\easyre.cmd open
.\easyre.cmd open crackme
.\easyre.cmd open crackme folder
```

1. Opens the newest job's `report.md` (or `tutor.md` for tutor jobs) in your default app.
2. Opens the newest job whose name starts with `crackme`.
3. Opens that job's folder in Explorer.

`open` runs on your computer, not in Docker, so it starts instantly.

### 🧑‍🏫 Tutor mode

```
.\easyre.cmd run crackme --mode tutor --success "Correct"
```

1. The agent first solves the task privately. The console shows only progress, so nothing spoils the answer.
2. Then a chat starts. Tell it what you did and what you see, and it replies to where **you** are: it confirms the right path, warns about dead ends, and suggests one small next step.

```
tutor> This is a small 64-bit console program. What have you tried so far?
you> I found main, it calls checkPassword. What next?
tutor> Good. Look at what checkPassword compares its argument with...
```

| Command | What it does |
|---|---|
| `/hint` | Ask for a nudge |
| `/answer` | Reveal the answer (asks for confirmation) |
| `/quit` | Leave. Continue later with `easyre tutor <job>` |

The conversation is saved to `tutor.md` in the job folder. If a reply accidentally contains the answer, it is replaced with `[hidden]`.

### ✅ How verification works

1. `--flag-format` must match, if set.
2. `--verify` runs, and its output is matched against `--success`. Without `--success`, exit code 0 counts as success.
3. If only `--success` is set and the task has exactly one `.exe` or ELF file, that file is run automatically with the candidate on stdin (through Wine for `.exe`).
4. With no verifier, the agent must prove the answer itself, and the report marks it `unverified`.

---

## 🤖 Backends

| | Backend | Runs | Setup in `.env` |
|---|---|---|---|
| 🟠 | `claude` | Claude Code (headless, subagents, skills) | `CLAUDE_CODE_OAUTH_TOKEN` (subscription) or `ANTHROPIC_API_KEY` |
| 🟢 | `codex` | OpenAI Codex CLI | `easyre login codex` or `OPENAI_API_KEY` |
| 🔵 | `openai` | Built-in agent loop (`bash`, `read_file`, `write_file`, `read_skill`) | `OPENAI_BASE_URL`, `OPENAI_API_KEY`, `OPENAI_MODEL` |

The `openai` backend covers every OpenAI-compatible API, including Google Gemini (profile `gemini`), OpenRouter, Ollama and LM Studio.

🦙 **Local model** (Ollama on the host):

```
EASYRE_BACKEND=openai
OPENAI_BASE_URL=http://host.docker.internal:11434/v1
OPENAI_MODEL=qwen3-coder
```

The model must support tool calling.

### 🎛️ Profiles

Save your models once in `config/backends.toml` and switch between them by name:

```toml
default = "claude-opus"

[profiles.claude-opus]
backend = "claude"
model = "opus"

[profiles.ollama-qwen]
backend = "openai"
base_url = "http://host.docker.internal:11434/v1"
model = "qwen3-coder"
api_key = "ollama"

[profiles.openrouter]
backend = "openai"
base_url = "https://openrouter.ai/api/v1"
model = "deepseek/deepseek-chat"
api_key_env = "OPENROUTER_API_KEY"
```

```powershell
.\easyre.cmd profiles
.\easyre.cmd run crackme --profile ollama-qwen
.\easyre.cmd resume crackme --profile claude-opus
```

- `easyre profiles` lists the profiles; `*` marks the default.
- `run ... --profile ollama-qwen` uses a local model.
- `resume ... --profile claude-opus` continues the same job with a stronger model.

`api_key_env` reads the key from `.env`, so secrets stay out of the profile file. If you omit `--profile`, the `default` profile is used, or `EASYRE_PROFILE` if it is set in `.env`. Passing `--backend` without `--profile` skips the profiles and uses the backend directly.

---

## 💰 Stats

```powershell
.\easyre.cmd stats
```

`easyre stats` sums time, tokens and cost per model over all your jobs. Claude reports its cost itself; this is the API-equivalent price, and a subscription costs nothing extra. For other APIs, add `price_in` and `price_out` (USD per 1M tokens) to the profile in `config/backends.toml`.

---

## 🧠 Skills

Skills are Markdown playbooks in `skills/<name>/SKILL.md`. The agent sees the list and loads the one that matches the target. Each skill is short and practical: when to use it, the steps, the commands, the pitfalls.

| | Skill | Covers | Status |
|---|---|---|---|
| 🧭 | `re-methodology` | General approach: orient, find the check, extract, solve, verify | 🚧 |
| ⚙️ | `native-binaries` | PE / ELF: C, C++, Go, Rust | 🚧 |
| 🟪 | `dotnet` | .NET and Unity | 🚧 |
| 🐍 | `python-targets` | Packaged Python apps and bytecode | 🚧 |
| ☕ | `jvm-android` | JAR and APK | 🚧 |
| 🌐 | `javascript-electron` | JS, Node, Electron | 🚧 |
| 🎰 | `custom-vm` | Custom VMs and bytecode interpreters | 🚧 |
| 🍷 | `dynamic-wine` | Running and observing Windows programs under Wine | 🚧 |
| 🧮 | `solvers` | Constraint solving, symbolic execution, emulation | 🚧 |
| 🔐 | `crypto-id` | Recognizing crypto and encoding primitives | 🚧 |
| 🗂️ | `formats-forensics` | Documents, archives, images, captures, custom formats | 🚧 |
| 🐉 | `ghidra-headless` | Ghidra without the GUI (headless / MCP) | 🚧 |

✅ ready · 🚧 in progress

To add a skill, copy `skills/_TEMPLATE.md` to `skills/<name>/SKILL.md`. It appears to the agent automatically.

---

## 🧰 Toolchain

The toolchain is installed by `toolchain/install.sh` during `docker compose build`. `toolchain/README.md` describes what is installed, and the agent reads it.

Currently installed:

| | Tool | Purpose |
|---|---|---|
| 🍷 | Wine (32 + 64 bit) + Xvfb | Run Windows `.exe` files, including GUI programs on a virtual display |
| 🐍 | Python 3 + pip | Solver scripts; the agent installs libraries as needed |
| 🟩 | Node.js | Runs Claude Code / Codex; also usable for JS targets |
| 📦 | 7-Zip, unzip | Extract task archives |
| 🔧 | file, curl, git, jq | Basic utilities |

The agent runs as root with network access and can install anything missing (`apt-get`, `pip`, `npm`) during a job. That is slower than having the tool preinstalled.

**Optional prefetch hook:** if `/opt/easyre/tools/prefetch` exists and is executable, triage runs it in the background on the main native binary:

```
prefetch <binary> <output_dir>
```

Use it, for example, to run an initial Ghidra analysis while the agent reads the task.

### 💾 Disk space

Rough estimates, not measured:

| Part | Size |
|---|---|
| Ubuntu base + Python + basic utilities | ~0.4 GB |
| Node.js + Claude Code + Codex CLI | ~0.5 GB |
| Wine 32/64-bit + Xvfb + prepared Wine prefix | ~1.5–2 GB |
| MinGW runtime DLLs (for MinGW-built `.exe`) | ~0.3 GB |
| **Image total (current toolchain)** | **~3–4 GB** |
| Build cache during `docker compose build` | +1–3 GB (free with `docker builder prune`) |

Every tool you add to `toolchain/install.sh` makes the image bigger. For example, Ghidra with a JDK adds about 1–1.5 GB, and the .NET SDK adds about 1 GB. Jobs in `jobs/` also use space: each one holds a copy of the task plus the agent's files.

---

## 📂 Output

Every job gets its own folder, `jobs/<name>-<timestamp>/`:

```
jobs/crackme-20260930-162257/
├── 📄 report.md    ← the result: answer, solution path, scripts
├── 💡 hints.md     ← graded hints (hint mode)
├── 🧑‍🏫 tutor.md     ← tutor conversation (tutor mode)
├── 📝 TASK.md      ← the task description
├── 📦 src/         ← the extracted task files (never modified)
├── 🛠️ agent/       ← the agent's workspace: notes.md, scripts, patched copies
└── ⚙️ .easyre/     ← internal: settings, full log, attempts, instructions
```

Usually you only need `report.md` (or `hints.md`). `agent/notes.md` shows how the agent reasoned. `.easyre/log.jsonl` records every step, for debugging.

---|---|---|
| 📄 | `report.md` | Status, answer, backend, time, tokens + the agent's write-up |
| 💡 | `hints.md` | Graded hints (hint mode) |
| 📝 | `TASK.md`, `triage.md` | Task and triage |
| 📦 | `src/` | Extracted handout |
| 🗒️ | `notes.md` | The agent's working notes |
| 🎯 | `attempts.log` | Every checked candidate |
| 📜 | `log.jsonl` | Full event log |

---

## 🗺️ Project layout

```
easyre                 CLI: jobs, triage, backends, verifier, reports, hints
setup.cmd / setup.sh   one-time setup: build, choose model, log in, check
easyre.cmd / easyre.sh wrappers to run easyre from Windows / Linux / macOS
config/                agent instructions, mode rules, stop hook, backend settings
skills/                playbooks for the agent
toolchain/install.sh   your tools
toolchain/README.md    tool list the agent reads
Dockerfile             base image: agent CLIs + toolchain + skills
docker-compose.yml     volumes: tasks/, jobs/, live-mounted easyre, config/, skills/
```

`easyre`, `config/` and `skills/` are mounted live, so edits take effect without rebuilding.

---

## ⚠️ Security

The container runs with `SYS_PTRACE` and `seccomp=unconfined`, has network access, and runs the targets. It is meant for crackmes and CTF challenges. Analyze real malware only in an isolated VM without network access.

## 📜 License

MIT, see [LICENSE](LICENSE).
