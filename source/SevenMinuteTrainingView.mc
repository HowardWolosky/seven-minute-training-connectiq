//!
//! Copyright 2015 by dr. Janne Ohtonen
//! Subject to Garmin SDK License Agreement and Wearables Application Developer Agreement.
//!

using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Timer as Timer;
using Toybox.Attention as Attention;
using Toybox.ActivityRecording as Record;
using Toybox.Sensor as Snsr;

//Variables used during the activity
var session = null;					//! session recording
var running = false;				//! activity running
var timer1 = null;					//! timer for seconds
var count1 = 0;						//! Seconds count
var move = 0;						//! current move	
var breakTime = 10;					//! time for breaks	in seconds
var activityTime = 30;				//! Time for each activity in seconds
var onBreak = false;				//! Is the user on break or in activity
var heartRate = 0;					//! Heartrate
var totalTime = 0;					//! Total duration of the exercise

class BaseInputDelegate extends Ui.BehaviorDelegate
{

	//! Counter for training activity seconds
    function callback1()
    {
    	if( running ) {
	    	count1 += 1; 											//! activity timer in seconds
			totalTime += 1;											//! total duration of the activity in seconds
			if ( ( onBreak == true ) && ( count1 > breakTime ) ) {
				count1 = 0;
				onBreak = false;		
				doNextNotification();	
			}
			if( count1 > activityTime ) {
				move += 1;
				count1 = 0;
				onBreak = true;
				doNextNotification();	
			}
    	}
        Ui.requestUpdate();
    }

	//! Notify about change of activity
	function doNextNotification() {	
	    var vibeNotify = [
	                        new Attention.VibeProfile(  25, 100 ),
	                        new Attention.VibeProfile(  50, 100 ),
	                        new Attention.VibeProfile(  75, 100 ),
	                        new Attention.VibeProfile( 100, 100 ),
	                        new Attention.VibeProfile(  75, 100 ),
	                        new Attention.VibeProfile(  50, 100 ),
	                        new Attention.VibeProfile(  0, 1 )
	                      ];
		Attention.vibrate(vibeNotify);
	}

	function onBack() {
        if( running == true ) {
			//! do nothing so that the activity doesn't stop from the back key.
			 return true;
        } else {
        	return false;
        }
	}

    function onKey(key) {
        if( key.getKey() == Ui.KEY_ENTER ) {
            if( running == false ) {
		        //! Initiate variables
		        count1 = 0;
		        move = 0;
		        totalTime = 0;
		        running = true;
		        onBreak = true;
		        //! Start recording
				if( Toybox has :ActivityRecording ) {        
    	            session = Record.createSession({:name=>"SevenMin", :sport=>Record.SPORT_TRAINING, :subSport=>Record.SUB_SPORT_EXERCISE});
	                session.start();
                }
		        //! Start timer
                timer1 = new Timer.Timer();
		        timer1.start( method(:callback1), 1000, true );
                //! Update
                Ui.requestUpdate();
            }
            else if( running == true ) {
				//! stop the timer
		        timer1.stop();
				//! Save the session data if it is longer than 1 minute.
	            if( ( session != null ) && session.isRecording() ) {
	                session.stop();
					if ( totalTime > 60 ) {
		                session.save();

		            } else {
		            	session.discard();
		            }
		        }
				//! clean up
                session = null;
		        timer1 = null;
		        count1 = 0;
		        move = 0;
		        running = false;
		        onBreak = false;
		        heartRate = 0;
		        totalTime = 0;
				//! Update
                Ui.requestUpdate();
            }
        }
        
    }
}

class SevenMinuteTrainingView extends Ui.View {

    //! Stop the recording and timer if necessary
    function stopRecording() {
		//! Stop the timer 
		if ( timer1 != null ) {
	        timer1.stop();
	    }
        //! Stop the session
        if( (Toybox has :ActivityRecording) && (session != null) && session.isRecording() ) {
				//! stop  the session
                session.stop();
				//! Save the session data if it is longer than 1 minute.
				if ( totalTime > 60 ) {
	                session.save();
	                
	            } else {
	            	session.discard();	            	
	            }
        }
		//! clean up the session and timers and counters
	    session = null;
	    timer1 = null;
	    count1 = 0;
	    move = 0;
	    running = false;
	    onBreak = false;
        heartRate = 0;
        totalTime = 0;
		//! request update
	    Ui.requestUpdate();
    }


