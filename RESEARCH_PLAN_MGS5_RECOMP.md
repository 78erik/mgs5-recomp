# Pesquisa: Recompilação Estática de Jogos de PS4, Xbox 360 e PS3
## + Plano para Recompilar Metal Gear Solid 5 (MGSV)

> Documento de pesquisa e planejamento. Nenhum código proprietário de jogo é distribuído ou incluído.

---

## 1. O que é recompilação estática (AOT)

Em vez de interpretar ou JIT-compilar instruções da CPU do console em tempo de execução (como fazem RPCS3, Xenia, shadPS4), a recompilação estática **traduz o binário inteiro para C/C++ antes da execução**, compila esse C/C++ com um compilador nativo (Clang/GCC/MSVC) e liga a um **runtime HLE** (High-Level Emulation) que reimplementa o SO do console (syscalls, bibliotecas, GPU, áudio, I/O). O resultado é um executável nativo x86-64/ARM64, sem camada de emulação em runtime.

Vantagens: performance nativa, menor requisito de hardware, código "hackável" (mods), portabilidade (qualquer plataforma com compilador), preservação a longo prazo.
Custo: cada jogo exige análise de binário, detecção de jump tables, funções indiretas, e um runtime HLE completo para o console alvo. Projetos grandes (AAA) levam meses/anos.

---

## 2. Estado por plataforma (nov/2026)

### 2.1 N64 — N64Recomp (pioneiro)
- ISA MIPS → C. Pioneiro do modelo moderno "recompilar para C, linkar com runtime".
- Maduro, vários jogos portados (Zelda, Banjo, etc.).

### 2.2 PS2 — PS2Recomp (ran-j)
- MIPS (Emotion Engine) → C. Sibling do ps3recomp. Menos maduro que N64/Xbox360.

### 2.3 Xbox 360 — XenonRecomp + ReXGlue (mais maduro para AAA)
- **XenonRecomp** (hedge-dev): ferramenta que converte XEX (PowerPC Xenon) em C++. Não inclui runtime — "fazer funcionar é sua responsabilidade". Detecta jump tables, function boundaries, register save/restore functions.
- **ReXGlue SDK** (rexglue): runtime + toolkit completo inspirado no Xenia. HLE do kernel Xbox 360, sistema de arquivos, áudio, rede, e renderer (Xenos → Vulkan/Metal/D3D). Suporta Windows, Linux, macOS (Apple Silicon), iOS, Android.
- **Projetos AAA comprovados**: Sonic Unleashed (UnleashedRecomp, 5.4k★), Sonic 06 (MarathonRecomp), GTA V (gtav-recomp, 360, TU27 — roda em PC/Mac/iPhone/Android), Dante's Inferno, Forza Horizon 2, Midnight Club LA, NFS Most Wanted, Call of Duty 3, Peter Jackson's King Kong, Daytona USA.
- **Lição do GTA V 360**: recompilação de AAA é viável mas exige patches no SDK, shader translation (XenosRecomp), e pipeline de release "clean-room" (taint scan, hashes de referência, compilação local pelo usuário). 811 arquivos C++ gerados, ~15-30 min de compilação.

### 2.4 Original Xbox — burnout3 (sp00nznet)
- PowerPC (Xbox original é x86 na verdade, mas o projeto trata como caso). Menos relevante.

### 2.5 PS3 — ps3recomp (sp00nznet) (maduro, Cell/SPU)
- **ps3recomp**: runtime libraries + ferramentas para recompilar PS3 (PowerPC PPU + SPU) para nativo. PowerPC → C++ via `ppu_lifter.py`, SPU → C via `spu_lifter.py`. HLE de ~300+ syscalls e 100+ módulos (cellAudio, cellGcmSys/RSX, cellPad, cellFs, cellSpurs, etc.).
- Render backends: D3D12 (Windows, roda jogos hoje), Metal (macOS, shaders no draw engine), Vulkan (Linux, opt-in), null (headless/CI).
- **Jogos em estado "in game"**: The Simpsons Arcade, Tornado Outbreak. **Ports da comunidade**: inFamous (macOS), Twisted Metal (Linux/Vulkan), Killzone 3 (Windows/Proton, 9 capítulos), LittleBigPlanet, Yakuza Dead Souls, God of War II HD, DBZ Budokai HD, Demon's Souls, God of War Ascension, Ratchet & Clank TOD, Resistance 3, Killzone 2, flOw.
- Desafio central: Cell (PPU + 6 SPU + DMA + channels + local store 256KB). SPU é o "elefante na sala". ps3recomp trata cada programa SPU como ELF separado, local store vira array, DMA vira memcpy, channels viram filas cross-thread.
- **Relação com RPCS3**: referência comportamental, não código (GPL). ps3recomp é MIT.

