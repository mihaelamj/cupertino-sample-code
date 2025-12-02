# Playing Media in a Client-Server App

Play media items in a client-server app using the built-in media player for TVMLKit JS.

## Overview

The TVML frameworks provide several built-in ways to play media items. After loading the initial page, the app automatically plays music in the background. The user navigates between two images and the app loads and plays a video or audio media item after the user selects an image. Both of these media items play using the built-in TVMLJKit JS media player.

## Configure the Sample Code Project

Before running the app, you need to set up a local server on your machine:
1. In Finder, navigate to the PlayingMedia directory inside of the PlayingMedia project directory.
2. In Terminal, enter at the prompt, `cd` followed by a space.
3. Drag the PlayingMedia folder from the Finder window into the Terminal window, and press Return. This changes the directory to that folder.
4. In Terminal, enter `ruby -run -ehttpd . -p9001` to run the server.
5. Build and run the app.

After testing the sample app in Apple TV Simulator, you can close the local server by pressing Control-C in Terminal. Closing the Terminal window also kills the server.

## Play Background Audio

To incorporate background audio into your TVML app, add the [`background`](https://developer.apple.com/documentation/tvml/background_elements/background) element to your TVML file. Inside of the background element, insert an [`audio`](https://developer.apple.com/documentation/tvml/background_elements/audio) element that contains an [`asset`](https://developer.apple.com/documentation/tvml/multimedia_elements/asset) element with a link to the music file. No changes to your JavaScript file are required. The audio automatically plays after pushing the document on to the documentation stack and displaying it on the TV.

```
<background>
    <audio>
        <asset src="http://localhost:9001/Server/Media/Rhythm.aif" />
    </audio>
</background>
```

## Play Media Using the Built-in Media Player

The user chooses one of the displayed elements to play—either a video or audio media item. The associated [`lockup`](https://developer.apple.com/documentation/tvml/lockup_elements/lockup) element contains the location and type of the media item; both must be present to create a [`MediaItem`](https://developer.apple.com/documentation/tvmljs/mediaitem) object.

```
<lockup onselect="playMedia('Server/Media/video1.mp4', 'video')">
    <img width="182" height="274" src="http://localhost:9001/Server/Images/Beach_Movie_250x375_A.png" />
    <title>Video</title>
</lockup>
```

To play a media item using the built-in media player, you must create a `MediaItem` object, push that object on to a [`Playlist`](https://developer.apple.com/documentation/tvmljs/playlist) object, and then add the playlist to the [`Player`](https://developer.apple.com/documentation/tvmljs/player) object. Finally, to begin playback, call the [`play`](https://developer.apple.com/documentation/tvmljs/player/1627432-play) function on the player.

``` javascript
function playMedia(extension, mediaType) {
    var mediaURL = baseURL + extension;
    var singleMediaItem = new MediaItem(mediaType, mediaURL);
    var mediaList = new Playlist();
    
    mediaList.push(singleMediaItem);
    var myPlayer = new Player();
    myPlayer.playlist = mediaList;
    myPlayer.play();
}
```