    //!Enable heart rate
    function onLayout(dc) {        
        Snsr.setEnabledSensors( [Snsr.SENSOR_HEARTRATE] );
        Snsr.enableSensorEvents( method(:onSnsr) );
    }

   	//! Restore the state of the app and prepare the view to be shown.
    function onShow() {
        Snsr.setEnabledSensors( [Snsr.SENSOR_HEARTRATE] );
        Snsr.enableSensorEvents( method(:onSnsr) );
    }

	//! Used to store the heartrate in a variable
    function onSnsr(sensor_info) {
        if( sensor_info.heartRate != null ) {
            heartRate = sensor_info.heartRate;
        }
        else {
            heartRate = 0;
        }
    }

    //! Update the view
    function onUpdate(dc) {
        // Set background color
        dc.clear();
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
        dc.fillRectangle(0, 0, dc.getWidth(), dc.getHeight());

        // Draw the instructions
        if( running == false ) {
            dc.setColor(Gfx.COLOR_GREEN, Gfx.COLOR_BLACK);
            dc.drawText(20, 10, Gfx.FONT_MEDIUM, "Press START key -->", Gfx.TEXT_JUSTIFY_LEFT);
            dc.drawText(20, 40, Gfx.FONT_MEDIUM, "to begin the Seven", Gfx.TEXT_JUSTIFY_LEFT);
            dc.drawText(20, 70, Gfx.FONT_MEDIUM, "Minute Training", Gfx.TEXT_JUSTIFY_LEFT);
            dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_BLACK);
        } else {

			//! instructions for the stop
            dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_BLACK);
            dc.drawText(10, 10, Gfx.FONT_SMALL, "Press key to STOP -->", Gfx.TEXT_JUSTIFY_LEFT);

