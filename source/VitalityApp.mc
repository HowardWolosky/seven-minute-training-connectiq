using Toybox.Application as App;

class VitalityApp extends App.AppBase {

    var vitalityView;

    //! onStart() is called on application start up
    function onStart() {
    }

    //! onStop() is called when your application is exiting
    function onStop() {
        vitalityView.stopRecording();
    }

    //! Return the initial view of your application here
    function getInitialView() {
        vitalityView = new VitalityView();
        return [ vitalityView, new BaseInputDelegate() ];
    }

}