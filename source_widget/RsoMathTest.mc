//!
//! RsoMathTest.mc -- Monkey C unit tests for the projection math. Run with:
//!   monkeydo -t build/rso_widget.iq fenix3
//! (or build a dedicated test target).
//!
//! Validates TC-02 (and several other reference points) against the
//! pyproj-generated known_points.json fixtures.
//!
//! API floor: 1.0.0.

import Toybox.Lang;
import Toybox.Test;

//! Module-level reference points and expected outputs (pyproj / EPSG:3375).
(:RsoMathTest) class RsoMathTest {

    var EPS_M as Double = 1.0d;   // 1 m tolerance per PRD TC-02

    function initialize() {
    }

    //! Helper: convert + compare.
    function approx(e as Double, n as Double, eExp as Double, nExp as Double) as Boolean {
        return absd(e - eExp) < EPS_M && absd(n - nExp) < EPS_M;
    }

    function absd(x as Double) as Double {
        if (x < 0.0d) { return -x; }
        return x;
    }

    //! TC-02: PRD reference point (3.138, 101.686).
    (:test) function test_tc02_kl_reference() {
        RsoMath.ensure(1);
        var xy = RsoMath.forward(3.138d, 101.686d);
        // Expected: E 409973 (display) = 409972.7013, N 347279 = 347279.2475 (pyproj)
        var ok = approx(xy[0], xy[1], 409972.7013d, 347279.2475d);
        System.println("TC-02: E=" + xy[0].format("%.4f") + " N=" + xy[1].format("%.4f"));
        Test.assert(ok);
    }

    //! Kuala Lumpur (the Suunto reference fixture point, more precise).
    (:test) function test_kl_reference() {
        RsoMath.ensure(1);
        var xy = RsoMath.forward(3.139003d, 101.686855d);
        var ok = approx(xy[0], xy[1], 410067.9999d, 347389.9282d);
        System.println("KL ref: E=" + xy[0].format("%.4f") + " N=" + xy[1].format("%.4f"));
        Test.assert(ok);
    }

    //! Projection origin (must equal false easting, false northing).
    (:test) function test_origin() {
        RsoMath.ensure(1);
        var xy = RsoMath.forward(4.0d, 102.25d);
        var ok = approx(xy[0], xy[1], 472830.4261d, 442454.0987d);
        System.println("Origin: E=" + xy[0].format("%.4f") + " N=" + xy[1].format("%.4f"));
        Test.assert(ok);
    }

    //! Penang.
    (:test) function test_penang() {
        RsoMath.ensure(1);
        var xy = RsoMath.forward(5.414895d, 100.317367d);
        var ok = approx(xy[0], xy[1], 258950.412d, 599583.0628d);
        System.println("Penang: E=" + xy[0].format("%.4f") + " N=" + xy[1].format("%.4f"));
        Test.assert(ok);
    }

    //! East Malaysia zone sanity (Kuching in EPSG:3376).
    (:test) function test_kuching_east() {
        RsoMath.ensure(2);
        var xy = RsoMath.forward(1.55d, 110.33d);
        var ok = approx(xy[0], xy[1], 71694.1204d, 171387.743d);
        System.println("Kuching(E): E=" + xy[0].format("%.4f") + " N=" + xy[1].format("%.4f"));
        Test.assert(ok);
    }
}