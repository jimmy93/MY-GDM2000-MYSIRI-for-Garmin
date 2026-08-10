//!
//! RsoZone.mc -- zone resolution for MY RSO Grid.
//!
//! AUTO mode picks the grid on longitude:
//!   lon <  ~108.0degE  -> Peninsular Malaysia  (EPSG:3375)
//!   lon >= ~108.0degE  -> East Malaysia (Borneo, EPSG:3376)
//! A 0.5deg hysteresis band around the boundary avoids zone flicker when
//! the GPS jitters near the coast of Sarawak.
//!
//! Manual modes: 1 = force EPSG:3375, 2 = force EPSG:3376.
//! API floor: 1.0.0.

//! Zone handling module.
import Toybox.Lang;

module RsoZone {

    const ZONE_AUTO = 0;
    const ZONE_PENINSULAR = 1;
    const ZONE_EAST = 2;

    const BOUNDARY = 108.0d;   //! nominal boundary longitude (deg E)
    const HYSTERESIS = 0.5d;   //! half-width of the hysteresis band

    //! User-selectable mode (0=auto, 1=peninsular, 2=east).
    //! Writable by both app types; default AUTO.
    var mode = ZONE_AUTO;

    //! Longitude of the last resolved fix (for hysteresis).
    var lastLon = 0.0d;

    //! Resolve the effective zone for a given longitude.
    //! @param lonDeg Longitude in degrees (E positive)
    //! @return 1 = EPSG:3375, 2 = EPSG:3376
    function resolve(lonDeg) {
        if (mode == ZONE_PENINSULAR) {
            return ZONE_PENINSULAR;
        }
        if (mode == ZONE_EAST) {
            return ZONE_EAST;
        }

        var zone = ZONE_PENINSULAR;
        if (lastLon > BOUNDARY) {
            // Currently east of the boundary: only flip back below boundary-hyst
            if (lonDeg < BOUNDARY - HYSTERESIS) {
                zone = ZONE_PENINSULAR;
            } else {
                zone = ZONE_EAST;
            }
        } else {
            // Currently west of the boundary: only flip over boundary+hyst
            if (lonDeg >= BOUNDARY + HYSTERESIS) {
                zone = ZONE_EAST;
            } else {
                zone = ZONE_PENINSULAR;
            }
        }

        lastLon = lonDeg;
        return zone;
    }

    //! Human-readable zone label.
    //! @param zone 1 = Peninsular, 2 = East
    //! @return Display string
    function label(zone) {
        if (zone == ZONE_EAST) {
            return "GDM2000 East";
        }
        return "GDM2000 Penin";
    }
}
