//!
//! RsoDataFieldView.mc -- data field view for MY RSO Grid.
//!
//! The system calls compute() roughly once per second during an activity
//! with the latest Activity.Info, then onUpdate(dc) to redraw. The device
//! context is already clipped to the field's cell, so this handles 1-field,
//! 2-field and 4-field layouts automatically.
//!
//! API floor: 1.0.0.

import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Position;
import Toybox.WatchUi;

//! The data field view.
class RsoDataFieldView extends WatchUi.DataField {

    var label;

    //! Constructor
    function initialize() {
        DataField.initialize();
        label = "MY RSO Grid";
    }

    //! Called ~1 Hz with the latest activity data.
    //! @param info Current Activity.Info
    function compute(info as Activity.Info) as Void {
        // Guard: currentLocation is null until the first valid fix.
        if (info.currentLocation != null) {
            RsoAppState.onActivityInfo(info);
        } else {
            RsoAppState.quality = Position.QUALITY_NOT_AVAILABLE;
        }
        // Refresh RsoGrid.curE/curN/curLabel from the (possibly updated)
        // RsoAppState snapshot. The widget calls this in onTick()/onUpdate();
        // the data field must do it here because there is no separate tick.
        RsoGrid.update();
    }

    //! Redraw the field.
    //! @param dc Device context (already clipped to the field cell)
    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var w = dc.getWidth();
        var h = dc.getHeight();

        // Small cells (2-field / 4-field layouts) get the compact view.
        if ((w < 90) || (h < 40)) {
            RsoView.drawCompact(dc, RsoGrid.curE, RsoGrid.curN);
            return;
        }

        RsoView.drawGrid(dc, RsoGrid.curLabel, RsoGrid.curE, RsoGrid.curN,
                         RsoAppState.alt, "MY RSO");
        RsoView.drawGpsStatus(dc, RsoAppState.quality);
    }
}
