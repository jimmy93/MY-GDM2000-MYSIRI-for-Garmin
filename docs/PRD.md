# Product Requirement Document (PRD) v2.0 -- "MY RSO Grid" (Garmin Connect IQ)

## 1. Introduction & Objectives

Build a lightweight, highly compatible Garmin Connect IQ application based on the open-source
MY-GDM2000-MYSIRI-for-Suunto project. The app captures real-time GPS (WGS84) directly on a
Garmin wearable and converts it locally into the **GDM2000 / RSO Malaya** grid (Peninsular
Malaysia, **EPSG:3375**) and **GDM2000 / BRSO** (East Malaysia / Borneo, **EPSG:3376**).

By setting **Connect IQ API Level 1.0.0** as the absolute floor, the app runs on legacy devices
(e.g. f?nix 3) with **no internet, no Bluetooth, and no companion phone sync**.

## 2. Target Audience & Use Cases

* **Search and Rescue (SAR):** BOMBA / SMART / APM responders needing immediate, offline local
  grid references during wilderness operations.
* **Hikers & Mountaineers:** positioning on Malaysian topographical maps that use the RSO Malaya grid.
* **Field Surveyors:** quick on-the-wrist verification of RSO Easting / Northing without booting
  dedicated GIS hardware.

## 3. Scope & System Architecture

* **Local calculation:** all geodetic conversions are processed entirely on-device using
  `Toybox.Math`.
* **Zero connectivity:** no Bluetooth, no phone app, no cellular data. The `Communications`
  permission is omitted from every manifest.
* **Datum:** GDM2000 ~= WGS84 within ?1 m (EPSG-recommended geocentric translation 0,0,0).
  **No datum shift is applied** -- only the ellipsoid projection math.
* **Target SDK floor:** `minSdkVersion="1.0.0"`.

## 4. Functional Requirements

### 4.1 App Types (Dual-Target Deployment)

Two app types are built from **one project folder** with a **shared logic layer**:

```
               ????????????????????????????????
               ?   source/common (shared)     ?
               ?  RsoMath ? RsoZone ? RsoView  ?
               ????????????????????????????????
                             ?
             ?????????????????????????????????
             ?                               ?
?????????????????????????????   ?????????????????????????????
?  Target A: Data Field     ?   ?  Target B: Widget          ?
?  resources/manifest_datafield.xml ?  resources/manifest_widget.xml ?
?  rso_datafield.iq         ?   ?  rso_widget.iq            ?
?  RAM pool (fenix3): 16 KB ?   ?  RAM pool (fenix3): 64 KB ?
?  Inside activity screens  ?   ?  Full screen from menu    ?
?  compute()/onUpdate ~1 Hz ?   ?  1 s Timer while visible  ?
?????????????????????????????   ?????????????????????????????
```

* **Target A -- Custom Data Field** (`App.DataField`): integrates into Run / Hike / Tactical
  activity screens; adapts layout automatically to the user's field split (1-field vs 2/4-field)
  via the clipped device context.
* **Target B -- Widget** (`App.AppBase` + `WatchUi.View`): launched from the watch menu for a
  quick full-screen coordinate check without starting an activity.
* **Publishing:** two separate Connect IQ Store listings (one per app type), built from the same
  project folder.

### 4.2 Core Features & User Interface (UI)

* **Live GPS status indicator:**
  `QUALITY_NOT_AVAILABLE` -> "NO GPS", `QUALITY_LAST_KNOWN` -> "LAST KNOWN",
  `QUALITY_POOR` -> "POOR (2D)", `QUALITY_USABLE` -> "USABLE (3D)", `QUALITY_GOOD` -> "GOOD (3D)".
* **Grid display:** RSO Easting / Northing as **integer metres (rounded, no decimals)** plus
  altitude in metres.
* **Zone handling:** AUTO (longitude-based ~=108degE boundary with 0.5deg hysteresis) /
  Peninsular (EPSG:3375) / East Malaysia (EPSG:3376). The widget cycles zones via tap/enter;
  the data field defaults to AUTO.
* **Power optimization:** the data field redraws on the activity lifecycle
  (`compute()`/`onUpdate()`, ~1 Hz); the widget redraws on a 1 s `Timer` started only in
  `onShow()` and stopped in `onHide()`.

```
?????????????????????????????
?      MY RSO Grid          ?
?   GDM2000 Peninsular      ?
?                           ?
?  Easting  : 410068 m      ?
?  Northing : 347390 m      ?
?  Altitude : 452 m         ?
?                           ?
?  GPS: Good (3D)           ?
?????????????????????????????
```


## 5. Non-Functional Requirements

### 5.1 Technical Constraints & Performance

* **Minimum API level:** 1.0.0 (compile floor; enforced by code convention -- see ?6.2).
* **Memory footprint:** data field must fit the **16 KB RAM pool** enforced by the f?nix 3
  compiler (`memoryLimit: 16384` for `datafield`); widget target uses the 64 KB pool.
  Forward-only projection, **no per-tick object allocation**, no inverse projection.
* **Mathematical precision:** all arithmetic in `Toybox.Lang.Double` (64-bit, `d`-suffixed
  literals; custom Double ? constant, since `Math.PI` is 32-bit) -> coordinate drift < 1 m vs
  pyproj/JUPEM references (EPSG:3375/3376).

### 5.2 Data Privacy & Security

* **Zero storage:** no `Application.Storage`, no flash writes; coordinates are processed
  transiently in volatile RAM.
* **No network permissions:** the `Communications` permission is omitted entirely from both
  manifests.

## 6. Technical Specifications & Dependencies

### 6.1 Manifests

