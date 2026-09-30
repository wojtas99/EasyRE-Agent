#!/bin/sh
cd "$(dirname "$0")" || exit 1

say() { printf '\033[36m%s\033[0m\n' "$1"; }
fail() { printf '\033[31m%s\033[0m\n' "$1"; exit 1; }
setenv() {
  if grep -q "^$1=" .env; then
    python3 - "$1" "$2" <<'P'
import sys
k, v = sys.argv[1], sys.argv[2]
lines = open(".env").read().splitlines()
open(".env", "w").write("\n".join(f"{k}={v}" if l.startswith(k + "=") else l for l in lines) + "\n")
P
  else
    printf '%s=%s\n' "$1" "$2" >> .env
  fi
}
ask() { printf '%s ' "$1"; read -r REPLY; }

say "== EasyRE-Agent setup =="
say "[1/4] Checking Docker..."
docker info >/dev/null 2>&1 || fail "Docker is not running. Install and start Docker, then run this again."
[ -f .env ] || cp .env.example .env
mkdir -p tasks jobs

say "[2/4] Building the image (first time: several minutes)..."
docker compose build || fail "Build failed. Copy the error above and report it."

say "[3/4] Choose your model:"
echo "  1) Claude subscription (Pro/Max)   - recommended"
echo "  2) Claude API key"
echo "  3) ChatGPT account via Codex"
echo "  4) OpenAI API key"
echo "  5) OpenRouter API key"
echo "  6) Ollama on this machine (local, free)"
echo "  7) LM Studio on this machine (local, free)"
echo "  8) Google Gemini API key"
ask "Number:"; c=$REPLY

case "$c" in
  1) setenv EASYRE_PROFILE claude-opus
     say "A login link will appear. Log in, paste the code back, then copy the sk-ant-oat token."
     docker compose run --rm easyre claude setup-token
     ask "Paste the token here:"; setenv CLAUDE_CODE_OAUTH_TOKEN "$REPLY" ;;
  2) setenv EASYRE_PROFILE claude-opus
     ask "Anthropic API key:"; setenv ANTHROPIC_API_KEY "$REPLY" ;;
  3) setenv EASYRE_PROFILE codex
     docker compose run --rm easyre easyre login codex ;;
  4) setenv EASYRE_PROFILE openai-api
     ask "OpenAI API key:"; setenv OPENAI_API_KEY "$REPLY"
     ask "Model name (Enter = gpt-4.1):"; [ -n "$REPLY" ] && setenv EASYRE_MODEL "$REPLY" ;;
  5) setenv EASYRE_PROFILE openrouter
     ask "OpenRouter API key:"; setenv OPENROUTER_API_KEY "$REPLY"
     ask "Model id (Enter = deepseek/deepseek-chat):"; [ -n "$REPLY" ] && setenv EASYRE_MODEL "$REPLY" ;;
  6) setenv EASYRE_PROFILE ollama-qwen
     say "Make sure Ollama is running and the model is pulled (ollama pull qwen3-coder)."
     ask "Model name (Enter = qwen3-coder):"; [ -n "$REPLY" ] && setenv EASYRE_MODEL "$REPLY" ;;
  7) setenv EASYRE_PROFILE lmstudio
     say "In LM Studio: load a model and start the local server (port 1234)."
     ask "Model name as shown in LM Studio:"; [ -n "$REPLY" ] && setenv EASYRE_MODEL "$REPLY" ;;
  8) setenv EASYRE_PROFILE gemini
     ask "Gemini API key (aistudio.google.com):"; setenv GEMINI_API_KEY "$REPLY"
     ask "Model name (Enter = gemini-2.5-pro):"; [ -n "$REPLY" ] && setenv EASYRE_MODEL "$REPLY" ;;
  *) fail "Unknown choice. Run setup again." ;;
esac

say "[4/4] Checking everything..."
docker compose run --rm easyre easyre doctor
say ""
say "Done. Put a task into ./tasks and run for example:"
echo '  ./easyre.sh run crackme --success "Correct"'