### 2.6 PS4 — PS4Recomp (wie-project) (experimental)
- Traduz ELF x86-64 do PS4 diretamente para ARM64 (assembly AOT), com backend Metal 3/4 (GCN → MSL via gcn-recompiler/SPIRV-Cross), kernel Orbis HLE, áudio 48kHz, ATRAC9, VideoToolbox H.264, GameController.
- **Apenas macOS Apple Silicon** (M1+). Não é Windows/Linux. É AOT de assembly x86→ARM, não "lifting para C" (diferente de ps3recomp/ReXGlue).
- Jogos "playable/in-game": Yakuza 0, Catherine Full Body, Bloodborne GOTY, TLOU Remastered. Hogwarts Legacy em progresso.
- Muito menos maduro que ps3recomp/ReXGlue; 42★, 6 forks.

### 2.7 PS5 — AnyPS5 (boykopovar)
- Muito inicial. Irrelevante para MGS5.

### 2.8 Tabela comparativa

| Console | Toolchain principal | Alvo de saída | Maturidade AAA | GPU | SPU/Coprocs | Melhor uso |
|---|---|---|---|---|---|---|
| N64 | N64Recomp | Win/Lin/Mac | Alta | N64 RDP | — | jogos N64 |
| PS2 | PS2Recomp | — | Baixa-Média | GS | — | jogos PS2 |
| Xbox 360 | XenonRecomp + ReXGlue | Win/Lin/Mac/iOS/Android | **Alta (AAA comprovado)** | Xenos → Vulkan/Metal | VMX (sem SPU separado) | port PC de jogos 360 |
| PS3 | ps3recomp | Win (D3D12) / Mac (Metal) / Lin (Vulkan) | Média (jogos menores) | RSX → D3D12/Metal/Vulkan | Cell PPU+6 SPU (complexo) | port PC de jogos PS3 |
| PS4 | PS4Recomp | **apenas macOS ARM64** | Baixa (experimental) | GCN → Metal | — (x86-64) | macOS nativo de jogos PS4 |

---

## 3. Metal Gear Solid 5 — análise

### 3.1 Versões existentes
- **PS3** (BLUS/BCES): 720p / 30 fps (TPP), Fox Engine, pesado em SPU.
- **Xbox 360** (discos instal/play + title update): 720p / 30 fps.
- **PS4 / Xbox One**: 1080p / 60 fps.
- **PC (Steam)**: já existe versão nativa (a melhor: maior resolução, 60 fps, modding via mods como MGSV QAR tools). **MGSV:TPP e Ground Zeroes**.

Conclusão importante: **MGS5 já tem port nativo de PC.** Recompilação estática de uma versão de console é redundante para jogar no Windows/Linux. Só faz sentido para: macOS nativo, preservação de um build específico de console, modding profundo de uma versão de console, ou pesquisa.

### 3.2 Engine e complexidade
- **Fox Engine** (Konami): streaming open-world, renderização diferida, física, áudio Wwise? (MGSV usa sistema próprio + Wwise em algumas partes), muitas cutscenes (vídeo).
- **PS3/360**: versão "old-gen" com assets reduzidos, 30 fps, 2 discos (instalação + jogo) no 360 — similar ao GTA V 360.
- **Desafios específicos**:
  1. Tamanho: TPP é um jogo enorme (mapa aberto, missões). Recompilar todo o código é um esforço de meses.
  2. Streaming de mundo: carregamento dinâmico de assets, memória gerenciada manualmente.
  3. Áudio: MGSV tem áudio complexo (rádio, música dinâmica). Precisa de HLE de áudio robusto.
  4. Vídeo: cutscenes em Bink/outras. Precisa de decoder.
  5. Online (FOB): Metal Gear Online / Forward Operating Bases. Recompilar online é muito difícil (servidores, netcode). Recomenda-se focar no single-player offline.
  6. SPU (se rota PS3): Fox Engine usa SPU intensivamente → recompilação SPU é o maior risco.
  7. Shader translation: Fox Engine usa shaders complexos; precisa de XenosRecomp (360) ou RSX shader translator (PS3).