```xml
<iq:manifest xmlns:iq="http://www.garmin.com/xml/connectiq" version="1">
    <iq:application entry="RsoDataFieldApp" id="<32-hex>" type="datafield"
                    minSdkVersion="1.0.0" name="@Strings.AppName">
        <iq:products><iq:product id="fenix3"/></iq:products>
        <iq:permissions><iq:uses-permission id="Positioning"/></iq:permissions>
        <iq:languages><iq:language>eng</iq:language></iq:languages>
    </iq:application>
</iq:manifest>
```

The widget manifest is identical except `type="widget"`, `entry="RsoWidgetApp"`, and a
different app `id`. **No** `Communications` permission in either.

### 6.2 Essential API Subsystems (API 1.0.0 subset only)

| Subsystem | Used for | 1.0.0-safe notes |
|---|---|---|
| `Toybox.Position` | `getInfo()`, `Info.position/altitude/accuracy/quality`, `enableLocationEvents` | all 1.0.0 |
| `Position.Location` | `toDegrees()` -> `[Double, Double]` | 1.0.0 |
| `Toybox.Math` | `sin cos tan asin acos atan atan2 sqrt ln pow floor ceil` | all 1.0.0 |
| `Toybox.Activity` | `DataField.compute(info)`; `Info.currentLocation/currentLocationAccuracy/altitude` | 1.0.0 |
| `Toybox.Timer` | widget 1 s refresh (`Timer.Timer`, `start(method, 1000, true)`) | 1.0.0 |
| `Toybox.Graphics` | `dc.setColor/drawText/drawLine/getWidth/getHeight/getFontHeight`, `FONT_*` 1.0.0 set, `COLOR_*` | 1.0.0 |
| `Toybox.WatchUi` | `View`, `BehaviorDelegate`, `requestUpdate()` | 1.0.0 |
| **Avoided** | `Math.toRadians/toDegrees` (1.3.0), `Math.round` (1.3.0) | manual deg?rad, `floor(x+0.5d)` |

## 7. Mathematical & Conversion Reference

Implementation = port of the Suunto project's proven PROJ `omerc` (Hotine Oblique Mercator,
**Variant A, `+no_uoff`**) algorithm. Values below are the **EPSG / JUPEM registry values**
(owner-approved; the PRD v1 constants were incorrect).

### 7.1 Constants -- Peninsular (EPSG:3375)

| Parameter | Value |
|---|---|
| Ellipsoid | GRS80, a = 6378137.0 m, 1/f = 298.257222101 |
| Projection centre ?? | 4deg00? N |
| Projection centre ?? | 102deg15? E (102.25deg) |
| Azimuth at centre ? | 323.025796466667deg |
| Angle from rectified to skew grid ? | 323.130102361111deg |
| Scale factor k? | 0.99984 |
| False easting | 804 671.0 m |
| False northing | 0.0 m |
| Method | Hotine Oblique Mercator (Variant A), `+no_uoff` |

### 7.2 Constants -- East Malaysia / Borneo (EPSG:3376)

| Parameter | Value |
|---|---|
| ?? / ?? | 4deg00? N / 115deg00? E |
| ? / ? | 53.31580995deg / 53.1301023611111deg |
| k? | 0.99984 |
| False easting / northing | 0.0 m / 0.0 m |

### 7.3 Corrections vs PRD v1

| Parameter | PRD v1 said | **EPSG/JUPEM (used)** |
|---|---|---|
| False easting (3375) | 400 000 m | **804 671 m** |
| Azimuth ? (3375) | 53deg07?00? | **323.025796466667deg** |
| Rectified grid angle ? | not stated | **323.130102361111deg** |
| Datum shift | not stated | **0,0,0** (GDM2000 ~= WGS84) |

> Note: a 400 000 m false easting belongs to the *legacy Kertau / RSO Malaya* convention;
> GDM2000 RSO uses 804 671 m. Using the v1 value would place every point ~405 km off JUPEM
> values and fail TC-02 by hundreds of kilometres.

### 7.4 Reference outputs (pyproj-verified, EPSG:3375)

| Location | lon, lat | Easting | Northing |
|---|---|---|---|
| Kuala Lumpur | 101.686855, 3.139003 | 410 068 | 347 390 |
| TC-02 point | 101.686, 3.138 | 409 973 | 347 279 |
| Projection origin | 102.25, 4.0 | 472 830 | 442 454 |
| Penang | 100.317367, 5.414895 | 258 950 | 599 583 |

## 8. Verification & Testing Matrix

| ID | Feature | Description | Expected | Pass criteria |
|---|---|---|---|---|
| TC-01 | GPS init | Launch widget/data field with GPS disabled | "NO GPS" / "ACQUIRING" indicator | No crash |
| TC-02 | Conversion | (3.138degN, 101.686degE) -> RSO | E 409 973, N 347 279 (integer display) | ? vs pyproj/JUPEM < 1.0 m |
| TC-03 | Memory | Compile data field for f?nix 3 | Build succeeds under 16 KB pool | No compiler memory-limit error |
| TC-04 | Memory | Compile widget for f?nix 3 | Build succeeds under 64 KB pool | No compiler memory-limit error |
| TC-05 | Zone auto | lon 101.9degE -> 3375; lon 110.33degE -> 3376 | Correct zone label | AUTO resolves correctly |
| TC-06 | API floor | Static check of source | No post-1.0.0 API usage | Review + build pass |

**Verification methods:** off-device pyproj cross-check (`dev/reference/`, `test/verify_reference.py`);
in-simulator self-test mode (`#if RSO_SELFTEST`) printing computed E/N for reference points;
compiler-enforced memory limits; on-screen confirmation on the f?nix 3 simulator.
