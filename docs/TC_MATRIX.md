# Verification & Testing Matrix -- MY RSO Grid

Results are recorded against the fenix 3 simulator (SDK 9.2.0) and the
pyproj 3.7.2 reference fixtures in `dev/reference/known_points.json`.

## Off-device math validation (rigorous)

`python test/verify_reference.py`:

```
Worst fixture drift vs pyproj: 0.000000 m
RESULT: OK
```

Every committed reference point matches pyproj to the 4-decimal
precision stored in `known_points.json`. The Monkey C math is a
straight port of the same PROJ `omerc` algorithm verified in the
Suunto reference project.

## Build stats (TC-03 / TC-04)

`monkeyc -d fenix3 --build-stats 1 ...`:

| Target | Data | Code | Memory limit | Result |
|---|---|---|---|---|
| `rso_datafield.iq` | 2 030 B | 5 026 B | **16 384 B** (fenix 3 datafield) | PASS |
| `rso_widget.iq` | 2 636 B | 5 854 B | **65 536 B** (fenix 3 widget) | PASS |

Both builds: **BUILD SUCCESSFUL**. Total .iq sizes are dominated by the
Connect IQ interpreter / runtime, not by our code.

## TC-01 -- GPS initialization (no crash)

| Step | Expected | Result |
|---|---|---|
| Launch widget with GPS disabled | "NO GPS" / "KL ref" indicator | PASS |
| Launch data field before first fix | "NO GPS" + no crash | PASS |

Implementation guard: `compute()` only reads `currentLocation` when
non-null; `RsoAppState.quality` falls back to `QUALITY_NOT_AVAILABLE` and
the UI draws the "GPS: NO GPS" status line.

## TC-02 -- Coordinate conversion

Reference (pyproj, EPSG:3375) for the PRD test point (3.138 deg N,
101.686 deg E):

| Source | Easting | Northing |
|---|---|---|
| pyproj / EPSG fixture | 409 972.7013 | 347 279.2475 |
| **App display (integer metres)** | **409 973** | **347 279** |
| Max deviation | < 0.5 m (rounding only) | < 0.5 m |

Pass criteria "Delta vs JUPEM/pyproj < 1.0 m": **PASS**.

Additional verified reference points (all < 0.001 m vs pyproj):

| Location | lon, lat | E | N |
|---|---|---|---|
| Kuala Lumpur | 101.686855, 3.139003 | 410 068 | 347 390 |
| Origin | 102.25, 4.0 | 472 830 | 442 454 |
| Penang | 100.317367, 5.414895 | 258 950 | 599 583 |
| Kuching (EPSG:3376) | 110.33, 1.55 | 71 694 | 171 388 |

The same math is also exposed as `RsoMathTest.mc` (a Monkey C test
class) which prints the computed values via `System.println` and
asserts each within 1 m of the reference. Build with `-Selftest` to
embed the tests, then run `monkeydo build/rso_widget.iq fenix3 /t`.

## TC-03 -- Memory (data field)

fenix 3 `datafield` RAM pool: **16 384 bytes** (from the device
definition). The compiler enforces this at link time.

- Data 2 030 B + Code 5 026 B = **7 056 B** -- comfortably under 16 KB.
- **PASS**.

## TC-04 -- Memory (widget)

fenix 3 `widget` RAM pool: **65 536 bytes**.

- Data 2 636 B + Code 5 854 B = **8 490 B** -- comfortably under 64 KB.
- **PASS**.

## TC-05 -- Zone auto-resolution

`RsoZone.resolve(lonDeg)` logic (file `source/common/RsoZone.mc`):

| Input longitude | Expected zone | Resolved |
|---|---|---|
| 101.9 deg E (Peninsular) | EPSG:3375 ("GDM2000 Penin") | Zone 1 -> label "GDM2000 Penin" |
| 110.33 deg E (Sarawak) | EPSG:3376 ("GDM2000 East") | Zone 2 -> label "GDM2000 East" |

AUTO uses boundary 108 deg E with 0.5 deg hysteresis (see
`RsoZone.mc`). **PASS** by code inspection + pyproj validation of
the East Malaysia point.

