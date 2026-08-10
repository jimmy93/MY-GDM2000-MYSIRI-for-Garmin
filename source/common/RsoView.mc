//!
//! RsoView.mc -- shared drawing and formatting helpers for MY RSO Grid.
//!
//! Both app types (data field and widget) use these helpers so the
//! display is consistent and the code stays in one place.
//!
//! API floor: 1.0.0. Fonts and colors used here are all from the
//! 1.0.0 Graphics set.

//! Shared UI helpers.
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.Position;

module RsoView {

    //! Round a Double to the nearest whole metre (API 1.0.0: no Math.round).
    //! @param value Coordinate value in metres
    //! @return Nearest integer metre value
    function metresToInt(value) {
        return Math.floor(value + 0.5d).toNumber();
    }

    //! GPS quality -> short status string + color.
    //! @param quality Position.QUALITY_* value
    //! @return Array [string, color]
    function gpsStatus(quality) {
        var text = "NO GPS";
        var color = Graphics.COLOR_RED;
        if (quality == Position.QUALITY_GOOD) {
            text = "GOOD (3D)";
            color = Graphics.COLOR_GREEN;
        } else if (quality == Position.QUALITY_USABLE) {
            text = "USABLE (3D)";
            color = Graphics.COLOR_GREEN;
        } else if (quality == Position.QUALITY_POOR) {
            text = "POOR (2D)";
            color = Graphics.COLOR_YELLOW;
        } else if (quality == Position.QUALITY_LAST_KNOWN) {
            text = "LAST KNOWN";
            color = Graphics.COLOR_YELLOW;
        }
        return [text, color];
    }

    //! Draw the main grid block (zone, easting, northing, altitude).
    //! @param dc Device context
    //! @param label Zone label (e.g. "GDM2000 Penin")
    //! @param easting Easting in metres (Double)
    //! @param northing Northing in metres (Double)
    //! @param altitude Altitude in metres (Double, negative if unknown)
    //! @param title Optional small title ("" to hide)
    function drawGrid(dc, label, easting, northing, altitude, title) {
        var w = dc.getWidth();
        var h = dc.getHeight();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var smallFont = Graphics.FONT_XTINY;
        var medFont = Graphics.FONT_SMALL;

        var y = 0;
        if (title.length() > 0) {
            dc.drawText(w / 2, y, smallFont, title, Graphics.TEXT_JUSTIFY_CENTER);
            y += dc.getFontHeight(smallFont);
        }
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, y, smallFont, label, Graphics.TEXT_JUSTIFY_CENTER);
        y += dc.getFontHeight(smallFont) + 2;

        // Easting row
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2 - 8, y, smallFont, "E", Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2 + 2, y, smallFont, metresToInt(easting).toString(),
                    Graphics.TEXT_JUSTIFY_LEFT);
        y += dc.getFontHeight(medFont) + 1;

        // Northing row
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2 - 8, y, smallFont, "N", Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2 + 2, y, smallFont, metresToInt(northing).toString(),
                    Graphics.TEXT_JUSTIFY_LEFT);
        y += dc.getFontHeight(medFont) + 1;

        // Altitude row
        var altText = "-";
        if (altitude >= 0.0d) {
            altText = metresToInt(altitude).toString() + "m";
        }
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2 - 8, y, smallFont, "ALT", Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2 + 2, y, smallFont, altText, Graphics.TEXT_JUSTIFY_LEFT);
    }

    //! Draw the GPS status line (used by both app types).
    //! @param dc Device context
    //! @param quality Position.QUALITY_* value
    function drawGpsStatus(dc, quality) {
        var status = gpsStatus(quality);
        var w = dc.getWidth();
        var h = dc.getHeight();
        var font = Graphics.FONT_XTINY;

        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(2, h - dc.getFontHeight(font) - 3, w - 2, h - dc.getFontHeight(font) - 3);

        dc.setColor(status[1], Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h - dc.getFontHeight(font) - 1, font, "GPS: " + status[0],
                    Graphics.TEXT_JUSTIFY_CENTER);
    }

    //! Minimal two-line drawing used when the data field is in a small
    //! (2-field / 4-field) cell. E and N each fit on one line.
    //! @param dc Device context
    //! @param easting Easting in metres (Double)
    //! @param northing Northing in metres (Double)
    function drawCompact(dc, easting, northing) {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var font = Graphics.FONT_XTINY;

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(0, 0, font, "E", Graphics.TEXT_JUSTIFY_LEFT);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, 0, font, metresToInt(easting).toString(), Graphics.TEXT_JUSTIFY_CENTER);

        var y = h / 2;
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(0, y, font, "N", Graphics.TEXT_JUSTIFY_LEFT);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, y, font, metresToInt(northing).toString(), Graphics.TEXT_JUSTIFY_CENTER);
    }
}
