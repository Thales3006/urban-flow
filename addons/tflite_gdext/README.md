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
export TFLITE_LIB_DIR=/path/to/tflite-cmake-build-dir   # contains libtensorflowlite_c.so

# Linux (desktop dev/testing)
scons platform=linux target=template_debug

# Android (needs ANDROID_NDK_ROOT / ANDROID_HOME from this project's flake.nix dev shell)
scons platform=android target=template_debug arch=arm64 android_api_level=24 ndk_version=<matching your NDK install>
```

Compiled `.so` files and the `libtensorflowlite_c*.so` runtime libs are not
committed to git (see `.gitignore`) — same reasoning as `model.tflite`: they're
large rebuildable binaries, not source. Copy the build output here (alongside
`tflite_gdext.gdextension`) before running the game with this extension enabled.

## Status (2026-06-21)

Verified working end-to-end on Linux desktop inside a real headless Godot run
(loads `model.tflite`, predicts on a known test image, matches the Python
server's output). Cross-compiles cleanly for Android arm64 with correct ELF
architecture and linkage. **Not yet verified to run correctly on an actual
Android device** — that needs real hardware.