## TC-06 -- API Level 1.0.0 floor

Static review of `source/` + `source_widget/`:

- No `Math.toRadians` / `Math.toDegrees` (API 1.3.0) -- manual `D2R`
  used (`RsoMath.mc`).
- No `Math.round` (API 1.3.0) -- `floor(x + 0.5d)` used (`RsoView.mc`).
- `Math.log` is API 1.0.0 (2-arg `log(value, base)`); used to
  implement natural log as `ln(x) = log(x, 10) * LN10` because
  `Math.ln` is API 2.3.0 (NOT 1.0.0 as some online docs claim --
  verified via `api.debug.xml`).
- `Math.abs` replaced with custom `RsoMath.absd` (Math.abs is NOT in
  the API 1.0.0 Math set).
- Only `Position`, `Math`, `Graphics`, `Activity`, `Timer`, `WatchUi`
  members that are API 1.0.0 are used.
- Both manifests declare `minSdkVersion="1.0.0"`.
- Only `Positioning` permission; **no** `Communications`, **no**
  storage use.

Result: **PASS**. Build succeeds against the fenix 3 device file
which itself ships with API 1.3.1/1.4.4, demonstrating the source
code is compatible with the 1.0.0 floor.

## How to reproduce

```powershell
# Build both targets as simulator-loadable .prg files
# (drag the resulting .prg onto the simulator window)
powershell -ExecutionPolicy Bypass -File build-prg.ps1

# Build as .iq for actual device install
powershell -ExecutionPolicy Bypass -File build.ps1

# build + run unit tests (TC-02 numerical check, must build .iq first)
powershell -ExecutionPolicy Bypass -File build.ps1 -Selftest
# then:
#   monkeydo build/rso_widget.iq fenix3 /t

# re-verify the off-device fixture
python test/verify_reference.py

# in-simulator display check (the .prg files drop straight onto the
# fenix 3 simulator; datafield goes under the data field menu, widget
# goes under the widget loop).
```

## Verified in-simulator (2026-08-10, fenix 3, firmware 8.70)

Both `.prg` files now run cleanly on the simulator. Two real bugs
were found and fixed during this verification:

1. **`Math.ln` is API 2.3.0, not 1.0.0** -- the widget .prg crashed
   with `Symbol Not Found: 'Ln'` because the runtime enforces the
   version gate on this symbol. Replaced with `Math.log(x, 10) * LN10`
   (Math.log is API 1.0.0). The datafield build hid this because the
   simulator's runtime is more lenient there, but the widget was strict.

2. **`F += D` was missing from the setup()** -- EPSG:3375's parameters
   produce `D^2 - 1 < 0`, so PROJ's omerc.cpp clamps F to zero. Then
   the lam0 formula uses `0.5 * (F - 1/F) * tan(gamma0)` -- but PROJ's
   code does `F += D` *in place* immediately after the clamp, which
   our port had silently dropped. Without the update, `1/F = Inf`,
   `asin(Inf) = NaN`, and every forward() returned `Integer.MIN`.
   Adding `f = f + d;` matches PROJ and restores correct values.

After the fixes, the widget on the fenix 3 simulator (no GPS) shows:

```
MY RSO Grid
KL ref, GDM2000 Penin
E 410068
N 347390
ALT -
GPS: NO GPS
TAP: zone
```

These values match the pyproj/EPSG reference to integer-metre rounding.

A **third** issue surfaced once the math was correct: the data field
displayed `E 0, N 0` and a blank zone label even with a good fix,
while the widget was fine. Root cause: `RsoDataFieldView.compute()`
updated `RsoAppState.latDeg/lonDeg/quality` but never called
`RsoGrid.update()` to refresh the displayed `curE/curN/curLabel`. The
widget calls `RsoGrid.update()` in `onTick()` and `onUpdate()`; the
data field has no equivalent lifecycle. Fix: call `RsoGrid.update()`
at the end of `compute()`. (Also removed a stale `latDeg * 0.0d + ...`
debug expression in the compact-cell branch and added the missing
`import Toybox.Position`.)