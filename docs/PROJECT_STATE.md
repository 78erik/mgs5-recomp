# MGS5 Recomp - Project State

## Current Phase
Phase 0: setup & analysis (toolchain ready, XEX analyzed)

## Target
- Primary: Android (ARM64) via ReXGlue (proven path)
- Secondary: Nintendo Switch (ARM64, homebrew) via ReXGlue + deko3d
- Source console: Xbox 360 (PowerPC -> recompiled to ARM64)
- Pilot: Ground Zeroes before TPP

## Game Files
- Path: G:\pro\recomp\game\Metal Gear Solid V The Phantom Pain
- XEX: Metal Gear Solid V The Phantom Pain\Default.xex
- Title ID: 4B4E085E | TU11 (tu00000011_00000000)
- Console: Xbox 360 (STFS dump)

## XEX Analysis (Raven)
- XEX2, 36,884,480 bytes, entry 0x83C20A68, base 0x82000000
- Title ID 0x4B4E085E, TU11
- PE: tpp_x360.exe; imports xam.xex/xboxkrnl.exe
- Static libs: XMP/XAUDIO2/XMCORE/XAPOBAS
- ANALYSIS.md updated. Function boundaries/jump tables pending disassembly tooling.

## Toolchain
- Clang 23.1.5 (G:\tools\llvm\...)
- Ninja 1.12.1 (G:\tools\ninja)
- XenonRecomp + XenonAnalyse built (G:\tools\XenonRecomp)
- XenonAnalyse: no jump tables found (game-specific detection)
- ReXGlue SDK cloned (G:\tools\rexglue-sdk) — submodules incomplete

## XenonRecomp Run
- Config: mgs5_recomp.toml (relative paths)
- Status: BLOCKED — register save/restore + setjmp/longjmp addresses unknown
- Need: find these addresses in decompressed binary (Ghidra/Xenia)
- Without them, XenonRecomp cannot generate C++ code.

## Resolved Addresses
(none yet)

## HLE Modules
(see docs/HLE_STATUS.md)

## Crashes
(none yet)

## Circuit Breaker Log
(none yet)