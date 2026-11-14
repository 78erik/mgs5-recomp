# Architecture

## Target Platforms (ARM)
- Primary: Android (ARM64) via ReXGlue (proven path, GTA V 360 -> Android).
- Secondary: Nintendo Switch (ARM64, homebrew) via ReXGlue + deko3d.
- Source console: Xbox 360 (PowerPC -> recompiled to ARM64).
- Pilot: Ground Zeroes before TPP.

## Architecture Notes
- Output target: ARM64 (aarch64). Cross-compile from x86-64 host.
- Android: NDK, Vulkan, touch + controller input, JNI packaging.
- Switch: devkitPro, deko3d/Vulkan, homebrew packaging (.nro).
- Performance: ARM NEON for SIMD; thermal throttling on phones.
- Memory: mobile constraints (~1.5-1.7 GB on iPhone precedent; Android similar).
