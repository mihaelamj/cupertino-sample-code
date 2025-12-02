/*
See LICENSE folder for this sample’s licensing information.

Abstract:
JavaScript methods to load data from a server and play the corresponding media.
*/

var baseURL;

function loadingTemplate() {
    var template = '<document><loadingTemplate><activityIndicator><text>Loading</text></activityIndicator></loadingTemplate></document>';
    var templateParser = new DOMParser();
    var parsedTemplate = templateParser.parseFromString(template, "application/xml");
    navigationDocument.pushDocument(parsedTemplate);
}

function getDocument(extension) {
    var templateXHR = new XMLHttpRequest();
    var url = baseURL + extension;
    
    loadingTemplate();
    templateXHR.responseType = "document";
    templateXHR.addEventListener("load", function() {pushPage(templateXHR.responseXML);}, false);
    templateXHR.open("GET", url, true);
    templateXHR.send();
}

function pushPage(document) {
    var currentDoc = getActiveDocument();
    if (currentDoc.getElementsByTagName("loadingTemplate").item(0) == null) {
        navigationDocument.pushDocument(document);
    } else {
        navigationDocument.replaceDocument(document, currentDoc);
    }
}

function playMedia(extension, mediaType) {
    var mediaURL = baseURL + extension;
    var singleMediaItem = new MediaItem(mediaType, mediaURL);
    var mediaList = new Playlist();
    
    mediaList.push(singleMediaItem);
    var myPlayer = new Player();
    myPlayer.playlist = mediaList;
    myPlayer.play();
}

App.onLaunch = function(options) {
    baseURL = options.BASEURL;
    var extension = "/Server/Templates/initialpage.xml";
    getDocument(extension);
}
