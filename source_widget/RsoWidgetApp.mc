//!
//! RsoWidgetApp.mc -- widget app entry for MY RSO Grid.
//!
//! The widget starts the location stream onStart and stops it onStop,
//! matching the app lifecycle so no GPS runs while the widget is hidden.
//!
//! API floor: 1.0.0.

import Toybox.Application;
import Toybox.Lang;
import Toybox.Position;

//! Widget application.
class RsoWidgetApp extends Application.AppBase {

    //! Constructor
    function initialize() {
        AppBase.initialize();
    }

    //! Handle app startup
    //! @param state Startup arguments
    function onStart(state as Dictionary?) {
        Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPosition));
    }

    //! Handle app shutdown
    //! @param state Shutdown arguments
    function onStop(state as Dictionary?) {
        Position.enableLocationEvents(Position.LOCATION_DISABLE, method(:onPosition));
    }

    //! GPS update callback (also fires once at startup with a NO-GPS fix,
    //! so the initial state is always coherent).
    //! @param info Position.Info
    function onPosition(info as Position.Info) as Void {
        RsoAppState.onPositionInfo(info);
    }

    //! Return the initial view + delegate for the app
    //! @return Array [View, Delegate]
    function getInitialView() {
        return [new RsoWidgetView(), new RsoWidgetDelegate()];
    }
}
