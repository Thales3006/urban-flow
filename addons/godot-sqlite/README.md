# godot-sqlite

Vendored from [2shady4u/godot-sqlite](https://github.com/2shady4u/godot-sqlite) v4.7,
trimmed to just the platforms this project ships (Linux x86_64, Android arm64).
Used by `global/player_info.gd` for local on-device telemetry storage
(`user://player_info.db`).

## Re-fetching the binaries

The compiled `.so` files are gitignored (rebuildable, not source — same
reasoning as `addons/tflite_gdext/`). To restore them:

```sh
curl -sL -o /tmp/godot-sqlite-bin.zip \
  https://github.com/2shady4u/godot-sqlite/releases/download/v4.7/bin.zip
unzip -o /tmp/godot-sqlite-bin.zip \
  bin/libgdsqlite.linux.template_debug.x86_64.so \
  bin/libgdsqlite.linux.template_release.x86_64.so \
  bin/libgdsqlite.android.template_debug.arm64.so \
  bin/libgdsqlite.android.template_release.arm64.so \
  -d addons/godot-sqlite/
```
