# tflite_gdext

GDExtension wrapping TensorFlow Lite's C API, so the handwriting-recognition
model can run directly inside Godot instead of round-tripping to
`server_predict/`'s HTTP server. See `src/tflite_predictor.h` for the
GDScript-facing API (`TFLitePredictor.load_model(path)`, `.predict(PackedFloat32Array)`).

## Building

Requires `godot-cpp` (matching this project's Godot version) cloned/symlinked
into this directory as `godot-cpp/`, plus a built TensorFlow Lite C library
(`tensorflow/lite/c/CMakeLists.txt` in a TF source tree, via CMake+Ninja —
see `tensorflow.org/lite/guide/build_cmake`). Point the build at both via env vars:

```sh
export TFLITE_SRC_DIR=/path/to/tensorflow-2.20.0
export TFLITE_LIB_DIR=/path/to/tflite-cmake-build-dir   # contains the TFLite C lib

# Linux (desktop dev/testing)
scons platform=linux target=template_debug

# Android (needs ANDROID_NDK_ROOT / ANDROID_HOME from this project's flake.nix dev shell)
scons platform=android target=template_debug arch=arm64 android_api_level=24 ndk_version=<matching your NDK install>

# Windows — cross-compile from Linux using MinGW (see below), or run natively on Windows
scons platform=windows target=template_debug
```

Compiled binaries and TFLite runtime libs are not committed to git (see
`.gitignore`) — same reasoning as `model.tflite`: they're large rebuildable
binaries, not source. Copy the build output here (alongside
`tflite_gdext.gdextension`) before running the game with this extension enabled.

### Windows build details

**Cross-compiling from Linux with MinGW** (no Windows machine needed):

1. Install a MinGW-w64 toolchain (e.g. `mingw-w64` package, or via Nix
   `pkgsCross.mingwW64`).

2. Build TFLite for Windows with MinGW:
   ```sh
   cmake -S /path/to/tensorflow -B tflite-win-build \
     -DCMAKE_SYSTEM_NAME=Windows \
     -DCMAKE_C_COMPILER=x86_64-w64-mingw32-gcc \
     -DCMAKE_CXX_COMPILER=x86_64-w64-mingw32-g++ \
     -DTFLITE_C_BUILD_SHARED_LIBS=ON \
     -G Ninja
   cmake --build tflite-win-build --target tensorflowlite_c
   # produces tflite-win-build/libtensorflowlite_c.dll
   #      and tflite-win-build/libtensorflowlite_c.dll.a (import lib)
   ```

3. Build the extension:
   ```sh
   export TFLITE_SRC_DIR=/path/to/tensorflow-2.20.0
   export TFLITE_LIB_DIR=/path/to/tflite-win-build
   scons platform=windows target=template_debug use_mingw=yes
   ```

4. Deploy the outputs:
   ```
   addons/tflite_gdext/libtflite_gdext.windows.template_debug.x86_64.dll
   addons/tflite_gdext/windows/libtensorflowlite_c.dll
   ```

   The `windows/` sub-folder keeps the Windows copy of `libtensorflowlite_c.dll`
   separate from the Linux `.so` of the same base name one level up. Godot
   flattens the path when deploying to a Windows export, so only the filename
   matters at runtime — Windows resolves the DLL by name from the same directory
   as the loading binary.

**Native Windows build with MSVC**:

CMake generates `tensorflowlite_c.dll` (no `lib` prefix) and
`tensorflowlite_c.lib` (import lib). In that case rename/copy the DLL to
`windows/libtensorflowlite_c.dll` to match the path declared in
`tflite_gdext.gdextension`, or update the `[dependencies]` block to point to
`windows/tensorflowlite_c.dll` instead.

**Important — Android dependency filename**: `libtflite_gdext.android.*.so` is
linked against a library whose embedded NEEDED name is `libtensorflowlite_c.so`
(set at link time from whatever the file was named in the build dir, regardless
of what you rename it to afterwards). Android's dynamic linker resolves NEEDED
libraries by exact filename in the flat `lib/<abi>/` directory it bundles them
into — so the Android build of `libtensorflowlite_c` must be deployed here as
exactly `android/libtensorflowlite_c.so` (the `android/` subfolder only exists
to avoid colliding with the Linux x86_64 copy of the same name one level up;
Android's APK packaging flattens subdirectories away, so only the filename
matters). Naming it anything else (e.g. `libtensorflowlite_c.android.so`, which
was the original mistake here) makes the extension silently fail to load on
Android with no crash — `ClassDB.class_exists("TFLitePredictor")` just returns
false at runtime, caught via `adb logcat` showing nothing more specific than
the extension's classes never registering.

## Status (2026-06-21)

Verified working end-to-end on Linux desktop inside a real headless Godot run
(loads `model.tflite`, predicts on a known test image, matches the Python
server's output). Cross-compiles cleanly for Android arm64 with correct ELF
architecture and linkage, and the dependency-filename bug above is fixed and
verified via a real headless `--export-debug` re-export (confirmed
`libtensorflowlite_c.so` lands correctly in the APK's `lib/arm64-v8a/`).
**Not yet confirmed working on an actual Android device** — that needs real
hardware.
