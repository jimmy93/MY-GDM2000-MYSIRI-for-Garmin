# MY RSO Grid -- Garmin Connect IQ (GDM2000 RSO / BRSO converter)

A lightweight, **offline** Connect IQ application that converts live WGS84 GPS
coordinates on a Garmin wearable into the **Malaysian GDM2000 grid system**:

* **EPSG:3375** -- GDM2000 / Peninsular RSO (West Malaysia, "RSO Malaya")
* **EPSG:3376** -- GDM2000 / East Malaysia BRSO (Sabah & Sarawak, "Borneo RSO")

The math is a Monkey C port of the PROJ Hotine Oblique Mercator (Variant A,
`+no_uoff`) algorithm -- the same verified projection used by the Suunto
reference project `jimmy93/MY-GDM2000-MYSIRI-for-Suunto` and by
pyproj/PROJ with the official EPSG registry parameters.

**No internet, no Bluetooth, no phone app.** All conversion happens on-device.
**Zero storage** -- coordinates live only in volatile RAM.

## Two app types (one project folder)

| Target | Type | File | f?nix 3 RAM pool |
|---|---|---|---|
| A | **Data Field** (in Run/Hike/Tactical screens) | `rso_datafield.iq` | 16 KB |
| B | **Widget** (full screen from the watch menu) | `rso_widget.iq` | 64 KB |

Both share `source/common/` (math, zone logic, drawing). At publish time they
are submitted to the Connect IQ Store as **two separate listings** (one per app
type) -- that is the only place they are split.

## Features

* Live GPS quality indicator: `NO GPS` / `LAST KNOWN` / `POOR (2D)` /
  `USABLE (3D)` / `GOOD (3D)`.
* RSO **Easting / Northing in integer metres** plus altitude.
* Zone modes: **AUTO** (longitude boundary ~=108degE with 0.5deg hysteresis),
  **Peninsular (3375)**, **East (3376)** -- cycle with a tap / Enter in the widget.
* 64-bit double-precision math (`Toybox.Lang.Double`) -> coordinate drift
  **< 1 m** vs pyproj/EPSG reference values.
* **Connect IQ API Level 1.0.0 floor** -> runs on legacy hardware (f?nix 3, etc.).

## Project layout

```
source/common/       RsoMath.mc (projection), RsoZone.mc (zones),
                     RsoView.mc (drawing), RsoAppState.mc, RsoGrid.mc
source/datafield/    RsoDataFieldApp.mc, RsoDataFieldView.mc
source/widget/       RsoWidgetApp.mc, RsoWidgetView.mc, RsoWidgetDelegate.mc
resources/           per-target manifest.xml + resources.xml + icons/
monkey_datafield.jungle   jungle build file (data field target)
monkey_widget.jungle      jungle build file (widget target)
build.ps1            one-command build for both targets
dev/reference/       pyproj-verified reference fixtures (known_points.json)
test/verify_reference.py  regenerates/verifies the fixtures
docs/PRD.md          corrected product requirements (v2.0)
docs/BUILD.md        build & simulate instructions
docs/TC_MATRIX.md    verification & testing matrix results
tools/               icon generator
```

## Build

Prerequisites: Connect IQ SDK (via Garmin SDK Manager), a Java runtime, and
openssl (for the developer key). On this machine they are already present.

```powershell
powershell -ExecutionPolicy Bypass -File build.ps1            # fenix3 default
powershell -ExecutionPolicy Bypass -File build.ps1 -Selftest  # enable TC-02 self-test
```

Artifacts land in `build/rso_datafield.iq` and `build/rso_widget.iq`.
See `docs/BUILD.md` for simulator/device install and testing steps.

## Verification

* `test/verify_reference.py` cross-checks committed reference fixtures against
  pyproj (dev-only tool).
* TC-01?TC-06 results are recorded in `docs/TC_MATRIX.md`.

## License

MIT (aligned with the source Suunto project).

## Disclaimer

GDM2000 ~= WGS84 within ~1 m (EPSG geocentric translation 0,0,0). The on-device
GPS is WGS84; no datum shift is applied -- only the ellipsoid projection math.
Always verify coordinates against official JUPEM sources for critical survey
work. This app is provided as-is for situational awareness and navigation aid.
