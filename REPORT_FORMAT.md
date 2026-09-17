# Report export (`players_info.json`) format

Produced by the MainMenu **Report** button → `PlayerInfo.build_report_json()`
(`global/player_info.gd`). One file per device: a full dump of that device's
local SQLite DB (`user://player_info.db`). Merge many devices by concatenating
the arrays; disambiguate rows by `device_id` + `session_id`.

## Top level

```json
{
  "export_version": 1,
  "device_id": "<uuid-v4>",
  "exported_at": 1758000000.0,
  "sessions": [ ... ],
  "scenes": [ ... ],
  "interactions": [ ... ],
  "writings": [ ... ]
}
```

| Field | Type | Meaning |
|---|---|---|
| `export_version` | int | Schema version of this file (currently `1`). |
| `device_id` | string | UUIDv4 identifying the device. Also on every `sessions` row. |
| `exported_at` | float | Unix epoch seconds when the file was generated. |

## Tables (array of row objects)

Each row carries `session_id` (UUIDv4) linking it to a `sessions` row.
Numeric `id` is auto-increment **per table, per device** — unique only within
one file; never join on `id` across files (use `session_id`).

### `sessions`
| Field | Type | Meaning |
|---|---|---|
| `session_id` | string | UUIDv4, primary key. |
| `device_id` | string | Same as top-level. |
| `absolute_start_time` | float | Unix epoch seconds at app/session launch. |
| `total_duration` | float | Session length in seconds. |
| `gender` | string | `"Male"` \| `"Female"` \| `"None"`. |
| `birth_day` / `birth_month` / `birth_year` | int | Player-entered birthdate. |
| `dirty`, `synced_at` | int / float | Reserved for a future remote-sync stage; **ignore for analysis**. |

### `scenes` — one row per screen visit
| Field | Type | Meaning |
|---|---|---|
| `scene` | string | Screen/scene name; level scenes are suffixed `_<level>`. |
| `time` | float | Seconds since app launch (relative clock, not wall-clock). |
| `duration` | float | Seconds spent on that screen. |

### `interactions` — one row per click or drag
| Field | Type | Meaning |
|---|---|---|
| `type` | string | `"click"` or `"drag"`. |
| `time` | float | Seconds since app launch (relative). |
| `duration` | float | Press→release seconds. |
| `root_scene` | string | Root scene name at the time. |
| `level` | int | Level number, or `0` if not in a level. |
| `position_x`, `position_y` | float | Pointer position — **click only** (null for drags). |
| `start_x`, `start_y`, `end_x`, `end_y` | float | Drag start/end — **drag only** (null for clicks). |
| `clicked` | string | Node name clicked — **click only**. |
| `drag`, `drop_target` | string | Dragged node / drop node names — **drag only**. |

### `writings` — one row per handwriting attempt on the blackboard
| Field | Type | Meaning |
|---|---|---|
| `kind` | string | Target building: `HOUSE`, `HOSPITAL`, `SCHOOL`, `RECYCLING`, `WATER`. |
| `image_b64` | string | Base64 of the drawing **PNG**; `base64.b64decode(...)` → PNG bytes. |
| `prediction` | object | CNN class→probability map, e.g. `{"hospital":0.9,"school":0.1}`. On prediction failure it is `{"prediction_error":0.0}`. If the stored JSON couldn't be parsed, a raw string field `prediction_json` appears instead. |

## Notes
- **Relative time**: `time` in `scenes`/`interactions` is seconds since app
  launch (`Time.get_ticks_msec`). Approx wall-clock of an event ≈
  `session.absolute_start_time + row.time`.
- **Coordinates** are in the game viewport space (1280×720 design size).
- **Completeness**: sessions that produced **zero** `writings` are deleted on
  quit, so essentially every session in the file has ≥1 writing.
