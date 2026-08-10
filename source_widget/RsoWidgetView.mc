//!
//! RsoWidgetView.mc -- full-screen widget view for MY RSO Grid.
//!
//! Uses a 1-second Timer (started in onShow, stopped in onHide) so the
//! screen only redraws while the widget is actually visible -- no CPU
//! wake-ups in the background.
//!
//! API floor: 1.0.0.

import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Timer;
import Toybox.WatchUi;

//! The widget view.
class RsoWidgetView extends WatchUi.View {

    var _timer = null;

    //! Constructor
    function initialize() {
        View.initialize();
    }

    //! Load your resources here
    //! @param dc Device context
    function onLayout(dc as Dc) as Void {
    }

    //! Restore the state of the app and prepare the view to be shown
    function onShow() as Void {
        // Start a 1 s repeating refresh while the widget is visible.
        if (_timer == null) {
            _timer = new Timer.Timer();
        }
        _timer.start(method(:onTick), 1000, true);
    }

    //! Handle view being hidden
    function onHide() as Void {
        if (_timer != null) {
            _timer.stop();
        }
    }

    //! Timer callback: recompute the grid and schedule a redraw.
    function onTick() as Void {
        RsoGrid.update();
        WatchUi.requestUpdate();
    }

    //! Draw the full-screen grid.
    //! @param dc Device context
    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        RsoGrid.update();
        RsoView.drawGrid(dc, RsoGrid.curLabel, RsoGrid.curE, RsoGrid.curN,
                         RsoAppState.alt, "MY RSO Grid");
        RsoView.drawGpsStatus(dc, RsoAppState.quality);

        // Zone hint line
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 2, dc.getHeight() - dc.getFontHeight(Graphics.FONT_XTINY),
                    Graphics.FONT_XTINY, "TAP: zone", Graphics.TEXT_JUSTIFY_CENTER);
    }
}
