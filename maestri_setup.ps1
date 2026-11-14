# Maestri setup script for MGS5 Recomp multi-agent team
# Run ONLY when Maestro Mode is active on this terminal.
# Usage: .\maestri_setup.ps1

$ErrorActionPreference = "Stop"

Write-Host "=== Checking Maestro Mode ===" -ForegroundColor Cyan
maestri preset list
if ($LASTEXITCODE -ne 0) { throw "Maestro Mode not active. Enable it in the canvas first." }

Write-Host "=== Creating roles ===" -ForegroundColor Cyan
maestri role create "Binary Analyst" "You are Raven, the binary analyst. Disassemble and analyze the MGS5 Xbox 360 XEX: function boundaries, jump tables, NIDs, addresses. Maintain ANALYSIS note. Use Ghidra MCP (GhydraMCP) for static analysis. Run maestri list before delegating. Report via maestri ask 'OpenCode' when done. Circuit breaker: stop after 3 identical failures." --scope current
maestri role create "Recompilation Engineer" "You are Forge. Run the ReXGlue/XenonRecomp lift pipeline, fix lifter errors, generate C++, build with cmake. Use recomp-harness-mcp for builds. Maintain build status. Report via ask-back. Circuit breaker active." --scope current
maestri role create "Runtime HLE Developer" "You are Anvil. Implement missing HLE modules (audio XAudio2/XMA, fs, input, network, save) for the 360 runtime. Maintain HLE_STATUS note. Unit-test each module. Report via ask-back." --scope current
maestri role create "Graphics Shader Engineer" "You are Prism. Translate Xenos shaders to SPIR-V via XenosRecomp, fix renderer, textures, render targets. Maintain SHADER_LOG. Profile GPU. Report via ask-back." --scope current
maestri role create "Platform Engineer" "You are Drift. Package for Android (primary) and Switch (secondary): input touch/controller, Vulkan/deko3d, performance, packaging. Maintain PLATFORM_LOG. Report via ask-back." --scope current
maestri role create "QA Debugger" "You are Probe. Run builds, compare against Xenia, capture crashes, apply circuit breakers, triage. Maintain CRASH_TRIAGE. Report via ask-back." --scope current

Write-Host "=== Creating floors ===" -ForegroundColor Cyan
maestri floor create "analysis" --branch feat/analysis
maestri floor create "runtime" --branch feat/runtime
maestri floor create "graphics" --branch feat/graphics
maestri floor create "platform" --branch feat/platform
maestri floor create "qa" --branch feat/qa

Write-Host "=== Recruiting agents ===" -ForegroundColor Cyan
maestri recruit "Raven" --role "Binary Analyst" --floor "analysis"
maestri recruit "Forge" --role "Recompilation Engineer" --floor "runtime"
maestri recruit "Anvil" --role "Runtime HLE Developer" --floor "runtime"
maestri recruit "Prism" --role "Graphics Shader Engineer" --floor "graphics"
maestri recruit "Drift" --role "Platform Engineer" --floor "platform"
maestri recruit "Probe" --role "QA Debugger" --floor "qa"

Write-Host "=== Creating shared notes ===" -ForegroundColor Cyan
maestri note create --name "PROJECT_STATE" "# MGS5 Recomp - Project State`n`n## Current Phase`nPhase 0: setup & analysis`n`n## Resolved Addresses`n(none yet)`n`n## HLE Modules`n(see HLE_STATUS)`n`n## Crashes`n(none yet)`n`n## Circuit Breaker Log`n(none)"
maestri note create --name "ARCHITECTURE" "# Architecture`n`n- Target primary: Android (ReXGlue, proven path).`n- Target secondary: Nintendo Switch (homebrew, experimental).`n- Source console: Xbox 360 (TU).`n- Pilot: Ground Zeroes before TPP.`n"
maestri note create --name "ANALYSIS" "# Analysis`n`n## Jump Tables`n(none yet)`n`n## Function Boundaries`n(none yet)`n`n## NIDs / Addresses`n(none yet)`n"
maestri note create --name "HLE_STATUS" "# HLE Status`n`n| Module | Status | Owner |`n|---|---|---|`n| kernel | todo | Anvil |`n| audio (XAudio2/XMA) | todo | Anvil |`n| fs | todo | Anvil |`n| input | todo | Anvil |`n| network | todo | Anvil |`n| video | todo | Anvil |`n"
maestri note create --name "SHADER_LOG" "# Shader Log`n`n## Failing Shaders`n(none yet)`n`n## Translations`n(none yet)`n"
maestri note create --name "PLATFORM_LOG" "# Platform Log`n`n## Android`n(none yet)`n`n## Switch`n(none yet)`n"
maestri note create --name "CRASH_TRIAGE" "# Crash Triage`n`n## Active Crashes`n(none yet)`n`n## Resolved`n(none yet)`n"
maestri note create --name "CLEAN_ROOM" "# Clean Room Rules`n`n- Never commit game-derived code (generated C++, shaders, assets).`n- Taint scan before release.`n- Reference hashes; local build by user.`n- Respect licenses (ReXGlue GPL-3, etc.).`n"

Write-Host "=== Wiring peers ===" -ForegroundColor Cyan
maestri connect "Raven" "Forge"
maestri connect "Forge" "Anvil"
maestri connect "Prism" "Forge"
maestri connect "Drift" "Forge"
maestri connect "Probe" "Forge"

Write-Host "=== Initial status ===" -ForegroundColor Cyan
maestri floor status "Phase 0: setup & analysis" --state working --floor "Ground"

Write-Host "=== DONE ===" -ForegroundColor Green
maestri list