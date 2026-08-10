//!
//! RsoAppState.mc -- shared transient state + no-fix demo reference for
//! MY RSO Grid.
//!
//! Holds the latest GPS-derived values used by both app types.
//! NOTHING is written to storage: this is pure volatile RAM state.
//!
//! When no GPS fix is available, computeGrid() falls back to a fixed
//! Kuala Lumpur reference coordinate. This doubles as a live in-simulator
//! validation of the projection math (TC-02) without needing a GPS signal.
//!
//! API floor: 1.0.0.

import Toybox.Lang;
import Toybox.Position;

//! Shared app state.
module RsoAppState {

    //! Kuala Lumpur reference coordinate used when there is no GPS fix.
    const DEMO_LAT = 3.139003d;
    const DEMO_LON = 101.686855d;

    //! Latest known position.
    var latDeg = 0.0d;
    var lonDeg = 0.0d;
    //! Latest altitude in metres (negative = unknown).
    var alt = -1.0d;
    //! Latest GPS quality (Position.QUALITY_*).
    var quality = Position.QUALITY_NOT_AVAILABLE;

    //! True when we are showing the no-fix demo reference instead of a
    //! live position.
    var demoTick = false;

    //! Update the snapshot from a Position.Info object.
    //! @param info A Position.Info or Activity.Info with position/accuracy
    function onPositionInfo(info) {
        var loc = info.position;
        if (loc != null) {
            var deg = loc.toDegrees();
            latDeg = deg[0];
            lonDeg = deg[1];
        }
        var altValue = info.altitude;
        if (altValue != null) {
            alt = altValue.toDouble();
        }
        var acc = info.accuracy;
        if (acc != null) {
            quality = acc;
        }
    }

    //! Update the snapshot from an Activity.Info object (data field path).
    //! @param info An Activity.Info with currentLocation/currentLocationAccuracy
    function onActivityInfo(info) {
        var loc = info.currentLocation;
        if (loc != null) {
            var deg = loc.toDegrees();
            latDeg = deg[0];
            lonDeg = deg[1];
        }
        var altValue = info.altitude;
        if (altValue != null) {
            alt = altValue.toDouble();
        }
        var acc = info.currentLocationAccuracy;
        if (acc != null) {
            quality = acc;
        }
    }

    //! Compute the grid coordinate for the current position.
    //! @return [easting, northing, zone] (zone 1=Peninsular, 2=East)
    function computeGrid() {
        var zone = RsoZone.ZONE_PENINSULAR;
        if (quality == Position.QUALITY_NOT_AVAILABLE) {
            // No fix: use the KL demo reference (doubles as TC-02 validation).
            demoTick = true;
            zone = RsoZone.ZONE_PENINSULAR;
            RsoMath.ensure(zone);
            var demo = RsoMath.forward(DEMO_LAT, DEMO_LON);
            return [demo[0], demo[1], zone];
        }
        demoTick = false;
        zone = RsoZone.resolve(lonDeg);
        RsoMath.ensure(zone);
        var xy = RsoMath.forward(latDeg, lonDeg);
        return [xy[0], xy[1], zone];
    }
}

