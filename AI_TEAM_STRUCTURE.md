# Estrutura de IAs para Acelerar a Recompilação do MGS5
## Port para Android (primário) / Nintendo Switch (secundário)

> Multi-agente no Maestri, inspirado em `recomp-harness-mcp` (sp00nznet) e `ps2-recomp-Agent-SKILL` (hkmodd).
> Alvo: Android (ReXGlue path comprovado) + Switch homebrew (experimental).

---

## 1. Por que multi-agente acelera a recompilação

Recompilação estática de um AAA é um pipeline heterogêneo e longo (análise binária → lifting → HLE → render → build → teste). Um único agente sofre com:
- Janela de contexto (degradação após horas).
- Tarefas bloqueantes (builds de minutos/horas).
- Falta de especialização (análise PowerPC vs. shaders vs. mobile packaging).

A estrutura abaixo divide o trabalho em **papéis especializados**, cada um com **memória persistente**, **circuit breakers** e **tools (MCP)**, rodando em **floors isolados** (git worktrees) para não colidir. Inspiração direta:
- `recomp-harness-mcp`: control plane que permite a um agente descobrir, buildar, recompilar e rodar ~90 harnesses em background com polling (jobId), sem bloquear.
- `ps2-recomp-Agent-SKILL`: agente autônomo com `PS2_PROJECT_STATE.md` (hipocampo externo), circuit breakers (parar após 3 falhas), builds diretos, integração MCP com Ghidra/PCSX2 para debug runtime, protocolo de boot "read-first, detect-second, ask-third, act-last".

---

## 2. Decisão de alvo

| Alvo | Fonte console | Toolchain | Maturidade | Notas |
|---|---|---|---|---|
| **Android (primário)** | Xbox 360 (TU) | ReXGlue + XenonRecomp + XenosRecomp | **Alta** (GTA V 360 → Android comprovado) | Path mais seguro; build Android via `--android` do launcher. |
| **Switch (secundário)** | Xbox 360 (TU) | ReXGlue + deko3d (peggle2-nx) | Média/Baixa | Homebrew ARM64; Vulkan/deko3d; mais experimental. Começar depois do Android. |
| (alt.) PS4 → Switch | PS4 | PS4Recomp | Baixa | PS4Recomp é macOS-only; não recomendado para Switch. |

**Recomendação:** fonte única = Xbox 360 TU; dois alvos de build (Android primário, Switch depois). Piloto = Ground Zeroes antes de TPP.

---

## 3. Papéis (agentes) — 7 agentes

| # | Codename | Papel | Responsabilidades-chave | Tools/MCP |
|---|---|---|---|---|
| 1 | **Maestro (você/OpenCode)** | Orquestrador | Coordena, atribui tarefas, mantém estado, revisa, decide merge de floors. | maestri CLI, git |
| 2 | **Raven** | Binary Analyst / Reverse Engineer | Disassembly, function boundaries, jump tables, addresses, NIDs. Mantém `ANALYSIS.md`. | Ghidra MCP (GhydraMCP), XenonAnalyse |
| 3 | **Forge** | Recompilation Engineer | Roda lift pipeline, corrige erros do lifter, gera C++, builda. | recomp-harness-mcp, cmake, clang |
| 4 | **Anvil** | Runtime / HLE Developer | Implementa módulos HLE faltantes (áudio XAudio2, fs, input, network, save). | editor, testes unitários |
| 5 | **Prism** | Graphics / Shader Engineer | Shaders Xenos→SPIR-V, renderer, texturas, render targets, performance GPU. | XenosRecomp, RenderDoc |
| 6 | **Drift** | Platform Engineer (Android/Switch) | Packaging Android/Switch, input touch/controle, Vulkan/deko3d, perf mobile. | Android SDK/NDK, devkitPro |
| 7 | **Probe** | QA / Debug | Roda builds, compara vs Xenia, captura crashes, aplica circuit breakers. | Xenia MCP, logs, ASan |

**Regra de colaboração:** cada agente roda `maestri list` antes de delegar; agentes se comunicam via `maestri ask "Peer" "..."`; reportam conclusão com ask-back (`maestri ask "Maestro" "<resultado>"`).

---

## 4. Floors (isolamento git)

Criar floors (worktrees) para streams paralelos, evitando colisão:

| Floor | Branch | Agente principal | Propósito |
|---|---|---|---|
| Ground | master | Maestro | Coordenação, notes compartilhadas, merge. |
| `analysis` | feat/analysis | Raven | Reverse engineering, endereços, jump tables. |
| `runtime` | feat/runtime | Anvil | HLE modules. |
| `graphics` | feat/graphics | Prism | Shaders/renderer. |
| `platform` | feat/platform | Drift | Android/Switch packaging. |
| `qa` | feat/qa | Probe | Testes, crash triage. |

