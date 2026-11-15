# Ghidra Setup for MGS5 Xbox 360 XEX Analysis

## Purpose
Find the register save/restore function addresses (restgprlr_14, savegprlr_14, restfpr_14, savefpr_14, restvmx_14, savevmx_14, restvmx_64, savevmx_64) and setjmp/longjmp addresses needed by XenonRecomp.

## Why these addresses
XenonRecomp's recompiler needs them to define the compiler-generated register restore/save functions as symbols. Without them, the lifted C++ code references undefined functions and won't link.

## Tool: Xenon360 Ghidra Extension
- Repo: https://github.com/EveryoneEverybody/Xenon360
- Ghidra 12.2 (primary) or 12.1.4 (best-effort)
- JDK 25 (for Ghidra 12.2) or JDK 21 (for 12.1.4)
- Extension ZIP: ghidra_12.2_XenonVMX128_0.8.3.zip
- Language: PowerPC:BE:64:Xenon-VMX128-32addr (v1.4)

## Installation Steps
1. Install JDK 25 (e.g., via winget: `winget install Microsoft.OpenJDK.25` or download from adoptium).
2. Download Ghidra 12.2 from https://github.com/NationalSecurityAgency/ghidra/releases.
3. Download Xenon360 extension ZIP from https://github.com/EveryoneEverybody/Xenon360/releases.
4. In Ghidra: File > Install Extensions > + > select ZIP. Restart Ghidra.
5. Enable XenonAnalysisPlugin (File > Configure > Configure All Plugins > Analysis).

## Importing MGS5 XEX
1. Create a Ghidra project.
2. File > Import File > select `Default.xex` from the game folder.
3. Confirm loader: "Xenon360 XEX", language: PowerPC:BE:64:Xenon-VMX128-32addr.
4. Accept Auto Analysis (keep native switch analysis enabled).
5. Review analysis log for warnings.

## Finding Register Save/Restore Addresses
Search the decompiled code for the byte patterns (XenonRecomp README):

| Function | Starting bytes |
|---|---|
| restgprlr_14 | e9 c1 ff 68 |
| savegprlr_14 | f9 c1 ff 68 |
| restfpr_14 | c9 cc ff 70 |
| savefpr_14 | d9 cc ff 70 |
| restvmx_14 | 39 60 fe e0 7d cb 60 ce |
| savevmx_14 | 39 60 fe e0 7d cb 61 ce |
| restvmx_64 | 39 60 fc 00 10 0b 60 cb |
| savevmx_64 | 39 60 fc 00 10 0b 61 cb |

In Ghidra: Search > Memory for the byte sequence. The first match for each pattern is the function start address.

Alternatively, search by function name if symbols/PDB are available (MGS5 may ship with partial symbols in the XEX).

## Finding setjmp/longjmp
- longjmp: look for calls to RtlUnwind.
- setjmp: typically appears just after longjmp in the binary.

## After Finding Addresses
1. Fill in mgs5_recomp.toml with the found addresses.
2. Re-run XenonRecomp to generate C++ code.
3. Update docs/ANALYSIS.md with the addresses.

## Notes
- The XEX loader handles decryption/decompression automatically.
- No host-specific executables needed.
- macOS not qualified; Windows/Linux tested.
- Ghidra 12.2 requires JDK 25 (not interchangeable with 12.1.4/JDK 21).