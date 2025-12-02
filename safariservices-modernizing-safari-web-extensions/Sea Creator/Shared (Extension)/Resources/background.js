/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The background script.
*/
var wordReplacementCount = 0;

browser.runtime.onMessage.addListener((request, sender, sendResponse) => {
    if (request.type == "Words replaced")
        wordReplacementCount += request.count;

    if (request.type == "Word count request")
        sendResponse({ response: wordReplacementCount })
});

browser.runtime.onMessageExternal.addListener(function(message, sender, sendResponse) {
    if (message.action == "determineID")
        sendResponse({ response: "Extension installed" });
});

// Below is an example of code you'd have to add to a webpage to message an extension.
/*
function determineExtensionID(extensionID) {
    return new Promise((resolve) => {
        try {
            browser.runtime.sendMessage(extensionID, { action: 'determineID' }, function(response) {
                if (response)
                    resolve({ extensionID: extensionID, isInstalled: true, response: response });
                else
                    resolve({ extensionID: extensionID, isInstalled: false });
            });
        }
        catch (e) { reject(e); }
    });
};

 const extensionID = "com.MyExtension.MyExtensionName (<Team_Identifier>)";

Promise.all([determineExtensionID(extensionID)]).then((extensions) => {
    var extensionObject = extensions.find(extension => {
        if (extension && extension.isInstalled)
            return true;
    });

    const extensionIDToUse = extensionObject.extensionID;
});
 */