Landing (`maestri floor land`) apenas quando o floor reporta `review` e o Maestro confirma. Floors com uncommitted work são recusados.

---

## 5. Memória persistente (notes compartilhadas)

Notes do Maestri (criadas com `--name` estável), lidas por todos via chain:

| Note | Conteúdo | Owner |
|---|---|---|
| `PROJECT_STATE` | Fase atual, endereços resolvidos, stubs, crashes, tentativas (circuit breaker). "Hipocampo externo". | Maestro (todos editam) |
| `ARCHITECTURE` | Decisões de alvo (Android/Switch), toolchain, build config. | Maestro |
| `ANALYSIS` | Jump tables, function boundaries, NIDs, endereços de restore/save. | Raven |
| `HLE_STATUS` | Tabela de módulos HLE: completo/parcial/faltando. | Anvil |
| `SHADER_LOG` | Shaders falhando, traduções, perfis GPU. | Prism |
| `PLATFORM_LOG` | Build Android/Switch, packaging, perf mobile. | Drift |
| `CRASH_TRIAGE` | Crashes capturados, tentativas, status circuit breaker. | Probe |
| `CLEAN_ROOM` | Regras legais, taint scan, hashes de referência. | Maestro |

---

## 6. MCP servers a integrar

| MCP | Uso | Como |
|---|---|---|
| `recomp-harness-mcp` | Descobrir/buildar/recompilar/rodar harnesses em background (jobId, polling). | `claude mcp add recomp-harness -e RECOMP_ROOT=...` |
| `GhydraMCP` (Ghidra, porta 8192) | Análise estática, decompilação, xrefs, tipos. | Agente dirige Ghidra via MCP. |
| `PCSX2-MCP` / `Xenia-MCP` | Debug runtime: breakpoints, registros, memória, A/B vs recomp. | Porta 21512 (DebugServer). |
| `git` (CLI) | Branches, commits, PRs. | Via shell. |

---

## 7. Circuit breakers e protocolo

- **Read-first**: agente lê `PROJECT_STATE` + skill antes de agir.
- **Detect-second**: inspeciona workspace (build dirs, ELF, TOML).
- **Ask-third**: pergunta o que falta.
- **Act-last**: só age com aprovação quando ambíguo.
- **Circuit breaker**: após 3 falhas iguais → parar, ler docs, pedir ajuda (não queimar tokens).
- **Context degradation**: se o agente começa a errar, abrir novo chat e resumir via `PROJECT_STATE`.
- **Ask-back**: toda tarefa termina com `maestri ask "Maestro" "<resultado>"`.

---

## 8. Fluxo de trabalho (exemplo de sprint)

1. Maestro cria floors + recruta agentes com roles.
2. Maestro posta tarefa no `PROJECT_STATE` e delega via `maestri ask --batch`.
3. Raven analisa XEX → atualiza `ANALYSIS`.
4. Forge roda lift → atualiza build status; se erro, Probe tria.
5. Anvil/Prism implementam HLE/shaders em paralelo.
6. Drift empacota Android (build `--android`).
7. Probe roda no Android/emulador, compara com Xenia, reporta crashes.
8. Floors reportam `review` → Maestro confirma → `floor land`.
9. Maestro atualiza `PROJECT_STATE`, posta resumo no Ground.

---

## 9. Regras clean-room (legais)

- Nunca commitar código derivado do jogo (C++ gerado, shaders, assets).
- Taint scan antes de release (`scan_release.sh`).
- Hashes de referência; compilação local pelo usuário.
- GPL/MIT conforme toolchain usada (ReXGlue GPL-3; ps3recomp MIT). Respeitar licenças de third-party.

---

## 10. Comandos Maestri para criar a estrutura

> Executar apenas com Maestro Mode ativo. Script completo em `maestri_setup.ps1`.

