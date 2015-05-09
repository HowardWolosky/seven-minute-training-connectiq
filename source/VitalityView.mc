//!
//! Copyright 2015 by Garmin Ltd. or its subsidiaries.
//! Subject to Garmin SDK License Agreement and Wearables
//! Application Developer Agreement.
//!

using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Lang as Lang;
using Toybox.ActivityRecording as Record;
using Toybox.Position as Position;
using Toybox.Timer as Timer;
using Toybox.Time as Clock;
using Toybox.Sensor as Snsr;
using Toybox.ActivityMonitor as ActMon;
using Toybox.Attention as Attention;

//Variables used during the activity
var session = null;
var timer1 = null;
var count1 = 0;
var count2 = 0;
var count3 = 0;
var heartRate = 0;


class BaseInputDelegate extends Ui.BehaviorDelegate
{

	//! Counters for heart rate. Once per second.
    function callback1()
    {
    	if( ( session != null ) && session.isRecording() ) {
    		if ( heartRate > 116 ) { count2 += 1; }
    		if ( heartRate > 134 ) { count1 += 1; }
    		if ( heartRate > 162 ) { count3 += 1; }
    	}
        Ui.requestUpdate();
    }

    function onKey(key) {
        if( ( Toybox has :ActivityRecording ) && ( key.getKey() == Ui.KEY_ENTER ) ) {
            if( ( session == null ) || ( session.isRecording() == false ) ) {
                session = Record.createSession({:name=>"Vitality", :sport=>Record.SPORT_TRAINING});
                session.start();
                timer1 = new Timer.Timer();
		        timer1.start( method(:callback1), 1000, true );
		        Attention.playTone(Attention.TONE_START);
                Ui.requestUpdate();
            }
            else if( ( session != null ) && session.isRecording() ) {
				//! stop the timers and the session
		        timer1.stop();
                session.stop();
				//! Save the session data
                session.save();
		        Attention.playTone(Attention.TONE_STOP);
				//! clean up the session and timers and counters
                session = null;
		        timer1 = null;
		        count1 = 0;
		        count2 = 0;
		        count3 = 0;
		        heartRate = 0;
				//! Update
                Ui.requestUpdate();
            }
        }
    }
}

class VitalityView extends Ui.View {

	//! vibration when sucessful
    var vibeSuccess = [
                        new Attention.VibeProfile(  25, 100 ),
                        new Attention.VibeProfile(  50, 100 ),
                        new Attention.VibeProfile(  75, 100 ),
                        new Attention.VibeProfile( 100, 100 ),
                        new Attention.VibeProfile(  75, 100 ),
                        new Attention.VibeProfile(  50, 100 ),
                        new Attention.VibeProfile(  25, 100 )
                      ];

    //! Stop the recording if necessary
    function stopRecording() {
        if( Toybox has :ActivityRecording ) {
            if( (session != null) && session.isRecording() ) {
				//! stop the timers and the session
		        timer1.stop();
                session.stop();
				//! Save the session data
                session.save();
				//! clean up the session and timers and counters
                session = null;
		        timer1 = null;
		        count1 = 0;
		        count2 = 0;
		        count3 = 0;
		        heartRate = 0;
				//! request update
                Ui.requestUpdate();
            }
        }
    }

    //! Load your resources here
    function onLayout(dc) {
		//!Set timer
        timer1 = new Timer.Timer();
        //!Enable heart rate
        Snsr.setEnabledSensors( [Snsr.SENSOR_HEARTRATE] );
        Snsr.enableSensorEvents( method(:onSnsr) );
    }

    function onHide() {
        Position.enableLocationEvents(Position.LOCATION_DISABLE, method(:onPosition));
    }

