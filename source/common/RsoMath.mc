//!
//! RsoMath.mc -- GDM2000 Rectified Skew Orthomorphic (RSO) projection math.
//!
//! Monkey C port of PROJ's Hotine Oblique Mercator ("omerc") forward
//! projection (EPSG method 9812, Variant A, +no_uoff), which is the
//! same algorithm verified in the Suunto reference project (math/rso.js).
//!
//! Ground truth: OSGeo/PROJ src/projections/omerc.cpp.
//! Parameters: EPSG registry (epsg.io / JUPEM), GRS80 ellipsoid.
//!
//! API floor: Connect IQ API Level 1.0.0.
//!  - Math.toRadians()/toDegrees() are API 1.3.0, so we convert manually.
//!  - Math.round() is API 1.3.0, so we use floor(x + 0.5d).
//!  - Math.PI is a 32-bit Float; we use a custom Double PI for precision.
//!
//! Precision: all constants are Doubles ('d' suffix) and every Math.* call
//! receives Doubles so the result chain stays 64-bit (Math.sin(Double) ->
//! Double, etc.). Target: < 1 m vs pyproj/EPSG reference values.
//!
//! Two non-obvious API-1.0.0 gotchas in the math:
//!  1. Math.ln() is API 2.3.0, NOT 1.0.0 (verified in api.debug.xml).
//!     We use Math.log(x, 10) * LN10 instead. (datafield build hides
//!     this because the simulator's runtime is lax with the version
//!     gate on its native API path, but the widget .prg crashes with
//!     "Symbol Not Found: 'Ln'" if Math.ln is used.)
//!  2. EPSG:3375 parameters make the raw (D^2 - 1) non-positive, so
//!     the standard "F = sqrt(D^2 - 1)" branch must clamp F to zero.
//!     PROJ's omerc.cpp then does "F += D" *in place* before using F
//!     in the lam0 formula -- a port that forgets the in-place update
//!     ends up dividing by zero (1/F = Inf, asin(Inf) = NaN, every
//!     forward() returns -2147483648). The setup() function below
//!     performs the same update.
//!
//! Footprint: forward-only (no inverse), no per-tick object allocation.
//! All state is computed once at first use.

//! The mathematical module.
import Toybox.Lang;
import Toybox.Math;

module RsoMath {

    //! --- GRS80 / WGS84 ellipsoid (Doubles) ---
    const A = 6378137.0d;          //! semi-major axis, metres
    const INV_F = 298.257222101d;  //! inverse flattening (EPSG)
    const E2 = (2.0d * INV_F - 1.0d) / (INV_F * INV_F);   //! first eccentricity squared
    const E = Math.sqrt(E2);
    const ONE_MINUS_E2 = 1.0d - E2;

    const PI_D = 3.141592653589793238462643383279502884d; //! Double pi (Math.PI is 32-bit)
    const D2R = PI_D / 180.0d;      //! degrees -> radians
    const HALF_PI = PI_D / 2.0d;
    const TOL = 1.0e-7d;            //! small-angle guard for atan2 denominator
    const EPS = 1.0e-10d;           //! convergence / pole guard
    //! ln(10) -- needed because Math.ln is API 2.3.0 (NOT API 1.0.0
    //! like I originally assumed; runtime enforces version gate on
    //! some firmware). We use ln(x) = log10(x) * LN10 instead, since
    //! Math.log(x, base) is API 1.0.0.
    const LN10 = 2.30258509299404568401799145468436421d;

    //! --- Prepared projection state (built once by setup()) ---
    var _B = 1.0d;
    var _A = 1.0d;
    var _E = 1.0d;
    var _F = 1.0d;
    var _singam = 0.0d;
    var _cosgam = 1.0d;
    var _sinrot = 0.0d;
    var _cosrot = 1.0d;
    var _ArB = 1.0d;
    var _lam0 = 0.0d;
    var _x0 = 0.0d;
    var _y0 = 0.0d;

    //! Cache flag: has setup() been run for the current zone?
    var _ready = false;
    //! Zone code for which the cached state is prepared (1=3375, 2=3376).
    var _zoneCache = 0;

    //! Isometric latitude (PROJ pj_tsfn):
    //! t = tan(pi/4 - phi/2) / ((1 - e*sin(phi))/(1 + e*sin(phi)))^(e/2)
    function tsfn(phi, sinPhi) {
        var t = Math.tan(0.5d * (HALF_PI - phi));
        return t / Math.pow((1.0d - E * sinPhi) / (1.0d + E * sinPhi), 0.5d * E);
    }

