$ErrorActionPreference = "Continue"
Set-Location $PSScriptRoot

function Say($t) { Write-Host $t -ForegroundColor Cyan }
function Fail($t) { Write-Host $t -ForegroundColor Red; exit 1 }

function Set-EnvValue($key, $value) {
    $lines = @()
    if (Test-Path .env) { $lines = @(Get-Content .env) }
    $found = $false
    $out = foreach ($l in $lines) {
        if ($l -match "^\s*$key=") { $found = $true; "$key=$value" } else { $l }
    }
    if (-not $found) { $out = @($out) + "$key=$value" }
    [System.IO.File]::WriteAllLines((Join-Path $PSScriptRoot ".env"), [string[]]$out)
}

Say "== EasyRE-Agent setup =="

Say "[1/4] Checking Docker..."
docker info *> $null
if ($LASTEXITCODE -ne 0) { Fail "Docker is not running. Install Docker Desktop, start it, and run this script again." }

if (-not (Test-Path .env)) { Copy-Item .env.example .env }
New-Item -ItemType Directory -Force tasks, jobs | Out-Null

Say "[2/4] Building the image (first time: several minutes)..."
docker compose build
if ($LASTEXITCODE -ne 0) { Fail "Build failed. Copy the error above and report it." }

Say "[3/4] Choose your model:"
Write-Host "  1) Claude subscription (Pro/Max)   - recommended"
Write-Host "  2) Claude API key"
Write-Host "  3) ChatGPT account via Codex"
Write-Host "  4) OpenAI API key"
Write-Host "  5) OpenRouter API key"
Write-Host "  6) Ollama on this PC (local, free)"
Write-Host "  7) LM Studio on this PC (local, free)"
Write-Host "  8) Google Gemini API key"
$c = Read-Host "Number"

switch ($c) {
    "1" {
        Set-EnvValue "EASYRE_PROFILE" "claude-opus"
        Say "A login link will appear. Open it, log in, paste the code back. Then copy the token that starts with sk-ant-oat."
        docker compose run --rm easyre claude setup-token
        $t = Read-Host "Paste the token here"
        Set-EnvValue "CLAUDE_CODE_OAUTH_TOKEN" $t.Trim()
    }
    "2" {
        Set-EnvValue "EASYRE_PROFILE" "claude-opus"
        $t = Read-Host "Paste your Anthropic API key (sk-ant-api...)"
        Set-EnvValue "ANTHROPIC_API_KEY" $t.Trim()
    }
    "3" {
        Set-EnvValue "EASYRE_PROFILE" "codex"
        docker compose run --rm easyre easyre login codex
    }
    "4" {
        Set-EnvValue "EASYRE_PROFILE" "openai-api"
        $t = Read-Host "Paste your OpenAI API key (sk-...)"
        Set-EnvValue "OPENAI_API_KEY" $t.Trim()
        $m = Read-Host "Model name (Enter = gpt-4.1)"
        if ($m) { Set-EnvValue "EASYRE_MODEL" $m.Trim() }
    }
    "5" {
        Set-EnvValue "EASYRE_PROFILE" "openrouter"
        $t = Read-Host "Paste your OpenRouter API key (sk-or-...)"
        Set-EnvValue "OPENROUTER_API_KEY" $t.Trim()
        $m = Read-Host "Model id from openrouter.ai/models (Enter = deepseek/deepseek-chat)"
        if ($m) { Set-EnvValue "EASYRE_MODEL" $m.Trim() }
    }
    "6" {
        Set-EnvValue "EASYRE_PROFILE" "ollama-qwen"
        Say "Make sure Ollama is running and the model is pulled (e.g. ollama pull qwen3-coder)."
        $m = Read-Host "Model name (Enter = qwen3-coder)"
        if ($m) { Set-EnvValue "EASYRE_MODEL" $m.Trim() }
    }
    "7" {
        Set-EnvValue "EASYRE_PROFILE" "lmstudio"
        Say "In LM Studio: load a model and start the local server (port 1234)."
        $m = Read-Host "Model name as shown in LM Studio"
        if ($m) { Set-EnvValue "EASYRE_MODEL" $m.Trim() }
    }
    "8" {
        Set-EnvValue "EASYRE_PROFILE" "gemini"
        $t = Read-Host "Paste your Gemini API key (from aistudio.google.com)"
        Set-EnvValue "GEMINI_API_KEY" $t.Trim()
        $m = Read-Host "Model name (Enter = gemini-2.5-pro)"
        if ($m) { Set-EnvValue "EASYRE_MODEL" $m.Trim() }
    }
    default { Fail "Unknown choice. Run setup again." }
}

Say "[4/4] Checking everything..."
docker compose run --rm easyre easyre doctor

Say ""
Say "Done. Put a task into the tasks folder and run for example:"
Write-Host '  .\easyre.cmd run crackme --success "Correct"'
