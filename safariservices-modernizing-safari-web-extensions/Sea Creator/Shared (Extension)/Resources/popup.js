/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The popup script.
*/
browser.runtime.sendMessage({ type: "Word count request" }, (message) => {
    var countDiv = document.getElementById("totalCount");
    countDiv.appendChild(document.createTextNode(`You've replaced ${message.response} words`));
});

async function replaceWords()
{
    var tab = await browser.tabs.getCurrent();
    browser.scripting.executeScript({
        target : { tabId: tab.id },
        files : [ "replaceWords.js" ]
    });

    window.close();
}

function updateRules()
{
    var rule = {
        id : 2,
        priority : 1,
        action : { type : "allow" },
        condition : {
            urlFilter : "webkit.org/blog-files",
            resourceTypes : [ "image" ]
        }
    };

    browser.declarativeNetRequest.updateSessionRules({ addRules : [ rule ] });
    window.close();
};

document.addEventListener("DOMContentLoaded", function() {
    document.getElementById("replaceWords").addEventListener("click", replaceWords);
    document.getElementById("updateRules").addEventListener("click", updateRules);
});
