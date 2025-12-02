/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Main JavaScript file containing functions for loading data from the server and displaying that data onscreen.
*/

var baseURL;
var serverURL;

App.onLaunch = function(options) {
    baseURL = options.BASEURL;
    serverURL = options.BASEURL + "/Server";
    var extension = "/Templates/InitialPage.xml";
    getDocument(extension);
}

//Create a loading template in your application.js file so it appears when loading information from your sever.
function loadingTemplate() {
    var template = '<document><loadingTemplate><activityIndicator><text>Loading</text></activityIndicator></loadingTemplate></document>';
    var templateParser = new DOMParser();
    var parsedTemplate = templateParser.parseFromString(template, "application/xml");
    navigationDocument.pushDocument(parsedTemplate);
    return parsedTemplate;
}

//Get a new TVML document from the server. Upon success, call pushPage() to place it onto the navigationDocument stack.
function getDocument(extension) {
    var templateXHR = new XMLHttpRequest();
    var url = serverURL + extension;
    var loadingScreen = loadingTemplate();
    
    templateXHR.responseType = "document";
    templateXHR.addEventListener("load", function() {pushPage(templateXHR.responseXML, loadingScreen);}, false);
    templateXHR.open("GET", url, true);
    templateXHR.send();
}

/*
 Replace the current document with the new document. In this case, you want to replace the loading  document so that users don't see the loading document when backing out of the current document. Instead they go to the original document.
 */
function pushPage(page, loading) {
    var currentDoc = getActiveDocument();
    navigationDocument.replaceDocument(page, loading);
}
