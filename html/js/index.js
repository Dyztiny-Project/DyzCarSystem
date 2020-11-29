// Function Declaration
const _$ = (query) => {
    const elm = document.querySelectorAll(query);
    if(elm.length == 1) return elm[0];
    else return elm;
},
_messageBomb = {

    toggleUI: (isShow) => {
        // Check UI toggle status.
        if(isShow) {
            // Remove old animation and show it on screen.
            _$('#allELM').style.animation = "";
            _$('#allELM').style.display = "block";
        } else {
            // Set fade out animation before hide element
            _$('#allELM').style.animation = "fadeOutDown .5s forwards";
            setTimeout(() => {
                _$('#allELM').style.display = "";
            }, 500);
        }
    },

    updateInfo: (data) => {

        /**
         * This event will update about the vehicle status:
         * 
         * - Vehicle's health progress.
         * - Vehicle's fuel progress.
         * - Current vehicle's speed.
         * - Current gear's number.
         * - The name of street where player is driving.
         */

        _$('#yeetHealth').style.width = data.carHealth + "%";
        _$('#yeetFuel').style.width = data.carFuel + "%";
        _$('#numSpeed').innerHTML = data.speed;
        _$('#gearNum').innerHTML = data.gear;
        _$('#placeName').innerHTML = data.streetName;
        _$('#speedUnit').innerHTML = data.speedUnit
    },

    toggleBelt: (data) => {

        /**
         * Check if belts is available for use then update the status.
         * Hide the belts's icon and red text status when it doesn't available.
         */

        if(!data.hasBelt) {
            _$('#belt').style.display = "none"
            _$('#txtNotice').style.display = "none";
            _$('#mainGUI').style.height = "39px";
            return false;
        }

        // Show belt icon.
        _$('#belt').style.display = "";
        _$('#txtNotice').style.display = "";

        // Check belt toggle and update ui.
        if(data.beltOn) {
            // Active belt status.
            _$('#mainGUI').style.height = "39px";
            _$('#txtNotice').style.display = "none";
            _$('#belt').classList.add('active');
            _$('#belt').getElementsByTagName('p')[0].innerHTML = "ON";
            _$('#belt').getElementsByTagName('p')[0].style.paddingLeft = "7px";
        } else {
            // Deactive belt status.
            _$('#mainGUI').style.height = "";
            _$('#txtNotice').style.display = "";
            _$('#belt').classList.remove('active');
            _$('#belt').getElementsByTagName('p')[0].innerHTML = "OFF";
            _$('#belt').getElementsByTagName('p')[0].style.paddingLeft = "";
        }
    },
    
    toggleCruise: (data) => {
        
        /**
         * Check if cruise is available for use then update the status.
         * Hide the cruise's icon when it doesn't available.
         */

        if(!data.hasCruise) {
            _$('#cruise').style.display = "none";
            return false;
        }

        // Show cruise icon.
        _$('#cruise').style.display = "";

        // Check cruise toggle and update ui.
        if(data.cruiseStatus) {
            // Active cruise status.
            _$('#cruise').classList.add('active');
            _$('#cruise').getElementsByTagName('p')[0].innerHTML = "ON";
            _$('#cruise').getElementsByTagName('p')[0].style.paddingLeft = "10px";
        } else {
            // Deactive cruise status.
            _$('#cruise').classList.remove('active');
            _$('#cruise').getElementsByTagName('p')[0].innerHTML = "OFF";
            _$('#cruise').getElementsByTagName('p')[0].style.paddingLeft = "";
        }
    },

    toggleEngine: (isEngineOn) => {
        // Check if engine is started and update ui.
        if(isEngineOn) {
            // Active engine status.
            _$('#engine').classList.add('active');
            _$('#engine').getElementsByTagName('p')[0].innerHTML = "ON";
            _$('#engine').getElementsByTagName('p')[0].style.paddingLeft = "3px";
        } else {
            // Deactive engine status.
            _$('#engine').classList.remove('active');
            _$('#engine').getElementsByTagName('p')[0].innerHTML = "OFF";
            _$('#engine').getElementsByTagName('p')[0].style.paddingLeft = "";
        }
    }
}

window.addEventListener('message', function(e) {
    // Ensure that event has exist.
    if(_messageBomb[e.data.event])
        _messageBomb[e.data.event](e.data.payload); // Drop the bomb.
})