			//! instructions text colour.
            dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);

			if ( onBreak == true ) {
				//! break instructions
				var breakTimeLeft = breakTime - count1;
	            dc.drawText(10, 30, Gfx.FONT_MEDIUM, "Next activity starts in", Gfx.TEXT_JUSTIFY_LEFT);
	            dc.drawText(10, 70, Gfx.FONT_LARGE, breakTimeLeft.toString(), Gfx.TEXT_JUSTIFY_LEFT);
	            dc.drawText(120, 77, Gfx.FONT_SMALL, "HR: " + heartRate.toString(), Gfx.TEXT_JUSTIFY_LEFT);
	            dc.drawText(10, 120, Gfx.FONT_SMALL, "seconds", Gfx.TEXT_JUSTIFY_LEFT);
	        	if ( move == 0 ) {
		            dc.drawText(70, 120, Gfx.FONT_SMALL, "(JUMPING JACKS)", Gfx.TEXT_JUSTIFY_LEFT);
	        	} else if ( move == 1 ) {
		            dc.drawText(70, 120, Gfx.FONT_SMALL, "(WALL SIT)", Gfx.TEXT_JUSTIFY_LEFT);
	        	} else if ( move == 2 ) {
		            dc.drawText(70, 120, Gfx.FONT_SMALL, "(PUSH UPS)", Gfx.TEXT_JUSTIFY_LEFT);
	        	} else if ( move == 3 ) {
		            dc.drawText(70, 120, Gfx.FONT_SMALL, "(AB CRUNCHES)", Gfx.TEXT_JUSTIFY_LEFT);
	        	} else if ( move == 4 ) {
		            dc.drawText(70, 120, Gfx.FONT_SMALL, "(CHAIR STEPS)", Gfx.TEXT_JUSTIFY_LEFT);
	        	} else if ( move == 5 ) {
		            dc.drawText(70, 120, Gfx.FONT_SMALL, "(SQUATS)", Gfx.TEXT_JUSTIFY_LEFT);
	        	} else if ( move == 6 ) {
		            dc.drawText(70, 120, Gfx.FONT_SMALL, "(CHAIR TRICEPS)", Gfx.TEXT_JUSTIFY_LEFT);
	        	} else if ( move == 7 ) {
		            dc.drawText(70, 120, Gfx.FONT_SMALL, "(PLANK)", Gfx.TEXT_JUSTIFY_LEFT);
	        	} else if ( move == 8 ) {
		            dc.drawText(70, 105, Gfx.FONT_SMALL, "(HIGH KNEES RUNNING)", Gfx.TEXT_JUSTIFY_LEFT);
	        	} else if ( move == 9 ) {
		            dc.drawText(70, 120, Gfx.FONT_SMALL, "(LUNGES)", Gfx.TEXT_JUSTIFY_LEFT);
	        	} else if ( move == 10 ) {
		            dc.drawText(70, 110, Gfx.FONT_SMALL, "(PUSH UP ROTATIONS)", Gfx.TEXT_JUSTIFY_LEFT);
	        	} else if ( move == 11 ) {
		            dc.drawText(70, 120, Gfx.FONT_SMALL, "(SIDE PLANK LEFT)", Gfx.TEXT_JUSTIFY_LEFT);
	        	} else if ( move == 12 ) {
		            dc.drawText(70, 120, Gfx.FONT_SMALL, "(SIDE PLANK RIGHT)", Gfx.TEXT_JUSTIFY_LEFT);
	        	}
	   		} else if ( move > 12 ) {	   		
		            dc.drawText(10, 30, Gfx.FONT_MEDIUM, "CONGRATULATIONS!", Gfx.TEXT_JUSTIFY_LEFT);
		            dc.drawText(10, 70, Gfx.FONT_MEDIUM, "You are ready.", Gfx.TEXT_JUSTIFY_LEFT);
	   		} else {
				//! move instructions        
				var activityTimeLeft = activityTime - count1;
	        	if ( move == 0 ) {
		            dc.drawText(10, 30, Gfx.FONT_MEDIUM, "JUMPING JACKS", Gfx.TEXT_JUSTIFY_LEFT);
	        	} else if ( move == 1 ) {
		            dc.drawText(10, 30, Gfx.FONT_MEDIUM, "WALL SIT", Gfx.TEXT_JUSTIFY_LEFT);
	        	} else if ( move == 2 ) {
		            dc.drawText(10, 30, Gfx.FONT_MEDIUM, "PUSH UPS", Gfx.TEXT_JUSTIFY_LEFT);
	        	} else if ( move == 3 ) {
		            dc.drawText(10, 30, Gfx.FONT_MEDIUM, "AB CRUNCHES", Gfx.TEXT_JUSTIFY_LEFT);
	        	} else if ( move == 4 ) {
		            dc.drawText(10, 30, Gfx.FONT_MEDIUM, "CHAIR STEPS", Gfx.TEXT_JUSTIFY_LEFT);
	        	} else if ( move == 5 ) {
		            dc.drawText(10, 30, Gfx.FONT_MEDIUM, "SQUATS", Gfx.TEXT_JUSTIFY_LEFT);
	        	} else if ( move == 6 ) {
		            dc.drawText(10, 30, Gfx.FONT_MEDIUM, "CHAIR TRICEPS", Gfx.TEXT_JUSTIFY_LEFT);
	        	} else if ( move == 7 ) {
		            dc.drawText(10, 30, Gfx.FONT_MEDIUM, "PLANK", Gfx.TEXT_JUSTIFY_LEFT);
	        	} else if ( move == 8 ) {
		            dc.drawText(1, 30, Gfx.FONT_MEDIUM, "HIGH KNEES RUNNING", Gfx.TEXT_JUSTIFY_LEFT);
	        	} else if ( move == 9 ) {
		            dc.drawText(10, 30, Gfx.FONT_MEDIUM, "LUNGES", Gfx.TEXT_JUSTIFY_LEFT);
	        	} else if ( move == 10 ) {
		            dc.drawText(5, 30, Gfx.FONT_MEDIUM, "PUSH UP ROTATIONS", Gfx.TEXT_JUSTIFY_LEFT);
	        	} else if ( move == 11 ) {
		            dc.drawText(10, 30, Gfx.FONT_MEDIUM, "SIDE PLANK LEFT", Gfx.TEXT_JUSTIFY_LEFT);
	        	} else if ( move == 12 ) {
		            dc.drawText(10, 30, Gfx.FONT_MEDIUM, "SIDE PLANK RIGHT", Gfx.TEXT_JUSTIFY_LEFT);
	        	}
	        	
	        	//! show activity time left
        		dc.drawText(10, 70, Gfx.FONT_LARGE, activityTimeLeft.toString(), Gfx.TEXT_JUSTIFY_LEFT);
	            dc.drawText(120, 77, Gfx.FONT_SMALL, "HR: " + heartRate.toString(), Gfx.TEXT_JUSTIFY_LEFT);
		        dc.drawText(10, 120, Gfx.FONT_SMALL, "seconds", Gfx.TEXT_JUSTIFY_LEFT);
			}			
			
        }

    }

}