    //! Prepare the per-zone constants for the Hotine Oblique Mercator,
    //! Variant A with u_0 = 0 ("no_uoff"). Mirrors PROJ pj_omerc_setup.
    //! @param lat0Deg Latitude of projection centre (degrees)
    //! @param lamCDeg Longitude of projection centre (degrees)
    //! @param alphaDeg Azimuth at projection centre (degrees)
    //! @param gamDeg Angle from rectified to skew grid (degrees)
    //! @param k0 Scale factor at projection centre
    //! @param x0 False easting (metres)
    //! @param y0 False northing (metres)
    //! @param zone Zone code cached with this state (1=Peninsular, 2=East)
    function setup(lat0Deg, lamCDeg, alphaDeg, gamDeg, k0, x0, y0, zone) {
        var phi0 = lat0Deg * D2R;
        var lamC = lamCDeg * D2R;
        var alpha = alphaDeg * D2R;
        var gamma = gamDeg * D2R;

        var sinPh0 = Math.sin(phi0);
        var cosPh0 = Math.cos(phi0);

        var con = 1.0d - E2 * sinPh0 * sinPh0;
        var com = Math.sqrt(ONE_MINUS_E2);

        // B = sqrt(1 + e2*cos^4(phi0)/(1-e2))
        var b = cosPh0 * cosPh0;
        b = Math.sqrt(1.0d + E2 * b * b / ONE_MINUS_E2);

        // A = B * k0 * com / con
        var a = b * k0 * com / con;

        // D = B * com / (cos(phi0) * sqrt(con))
        var d = b * com / (cosPh0 * Math.sqrt(con));

        // F (with sign of phi0)
        var f = d * d - 1.0d;
        if (f <= 0.0d) {
            f = 0.0d;
        } else {
            f = Math.sqrt(f);
            if (phi0 < 0.0d) {
                f = -f;
            }
        }
        // Per PROJ omerc.cpp: "Q->E = F += D;" -- update F in place
        // by adding D. This matters for the lam0 formula below: when
        // the raw (D^2 - 1) was non-positive we set f = 0, so without
        // this update the next line would compute 1/f = Inf and the
        // whole chain would NaN out. After f += D, f is D and the
        // expression (f - 1/f) stays finite.
        f = f + d;

        // E = F * tsfn(phi0, sin(phi0))^B, where F has already been
        // updated to (f + D) in place (PROJ omerc.cpp does the same:
        // "Q->E = F += D;"). After the update, f is D when the raw
        // (D^2 - 1) was non-positive, so the lam0 formula below --
        // 0.5 * (f - 1/f) * tan(gamma0) -- stays finite even when
        // the raw pre-update f was zero (otherwise 1/0 = Inf and the
        // whole chain NaN's).
        var e = f * Math.pow(tsfn(phi0, sinPh0), b);

        // gamma0 = asin(sin(alpha)/D)
        var gamma0 = Math.asin(Math.sin(alpha) / d);

        _B = b;
        _A = a;
        _E = e;
        _F = f;
        _singam = Math.sin(gamma0);
        _cosgam = Math.cos(gamma0);
        _sinrot = Math.sin(gamma);
        _cosrot = Math.cos(gamma);
        _ArB = a / b;

        // lam0 = lamC - asin(0.5*(F - 1/F)*tan(gamma0))/B
        _lam0 = lamC - Math.asin(0.5d * (f - 1.0d / f) * Math.tan(gamma0)) / b;

        _x0 = x0;
        _y0 = y0;
        _zoneCache = zone;
        _ready = true;
    }

    //! Absolute value (Toybox.Math has no abs in API 1.0.0).
    function absd(x) {
        if (x < 0.0d) {
            return -x;
        }
        return x;
    }

    //! Compute the RSO grid position.
    //! @param latDeg Latitude (degrees, WGS84/GDM2000)
    //! @param lonDeg Longitude (degrees, WGS84/GDM2000)
    //! @return [easting, northing] in metres (Doubles)
    function forward(latDeg, lonDeg) {
        var phi = latDeg * D2R;
        var lam = lonDeg * D2R - _lam0;

        var u = 0.0d;
        var v = 0.0d;

        if (absd(absd(phi) - HALF_PI) > EPS) {
            // W = E / t^B ;  t = isometric latitude
            var w = _E / Math.pow(tsfn(phi, Math.sin(phi)), _B);
            var s = 0.5d * (w - 1.0d / w);
            var t = 0.5d * (w + 1.0d / w);
            var vv = Math.sin(_B * lam);
            var uu = (s * _singam - vv * _cosgam) / t;

            if (absd(absd(uu) - 1.0d) < EPS) {
                uu = 0.999999999999d;
            }

            v = 0.5d * _ArB * Math.log((1.0d - uu) / (1.0d + uu), 10.0d) * LN10;

            var temp = Math.cos(_B * lam);
            if (absd(temp) < TOL) {
                u = _A * lam;
            } else {
                u = _ArB * Math.atan2(s * _cosgam + vv * _singam, temp);
            }
        } else {
            // At the poles
            v = 0.0d;
            u = _ArB * phi;
        }

        // Rotate from skew axes to rectified grid (u_0 = 0)
        var x = v * _cosrot + u * _sinrot;
        var y = u * _cosrot - v * _sinrot;

        // Scale by a (dimensionless -> metres) and apply false origin
        var easting = x * A + _x0;
        var northing = y * A + _y0;

        return [easting, northing];
    }

    //! Ensure the prepared state matches the requested zone.
    //! @param zone 1 = Peninsular (EPSG:3375), 2 = East Malaysia (EPSG:3376)
    function ensure(zone) {
        if (_ready && _zoneCache == zone) {
            return;
        }
        if (zone == 2) {
            setup(4.0d, 115.0d, 53.31580995d, 53.1301023611111d,
                  0.99984d, 0.0d, 0.0d, 2);
        } else {
            setup(4.0d, 102.25d, 323.025796466667d, 323.130102361111d,
                  0.99984d, 804671.0d, 0.0d, 1);
        }
    }
}