### 3.3 Recomendação de fonte
- **Windows/Linux/macOS (PC port de console)**: **Xbox 360** via **ReXGlue**. É a toolchain mais madura para AAA (GTA V 360 é o precedente direto), suporta multiplataforma incluindo macOS, e o 360 usa PowerPC+VMX (sem SPU separado, mais simples que PS3).
- **Windows apenas, se preferir D3D12 e já tiver infra ps3recomp**: **PS3** via ps3recomp. Mas SPU torna isso mais arriscado para Fox Engine.
- **macOS nativo de alta qualidade**: **PS4** via PS4Recomp (1080p/60fps), mas experimental e arriscado. Alternativa mais segura: 360 via ReXGlue (também suporta macOS via MoltenVK).
- **Não recompilar**: usar PC Steam + Proton (Linux) / CrossOver (macOS). Para a maioria dos casos, é a resposta correta.

---

## 4. Plano de Recompilação do MGS5

### 4.1 Decisão recomendada (melhor forma)

> **Fonte: Xbox 360 (TU mais recente). Toolchain: ReXGlue SDK + XenonRecomp + XenosRecomp. Alvo: Windows + Linux + macOS. Piloto: MGSV: Ground Zeroes (mesmo Fox Engine, escopo menor) antes de TPP.**

Justificativa:
1. ReXGlue é a única toolchain com AAA comprovado (GTA V 360) e pipeline de release multiplataforma.
2. 360 não tem SPU separado → evita o maior risco da rota PS3.
3. Suporta macOS via MoltenVK (única rota de recomp que dá macOS nativo de forma estável hoje).
4. Ground Zeroes como piloto valida o Fox Engine no pipeline com escopo 10x menor que TPP.

### 4.2 Pré-requisitos
- **Jogo próprio**: MGSV para Xbox 360 (discos instal + play) + title update (TU). **Nunca distribuir**.
- **Hardware**: PC x86-64 com AVX2, GPU com driver Vulkan, ≥8 GB RAM, ≥25 GB livres. Para Mac: Apple Silicon M1+.
- **Software**: ReXGlue SDK, XenonRecomp, XenosRecomp, LLVM/Clang, CMake, Ninja, Python 3.10+.
- **Conhecimento**: leitura de assembly PowerPC, HLE, debug com logs.
- **Legal**: seguir modelo "clean-room" do GTA V recomp (taint scan, hashes de referência, compilação local pelo usuário, nunca commitar código derivado do jogo).

### 4.3 Fases

#### Fase 0 — Setup e análise (2-4 semanas)
- Obter e verificar dumps (hashes).
- Instalar ReXGlue SDK, buildar.
- Rodar `XenonAnalyse` no XEX para detectar jump tables.
- Criar TOML de config do recompilador (function boundaries, register save/restore addresses, setjmp/longjmp).
- Estimar tamanho do código (número de funções, arquivos gerados).
- **Entregável**: XEX analisado, TOML inicial, build do SDK funcionando.

#### Fase 1 — Primeiro boot (4-8 semanas)
- Recompilar código, linkar com runtime ReXGlue.
- Implementar HLE mínimo: kernel, memória, threads, filesystem (montar /app0 com assets do jogo), vídeo out.
- Objetivo: chegar na tela de título / menus.
- **Entregável**: menus renderizando, input funcionando.

#### Fase 2 — Fox Engine init + render (8-16 semanas)
- Implementar HLE de GPU (Xenos → Vulkan via XenosRecomp): vertex/fragment shaders, texturas, render targets.
- Resolver init do Fox Engine (alocação de memória, threads, módulos).
- Objetivo: cutscene de abertura / gameplay inicial renderizando.
- **Entregável**: primeira missão visível, mesmo que com bugs.

#### Fase 3 — Gameplay (16-32 semanas)
- Input completo (pad), câmera, movimento, stealth, combate.
- Áudio: implementar HLE de áudio do 360 (XAudio2 → SDL/OpenAL ou WASAPI) + decodificação XMA.
- Streaming de mundo: carregamento de assets, LOD, memória.
- Vídeo: decodificação de cutscenes (Bink → FFmpeg).
- **Entregável**: gameplay jogável do início ao fim (single-player).

#### Fase 4 — Polimento (8-16 semanas)
- Performance: 60 fps estável, otimizações do recompilador (skip_lr, locals, etc.).
- Resolução: suporte a resoluções arbitrárias (ultrawide, 4K).
- Correção de bugs visuais (shaders, iluminação, sombras).
- Save system, conquistas (opcional).
- **Entregável**: versão estável, jogável, com performance boa.

#### Fase 5 — Online/FOB (opcional, 12+ semanas, alto risco)
- Metal Gear Online / FOB. Requer emulação de rede/servidores. **Recomenda-se pular ou fazer por último.**
- **Entregável**: FOB funcionando (se viável).