    //! Restore the state of the app and prepare the view to be shown.
    //! We need to enable the location events for now so that we make sure GPS is on.
    //! Also enable heart rate
    function onShow() {
        Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPosition));
        Snsr.setEnabledSensors( [Snsr.SENSOR_HEARTRATE] );
        Snsr.enableSensorEvents( method(:onSnsr) );
    }

    //! Update the view
    function onUpdate(dc) {
        // Set background color
        dc.clear();
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
        dc.fillRectangle(0, 0, dc.getWidth(), dc.getHeight());

        if( Toybox has :ActivityRecording ) {
            // Draw the instructions
            if( ( session == null ) || ( session.isRecording() == false ) ) {
                dc.setColor(Gfx.COLOR_GREEN, Gfx.COLOR_BLACK);
                dc.drawText(20, 10, Gfx.FONT_MEDIUM, "Press START key -->", Gfx.TEXT_JUSTIFY_LEFT);
                dc.drawText(20, 40, Gfx.FONT_MEDIUM, "to start recording", Gfx.TEXT_JUSTIFY_LEFT);
                dc.drawText(20, 70, Gfx.FONT_MEDIUM, "a Vitality activity", Gfx.TEXT_JUSTIFY_LEFT);
                dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_BLACK);
            }
            else if( ( session != null ) && session.isRecording() ) {
                dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_BLACK);
                dc.drawText(20, 10, Gfx.FONT_MEDIUM, "Press key to STOP -->", Gfx.TEXT_JUSTIFY_LEFT);

                dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);
				dc.drawText(20, 40, Gfx.FONT_SMALL, "HR: " + heartRate, Gfx.TEXT_JUSTIFY_LEFT);
				
				//! Default vitality points 0. Will be overriden below if needed.
				dc.drawText(110, 120, Gfx.FONT_SMALL, "Points: 0", Gfx.TEXT_JUSTIFY_LEFT);
				
				//! Lower heart rate. Goal is over 62 mins.
				if (count2 > 3720) {
	                dc.setColor(Gfx.COLOR_GREEN, Gfx.COLOR_BLACK);
	                dc.drawText(20, 60, Gfx.FONT_SMALL, "HR > 116 (60%): " + (count2 / 60) +":" + ( count2 % 60 ) + " mins", Gfx.TEXT_JUSTIFY_LEFT);
					dc.drawText(110, 120, Gfx.FONT_SMALL, "Points: 10", Gfx.TEXT_JUSTIFY_LEFT);
			        Attention.vibrate(vibeSuccess);
				} else {
	                dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);
	                dc.drawText(20, 60, Gfx.FONT_SMALL, "HR > 116 (60%): " + (count2 / 60) +":" + ( count2 % 60 ) + " mins", Gfx.TEXT_JUSTIFY_LEFT);
					if (count2 > 1920) {
						dc.drawText(110, 120, Gfx.FONT_SMALL, "Points: 5", Gfx.TEXT_JUSTIFY_LEFT);
					}
				}
				
				//! Medium heart rate. Goal is over 32 mins.
				if (count1 > 1920) {
	                dc.setColor(Gfx.COLOR_GREEN, Gfx.COLOR_BLACK);
					dc.drawText(20, 80, Gfx.FONT_SMALL, "HR > 134 (70%): " + (count1 / 60) +":" + ( count1 % 60 ) + " mins", Gfx.TEXT_JUSTIFY_LEFT);
					dc.drawText(110, 120, Gfx.FONT_SMALL, "Points: 10", Gfx.TEXT_JUSTIFY_LEFT);
			        Attention.vibrate(vibeSuccess);
				} else {
	                dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);
					dc.drawText(20, 80, Gfx.FONT_SMALL, "HR > 134 (70%): " + (count1 / 60) +":" + ( count1 % 60 ) + " mins", Gfx.TEXT_JUSTIFY_LEFT);
				}
				
				//! Highest heart rate. Just for information.
                dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);
				dc.drawText(20, 100, Gfx.FONT_SMALL, "HR > 162 (85%): " + (count3 / 60) +":" + ( count3 % 60 ) + " mins", Gfx.TEXT_JUSTIFY_LEFT);
				
				//! Steps
				var curSteps = ActMon.getInfo().steps;
				if(curSteps > 12550) {
	                dc.setColor(Gfx.COLOR_GREEN, Gfx.COLOR_BLACK);
					dc.drawText(110, 40, Gfx.FONT_SMALL, "Steps: " + curSteps, Gfx.TEXT_JUSTIFY_LEFT);
					dc.drawText(110, 100, Gfx.FONT_SMALL, "Points: 10", Gfx.TEXT_JUSTIFY_LEFT);
			        Attention.vibrate(vibeSuccess);
				} else {
	                dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);
					dc.drawText(110, 40, Gfx.FONT_SMALL, "Steps: " + curSteps, Gfx.TEXT_JUSTIFY_LEFT);
					if(curSteps > 10050) {
						dc.drawText(110, 120, Gfx.FONT_SMALL, "Points: 5", Gfx.TEXT_JUSTIFY_LEFT);
					} else if (curSteps > 7050) {
						dc.drawText(110, 120, Gfx.FONT_SMALL, "Points: 3", Gfx.TEXT_JUSTIFY_LEFT);
					}
				}
             
             	//! Clock
				var clockMins;
				if(Sys.getClockTime().min < 10) {
					clockMins = "0" + Sys.getClockTime().min.toString();
				} else {
					clockMins = Sys.getClockTime().min.toString();
				}			
				dc.drawText(20, 120, Gfx.FONT_SMALL, "Clock: " + Sys.getClockTime().hour + ":" + clockMins, Gfx.TEXT_JUSTIFY_LEFT);


            }
        }
        // tell the user this app doesn't work
        else {
            dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_WHITE);
            dc.drawText(20, 20, Gfx.FONT_MEDIUM, "This product doesn't", Gfx.TEXT_JUSTIFY_LEFT);
            dc.drawText(25, 50, Gfx.FONT_MEDIUM, "have FIT Support", Gfx.TEXT_JUSTIFY_LEFT);
        }
    }

    function onSnsr(sensor_info) {
        if( sensor_info.heartRate != null ) {
            heartRate = sensor_info.heartRate;
        }
        else {
            heartRate = 0;
        }
    }

    function onPosition(position_info) {
    }

}
