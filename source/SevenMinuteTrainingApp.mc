using Toybox.Application as App;

class SevenMinuteTrainingApp extends App.AppBase {
   
    var sevenMinView;
    
    //! onStart() is called on application start up
    function onStart() {
    }

    //! onStop() is called when your application is exiting
    function onStop() {
    	sevenMinView.stopRecording();
    }

    //! Return the initial view of your application here
    function getInitialView() {
        sevenMinView = new SevenMinuteTrainingView();
        return [ sevenMinView, new BaseInputDelegate() ];
    }

}