### Roles (criar uma vez)
```powershell
maestri role create "Binary Analyst" "You are Raven, the binary analyst. Disassemble and analyze the MGS5 Xbox 360 XEX: function boundaries, jump tables, NIDs, addresses. Maintain ANALYSIS note. Use Ghidra MCP (GhydraMCP) for static analysis. Run maestri list before delegating. Report via maestri ask 'Maestro' when done. Circuit breaker: stop after 3 identical failures." --scope current
maestri role create "Recompilation Engineer" "You are Forge. Run the ReXGlue/XenonRecomp lift pipeline, fix lifter errors, generate C++, build with cmake. Use recomp-harness-mcp for builds. Maintain build status. Report via ask-back. Circuit breaker active." --scope current
maestri role create "Runtime HLE Developer" "You are Anvil. Implement missing HLE modules (audio XAudio2/XMA, fs, input, network, save) for the 360 runtime. Maintain HLE_STATUS note. Unit-test each module. Report via ask-back." --scope current
maestri role create "Graphics Shader Engineer" "You are Prism. Translate Xenos shaders to SPIR-V via XenosRecomp, fix renderer, textures, render targets. Maintain SHADER_LOG. Profile GPU. Report via ask-back." --scope current
maestri role create "Platform Engineer" "You are Drift. Package for Android (primary) and Switch (secondary): input touch/controller, Vulkan/deko3d, performance, packaging. Maintain PLATFORM_LOG. Report via ask-back." --scope current
maestri role create "QA Debugger" "You are Probe. Run builds, compare against Xenia, capture crashes, apply circuit breakers, triage. Maintain CRASH_TRIAGE. Report via ask-back." --scope current
```

### Floors
```powershell
maestri floor create "analysis" --branch feat/analysis
maestri floor create "runtime" --branch feat/runtime
maestri floor create "graphics" --branch feat/graphics
maestri floor create "platform" --branch feat/platform
maestri floor create "qa" --branch feat/qa
```

### Recruits (um por floor)
```powershell
maestri recruit "Raven" --role "Binary Analyst" --floor "analysis"
maestri recruit "Forge" --role "Recompilation Engineer" --floor "runtime"
maestri recruit "Anvil" --role "Runtime HLE Developer" --floor "runtime"
maestri recruit "Prism" --role "Graphics Shader Engineer" --floor "graphics"
maestri recruit "Drift" --role "Platform Engineer" --floor "platform"
maestri recruit "Probe" --role "QA Debugger" --floor "qa"
```

### Notes compartilhadas (criar no Ground)
```powershell
maestri note create --name "PROJECT_STATE" "## MGS5 Recomp State`nPhase: 0 (setup)`n..."
maestri note create --name "ARCHITECTURE" "## Architecture`nTarget: Android primary, Switch secondary`n..."
maestri note create --name "ANALYSIS" "## Analysis`n..."
maestri note create --name "HLE_STATUS" "## HLE Status`n..."
maestri note create --name "SHADER_LOG" "## Shader Log`n..."
maestri note create --name "PLATFORM_LOG" "## Platform Log`n..."
maestri note create --name "CRASH_TRIAGE" "## Crash Triage`n..."
maestri note create --name "CLEAN_ROOM" "## Clean Room`n..."
```

### Conexões (peers)
```powershell
maestri connect "Raven" "Forge"
maestri connect "Forge" "Anvil"
maestri connect "Prism" "Forge"
maestri connect "Drift" "Forge"
maestri connect "Probe" "Forge"
```

### Status inicial
```powershell
maestri floor status "Phase 0: setup & analysis" --state working --floor "Ground"
```

---

## 11. Universal Starter Prompt (cole no Maestro após rodar o script)

```
Read AI_TEAM_STRUCTURE.md and RESEARCH_PLAN_MGS5_RECOMP.md first.
Then execute startup sequence:

1. INSPECT workspace: check for PROJECT_STATE note, build dirs, ELF/XEX files.
   WARNING: do not list huge dirs (runner/ etc). Use Test-Path and counts.

2. If a build dir exists, read CMakeCache.txt and report generator/compiler/build type.
   Rate config (optimal/acceptable/critical). Do not change without OK.

3. ASK for anything still unknown:
   - Which game? (Ground Zeroes or TPP, region code)
   - Where is the ISO/XEX? (absolute path)
   - Which phase? (infer from workspace if possible)

4. REPORT: what you found, current phase, next concrete step. Wait for go-ahead.

Then delegate Phase 0 tasks via maestri ask --batch to Raven/Forge/etc.
End every task with ask-back: maestri ask "OpenCode" "<resultado>".
```

## 12. Quick Resume (novo chat, mesmo projeto)

```
Read AI_TEAM_STRUCTURE.md and the PROJECT_STATE note.
Resume from there. Do not re-ask what is already in PROJECT_STATE.
```

## 13. Entregáveis

- [x] Git repo inicializado.
- [x] RESEARCH_PLAN_MGS5_RECOMP.md (pesquisa + plano).
- [x] AI_TEAM_STRUCTURE.md (estrutura multi-agente).
- [x] maestri_setup.ps1 (script de criação da estrutura).
- [ ] Maestro Mode ativo + script executado.
- [ ] Roles criadas.
- [ ] Floors criados.
- [ ] Agentes recrutados.
- [ ] Notes compartilhadas criadas.
- [ ] MCP servers configurados (recomp-harness, Ghidra, Xenia).
- [ ] Primeira análise do XEX (Ground Zeroes) rodando.