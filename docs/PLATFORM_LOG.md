# Platform Log

Owner: Drift (Platform Engineer). Tracks ARM64 cross-compilation, packaging, input, rendering backends and mobile performance for the MGS5 recomp (source: Xbox 360 TU; pilot: Ground Zeroes).

## Overview
- Output target: **ARM64 (aarch64)**, cross-compiled from x86-64 host.
- Primary: **Android** (ReXGlue proven path, GTA V 360 -> Android).
- Secondary: **Nintendo Switch** (homebrew, experimental) via ReXGlue + deko3d.
- Phase: 0 (setup & analysis). No builds yet.

---

## Android (primary)

### Toolchain
- Android NDK r26+ (clang 17, `aarch64-linux-android` target).
- CMake 3.22+ with NDK toolchain file.
- Vulkan 1.3 (NDK system libs / Vulkan loader).
- Gradle + Android Studio for packaging (APK/AAB).
- JDK 17.
- ReXGlue SDK Android target (`--android` build flag from launcher).

### Cross-compilation
- Host: Windows x86-64 (or Linux). NDK clang cross-compiler.
- ABI: `arm64-v8a` (primary; no 32-bit target).
- STL: `c++_shared`.
- Build type: Release with LTO for size/perf.
- CMake flags:
  - `-DCMAKE_TOOLCHAIN_FILE=$NDK/build/cmake/android.toolchain.cmake`
  - `-DANDROID_ABI=arm64-v8a`
  - `-DANDROID_PLATFORM=android-26` (min SDK 26 for Vulkan)
  - `-DCMAKE_BUILD_TYPE=Release`

### Rendering: Vulkan
- ReXGlue Xenos -> Vulkan backend (Vulkan 1.1+).
- Android surface via `ANativeWindow`; swapchain + present modes; vsync control.
- Dynamic resolution / quality tiers for thermal headroom.

### Input
- Touch: on-screen virtual pad (sticks + buttons) for menus and basic control.
- Controller: Android Game Controller API / SDL; Bluetooth + USB gamepads; Xbox 360 pad mapping.
- Key events via `AInputEvent`.

### Audio
- ReXGlue audio HLE -> AAudio (low latency) with OpenSL ES fallback.

### Filesystem / packaging
- APK assets or OBB; large game data on external storage / SAF.
- JNI bridge for lifecycle, permissions, surface creation.

### Performance
- ARM NEON SIMD (compiler auto-vectorization + explicit intrinsics where needed).
- Thermal throttling: monitor CPU/GPU thermals, reduce quality / resolution.
- Memory budget ~1.5-1.7 GB (mobile precedent); emulated 360 512 MB + streaming assets.
- Target 30 fps first, then 60 fps where stable.

### Packaging
- APK/AAB, signing, versionCode; per-ABI splits.

### Risks
- Vulkan driver fragmentation across Android devices.
- Memory limits / OOM on low-end phones.
- Touch UX for a controller-centric game.

### Phase 0 deliverables
- [ ] NDK toolchain validated (hello-world cross build).
- [ ] ReXGlue Android build green.
- [ ] Vulkan triangle smoke test on device/emulator.

---

## Switch (secondary)

### Toolchain
- devkitPro (devkitA64) + libnx.
- CMake with devkitPro toolchain file.
- deko3d (Vulkan-like) for rendering (peggle2-nx precedent); no native Vulkan on Switch homebrew.
- nxlink for deploy; `.nro` packaging.

### Cross-compilation
- Target: `aarch64-none-elf` (devkitA64) GCC/Clang.
- CMake flags:
  - `-DCMAKE_TOOLCHAIN_FILE=$DEVKITPRO/cmake/Switch.cmake`
  - Link against libnx.
- Output: `.nro` homebrew executable.

### Rendering: deko3d
- Xenos -> deko3d backend.
- deko3d command buffers; swapchain via vi service.
- Handheld 720p / docked 1080p targets.

### Input
- libnx pad API: Pro Controller + Joy-Con (combined/split).
- Touch screen via hid (menus).

### Filesystem / packaging
- `.nro` (homebrew); no signed `.nsp`.
- RomFS for bundled assets; SD card for large game data.

### Performance
- Tegra X1/X2 thermal; 720p handheld / 1080p docked.
- ARM NEON SIMD.
- Shared ~4 GB memory; homebrew heap limits apply.

### Risks
- deko3d maturity and homebrew-only distribution.
- No standard Vulkan; backend divergence from Android.
- More experimental than Android path.

### Phase 0 deliverables
- [ ] devkitPro environment validated.
- [ ] Minimal `.nro` booting on emulator/hardware.
- [ ] deko3d smoke test.

---

## Cross-cutting notes
- Source console Xbox 360 (PowerPC -> ARM64 via ReXGlue/XenonRecomp); no SPU (unlike PS3 route).
- Pilot Ground Zeroes before The Phantom Pain.
- Clean-room rules apply (no game-derived code committed); see CLEAN_ROOM note.
- Coordinate with Forge (build), Prism (shaders), Anvil (HLE audio/input) via maestri.

## Phase 0 status
- ARM plan documented (this file + docs/ARCHITECTURE.md).
- Toolchains not yet installed/validated.
- No cross-build attempted yet.