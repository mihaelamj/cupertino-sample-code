/*
See LICENSE folder for this sample’s licensing information.

Abstract:
JSON data is retrieved from the server and used to populate a TVML document.
*/

var baseURL;

function getTemplate(url, jsonURL) {
    var xhr = new XMLHttpRequest();
    xhr.onreadystatechange = function () {
        if (this.readyState == 4 && this.status == 200) {
            getJson(jsonURL, xhr.responseXML);
        }
    }
    xhr.open("GET", url, false);
    xhr.send();
}

function getJson(url, template) {
    var templateXHR = new XMLHttpRequest();
    templateXHR.responseType = "document";
    templateXHR.addEventListener("load", function() {insertJson(templateXHR.responseText, template);}, false);
    templateXHR.open("GET", url, true);
    templateXHR.send();
}

function insertJson(information, template) {
    // Parse the JSON information.
    var results = JSON.parse(information);
    
    // Find the shelf elements.
    let shelves = template.getElementsByTagName('shelf');
    
    if (shelves.length > 0) {
        for (var i = 0; i < shelves.length; i++) {
            let shelf = shelves.item(i);
            let section = shelf.getElementsByTagName("section").item(0);
            // Create an empty data item for the section.
            section.dataItem = new DataItem();
            
            // Map JSON values to data item values depending on which shelf is presented.
            if (i == 0) { //first shelf
                let newItems = results.cars.map((result) => {
                    let objectItem = new DataItem(result.type, result.ID);
                    objectItem.url = baseURL + result.url;
                    objectItem.title = result.title;
                    objectItem.hoursRemaining = result.hoursRemaining;
                    return objectItem;
                });
                section.dataItem.setPropertyPath("images", newItems);
            } else {  //second shelf
                let newItems = results.beaches.map((result) => {
                    let objectItem = new DataItem(result.type, result.ID);
                    objectItem.url = baseURL + result.url;
                    objectItem.title = result.title;
                    objectItem.hoursRemaining = result.hoursRemaining;
                    return objectItem;
                });
                section.dataItem.setPropertyPath("images", newItems);
            }
        }
    }
    
    navigationDocument.pushDocument(template);
}


// Creates a loading template that displays a rotating circle while movie information is downloaded.
function loadTemplate() {
    let loadingTemplate = '<document><loadingTemplate><activityIndicator><text>Loading</text></activityIndicator></loadingTemplate></document>';
    return new DOMParser().parseFromString(loadingTemplate, "application/xml");
}

// Displays the latest template on the Apple TV.
function pushDoc(document) {
    navigationDocument.pushDocument(document);
}

App.onLaunch = function(options) {
    baseURL = options.BASEURL + "Server/";
    var jsonURL = baseURL + "JSON/movies.json";
    let templateURL = baseURL + "Templates/stack.xml";
    navigationDocument.pushDocument(loadTemplate());
    getTemplate(templateURL, jsonURL);
}
