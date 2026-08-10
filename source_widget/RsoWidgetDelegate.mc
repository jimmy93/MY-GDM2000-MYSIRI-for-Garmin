//!
//! RsoWidgetDelegate.mc -- input delegate for the MY RSO Grid widget.
//!
//! Cycles the zone mode: AUTO -> Peninsular -> East -> AUTO.
//! API floor: 1.0.0.

import Toybox.Lang;
import Toybox.WatchUi;

//! The widget input delegate.
class RsoWidgetDelegate extends WatchUi.BehaviorDelegate {

    //! Constructor
    function initialize() {
        BehaviorDelegate.initialize();
    }

    //! Handle a tap on the screen (zone cycle).
    //! @param clickEvent The click event
    //! @return true if handled
    function onTap(clickEvent as ClickEvent) as Boolean {
        return cycleZone();
    }

    //! Handle the enter/OK key (zone cycle).
    //! @return true if handled
    function onKey(evt as KeyEvent) as Boolean {
        return cycleZone();
    }

    //! Cycle AUTO -> Peninsular -> East -> AUTO and refresh.
    //! @return true
    function cycleZone() as Boolean {
        RsoZone.mode = (RsoZone.mode + 1) % 3;
        RsoZone.lastLon = 0.0d;  // reset hysteresis on manual change
        RsoGrid.update();
        WatchUi.requestUpdate();
        return true;
    }
}
