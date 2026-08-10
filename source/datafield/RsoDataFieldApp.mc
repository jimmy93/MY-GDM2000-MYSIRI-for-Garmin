//!
//! RsoDataFieldApp.mc -- data field app entry for MY RSO Grid.
//!
//! API floor: 1.0.0.

import Toybox.Application;
import Toybox.Lang;

//! Data field application.
class RsoDataFieldApp extends Application.AppBase {

    //! Constructor
    function initialize() {
        AppBase.initialize();
    }

    //! Handle app startup
    //! @param state Startup arguments
    function onStart(state as Dictionary?) {
    }

    //! Handle app shutdown
    //! @param state Shutdown arguments
    function onStop(state as Dictionary?) {
    }

    //! Return the initial view for the app
    //! @return Array [View]
    function getInitialView() {
        return [new RsoDataFieldView()];
    }
}
