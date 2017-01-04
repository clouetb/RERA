var UI = require('ui');

var menuEntries = [
                   {
                   title: 'Vincennes',
                   subtitle: 'vers Noisiel',
                   latitude:48.8453956,
                   longitude:2.4261997,
                   distance:0,
                   id: 36,
                   destination: 2
                   },
                   {
                   title: 'Noisy-Champs',
                   subtitle: 'vers Noisiel',
                   latitude:48.8400735,
                   longitude:2.5979685,
                   distance:0,
                   id: 28,
                   destination: 2
                   },
                   {
                   title: 'Noisiel',
                   subtitle: 'vers Paris',
                   latitude:48.8435892,
                   longitude:2.6140001,
                   distance:0,
                   id: 26,
                   destination: 1
                   },
                   {
                   title: 'Vincennes',
                   subtitle: 'vers Paris',
                   latitude:48.8453956,
                   longitude:2.4261997,
                   distance:0,
                   id: 36,
                   destination: 1
                   },
                   {
                   title: 'Paris',
                   subtitle: 'vers Vincennes',
                   latitude:48.86188,
                   longitude:2.3414072,
                   distance:0,
                   id: 8,
                   destination: 2
                   }
                   ];

var menuStations = new UI.Menu({
                               sections: [{
                                          title: 'Stations',
                                          items: menuEntries
                                          }]
                               });

var currentSelection = 0;
var splashCard = new UI.Card({
                             title: "Chargement",
                             body: "Patientez..."
                             });

function selectElement(e) {
    splashCard.show();
    currentSelection = e.itemIndex;
    var elt = menuEntries[e.itemIndex];
    console.log('Selected : ' + elt.title + ' ' + elt.subtitle + ' ' + elt.url);
    updateMenu(elt);
}

menuStations.on('select', selectElement);

menuStations.show();

var ajax = require('ajax');
var Vibe = require('ui/vibe');
require('ui/accel');

var urlRoot = 'http://api-ratp.pierre-grimaud.fr/v2/rers/a/stations/';
var menuStation;

var locationOptions = {
enableHighAccuracy: true,
maximumAge: 10000,
timeout: 10000
};

menuStations.on('accelTap', function(e) {
                navigator.geolocation.getCurrentPosition(locationSuccess, locationError, locationOptions);
                Vibe.vibrate('short');
                });

function traceError(error){
    console.log("Download failed: " + error);
}

function updateMenu(m) {
    ajax(
         {
         url:urlRoot + m.id + "?destination=" + m.destination,
         type:'json'
         },
         function(data){
         var items = [];
         var titleElt = data.response.informations;
         var titleCaption = titleElt.station.name + ' > ' + titleElt.destination.name;
         var resultElts = data.response.schedules;
         
         //Vibe.vibrate('short');
         
         for (var i = 0 ; i < resultElts.length ; i++){
         items.push(
                    {
                    title: resultElts[i].destination,
                    subtitle: resultElts[i].message
                    }
                    );
         }
         menuStation = new UI.Menu({
                                   sections: [{
                                              title: titleCaption,
                                              items: items
                                              }]
                                   });
         menuStation.on('accelTap', function(e) {
                        splashCard.show();
                        menuStation.hide();
                        updateMenu(menuEntries[currentSelection]);
                        // Notify the user
                        // Vibe.vibrate('short');
                        });
         menuStation.show();
         splashCard.hide();
         },
         traceError
         );
}

function compare(a, b) {
    if (a.distance < b.distance)
        return -1;
    if (a.distance < b.distance)
        return 1;
    // a doit être égal à b
    return 0;
}

function distance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;    // Math.PI / 180
    var c = Math.cos;
    var a = 0.5 - c((lat2 - lat1) * p)/2 +
    c(lat1 * p) * c(lat2 * p) *
    (1 - c((lon2 - lon1) * p))/2;
    return 12742 * Math.asin(Math.sqrt(a)); // 2 * R; R = 6371 km
}

function locationSuccess(pos) {
    console.log('lat= ' + pos.coords.latitude + ' lon= ' + pos.coords.longitude);
    for (var i = 0 ; i < menuEntries.length ; i++){
        menuEntries[i].distance = distance(menuEntries[i].latitude,
                                           menuEntries[i].longitude,
                                           pos.coords.latitude,
                                           pos.coords.longitude);
        console.log('dist ' + menuEntries[i].title + ' = ' + menuEntries[i].distance);
    }
    menuEntries.sort(compare);
    // Pre-fill the list with the informations for the nearest station
    console.log(">>> " + urlRoot + menuEntries[0].id + "?destination=" + menuEntries[0].destination);
    ajax(
         {
         url:urlRoot + menuEntries[0].id + "?destination=" + menuEntries[0].destination,
         type:'json',
         async: false
         },
         function(data){
         console.log("Got data");
         var items = [];
         var resultElts = data.response.schedules;
         
         for (var i = 0 ; i < resultElts.length ; i++){
         items.push(
                    {
                    title: resultElts[i].destination,
                    subtitle: resultElts[i].message
                    }
                    );
         console.log("itm : " + resultElts[i].destination + ":" + resultElts[i].message);
         }
         for (i = (items.length -1) ; i > -1 ; i--){
         menuEntries.splice(1, 0, items[i]);
         }
         console.log("entries " + JSON.stringify(menuEntries, null, 4));
         menuStations.items(0, menuEntries);
         },
         traceError
         );
}

function locationError(err) {
    console.log('location error (' + err.code + '): ' + err.message);
}

// Make an asynchronous request
navigator.geolocation.getCurrentPosition(locationSuccess, locationError, locationOptions);
