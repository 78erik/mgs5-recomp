# MGS5 Recomp - Project State

## Current Phase
Phase 1: C++ code generated (XenonRecomp complete). Next: build + runtime integration.

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
- ANALYSIS.md updated.

## Toolchain
- Clang 23.1.5, Ninja 1.12.1, XenonRecomp + XenonAnalyse built
- Ghidra 12.1.4 + Xenon360 extension (register addresses found)
- ReXGlue SDK cloned (submodules partially complete)

## XenonRecomp Run
- Config: mgs5_recomp.toml
- Status: ✅ COMPLETE — 186,799 functions recompiled → 734 files (605 MB) in generated/mgs5/
- Register addresses: restgprlr_14=0x83C082A0, savegprlr_14=0x83C08250, restfpr_14=0x83C09A8C, savefpr_14=0x83C09A40, restvmx_14=0x83C0CBF8, savevmx_14=0x83C0C960, restvmx_64=0x83C0CC8C, savevmx_64=0x83C0C9F4
- Warnings: unrecognized instructions (lfsu, subfze, sthu) — non-fatal
- Image dumped: mgs5_image.bin (38MB, base 0x82000000)

## Resolved Addresses
- restgprlr_14 = 0x83C082A0
- savegprlr_14 = 0x83C08250
- restfpr_14 = 0x83C09A8C
- savefpr_14 = 0x83C09A40
- restvmx_14 = 0x83C0CBF8
- savevmx_14 = 0x83C0C960
- restvmx_64 = 0x83C0CC8C
- savevmx_64 = 0x83C0C9F4

## HLE Modules
(see docs/HLE_STATUS.md)

## Crashes
(none yet)

## Circuit Breaker Log
(none yet)