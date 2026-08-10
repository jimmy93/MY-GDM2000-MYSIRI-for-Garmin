//!
//! RsoGrid.mc -- shared display state for MY RSO Grid.
//!
//! Holds the latest projected Easting / Northing and the resolved zone
//! label so the views can draw without recomputing the projection.
//!
//! API floor: 1.0.0.

//! Shared display state.
import Toybox.Lang;

module RsoGrid {

    //! Latest projected easting (metres, Double).
    var curE = 0.0d;
    //! Latest projected northing (metres, Double).
    var curN = 0.0d;
    //! Latest resolved zone label.
    var curLabel = "NO GPS";
    //! Latest resolved zone code (1=Peninsular, 2=East).
    var curZone = RsoZone.ZONE_PENINSULAR;

    //! Recompute the grid from the shared position snapshot.
    function update() {
        var result = RsoAppState.computeGrid();
        curE = result[0];
        curN = result[1];
        curZone = result[2];
        curLabel = RsoZone.label(curZone);
        if (RsoAppState.demoTick) {
            curLabel = "KL ref, " + curLabel;
        }
    }
}
