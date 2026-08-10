# Build & Simulation Guide

## Prerequisites (this machine)

* Connect IQ **SDK 9.2.0** (SDK Manager install)
  `%APPDATA%\Garmin\ConnectIQ\Sdks\connectiq-sdk-win-9.2.0-*`
* **Java** -- monkeyc is a Java tool. This machine has
  `C:\Program Files\Android\jdk\jdk-8.0.302.8-hotspot\jdk8u302-b08\bin\java.exe`
  (JDK 8). `build.ps1` locates it automatically and puts it on PATH.
* **openssl** -- used to generate `developer_key.der` on first build
  (`C:\Program Files\Git\usr\bin\openssl.exe`).
* **f?nix 3 device definition** (installed via SDK Manager) -- the 
  `fenix3` simulator target used for TC-01?TC-06.

## Build

```powershell
# normal build (fenix3)
powershell -ExecutionPolicy Bypass -File build.ps1

# with the in-simulator self-test for TC-02 (prints KL reference conversion)
powershell -ExecutionPolicy Bypass -File build.ps1 -Selftest
```

Output:
* `build/rso_datafield.iq` -- data field target (16 KB pool)
* `build/rso_widget.iq` -- widget target (64 KB pool)

The compiler prints `Memory Limit: <N>` per target -- that is the RAM budget
enforcement for TC-03 / TC-04.

## Run in the simulator

```powershell
$sdk = Get-Content "$env:APPDATA\Garmin\ConnectIQ\current-sdk.cfg"
& "$sdk\bin\monkeydo.bat" "build\rso_widget.iq" fenix3
& "$sdk\bin\monkeydo.bat" "build\rso_datafield.iq" fenix3
```

monkeydo starts the simulator if it is not already running.

### Feeding a position (TC-02 / TC-05)

In the simulator UI:
1. **Simulator -> Settings -> Position** (or the location dialog).
2. Enter the desired lat/lon (e.g. `3.138, 101.686`) and press OK.
3. The simulator streams that fix; the app recomputes and redraws.

Alternatively, use the simulator's **GPS Position** toolbar / `Simulator ->
Sensor->GPS` menu on newer SDKs.

### Self-test mode (TC-02 without GPS)

Build with `-Selftest` (defines `RSO_SELFTEST`). The data field's `compute()`
and the widget's first tick call `RsoAppState.selftest()`, which projects the
Kuala Lumpur reference coordinate and prints:

```
SELFTEST E=410067.9999 N=347389.9282
```

to the simulator console -- matching `dev/reference/known_points.json` to
well under 1 m.

## Install on a real watch

* Connect IQ app for your phone -> device -> install app (`.iq` files), or
* Drag the `.iq` onto the watch-mounted volume when it is in USB Mass Storage
  mode (if supported by the device).
