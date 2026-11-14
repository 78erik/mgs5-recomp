# Analysis

Source XEX: `G:\pro\recomp\game\Metal Gear Solid V The Phantom Pain\Metal Gear Solid V The Phantom Pain\Default.xex`
Title update TU11: `4B4E085E\000B0000\tu00000011_00000000`
Title ID: `0x4B4E085E` (MGS5: TPP). Alternate title id `0x4B4E085C` (Ground Zeroes) present in optional headers.
XEX magic: `XEX2` (big-endian). Module flags: `0x00000001`. Header size / PE data offset: `0x5000`. Security info offset: `0xB0`. Optional header count: `19`.

## XEX Header Findings

- Entry point (virtual): `0x83C20A68` (image base `0x82000000`, RVA `0x01C20A68`).
- Original PE name: `tpp_x360.exe`.
- Execution info: media id `0x1395B6F200000011`, version `0x00000011` (TU11), base version `0x00000011`.
- Import libraries: `xam.xex`, `xboxkrnl.exe` (records at `0x46B0`).
- Statically linked libs: `XMP`, `XAUDIO2`, `XMCORE`, `XAPOBAS`, `XGRAPHC`-style entries (records at `0x38F4`).
- TLS slot count: `0x00000040` (TLS info at `0x3A68`).
- System flags: `0x00000200`; default heap `0x00040000`; default stack `0x00002000`; title workspace `0x00100000`.
- File format info at `0x38A8` (encryption/compression type per XEX spec).

## Jump Tables

(none yet - requires disassembly; Ghidra/XenonAnalyse not available in this environment)

## Function Boundaries

(none yet - requires disassembly; entry point RVA `0x01C20A68` is the only resolved code address so far)

## NIDs / Addresses

- Title ID: `0x4B4E085E`
- Entry point: `0x83C20A68`
- Image base: `0x82000000`
- Alternate title id: `0x4B4E085C`

## Tooling Status

- `XenonAnalyse`: not found on PATH / not installed.
- `GhydraMCP` (Ghidra MCP, port 8192): not running; no Ghidra binary installed (only source tree at `C:\Users\eriks\Downloads\ghidra-master`).
- Static disassembly, function boundaries and jump tables require Ghidra with the Xbox 360 XEX loader (or XenonAnalyse). Pending tooling setup.