#### Fase 6 — Release clean-room (4-8 semanas)
- Taint scan contra código gerado e shaders.
- Build de release multiplataforma (Windows/Linux/macOS).
- Documentação, hashes de referência, instruções de build local.
- **Entregável**: release público seguindo regras do GTA V recomp.

### 4.4 Estimativa total
- **Ground Zeroes (piloto)**: 3-6 meses com 1-2 devs dedicados.
- **The Phantom Pain**: 12-24 meses com equipe (3-5 devs). Comparável ao GTA V 360 recomp, mas MGSV tem engine mais complexa em alguns aspectos (streaming, áudio).
- **Risco alto**: Fox Engine pode ter padrões de código que XenonAnalyse não detecta (jump tables não-padrão, exceções, setjmp/longjmp). Será necessário ajustar o analisador.

### 4.5 Alternativas e quando usar

| Cenário | Rota recomendada |
|---|---|
| Quer jogar no Windows/Linux hoje | PC Steam + Proton (não recompilar) |
| Quer macOS nativo, aceita risco | PS4 via PS4Recomp (experimental, 1080p) |
| Quer macOS nativo, quer estabilidade | 360 via ReXGlue (MoltenVK) |
| Quer preservar build de PS3 | PS3 via ps3recomp (D3D12, Windows) |
| Quer modding profundo de código | Qualquer rota de recomp (código C++ hackável) |
| Quer aprender recompilação | Começar com Ground Zeroes (360) |

### 4.6 Riscos e mitigações

| Risco | Mitigação |
|---|---|
| Fox Engine não bootar no runtime | Começar pelo piloto (GZ); usar logs/diagnósticos do ReXGlue; comparar com Xenia para comportamento |
| Jump tables não detectados | Ajustar XenonAnalyse; definir boundaries manualmente no TOML; usar mid-asm hooks |
| Shaders complexos falharem | Usar XenosRecomp; testar incrementalmente; capturar GPU traces |
| Áudio dessincronizado | Implementar XAudio2 HLE robusto; usar FFmpeg para XMA |
| Memória/streaming quebrar | Emular memória do 360 (512MB) com atenção; testar com missões longas |
| Escopo muito grande | Focar single-player offline; deixar FOB por último |
| Legal/takedown | Seguir clean-room estrito; taint scan; nunca distribuir código do jogo |

### 4.7 Entregáveis por fase (checklist)

- [ ] Fase 0: XEX analisado, TOML, SDK buildando
- [ ] Fase 1: menus renderizando
- [ ] Fase 2: primeira missão visível
- [ ] Fase 3: gameplay completo single-player
- [ ] Fase 4: 60 fps estável, multi-resolução
- [ ] Fase 5 (opcional): FOB
- [ ] Fase 6: release clean-room multiplataforma

---

## 5. Recursos e referências

- ps3recomp: https://github.com/sp00nznet/ps3recomp (MIT)
- ReXGlue SDK: https://github.com/rexglue/rexglue-sdk
- XenonRecomp: https://github.com/hedge-dev/XenonRecomp (MIT)
- PS4Recomp: https://github.com/wie-project/PS4Recomp (GPL-2.0)
- GTA V 360 recomp (referência AAA): https://github.com/andrewnakas/gtav-recomp
- Unleashed Recomp: https://github.com/hedge-dev/UnleashedRecomp
- N64Recomp: https://github.com/N64Recomp/N64Recomp
- PS2Recomp: https://github.com/ran-j/PS2Recomp
- Xenia (referência de comportamento Xbox 360): https://github.com/xenia-project/xenia
- RPCS3 (referência de comportamento PS3): https://github.com/RPCS3/rpcs3
- shadPS4 (referência PS4): https://github.com/shadps4-emu/shadPS4

---

## 6. Conclusão

Para MGS5, a **melhor forma de recompilar** é:

1. **Não recompilar se o objetivo é jogar** — use a versão PC Steam (já existe, é a melhor). Para Linux, Proton; para macOS, CrossOver.
2. **Se o objetivo é port nativo de console / preservação / macOS**: use **Xbox 360 + ReXGlue**, com **Ground Zeroes como piloto**, focando single-player offline, seguindo o modelo clean-room do GTA V 360 recomp.
3. **PS3 (ps3recomp)** é alternativa viável para Windows mas tem risco maior por causa do SPU no Fox Engine.
4. **PS4 (PS4Recomp)** só se o alvo for macOS Apple Silicon e você aceitar tooling experimental.

O esforço é grande (meses a anos), mas o precedente do GTA V 360 recomp prova que é viável para jogos AAA de 360. A chave é começar pequeno (GZ), validar o pipeline, e só então atacar TPP.